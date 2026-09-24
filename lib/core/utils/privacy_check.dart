/// 公開前に、本人や他人を特定できそうな情報が含まれていないかを確かめる。
///
/// 完全な検出はできないため、見つかったものを注意として示し、判断は本人に委ねる。
class PrivacyCheck {
  static final _patterns = <String, RegExp>{
    'メールアドレス': RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'),
    '電話番号': RegExp(r'(?<!\d)0\d{1,4}[-(（ ]?\d{1,4}[-)） ]?\d{3,4}(?!\d)'),
    '郵便番号': RegExp(r'〒\s?\d{3}-?\d{4}|(?<![\d-])\d{3}-\d{4}(?![\d-])'),
    '住所の番地': RegExp(r'\d+丁目|\d+番地|\d+番\d+号'),
    'SNSのアカウント名': RegExp(r'(?<![\w@])@[A-Za-z0-9_]{3,}'),
  };

  /// 見つかった情報の種類を返す（例: ['電話番号']）。何もなければ空。
  static List<String> findConcerns(String text) {
    return [
      for (final entry in _patterns.entries)
        if (entry.value.hasMatch(text)) entry.key,
    ];
  }
}
