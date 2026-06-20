enum EventVisibility { public, followers, private }

class LifeEvent {
  final String eventId;
  final String authorId;
  final String title;
  final String body;
  final String occurredYearMonth;
  final String category;
  final String emotionTag;
  final int emotionScore;
  final bool isTurningPoint;
  final List<String> imageUrls;
  final EventVisibility visibility;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LifeEvent({
    required this.eventId,
    required this.authorId,
    required this.title,
    required this.body,
    required this.occurredYearMonth,
    required this.category,
    required this.emotionTag,
    required this.emotionScore,
    required this.isTurningPoint,
    required this.imageUrls,
    required this.visibility,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LifeEvent.fromMap(String eventId, Map<String, dynamic> map) {
    return LifeEvent(
      eventId: eventId,
      authorId: map['authorId'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      occurredYearMonth: map['occurredYearMonth'] as String,
      category: map['category'] as String,
      emotionTag: map['emotionTag'] as String,
      emotionScore: map['emotionScore'] as int,
      isTurningPoint: map['isTurningPoint'] as bool? ?? false,
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? const []),
      visibility: EventVisibility.values.firstWhere(
        (v) => v.name == map['visibility'],
        orElse: () => EventVisibility.private,
      ),
      likeCount: map['likeCount'] as int? ?? 0,
      commentCount: map['commentCount'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'title': title,
      'body': body,
      'occurredYearMonth': occurredYearMonth,
      'category': category,
      'emotionTag': emotionTag,
      'emotionScore': emotionScore,
      'isTurningPoint': isTurningPoint,
      'imageUrls': imageUrls,
      'visibility': visibility.name,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
