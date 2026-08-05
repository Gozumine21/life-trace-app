import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/constants.dart';
import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _labelFor(String type) {
    switch (type) {
      case NotificationType.like:
        return 'があなたのライフイベントにいいねしました';
      case NotificationType.comment:
        return 'があなたのライフイベントにコメントしました';
      case NotificationType.follow:
        return 'があなたをフォローしました';
      case NotificationType.newEvent:
        return 'が新しいライフイベントを投稿しました';
      default:
        return '';
    }
  }

  IconData _iconFor(String type) {
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
    final notificationsAsync = ref.watch(notificationsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyView(message: '通知はまだありません', icon: Icons.notifications_none);
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                leading: Icon(_iconFor(n.type), color: Colors.deepPurple),
                title: Text(_labelFor(n.type)),
                subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(n.createdAt)),
                tileColor: n.isRead ? null : Colors.deepPurple.withValues(alpha: 0.05),
                onTap: () {
                  if (user != null && !n.isRead) {
                    ref
                        .read(firestoreServiceProvider)
                        .markNotificationRead(user.uid, n.notificationId);
                  }
                  if (n.targetEventId != null) {
                    context.push('/life-event/${n.targetEventId}');
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
