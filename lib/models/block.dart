class Block {
  final String blockId;
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;

  const Block({
    required this.blockId,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  static String idFor(String blockerId, String blockedId) =>
      '${blockerId}_$blockedId';

  factory Block.fromMap(String id, Map<String, dynamic> map) {
    return Block(
      blockId: id,
      blockerId: map['blockerId'] as String,
      blockedId: map['blockedId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
