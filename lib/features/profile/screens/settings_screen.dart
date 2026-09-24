import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/constants.dart';
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
