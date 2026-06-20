class Comment {
  final String commentId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  const Comment({
    required this.commentId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  factory Comment.fromMap(String commentId, Map<String, dynamic> map) {
    return Comment(
      commentId: commentId,
      authorId: map['authorId'] as String,
      body: map['body'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'body': body,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
