class Follow {
  final String followId;
  final String followerId;
  final String followeeId;
  final DateTime createdAt;

  const Follow({
    required this.followId,
    required this.followerId,
    required this.followeeId,
    required this.createdAt,
  });

  static String idFor(String followerId, String followeeId) =>
      '${followerId}_$followeeId';

  factory Follow.fromMap(String followId, Map<String, dynamic> map) {
    return Follow(
      followId: followId,
      followerId: map['followerId'] as String,
      followeeId: map['followeeId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'followerId': followerId,
      'followeeId': followeeId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
