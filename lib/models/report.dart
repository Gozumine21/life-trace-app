class ReportTargetType {
  static const lifeEvent = 'lifeEvent';
  static const user = 'user';
}

class ReportReason {
  static const spam = 'spam';
  static const harassment = 'harassment';
  static const inappropriate = 'inappropriate';
  static const blockedByUser = 'blockedByUser';
  static const other = 'other';

  static const List<String> all = [spam, harassment, inappropriate, other];

  static String labelFor(String value) {
    switch (value) {
      case spam:
        return 'スパム・宣伝';
      case harassment:
        return '嫌がらせ・誹謗中傷';
      case inappropriate:
        return '不適切なコンテンツ';
      case blockedByUser:
        return '他ユーザーによるブロック';
      default:
        return 'その他';
    }
  }
}

class ReportStatus {
  static const pending = 'pending';
  static const resolved = 'resolved';
}

class Report {
  final String reportId;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String? eventId;
  final String reason;
  final String details;
  final String status;
  final DateTime createdAt;

  const Report({
    required this.reportId,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.eventId,
    required this.reason,
    required this.details,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromMap(String id, Map<String, dynamic> map) {
    return Report(
      reportId: id,
      reporterId: map['reporterId'] as String,
      targetType: map['targetType'] as String,
      targetId: map['targetId'] as String,
      eventId: map['eventId'] as String?,
      reason: map['reason'] as String,
      details: map['details'] as String? ?? '',
      status: map['status'] as String? ?? ReportStatus.pending,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'eventId': eventId,
      'reason': reason,
      'details': details,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
