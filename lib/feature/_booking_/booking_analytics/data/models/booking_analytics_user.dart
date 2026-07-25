class BookingAnalyticsUser {
  const BookingAnalyticsUser({
    required this.id,
    required this.displayName,
    required this.username,
  });

  final String id;
  final String displayName;
  final String username;

  String get displayLabel {
    final handle = username.trim();
    final normalized = handle.startsWith('@') ? handle : '@$handle';
    return '$displayName · $normalized';
  }
}
