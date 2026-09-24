import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../models/notification.dart';
import '../../auth/providers/auth_providers.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchNotifications(user.uid);
});

/// ナビゲーションバーのバッジに表示する未読件数。
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).asData?.value ?? const [];
  return notifications.where((n) => !n.isRead).length;
});
