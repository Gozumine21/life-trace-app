import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../notifications/providers/notifications_providers.dart';
import '../../notifications/providers/push_providers.dart';

class HomeShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  // 「記録する」ボタンを出すタブ（ホーム・マイページ）。
  static const _tabsWithRecordButton = {0, 3};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    // プッシュ通知を有効にしている端末では、起動時に送信先を登録し直す。
    ref.watch(pushEnabledProvider);
    final showRecordButton = _tabsWithRecordButton.contains(navigationShell.currentIndex);

    return Scaffold(
      body: navigationShell,
      floatingActionButton: showRecordButton
          ? FloatingActionButton.extended(
              heroTag: 'record-life-event',
              onPressed: () => context.push('/life-event/new'),
              icon: const Icon(Icons.edit_note),
              label: const Text('記録する'),
              tooltip: '新しいライフイベントを記録する',
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
            tooltip: 'みんなのライフイベント',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search),
            label: 'さがす',
            tooltip: 'カテゴリや気持ちで探す',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
              child: const Icon(Icons.notifications),
            ),
            label: 'お知らせ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'マイページ',
            tooltip: '自分のライフラインと感情グラフ',
          ),
        ],
      ),
    );
  }
}
