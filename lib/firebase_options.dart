import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// ローカルのFirebase Emulator Suiteに接続するための仮設定。
/// `demo-` プレフィックスのプロジェクトIDはGoogle側の実プロジェクトを必要とせず、
/// エミュレータ専用として動作する（`firebase login`不要）。
/// 本番のFirebaseプロジェクトに切り替える際は、`flutterfire configure`で
/// このファイルを上書き生成する。
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  // Firebase iOS/Android SDKはAPIキーの形式（39文字・`A`始まり）を
  // 厳密に検証し、不正な形式だと起動時に例外でクラッシュするため、
  // ダミーでも正しい形式の文字列を使う。
  static const String _dummyApiKey = 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _dummyApiKey,
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-lifetrace',
    storageBucket: 'demo-lifetrace.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _dummyApiKey,
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-lifetrace',
    storageBucket: 'demo-lifetrace.appspot.com',
    iosBundleId: 'com.lifetrace.lifeTraceApp',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _dummyApiKey,
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-lifetrace',
    storageBucket: 'demo-lifetrace.appspot.com',
  );
}
