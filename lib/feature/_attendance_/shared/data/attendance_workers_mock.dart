/// Mock-список работников компании (UI v1).
abstract final class AttendanceWorkersMock {
  static const accepted = AttendanceWorkerListItem(
    id: 'worker_you',
    displayName: 'Вы',
    username: '@you',
    status: AttendanceWorkerInviteStatus.accepted,
  );

  static const mariaPending = AttendanceWorkerListItem(
    id: 'worker_maria',
    displayName: 'Мария',
    username: '@maria',
    status: AttendanceWorkerInviteStatus.pending,
  );

  static const ivanAccepted = AttendanceWorkerListItem(
    id: 'worker_ivan',
    displayName: 'Иван',
    username: '@ivan',
    status: AttendanceWorkerInviteStatus.accepted,
  );

  static const aidanaAccepted = AttendanceWorkerListItem(
    id: 'worker_aidana',
    displayName: 'Айдана',
    username: '@aidana',
    status: AttendanceWorkerInviteStatus.accepted,
  );

  static const sergeyArchived = AttendanceWorkerListItem(
    id: 'worker_sergey',
    displayName: 'Сергей',
    username: '@sergey',
    status: AttendanceWorkerInviteStatus.archived,
  );

  /// Кандидаты для «Добавить работника» (ещё не в команде).
  static const inviteCandidates = <AttendanceWorkerListItem>[
    AttendanceWorkerListItem(
      id: 'worker_nurlan',
      displayName: 'Нурлан',
      username: '@nurlan',
      status: AttendanceWorkerInviteStatus.pending,
    ),
    AttendanceWorkerListItem(
      id: 'worker_aliya',
      displayName: 'Алия',
      username: '@aliya',
      status: AttendanceWorkerInviteStatus.pending,
    ),
  ];

  static List<AttendanceWorkerListItem> forWorkplace(String workplaceId) {
    return const [accepted, mariaPending, ivanAccepted, aidanaAccepted, sergeyArchived];
  }

  static AttendanceWorkerListItem? byId(String workerId) {
    for (final w in forWorkplace('')) {
      if (w.id == workerId) return w;
    }
    for (final w in inviteCandidates) {
      if (w.id == workerId) return w;
    }
    return null;
  }
}

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
