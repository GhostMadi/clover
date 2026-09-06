import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';

/// Членство работника в компании (локальный snapshot).
class AttendanceMembership {
  const AttendanceMembership({
    required this.workplaceId,
    required this.workplaceName,
    this.id,
    this.profileId,
    this.status = AttendanceWorkerInviteStatus.accepted,
    this.shiftOpen = false,
    this.ackVersion = 1,
    this.configVersion = 1,
    this.lastPunchLabel,
    this.lastPunchAt,
  });

  final String? id;
  final String workplaceId;
  final String workplaceName;
  final String? profileId;
  final AttendanceWorkerInviteStatus status;
  final bool shiftOpen;
  final int ackVersion;
  final int configVersion;
  final String? lastPunchLabel;
  final DateTime? lastPunchAt;

  bool get needsAck => status == AttendanceWorkerInviteStatus.accepted && ackVersion < configVersion;

  bool get isActive => status == AttendanceWorkerInviteStatus.accepted;

  bool get isPending => status == AttendanceWorkerInviteStatus.pending;

  AttendanceMembership copyWith({
    String? id,
    String? profileId,
    AttendanceWorkerInviteStatus? status,
    bool? shiftOpen,
    int? ackVersion,
    int? configVersion,
    String? lastPunchLabel,
    DateTime? lastPunchAt,
    bool clearLastPunch = false,
  }) {
    return AttendanceMembership(
      id: id ?? this.id,
      workplaceId: workplaceId,
      workplaceName: workplaceName,
      profileId: profileId ?? this.profileId,
      status: status ?? this.status,
      shiftOpen: shiftOpen ?? this.shiftOpen,
      ackVersion: ackVersion ?? this.ackVersion,
      configVersion: configVersion ?? this.configVersion,
      lastPunchLabel: clearLastPunch ? null : (lastPunchLabel ?? this.lastPunchLabel),
      lastPunchAt: clearLastPunch ? null : (lastPunchAt ?? this.lastPunchAt),
    );
  }
}
