import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/terms_screen.dart';
import '../../moderation/providers/moderation_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('利用規約'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('通報管理'),
              onTap: () => context.push('/admin/reports'),
            ),
          const Divider(),
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
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('アカウントを削除しますか？'),
                  content: const Text('この操作は取り消せません。投稿したライフイベントは残ります。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除する')),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authServiceProvider).deleteAccount();
              }
            },
          ),
        ],
      ),
    );
  }
}
