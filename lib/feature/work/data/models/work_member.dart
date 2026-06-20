/// Участник рабочих отношений (работник или работодатель).
class WorkMember {
  const WorkMember({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.displayName,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final String? displayName;

  String get displayUsername {
    final name = username.trim();
    if (name.isEmpty) return 'noName';
    return name.startsWith('@') ? name : '@$name';
  }
}
