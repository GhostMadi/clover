class BookingCalendarHost {
  const BookingCalendarHost({
    required this.hostId,
    required this.hostDisplayName,
    required this.staffId,
    this.hostUsername,
    this.staffDisplayName,
    this.isActive = true,
  });

  final String hostId;
  final String hostDisplayName;
  final String? hostUsername;
  final String staffId;
  final String? staffDisplayName;
  final bool isActive;

  String get hostUsernameLabel {
    final raw = hostUsername?.trim();
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  factory BookingCalendarHost.fromJson(Map<String, dynamic> json) {
    return BookingCalendarHost(
      hostId: json['host_id']?.toString() ?? '',
      hostDisplayName: json['host_display_name']?.toString() ?? '',
      hostUsername: json['host_username']?.toString(),
      staffId: json['staff_id']?.toString() ?? '',
      staffDisplayName: json['staff_display_name']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
