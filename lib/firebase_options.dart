import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC2aJy-jgxvdU24smgw_olJbGAy6lT0zvI',
    appId: '1:730935333338:web:0000000000000000000000',
    messagingSenderId: '730935333338',
    projectId: 'life-trace-app',
    storageBucket: 'life-trace-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC2aJy-jgxvdU24smgw_olJbGAy6lT0zvI',
    appId: '1:730935333338:ios:c2c89e055283a7316e70e3',
    messagingSenderId: '730935333338',
    projectId: 'life-trace-app',
    storageBucket: 'life-trace-app.firebasestorage.app',
    iosBundleId: 'com.gozumine21.life-trace-app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC2aJy-jgxvdU24smgw_olJbGAy6lT0zvI',
    appId: '1:730935333338:android:0000000000000000000000',
    messagingSenderId: '730935333338',
    projectId: 'life-trace-app',
    storageBucket: 'life-trace-app.firebasestorage.app',
  );
}
