/// Статус бонусной программы host-аккаунта (`public.bonus_program_status`).
enum BonusProgramStatus {
  active,
  inactive;

  bool get isActive => this == BonusProgramStatus.active;

  String get dbValue => switch (this) {
        BonusProgramStatus.active => 'active',
        BonusProgramStatus.inactive => 'inactive',
      };

  static BonusProgramStatus fromDb(String? raw) {
    return switch (raw?.trim()) {
      'active' => BonusProgramStatus.active,
      _ => BonusProgramStatus.inactive,
    };
  }
}
