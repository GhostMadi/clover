/// Аккаунт приложения, которого можно назначить исполнителем услуги.
class BookingStaffProfile {
  const BookingStaffProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  String get displayUsername {
    final name = username.trim();
    if (name.isEmpty) return 'noName';
    return name.startsWith('@') ? name : '@$name';
  }

  String get title {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return displayUsername;
  }
}
