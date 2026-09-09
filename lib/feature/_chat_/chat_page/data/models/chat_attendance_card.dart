import 'dart:convert';

/// Structured attendance card from chat (`attendance_card` JSON or legacy `CLOVER_CARD:` text).
class ChatAttendanceCard {
  const ChatAttendanceCard({
    required this.card,
    required this.workplaceId,
    required this.workplaceName,
    this.membershipId,
    this.configVersion,
  });

  final String card; // attendance_invite | attendance_rules
  final String workplaceId;
  final String workplaceName;
  final String? membershipId;
  final int? configVersion;

  bool get isInvite => card == 'attendance_invite';
  bool get isRules => card == 'attendance_rules';

  Map<String, dynamic> toJson() {
    return {
      'card': card,
      'workplace_id': workplaceId,
      'workplace_name': workplaceName,
      if (membershipId != null) 'membership_id': membershipId,
      if (configVersion != null) 'config_version': configVersion,
    };
  }

  static ChatAttendanceCard? fromRef(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return null;
    final card = map['card']?.toString() ?? '';
    if (card != 'attendance_invite' && card != 'attendance_rules') return null;
    final workplaceId = map['workplace_id']?.toString() ?? '';
    if (workplaceId.isEmpty) return null;
    return ChatAttendanceCard(
      card: card,
      workplaceId: workplaceId,
      workplaceName: map['workplace_name']?.toString() ?? 'компания',
      membershipId: map['membership_id']?.toString(),
      configVersion: (map['config_version'] as num?)?.toInt(),
    );
  }

  static ChatAttendanceCard? tryParse(String? text) {
    if (text == null || text.isEmpty) return null;
    final raw = text.startsWith('CLOVER_CARD:') ? text.substring('CLOVER_CARD:'.length) : text;
    if (!raw.trimLeft().startsWith('{')) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return fromRef(map);
    } catch (_) {
      return null;
    }
  }
}
