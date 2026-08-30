class PostShareRecipient {
  const PostShareRecipient({
    required this.profileId,
    this.username,
    this.avatarUrl,
    this.shareCount = 0,
  });

  final String profileId;
  final String? username;
  final String? avatarUrl;
  final int shareCount;

  String get displayUsername {
    final value = username?.trim();
    if (value == null || value.isEmpty) return 'noName';
    return value;
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'share_count': shareCount,
    };
  }

  factory PostShareRecipient.fromJson(Map<String, dynamic> json) {
    return PostShareRecipient(
      profileId: (json['profile_id'] as String?)?.trim() ?? '',
      username: (json['username'] as String?)?.trim(),
      avatarUrl: (json['avatar_url'] as String?)?.trim(),
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
    );
  }
}
