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

  /// カテゴリを選ぶときに添えるアイコン。
  static const Map<String, String> emojis = {
    '学業': '📚',
    '仕事': '💼',
    '家族': '🏠',
    '恋愛': '💗',
    '健康': '🩺',
    '挑戦': '🚀',
    '挫折': '🌧️',
    '達成': '🏆',
    '転居': '🚚',
    'その他': '✨',
  };

  static String emojiFor(String category) => emojis[category] ?? '✨';
}

class EmotionTag {
  final String label;
  final int score;
  final String emoji;

  const EmotionTag(this.label, this.score, this.emoji);

  static const List<EmotionTag> all = [
    EmotionTag('最高に嬉しい', 5, '🤩'),
    EmotionTag('嬉しい', 3, '😊'),
    EmotionTag('誇り', 3, '😤'),
    EmotionTag('安心', 2, '😌'),
    EmotionTag('普通', 0, '😐'),
    EmotionTag('不安', -2, '😟'),
    EmotionTag('辛い', -3, '😣'),
    EmotionTag('悲しい', -4, '😢'),
    EmotionTag('絶望', -5, '😭'),
  ];

  static String emojiFor(String label) {
    for (final e in all) {
      if (e.label == label) return e.emoji;
    }
    return '😐';
  }

  static int scoreFor(String label) {
    return all
        .firstWhere(
          (e) => e.label == label,
          orElse: () => const EmotionTag('普通', 0, '😐'),
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

  /// 公開範囲を選ぶときに表示する、誰に見えるかの説明。
  static String descriptionFor(String value) {
    switch (value) {
      case followers:
        return 'あなたをフォローしている人だけが見られます';
      case private:
        return '自分だけが見られます（日記として使えます）';
      default:
        return 'すべてのユーザーが見られます';
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

  static String emojiFor(String value) {
    switch (value) {
      case empathy:
        return '🤝';
      case moved:
        return '🥹';
      default:
        return '❤️';
    }
  }
}

class NotificationType {
  static const String like = 'like';
  static const String comment = 'comment';
  static const String follow = 'follow';
  static const String newEvent = 'newEvent';

  /// 自分の記録に「応えて」誰かが記録した（応答記録）。
  static const String response = 'response';
}

/// 伝わる記録を書くための手がかり（活用マニュアル第3章）。
class WritingGuide {
  /// 本文に挿入する「5つの問い」。全部埋める必要はない。
  static const String bodyTemplate = '【状況】そのとき、どんな状況だった？\n\n'
      '【迷い】何に悩み、どんな選択肢があった？\n\n'
      '【選択】どうした？決め手は何だった？\n\n'
      '【その後】結果、何が変わった？\n\n'
      '【今思うこと】同じ場面にいる人に伝えたいことは？（「私の場合は」の形で）\n';

  /// コメント入力欄のヒント（受け止める → 自分のこと → 返す）。
  static const String commentHint = '心に残ったところ・自分の似た経験・感謝などを送る';

  /// 転機マークの目安。全体に対する割合がこれを超えたら控えめにするよう案内する。
  static const double turningPointRatioGuide = 0.1;
}

class AppInfo {
  /// pubspec.yaml の version と合わせて更新する。
  static const String version = '1.2.0';
}
