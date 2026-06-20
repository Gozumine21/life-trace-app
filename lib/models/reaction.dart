class Reaction {
  final String userId;
  final String type;
  final DateTime createdAt;

  const Reaction({
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  factory Reaction.fromMap(String userId, Map<String, dynamic> map) {
    return Reaction(
      userId: userId,
      type: map['type'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
