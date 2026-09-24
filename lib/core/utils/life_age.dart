/// "YYYY-MM" 形式の年月を扱う小さな関数群。
class LifeAge {
  static (int, int)? parseYearMonth(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(value.trim());
    if (match == null) return null;
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return null;
    return (int.parse(match.group(1)!), month);
  }

  /// 生年月から見た、出来事が起きたときの年齢。どちらかが不明なら null。
  static int? ageAt({required String? birthYearMonth, required String occurredYearMonth}) {
    final birth = parseYearMonth(birthYearMonth);
    final at = parseYearMonth(occurredYearMonth);
    if (birth == null || at == null) return null;
    var age = at.$1 - birth.$1;
    if (at.$2 < birth.$2) age--;
    return age < 0 ? null : age;
  }

  /// 年代（10代なら 10）。
  static int? decadeAt({required String? birthYearMonth, required String occurredYearMonth}) {
    final age = ageAt(birthYearMonth: birthYearMonth, occurredYearMonth: occurredYearMonth);
    return age == null ? null : (age ~/ 10) * 10;
  }

  /// 「28歳ごろ」のような表示。
  static String? label({required String? birthYearMonth, required String occurredYearMonth}) {
    final age = ageAt(birthYearMonth: birthYearMonth, occurredYearMonth: occurredYearMonth);
    return age == null ? null : '$age歳ごろ';
  }

  /// 今月がふり返りの時期（誕生月、または12月）か。
  static bool isReviewMonth({required String? birthYearMonth, DateTime? now}) {
    final month = (now ?? DateTime.now()).month;
    return month == 12 || parseYearMonth(birthYearMonth)?.$2 == month;
  }
}
