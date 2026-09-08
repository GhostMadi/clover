class BookingStaffInvite {
  const BookingStaffInvite({
    required this.id,
    required this.hostId,
    required this.inviteeId,
    required this.status,
    required this.createdAt,
    required this.inviteeDisplayName,
    this.inviteeUsername,
    this.inviteeAvatarUrl,
  });

  final String id;
  final String hostId;
  final String inviteeId;
  final String status;
  final DateTime createdAt;
  final String inviteeDisplayName;
  final String? inviteeUsername;
  final String? inviteeAvatarUrl;

  bool get isPending => status == 'pending';

  String get title {
    final name = inviteeDisplayName.trim();
    if (name.isNotEmpty) return name;
    final nick = inviteeUsername?.trim();
    if (nick != null && nick.isNotEmpty) return nick;
    return 'Пользователь';
  }

  factory BookingStaffInvite.fromJson(Map<String, dynamic> json) {
    return BookingStaffInvite(
      id: json['id']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      inviteeId: json['invitee_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      inviteeDisplayName: json['invitee_display_name']?.toString() ?? '',
      inviteeUsername: json['invitee_username']?.toString(),
      inviteeAvatarUrl: json['invitee_avatar_url']?.toString(),
    );
  }
}
