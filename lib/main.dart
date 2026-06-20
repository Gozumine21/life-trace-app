import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

// TODO(firebase): `flutterfire configure` 実行後、firebase_options.dart を生成し、
// ここで Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform) を呼ぶ。
void main() {
  runApp(const ProviderScope(child: LifeTraceApp()));
}
