import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:injectable/injectable.dart';

/// Кэш профиля: свой — диск; любой userId — memory на сессию (guest local-first).
@lazySingleton
class ProfileLocalCache {
  ProfileLocalCache(this._storage);

  final IAppStorage _storage;

  final Map<String, ProfileNewModel> _memoryProfiles = {};
  final Map<String, bool> _memoryFollowing = {};

  static String _diskKey(String userId) => 'profile_current_$userId';

  // --- Own profile (disk) -------------------------------------------------

  Future<ProfileNewModel?> read(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return null;

    return _storage.readObject<ProfileNewModel>(
      key: _diskKey(id),
      fromJson: _fromCacheJson,
    );
  }

  Future<void> write(ProfileNewModel profile) async {
    final id = profile.id.trim();
    if (id.isEmpty) return;

    putMemoryProfile(profile);
    await _storage.writeObject(
      key: _diskKey(id),
      value: profile,
      toJson: _toCacheJson,
    );
  }

  Future<void> clear(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return;
    _memoryProfiles.remove(id);
    _memoryFollowing.remove(id);
    await _storage.delete(key: _diskKey(id));
  }

  // --- Session memory (own + guest) ---------------------------------------

  ProfileNewModel? readMemoryProfile(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return null;
    return _memoryProfiles[id];
  }

  void putMemoryProfile(ProfileNewModel profile) {
    final id = profile.id.trim();
    if (id.isEmpty) return;
    _memoryProfiles[id] = profile;
  }

  bool? readMemoryFollowing(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return null;
    return _memoryFollowing[id];
  }

  void putMemoryFollowing(String userId, bool isFollowing) {
    final id = userId.trim();
    if (id.isEmpty) return;
    _memoryFollowing[id] = isFollowing;
  }

  /// Выход из аккаунта: чужие профили и follow-флаги не переживают сессию.
  void clearSessionMemory() {
    _memoryProfiles.clear();
    _memoryFollowing.clear();
  }

  static Map<String, dynamic> _toCacheJson(ProfileNewModel profile) {
    final json = Map<String, dynamic>.from(profile.toJson());
    json['account_tags'] = [
      for (final tag in profile.tags) tag.toJson(),
    ];
    return json;
  }

  static ProfileNewModel _fromCacheJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawTags = map.remove('account_tags');
    final tags = <MarkerTagModel>[];
    if (rawTags is List) {
      for (final item in rawTags) {
        if (item is! Map) continue;
        tags.add(MarkerTagModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return ProfileNewModel.fromJson(map).copyWith(tags: List.unmodifiable(tags));
  }
}
