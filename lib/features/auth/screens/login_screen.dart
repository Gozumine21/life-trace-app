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
  bool _obscurePassword = true;

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
            message = 'インターネットに接続できませんでした。通信環境を確認してください。';
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

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (!email.contains('@')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('上の欄に登録したメールアドレスを入力してから、もう一度押してください')),
      );
      return;
    }
    await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(email);
    if (!mounted) return;
    final failed = ref.read(authControllerProvider).hasError;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failed
              ? '再設定メールを送信できませんでした。メールアドレスを確認してください。'
              : '$email にパスワード再設定メールを送信しました',
        ),
      ),
    );
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
              const _AppHeader(),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'メールアドレスを入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    tooltip: _obscurePassword ? 'パスワードを表示' : 'パスワードを隠す',
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
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
              const SizedBox(height: 8),
              TextButton(
                onPressed: _sendPasswordReset,
                child: const Text('パスワードを忘れた場合'),
              ),
              const Divider(height: 32),
              Text(
                'はじめての方',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push('/signup'),
                child: const Text('無料でアカウントを作成'),
              ),
              TextButton.icon(
                onPressed: () => context.push('/guide'),
                icon: const Icon(Icons.help_outline),
                label: const Text('LifeTraceの使い方を見る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.timeline, size: 64, color: colorScheme.primary),
        const SizedBox(height: 8),
        const Text('LifeTrace', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'あなたの人生を記録し、振り返り、分かち合う',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
