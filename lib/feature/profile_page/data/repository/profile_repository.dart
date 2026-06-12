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

  /// Явный список колонок — проще читать, чем `select()` без аргументов.
  static const _columns = '''
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
open_for_memberships
''';

  @override
  Future<ProfileNewModel?> getById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;

    final data = await _client.from('profiles').select(_columns).eq('id', trimmed).maybeSingle();
    if (data == null) return null;

    return ProfileNewModel.fromJson(_normalizeRow(data));
  }

  @override
  Future<ProfileNewModel?> getCurrent() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return getById(uid);
  }

  /// PostgREST иногда отдаёт старое имя счётчика коллекций.
  static Map<String, dynamic> _normalizeRow(Object row) {
    final map = Map<String, dynamic>.from(row as Map);
    if (!map.containsKey('cluster_count') && map.containsKey('collection_count')) {
      map['cluster_count'] = map['collection_count'];
    }
    return map;
  }
}
