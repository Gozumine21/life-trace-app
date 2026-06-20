class UserProfile {
  final String uid;
  final String displayName;
  final String? iconUrl;
  final String bio;
  final String? birthYearMonth;
  final String defaultVisibility;
  final int followerCount;
  final int followingCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.iconUrl,
    required this.bio,
    required this.birthYearMonth,
    required this.defaultVisibility,
    required this.followerCount,
    required this.followingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      displayName: map['displayName'] as String? ?? '',
      iconUrl: map['iconUrl'] as String?,
      bio: map['bio'] as String? ?? '',
      birthYearMonth: map['birthYearMonth'] as String?,
      defaultVisibility: map['defaultVisibility'] as String? ?? 'public',
      followerCount: map['followerCount'] as int? ?? 0,
      followingCount: map['followingCount'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'iconUrl': iconUrl,
      'bio': bio,
      'birthYearMonth': birthYearMonth,
      'defaultVisibility': defaultVisibility,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
