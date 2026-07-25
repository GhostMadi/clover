import 'package:clover/feature/_bonus_/shared/data/models/bonus_program_status.dart';

/// Общие настройки бонусной программы (сейчас — только вкл/выкл).
class BonusProgramSettings {
  const BonusProgramSettings({required this.status});

  final BonusProgramStatus status;

  bool get isEnabled => status.isActive;

  factory BonusProgramSettings.defaults() {
    return const BonusProgramSettings(status: BonusProgramStatus.inactive);
  }

  factory BonusProgramSettings.fromStatus(BonusProgramStatus status) {
    return BonusProgramSettings(status: status);
  }

  BonusProgramSettings copyWith({BonusProgramStatus? status}) {
    return BonusProgramSettings(status: status ?? this.status);
  }
}
