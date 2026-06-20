import 'package:clover/feature/profile_page/data/model/profile_new_model.dart';

/// Лимиты смены никнейма (`enforce_username_change_limit` на бэке).
class EditProfileUsernamePolicy {
  const EditProfileUsernamePolicy._({
    required this.effectiveChangeCount,
    required this.cooldownUntil,
  });

  factory EditProfileUsernamePolicy.fromProfile(ProfileNewModel profile) {
    final rawCount = profile.usernameChangeCount;
    final cooldown = profile.usernameNextChangeAllowedAt?.toUtc();
    final now = DateTime.now().toUtc();

    if (cooldown != null && !now.isBefore(cooldown)) {
      return const EditProfileUsernamePolicy._(
        effectiveChangeCount: 0,
        cooldownUntil: null,
      );
    }

    return EditProfileUsernamePolicy._(
      effectiveChangeCount: rawCount,
      cooldownUntil: cooldown,
    );
  }

  static const maxChangesPerWindow = 4;

  final int effectiveChangeCount;
  final DateTime? cooldownUntil;

  bool get isInCooldown {
    final until = cooldownUntil;
    if (until == null) return false;
    return DateTime.now().toUtc().isBefore(until);
  }

  bool get canChange => !isInCooldown && effectiveChangeCount < maxChangesPerWindow;

  int get remainingChanges => (maxChangesPerWindow - effectiveChangeCount).clamp(0, maxChangesPerWindow);

  String? get statusHint {
    if (isInCooldown && cooldownUntil != null) {
      final local = cooldownUntil!.toLocal();
      final date =
          '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} '
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      return 'Смена никнейма будет доступна после $date';
    }
    if (!canChange) {
      return 'Лимит смен никнейма исчерпан';
    }
    if (remainingChanges < maxChangesPerWindow) {
      return 'Осталось смен: $remainingChanges из $maxChangesPerWindow';
    }
    return 'Латиница, цифры, «_» и «.». Не более $maxChangesPerWindow смен за 7 дней';
  }
}
