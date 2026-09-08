/// Structured booking staff invite card from chat (`booking_card` JSON).
class ChatBookingStaffCard {
  const ChatBookingStaffCard({
    required this.inviteId,
    required this.hostId,
    required this.hostDisplayName,
  });

  final String inviteId;
  final String hostId;
  final String hostDisplayName;

  static ChatBookingStaffCard? fromRef(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return null;
    final card = map['card']?.toString() ?? '';
    if (card != 'booking_staff_invite') return null;
    final inviteId = map['invite_id']?.toString().trim() ?? '';
    final hostId = map['host_id']?.toString().trim() ?? '';
    if (inviteId.isEmpty || hostId.isEmpty) return null;
    return ChatBookingStaffCard(
      inviteId: inviteId,
      hostId: hostId,
      hostDisplayName: map['host_display_name']?.toString().trim().isNotEmpty == true
          ? map['host_display_name'].toString().trim()
          : 'аккаунт',
    );
  }
}
