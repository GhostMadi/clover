import 'package:clover/feature/onboarding/data/onboarding_store.dart';
import 'package:clover/feature/onboarding/data/onboarding_tip_catalog.dart';
import 'package:clover/feature/onboarding/data/onboarding_tip_id.dart';
import 'package:injectable/injectable.dart';

/// Выбирает следующий unseen tip для surface с учётом кэша и тегов профиля.
@lazySingleton
class OnboardingTipResolver {
  OnboardingTipResolver(this._store);

  final OnboardingStore _store;

  /// [profileTagKeys] — EN ключи супер-тегов уже загруженного профиля (можно пустой set).
  Future<OnboardingTipDefinition?> nextForSurface({
    required String userId,
    required String surface,
    Set<String> profileTagKeys = const {},
  }) async {
    final uid = userId.trim();
    final surf = surface.trim();
    if (uid.isEmpty || surf.isEmpty) return null;

    final candidates = OnboardingTipCatalog.forSurface(surf);
    if (candidates.isEmpty) return null;

    final unseen = await _store.unseenOf(
      uid,
      candidates.map((c) => c.id),
    );
    if (unseen.isEmpty) return null;

    final unseenSet = unseen.toSet();
    final tags = {
      for (final t in profileTagKeys) t.trim().toLowerCase(),
    }..removeWhere((e) => e.isEmpty);

    final eligible = <OnboardingTipDefinition>[
      for (final tip in candidates)
        if (unseenSet.contains(tip.id) && _passesGate(tip, tags)) tip,
    ]..sort((a, b) => a.priority.compareTo(b.priority));

    return eligible.isEmpty ? null : eligible.first;
  }

  Future<void> markSeen(String userId, OnboardingTipId tipId) {
    return _store.markSeen(userId, tipId);
  }

  bool _passesGate(OnboardingTipDefinition tip, Set<String> tags) {
    switch (tip.gate) {
      case OnboardingTipGate.onceOnSurface:
        return true;
      case OnboardingTipGate.onceOnSurfaceWithTag:
        final need = tip.requiredTag?.trim().toLowerCase();
        if (need == null || need.isEmpty) return true;
        return tags.contains(need);
    }
  }
}
