import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/feature/onboarding/data/onboarding_tip_id.dart';
import 'package:injectable/injectable.dart';

/// Persists which onboarding / service tips a user has already seen.
///
/// Keys are per-user under `resource_` so logout не сбрасывает прогресс,
/// но разные аккаунты на одном устройстве не мешают друг другу.
@lazySingleton
class OnboardingStore {
  OnboardingStore(this._storage);

  final IAppStorage _storage;

  static String _key(String userId) => 'resource_onboarding_seen_$userId';

  Future<Set<String>> _readRaw(String userId) async {
    final list = await _storage.read<List<dynamic>>(key: _key(userId));
    if (list == null) return <String>{};
    return list.whereType<String>().toSet();
  }

  Future<void> _writeRaw(String userId, Set<String> ids) {
    return _storage.write<List<dynamic>>(
      key: _key(userId),
      value: ids.toList(growable: false),
    );
  }

  Future<bool> hasSeen(String userId, OnboardingTipId tipId) async {
    final seen = await _readRaw(userId);
    return seen.contains(tipId.storageValue);
  }

  Future<void> markSeen(String userId, OnboardingTipId tipId) async {
    final seen = await _readRaw(userId);
    if (seen.add(tipId.storageValue)) {
      await _writeRaw(userId, seen);
    }
  }

  /// Для будущих service-tips: список ещё не показанных.
  Future<List<OnboardingTipId>> unseenOf(
    String userId,
    Iterable<OnboardingTipId> candidates,
  ) async {
    final seen = await _readRaw(userId);
    return [
      for (final id in candidates)
        if (!seen.contains(id.storageValue)) id,
    ];
  }
}
