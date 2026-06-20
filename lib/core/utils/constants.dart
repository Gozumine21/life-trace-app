/// カテゴリ・感情タグなど、アプリ全体で使う定義値。
class LifeEventCategories {
  static const List<String> all = [
    '学業',
    '仕事',
    '家族',
    '恋愛',
    '健康',
    '挑戦',
    '挫折',
    '達成',
    '転居',
    'その他',
  ];
}

class EmotionTag {
  final String label;
  final int score;

  const EmotionTag(this.label, this.score);

  static const List<EmotionTag> all = [
    EmotionTag('最高に嬉しい', 5),
    EmotionTag('嬉しい', 3),
    EmotionTag('誇り', 3),
    EmotionTag('安心', 2),
    EmotionTag('普通', 0),
    EmotionTag('不安', -2),
    EmotionTag('辛い', -3),
    EmotionTag('悲しい', -4),
    EmotionTag('絶望', -5),
  ];

  static int scoreFor(String label) {
    return all
        .firstWhere(
          (e) => e.label == label,
          orElse: () => const EmotionTag('普通', 0),
        )
        .score;
  }
}

class VisibilityOption {
  static const String public = 'public';
  static const String followers = 'followers';
  static const String private = 'private';

  static const List<String> all = [public, followers, private];

  static String labelFor(String value) {
    switch (value) {
      case followers:
        return 'フォロワー限定';
      case private:
        return '非公開';
      default:
        return '全体公開';
    }
  }
}

class ReactionType {
  static const String like = 'like';
  static const String empathy = 'empathy';
  static const String moved = 'moved';

  static const List<String> all = [like, empathy, moved];

  static String labelFor(String value) {
    switch (value) {
      case empathy:
        return 'わかる';
      case moved:
        return '感動した';
      default:
        return 'いいね';
    }
  }
}

class NotificationType {
  static const String like = 'like';
  static const String comment = 'comment';
  static const String follow = 'follow';
  static const String newEvent = 'newEvent';
}
