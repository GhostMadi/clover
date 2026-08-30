/// Строка списка подписчиков / подписок.
class FollowProfileRow {
  const FollowProfileRow({
    required this.profileId,
    this.username,
    this.avatarUrl,
    this.isFollowing = false,
    this.isFollowUpdating = false,
  });

  final String profileId;
  final String? username;
  final String? avatarUrl;
  final bool isFollowing;
  final bool isFollowUpdating;

  String get displayUsername {
    final value = username?.trim();
    if (value == null || value.isEmpty) return 'noName';
    return value;
  }

  FollowProfileRow copyWith({
    String? profileId,
    String? username,
    String? avatarUrl,
    bool? isFollowing,
    bool? isFollowUpdating,
  }) {
    return FollowProfileRow(
      profileId: profileId ?? this.profileId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowUpdating: isFollowUpdating ?? this.isFollowUpdating,
    );
  }
}
