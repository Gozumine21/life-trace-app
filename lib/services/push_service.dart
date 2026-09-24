import 'package:firebase_messaging/firebase_messaging.dart';

import 'firestore_service.dart';

/// プッシュ通知の送信先（FCMトークン）を登録・解除する。
///
/// 実際の送信は Cloud Functions（functions/src/index.ts）が、
/// お知らせ（users/{uid}/notifications）の作成をきっかけに行う。
class PushService {
  final FirebaseMessaging _messaging;
  final FirestoreService _firestore;

  PushService(this._messaging, this._firestore);

  /// 通知の許可を求め、許可されたらトークンを保存する。許可されなければ false。
  Future<bool> enable(String uid) async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      return false;
    }
    await register(uid);
    return true;
  }

  /// 現在のトークンを保存する（起動時やトークン更新時にも呼ぶ）。
  Future<void> register(String uid) async {
    // iOS では APNs のトークンが届く前に getToken を呼ぶと失敗するため、先に確認する。
    if (await _messaging.getAPNSToken() == null) {
      await Future.delayed(const Duration(seconds: 2));
      if (await _messaging.getAPNSToken() == null) return;
    }
    final token = await _messaging.getToken();
    if (token != null) await _firestore.saveFcmToken(uid, token);
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> disable(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) await _firestore.deleteFcmToken(uid, token);
    await _messaging.deleteToken();
  }
}
