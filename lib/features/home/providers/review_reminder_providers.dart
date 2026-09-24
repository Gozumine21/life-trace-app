import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/life_age.dart';
import '../../onboarding/providers/onboarding_providers.dart';
import '../../profile/providers/profile_providers.dart';

/// 誕生月と12月に、ホームで一年のふり返りを案内する（活用マニュアル第8章）。
class ReviewReminderNotifier extends Notifier<bool> {
  static String _keyFor(DateTime now) => 'review_reminder_dismissed_${now.year}_${now.month}';

  @override
  bool build() {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile == null) return false;
    final now = DateTime.now();
    if (!LifeAge.isReviewMonth(birthYearMonth: profile.birthYearMonth, now: now)) return false;
    return !(ref.watch(sharedPreferencesProvider).getBool(_keyFor(now)) ?? false);
  }

  Future<void> dismiss() async {
    await ref.read(sharedPreferencesProvider).setBool(_keyFor(DateTime.now()), true);
    state = false;
  }
}

/// ふり返りの案内をいま表示するか。
final reviewReminderProvider = NotifierProvider<ReviewReminderNotifier, bool>(
  ReviewReminderNotifier.new,
);
