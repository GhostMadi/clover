class PostShareResult {
  const PostShareResult({
    required this.sharedCount,
    required this.sendsCount,
  });

  final int sharedCount;
  final int sendsCount;

  factory PostShareResult.fromJson(Map<String, dynamic> json) {
    return PostShareResult(
      sharedCount: (json['shared_count'] as num?)?.toInt() ?? 0,
      sendsCount: (json['sends_count'] as num?)?.toInt() ?? 0,
    );
  }
}
