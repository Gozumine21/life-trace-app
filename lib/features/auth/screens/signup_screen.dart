import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'terms_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('利用規約に同意してください')),
      );
      return;
    }
    await ref.read(authControllerProvider.notifier).signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
    final state = ref.read(authControllerProvider);
    if (state.hasError && mounted) {
      final error = state.error;
      String message;
      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'email-already-in-use':
            message = 'このメールアドレスは既に登録されています。ログイン画面からサインインしてください。';
          case 'network-request-failed':
            message = 'ネットワークエラーです。WiFi接続を確認してください。';
          case 'weak-password':
            message = 'パスワードが弱すぎます。6文字以上にしてください。';
          case 'invalid-email':
            message = 'メールアドレスの形式が正しくありません。';
          default:
            message = '登録に失敗しました: ${error.message}';
        }
      } else {
        message = '登録に失敗しました: $error';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '表示名'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '表示名を入力してください' : null,
              ),
              const SizedBox(height: 16),
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
                decoration: const InputDecoration(labelText: 'パスワード（6文字以上）'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? '6文字以上で入力してください' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  ),
                  const Text('利用規約に同意します'),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  ),
                  child: const Text('利用規約を読む'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('登録する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
