class ChatParticipant {
  const ChatParticipant({
    required this.userId,
    required this.role,
    required this.username,
    this.avatarUrl,
    this.joinedAt,
  });

  final String userId;

  /// Backend EN key: `admin` | `member`.
  final String role;
  final String username;
  final String? avatarUrl;
  final DateTime? joinedAt;

  bool get isAdmin => role == 'admin';

  String get displayUsername {
    final raw = username.trim();
    if (raw.isEmpty) return '@user';
    return raw.startsWith('@') ? raw : '@$raw';
  }
}
