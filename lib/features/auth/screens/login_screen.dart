import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text);
    final state = ref.read(authControllerProvider);
    if (state.hasError && mounted) {
      final error = state.error;
      String message;
      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'user-not-found':
          case 'invalid-credential':
            message = 'メールアドレスまたはパスワードが正しくありません。';
          case 'wrong-password':
            message = 'パスワードが正しくありません。';
          case 'network-request-failed':
            message = 'ネットワークエラーです。MacのエミュレータとWiFiが同じか確認してください。';
          case 'too-many-requests':
            message = 'ログイン試行が多すぎます。しばらく待ってから再試行してください。';
          default:
            message = 'ログインに失敗しました: ${error.message}';
        }
      } else {
        message = 'ログインに失敗しました: $error';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.timeline, size: 64, color: Colors.deepPurple),
                    SizedBox(height: 8),
                    Text(
                      'LifeTrace',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'メールアドレス'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'メールアドレスを入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? '6文字以上で入力してください' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ログイン'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text('新規登録はこちら'),
              ),
              TextButton(
                onPressed: () async {
                  if (_emailController.text.trim().isEmpty) return;
                  final messenger = ScaffoldMessenger.of(context);
                  await ref
                      .read(authControllerProvider.notifier)
                      .sendPasswordResetEmail(_emailController.text.trim());
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('パスワード再設定メールを送信しました')),
                    );
                  }
                },
                child: const Text('パスワードを忘れた場合'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
