import 'dart:async';

import 'package:clover/core/catalog_sync/domain/catalog_sync_manager.dart';
import 'package:clover/core/catalog_sync/models/sync_meta.dart';
import 'package:clover/feature/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/profile_page/data/model/profile_new_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Чтение профиля из `public.profiles_with_sync_meta`.
abstract class ProfileNewRepository {
  /// Профиль по id (совпадает с id пользователя в auth).
  Future<ProfileNewModel?> getById(String id);

  /// Профиль текущего авторизованного пользователя.
  Future<ProfileNewModel?> getCurrent();
}

@Injectable(as: ProfileNewRepository)
class ProfileNewRepositoryImpl implements ProfileNewRepository {
  ProfileNewRepositoryImpl(this._client, this._catalogSync);

  final SupabaseClient _client;
  final CatalogSyncManager _catalogSync;

  static const _profileTable = 'profiles_with_sync_meta';

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
has_filters,
bonus_program_status,
sync_meta
''';

  /// Профиль + tag_ids + теги + встроенный sync_meta.
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
      data = await _client.from(_profileTable).select(_columnsWithTags).eq('id', trimmed).maybeSingle();
    } on PostgrestException catch (error) {
      if (!_isMissingTagsSchema(error)) rethrow;
      data = await _client.from(_profileTable).select(_baseColumns).eq('id', trimmed).maybeSingle();
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

  ProfileNewModel _mapProfile(Object row) {
    final normalized = _normalizeRow(row);
    final syncMeta = _parseEmbeddedSyncMeta(normalized);
    final tags = _parseTags(normalized.remove('account_tags'));
    final profile = ProfileNewModel.fromJson(normalized);

    final result = profile.copyWith(tags: tags, syncMeta: syncMeta);
    if (syncMeta != null) {
      unawaited(_catalogSync.validateAndSync(syncMeta));
    }
    return result;
  }

  static SyncMeta? _parseEmbeddedSyncMeta(Map<String, dynamic> map) {
    final nested = map.remove('sync_meta');
    if (nested is! Map) return null;

    final meta = SyncMeta.fromJson(Map<String, dynamic>.from(nested));
    return meta.isValid ? meta : null;
  }

  static bool _isMissingTagsSchema(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == '42703' ||
        error.code == 'PGRST200' ||
        error.code == 'PGRST204' ||
        message.contains('tag_link_id') ||
        message.contains('profile_tag_links') ||
        message.contains('relationship') ||
        message.contains('schema cache') ||
        message.contains('profiles_with_sync_meta');
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
