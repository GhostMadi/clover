import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_duty_roster.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';

/// Компания / workplace (mock UI).
class AttendanceWorkplace {
  const AttendanceWorkplace({
    required this.id,
    required this.name,
    this.folderId,
    this.latitude,
    this.longitude,
    this.geofenceRadiusM = 150,
    this.clockInEnabled = true,
    this.clockOutEnabled = true,
    this.clockInScheduledTime,
    this.clockOutScheduledTime,
    this.customPunches = const [],
    this.payrollRules = const AttendancePayrollRules(),
    this.workerBaseSalaries = const {},
    this.dutyRoster = const AttendanceDutyRoster(),
    this.isAdmin = false,
  });

  final String id;
  final String name;
  final String? folderId;
  final double? latitude;
  final double? longitude;
  final int geofenceRadiusM;

  final bool clockInEnabled;
  final bool clockOutEnabled;

  /// Когда ожидается «Пришёл» (например 09:00).
  final AttendanceDayTime? clockInScheduledTime;

  /// Когда ожидается «Ушёл» (например 18:00).
  final AttendanceDayTime? clockOutScheduledTime;

  final List<AttendanceCustomPunchConfig> customPunches;
  final AttendancePayrollRules payrollRules;

  /// Оклад работника, ₸ (ключ — worker id).
  final Map<String, int> workerBaseSalaries;
  final AttendanceDutyRoster dutyRoster;
  final bool isAdmin;

  bool get hasSystemPunch => clockInEnabled || clockOutEnabled;

  List<AttendanceSystemPunchCode> get enabledSystemCodes {
    final codes = <AttendanceSystemPunchCode>[];
    if (clockInEnabled) codes.add(AttendanceSystemPunchCode.clockIn);
    if (clockOutEnabled) codes.add(AttendanceSystemPunchCode.clockOut);
    return codes;
  }

  List<AttendancePunchType> get enabledSystemTypes =>
      enabledSystemCodes.map((c) => c.toType()).toList(growable: false);

  List<AttendancePunchType> get customPunchTypes =>
      customPunches.map((e) => AttendancePunchType.custom(e.label)).toList(growable: false);

  AttendancePunchType? resolvePrimaryPunchType({required bool shiftOpen}) {
    if (clockInEnabled && clockOutEnabled) {
      return shiftOpen ? AttendancePunchType.clockOut : AttendancePunchType.clockIn;
    }
    if (clockInEnabled) return AttendancePunchType.clockIn;
    if (clockOutEnabled) return AttendancePunchType.clockOut;
    return null;
  }

  bool get hasGeofenceCenter => latitude != null && longitude != null;

  AttendanceWorkplace copyWith({
    String? name,
    String? folderId,
    double? latitude,
    double? longitude,
    int? geofenceRadiusM,
    bool? clockInEnabled,
    bool? clockOutEnabled,
    AttendanceDayTime? clockInScheduledTime,
    AttendanceDayTime? clockOutScheduledTime,
    bool clearClockInScheduledTime = false,
    bool clearClockOutScheduledTime = false,
    List<AttendanceCustomPunchConfig>? customPunches,
    AttendancePayrollRules? payrollRules,
    Map<String, int>? workerBaseSalaries,
    AttendanceDutyRoster? dutyRoster,
    bool? isAdmin,
  }) {
    return AttendanceWorkplace(
      id: id,
      name: name ?? this.name,
      folderId: folderId ?? this.folderId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadiusM: geofenceRadiusM ?? this.geofenceRadiusM,
      clockInEnabled: clockInEnabled ?? this.clockInEnabled,
      clockOutEnabled: clockOutEnabled ?? this.clockOutEnabled,
      clockInScheduledTime:
          clearClockInScheduledTime ? null : (clockInScheduledTime ?? this.clockInScheduledTime),
      clockOutScheduledTime:
          clearClockOutScheduledTime ? null : (clockOutScheduledTime ?? this.clockOutScheduledTime),
      customPunches: customPunches ?? this.customPunches,
      payrollRules: payrollRules ?? this.payrollRules,
      workerBaseSalaries: workerBaseSalaries ?? this.workerBaseSalaries,
      dutyRoster: dutyRoster ?? this.dutyRoster,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

/// Папка для группировки компаний в admin UI.
class AttendanceFolder {
  const AttendanceFolder({required this.id, required this.name});

  final String id;
  final String name;
}
