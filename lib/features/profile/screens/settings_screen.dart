import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/terms_screen.dart';
import '../../moderation/providers/moderation_providers.dart';
import '../../notifications/providers/push_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final pushEnabled = ref.watch(pushEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _SectionTitle('通知'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('プッシュ通知'),
            subtitle: const Text('気持ち・コメント・フォロー・応答記録が届いたときに知らせます'),
            value: pushEnabled,
            onChanged: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final ok = await ref.read(pushEnabledProvider.notifier).setEnabled(value);
                if (!ok) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('通知が許可されていません。iPhoneの「設定」→「LifeTrace」→「通知」から許可してください。')),
                  );
                }
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('設定を変更できませんでした。通信環境を確認して、もう一度お試しください。')),
                );
              }
            },
          ),
          const _SectionTitle('ヘルプ'),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('LifeTraceの使い方'),
            subtitle: const Text('人生経験の記録・共有・追体験のしかた'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/how-to-use'),
          ),
          ListTile(
            leading: const Icon(Icons.slideshow_outlined),
            title: const Text('はじめのガイド'),
            subtitle: const Text('初回に表示された紹介をもう一度見る'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/guide'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          if (isAdmin) ...[
            const _SectionTitle('管理者'),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('通報管理'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/reports'),
            ),
          ],
          const _SectionTitle('アカウント'),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('プロフィールを編集'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ログアウトしますか？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ログアウト')),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('アカウントを削除', style: TextStyle(color: Colors.red)),
            subtitle: const Text('記録・コメント・フォローなど、すべてのデータを削除します'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => const _DeleteAccountDialog(),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'LifeTrace バージョン ${AppInfo.version}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

/// パスワードで本人確認してから、アカウントとすべてのデータを削除するダイアログ。
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount(_passwordController.text);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'wrong-password' || 'invalid-credential' => 'パスワードが違います',
          'too-many-requests' => '試行回数が多すぎます。しばらくしてからお試しください',
          _ => '削除できませんでした。通信環境を確認して、もう一度お試しください',
        };
      });
    } catch (_) {
      setState(() => _error = '削除できませんでした。通信環境を確認して、もう一度お試しください');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('アカウントを削除しますか？'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'あなたのライフイベント（届いたコメント・リアクションを含む）、フォロー、お知らせ、'
            'プロフィールをすべて削除します。この操作は取り消せません。\n\n'
            '確認のため、パスワードを入力してください。',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            enabled: !_isDeleting,
            decoration: InputDecoration(labelText: 'パスワード', errorText: _error),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: _isDeleting || _passwordController.text.isEmpty ? null : _delete,
          child: _isDeleting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('すべて削除する'),
        ),
      ],
    );
  }
}
