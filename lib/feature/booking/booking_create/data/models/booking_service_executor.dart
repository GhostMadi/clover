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
}
