import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../services/push_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../onboarding/providers/onboarding_providers.dart';

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(FirebaseMessaging.instance, ref.watch(firestoreServiceProvider)),
);

/// プッシュ通知を受け取る設定（この端末ごと）。
class PushEnabledNotifier extends Notifier<bool> {
  static const _key = 'push_enabled_v1';

  @override
  bool build() {
    final enabled = ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;
    final uid = ref.watch(currentUserProvider)?.uid;
    if (enabled && uid != null) {
      // ログインのたびにトークンを登録し直し、更新にも追従する。
      final service = ref.read(pushServiceProvider);
      unawaited(service.register(uid).catchError((_) {}));
      final sub = service.onTokenRefresh.listen((_) => service.register(uid).catchError((_) {}));
      ref.onDispose(sub.cancel);
    }
    return enabled;
  }

  /// 有効にできたかを返す（通知が許可されなければ false）。
  Future<bool> setEnabled(bool value) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return false;
    final service = ref.read(pushServiceProvider);
    var ok = true;
    if (value) {
      ok = await service.enable(uid);
    } else {
      await service.disable(uid);
    }
    final enabled = value && ok;
    await ref.read(sharedPreferencesProvider).setBool(_key, enabled);
    state = enabled;
    return ok;
  }
}

final pushEnabledProvider = NotifierProvider<PushEnabledNotifier, bool>(
  PushEnabledNotifier.new,
);
