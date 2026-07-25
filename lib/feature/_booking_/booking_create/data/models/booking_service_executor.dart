class BookingServiceExecutor {
  const BookingServiceExecutor({
    required this.id,
    required this.displayName,
    required this.username,
    this.profileId,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String username;
  final String? profileId;
  final String? avatarUrl;

  String get displayLabel {
    final handle = username.trim();
    final normalized = handle.isEmpty
        ? ''
        : handle.startsWith('@')
        ? handle
        : '@$handle';
    if (normalized.isEmpty) return displayName;
    return '$displayName · $normalized';
  }

  factory BookingServiceExecutor.fromJson(Map<String, dynamic> json) {
    return BookingServiceExecutor(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profileId: json['profile_id']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'username': username,
        'profile_id': profileId,
        'avatar_url': avatarUrl,
      };
}
