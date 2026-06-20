class AppNotification {
  final String notificationId;
  final String type;
  final String fromUserId;
  final String? targetEventId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.notificationId,
    required this.type,
    required this.fromUserId,
    required this.targetEventId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(
    String notificationId,
    Map<String, dynamic> map,
  ) {
    return AppNotification(
      notificationId: notificationId,
      type: map['type'] as String,
      fromUserId: map['fromUserId'] as String,
      targetEventId: map['targetEventId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'fromUserId': fromUserId,
      'targetEventId': targetEventId,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
