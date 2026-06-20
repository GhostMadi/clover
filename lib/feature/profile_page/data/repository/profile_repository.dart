import 'package:clover/feature/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/profile_page/data/model/profile_new_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Чтение профиля из `public.profiles`.
abstract class ProfileNewRepository {
  /// Профиль по id (совпадает с id пользователя в auth).
  Future<ProfileNewModel?> getById(String id);

  /// Профиль текущего авторизованного пользователя.
  Future<ProfileNewModel?> getCurrent();
}

@Injectable(as: ProfileNewRepository)
class ProfileNewRepositoryImpl implements ProfileNewRepository {
  ProfileNewRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _baseColumns = '''
id,
email,
full_name,
username,
category_code,
city_code,
country_code,
avatar_url,
background_url,
bio,
phone,
followers_count,
following_count,
cluster_count,
post_count,
username_change_count,
username_next_change_allowed_at,
created_at,
updated_at,
hiring_enabled,
open_for_memberships,
has_filters
''';

  /// Один запрос: профиль + tag_ids + готовые теги из profile_tag_links.tags.
  static const _columnsWithTags = '''
$_baseColumns,
tag_link_id,
profile_tag_links!tag_link_id(tag_ids, tags)
''';

  @override
  Future<ProfileNewModel?> getById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;

    Map<String, dynamic>? data;

    try {
      data = await _client.from('profiles').select(_columnsWithTags).eq('id', trimmed).maybeSingle();
    } on PostgrestException catch (error) {
      if (!_isMissingTagsSchema(error)) rethrow;
      data = await _client.from('profiles').select(_baseColumns).eq('id', trimmed).maybeSingle();
    }

    if (data == null) return null;

    return _mapProfile(data);
  }

  @override
  Future<ProfileNewModel?> getCurrent() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return getById(uid);
  }

  static ProfileNewModel _mapProfile(Object row) {
    final normalized = _normalizeRow(row);
    final tags = _parseTags(normalized.remove('account_tags'));
    final profile = ProfileNewModel.fromJson(normalized);
    return profile.copyWith(tags: tags);
  }

  static bool _isMissingTagsSchema(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == '42703' ||
        error.code == 'PGRST200' ||
        error.code == 'PGRST204' ||
        message.contains('tag_link_id') ||
        message.contains('profile_tag_links') ||
        message.contains('relationship') ||
        message.contains('schema cache');
  }

  static Map<String, dynamic> _normalizeRow(Object row) {
    final map = Map<String, dynamic>.from(row as Map);
    if (!map.containsKey('cluster_count') && map.containsKey('collection_count')) {
      map['cluster_count'] = map['collection_count'];
    }

    final nested = map.remove('profile_tag_links');
    if (nested is Map) {
      final rawIds = nested['tag_ids'];
      if (rawIds is List) {
        map['tag_ids'] = [
          for (final id in rawIds)
            if (id != null) id.toString(),
        ];
      }

      map['account_tags'] = nested['tags'];
    }

    if (!map.containsKey('tag_ids')) {
      map['tag_ids'] = const <String>[];
    }

    return map;
  }

  static List<MarkerTagModel> _parseTags(dynamic raw) {
    if (raw is! List) return const [];

    final tags = <MarkerTagModel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      tags.add(MarkerTagModel.fromJson(Map<String, dynamic>.from(item)));
    }

    return List.unmodifiable(tags);
  }
}
