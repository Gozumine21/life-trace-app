import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/constants.dart';
import '../../../models/notification.dart';
import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/notifications_providers.dart';

/// 「3分前」「2日前」のような、ひと目で分かる時刻表記。
String relativeTimeLabel(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inHours < 1) return '${diff.inMinutes}分前';
  if (diff.inDays < 1) return '${diff.inHours}時間前';
  if (diff.inDays < 7) return '${diff.inDays}日前';
  return DateFormat('yyyy/MM/dd').format(time);
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final user = ref.watch(currentUserProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ'),
        actions: [
          if (unreadCount > 0 && user != null)
            TextButton(
              onPressed: () {
                final service = ref.read(firestoreServiceProvider);
                for (final n in notificationsAsync.asData?.value ?? const <AppNotification>[]) {
                  if (!n.isRead) service.markNotificationRead(user.uid, n.notificationId);
                }
              },
              child: const Text('すべて既読'),
            ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyView(
              message: 'お知らせはまだありません。\nあなたの投稿にいいねやコメントが届くと、ここに表示されます。',
              icon: Icons.notifications_none,
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationTile(
                notification: n,
                onTap: () {
                  if (user != null && !n.isRead) {
                    ref
                        .read(firestoreServiceProvider)
                        .markNotificationRead(user.uid, n.notificationId);
                  }
                  if (n.targetEventId != null) {
                    context.push('/life-event/${n.targetEventId}');
                  } else if (n.type == NotificationType.follow) {
                    context.push('/user/${n.fromUserId}');
                  }
                },
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(error: e, onRetry: () => ref.invalidate(notificationsProvider)),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  static String _labelFor(String type) {
    switch (type) {
      case NotificationType.like:
        return 'さんがあなたのライフイベントに気持ちを送りました';
      case NotificationType.comment:
        return 'さんがあなたのライフイベントにコメントしました';
      case NotificationType.follow:
        return 'さんがあなたをフォローしました';
      case NotificationType.newEvent:
        return 'さんが新しいライフイベントを投稿しました';
      default:
        return 'さんからお知らせがあります';
    }
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.mode_comment;
      case NotificationType.follow:
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final fromName =
        ref.watch(userProfileProvider(notification.fromUserId)).asData?.value?.displayName ?? 'ユーザー';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(_iconFor(notification.type), color: colorScheme.primary, size: 20),
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: fromName, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: _labelFor(notification.type)),
          ],
        ),
      ),
      subtitle: Text(relativeTimeLabel(notification.createdAt)),
      trailing: notification.isRead
          ? null
          : Icon(Icons.circle, size: 10, color: colorScheme.primary, semanticLabel: '未読'),
      tileColor: notification.isRead ? null : colorScheme.primaryContainer.withValues(alpha: 0.3),
      onTap: onTap,
    );
  }
}
