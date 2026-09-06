enum AttendanceCorrectionStatus {
  pending,
  approved,
  rejected,
}

extension AttendanceCorrectionStatusX on AttendanceCorrectionStatus {
  String get key => switch (this) {
        AttendanceCorrectionStatus.pending => 'pending',
        AttendanceCorrectionStatus.approved => 'approved',
        AttendanceCorrectionStatus.rejected => 'rejected',
      };

  String get labelRu => switch (this) {
        AttendanceCorrectionStatus.pending => 'Ожидает',
        AttendanceCorrectionStatus.approved => 'Утверждено',
        AttendanceCorrectionStatus.rejected => 'Отклонено',
      };

  static AttendanceCorrectionStatus fromKey(String? raw) => switch (raw) {
        'approved' => AttendanceCorrectionStatus.approved,
        'rejected' => AttendanceCorrectionStatus.rejected,
        _ => AttendanceCorrectionStatus.pending,
      };
}

class AttendanceCorrectionRequest {
  const AttendanceCorrectionRequest({
    required this.id,
    required this.workplaceId,
    required this.punchId,
    required this.profileId,
    required this.workerName,
    required this.status,
    required this.createdAt,
    this.note,
    this.proposedPunchedAt,
    this.resolvedAt,
    this.punchKind,
    this.punchedAt,
  });

  final String id;
  final String workplaceId;
  final String punchId;
  final String profileId;
  final String workerName;
  final AttendanceCorrectionStatus status;
  final DateTime createdAt;
  final String? note;
  final DateTime? proposedPunchedAt;
  final DateTime? resolvedAt;
  final String? punchKind;
  final DateTime? punchedAt;

  String get punchKindLabelRu => switch (punchKind) {
        'clock_in' => 'Пришёл',
        'clock_out' => 'Ушёл',
        final k when k != null && k.isNotEmpty => k,
        _ => 'Отметка',
      };

  AttendanceCorrectionRequest copyWith({AttendanceCorrectionStatus? status, DateTime? resolvedAt}) {
    return AttendanceCorrectionRequest(
      id: id,
      workplaceId: workplaceId,
      punchId: punchId,
      profileId: profileId,
      workerName: workerName,
      status: status ?? this.status,
      createdAt: createdAt,
      note: note,
      proposedPunchedAt: proposedPunchedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      punchKind: punchKind,
      punchedAt: punchedAt,
    );
  }

  factory AttendanceCorrectionRequest.fromJson(Map<String, dynamic> json) {
    return AttendanceCorrectionRequest(
      id: json['id']?.toString() ?? '',
      workplaceId: json['workplace_id']?.toString() ?? '',
      punchId: json['punch_id']?.toString() ?? '',
      profileId: json['profile_id']?.toString() ?? '',
      workerName: json['worker_name']?.toString() ?? 'Работник',
      status: AttendanceCorrectionStatusX.fromKey(json['status']?.toString()),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      note: json['note']?.toString(),
      proposedPunchedAt: DateTime.tryParse(json['proposed_punched_at']?.toString() ?? '')?.toLocal(),
      resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? '')?.toLocal(),
      punchKind: json['punch_kind']?.toString(),
      punchedAt: DateTime.tryParse(json['punched_at']?.toString() ?? '')?.toLocal(),
    );
  }
}
