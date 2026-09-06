import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';

/// Локальный seed для offline/demo snapshot (не remote path).
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

  static const teamSeed = <AttendanceWorkerListItem>[
    accepted,
    mariaPending,
    ivanAccepted,
    aidanaAccepted,
    sergeyArchived,
  ];

  /// Кандидаты для «Добавить работника» (ещё не в команде) — только demo.
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

  static AttendanceWorkerListItem? byId(String workerId) {
    for (final w in teamSeed) {
      if (w.id == workerId) return w;
    }
    for (final w in inviteCandidates) {
      if (w.id == workerId) return w;
    }
    return null;
  }
}
