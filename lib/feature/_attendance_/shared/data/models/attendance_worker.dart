/// Статус invite / membership работника в компании.
enum AttendanceWorkerInviteStatus {
  accepted,
  pending,
  archived,
  /// Отклонил invite — вне команды, не в вкладках.
  declined,
}

extension AttendanceWorkerInviteStatusX on AttendanceWorkerInviteStatus {
  String get labelRu => switch (this) {
        AttendanceWorkerInviteStatus.accepted => 'Принят',
        AttendanceWorkerInviteStatus.pending => 'Ожидает приглашения',
        AttendanceWorkerInviteStatus.archived => 'В архиве',
        AttendanceWorkerInviteStatus.declined => 'Отклонён',
      };

  bool get isActive => this == AttendanceWorkerInviteStatus.accepted;
}

/// Работник в списках admin / absences / payroll.
class AttendanceWorkerListItem {
  const AttendanceWorkerListItem({
    required this.id,
    required this.displayName,
    required this.username,
    required this.status,
  });

  final String id;
  final String displayName;
  final String username;
  final AttendanceWorkerInviteStatus status;

  bool get isAccepted => status == AttendanceWorkerInviteStatus.accepted;

  bool get isPending => status == AttendanceWorkerInviteStatus.pending;

  bool get isArchived => status == AttendanceWorkerInviteStatus.archived;

  bool get isDeclined => status == AttendanceWorkerInviteStatus.declined;

  AttendanceWorkerListItem copyWith({AttendanceWorkerInviteStatus? status}) {
    return AttendanceWorkerListItem(
      id: id,
      displayName: displayName,
      username: username,
      status: status ?? this.status,
    );
  }
}
