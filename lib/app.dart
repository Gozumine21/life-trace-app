import 'package:flutter/material.dart';

class LifeTraceApp extends StatelessWidget {
  const LifeTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeTrace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePlaceholderScreen(),
    );
  }
}

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LifeTrace')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'LifeTrace の初期セットアップが完了しました。\n'
            'Firebase連携（flutterfire configure）を行うと\n'
            '機能実装を開始できます。',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
