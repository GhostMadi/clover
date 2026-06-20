import 'package:clover/feature/work/data/models/work_member.dart';
import 'package:clover/feature/work/data/models/work_relation_status.dart';
import 'package:clover/feature/work/data/models/work_relation_type.dart';

class WorkRelationModel {
  const WorkRelationModel({
    required this.id,
    required this.type,
    required this.status,
    required this.initiatorId,
    required this.peer,
    required this.currentUserId,
    this.updatedAt,
  });

  final String id;
  final WorkRelationType type;
  final WorkRelationStatus status;
  final String initiatorId;
  final WorkMember peer;
  final String currentUserId;
  final DateTime? updatedAt;

  bool get isIncoming => initiatorId.trim() != currentUserId.trim();

  String get incomingMessage => switch (type) {
    WorkRelationType.hire => '${peer.displayUsername} хочет добавить вас как работника',
    WorkRelationType.join => '${peer.displayUsername} хочет присоединиться к вашей команде',
  };

  String? get outgoingCustomMessage => isIncoming
      ? null
      : switch (type) {
          WorkRelationType.hire => 'Приглашение отправлено ${peer.displayUsername}',
          WorkRelationType.join => 'Заявка отправлена ${peer.displayUsername}',
        };

  String get actionSubtitle => type.actionSubtitle;

  String get outgoingPendingSubtitle => outgoingCustomMessage ?? type.outgoingPendingSubtitle;

  String get outgoingResolvedSubtitle => outgoingCustomMessage ?? type.outgoingPendingSubtitle;

  /// Активный работник у работодателя [userId].
  static bool isActiveEmployee(WorkRelationModel r, String userId) {
    if (r.status != WorkRelationStatus.active) return false;
    final uid = userId.trim();
    if (r.type == WorkRelationType.hire && r.initiatorId.trim() == uid) return true;
    if (r.type == WorkRelationType.join && r.initiatorId.trim() != uid) return true;
    return false;
  }

  /// Активный работодатель у работника [userId].
  static bool isActiveEmployer(WorkRelationModel r, String userId) {
    if (r.status != WorkRelationStatus.active) return false;
    final uid = userId.trim();
    if (r.type == WorkRelationType.join && r.initiatorId.trim() == uid) return true;
    if (r.type == WorkRelationType.hire && r.initiatorId.trim() != uid) return true;
    return false;
  }

  /// Peer-id, с которыми уже есть pending/active связь (не показывать в поиске).
  static Set<String> peerIdsWithOpenRelation(Iterable<WorkRelationModel> relations) {
    return {
      for (final r in relations)
        if (r.status.blocksNewRequest) r.peer.id.trim(),
    }.where((id) => id.isNotEmpty).toSet();
  }

  factory WorkRelationModel.fromEnrichedRow(Map<String, dynamic> row, {required String currentUserId}) {
    final id = row['id']?.toString().trim() ?? '';
    final type = WorkRelationType.fromDb(row['relation_type']?.toString()) ?? WorkRelationType.hire;
    final status = WorkRelationStatus.fromDb(row['status']?.toString()) ?? WorkRelationStatus.pending;
    final initiatorId = row['initiator_id']?.toString().trim() ?? '';
    final peerId = row['peer_id']?.toString().trim() ?? '';

    DateTime? updatedAt;
    final rawUpdated = row['updated_at'];
    if (rawUpdated is String) updatedAt = DateTime.tryParse(rawUpdated);
    if (rawUpdated is DateTime) updatedAt = rawUpdated;

    return WorkRelationModel(
      id: id,
      type: type,
      status: status,
      initiatorId: initiatorId,
      currentUserId: currentUserId,
      updatedAt: updatedAt,
      peer: WorkMember(
        id: peerId,
        username: row['peer_username']?.toString() ?? 'noName',
        avatarUrl: row['peer_avatar_url']?.toString(),
        displayName: row['peer_full_name']?.toString(),
      ),
    );
  }
}
