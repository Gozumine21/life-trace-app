import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../models/report.dart';
import '../../auth/providers/auth_providers.dart';

const developerEmail = 'bulltop21@gmail.com';

final blockedUserIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchBlockedUserIds(user.uid);
});

final isUserBlockedProvider = Provider.family<bool, String>((ref, targetUid) {
  final blockedIds = ref.watch(blockedUserIdsProvider).asData?.value ?? const [];
  return blockedIds.contains(targetUid);
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email == developerEmail;
});

class BlockController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggleBlock(String targetUid, bool isCurrentlyBlocked) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(firestoreServiceProvider);
      if (isCurrentlyBlocked) {
        await service.unblockUser(user.uid, targetUid);
      } else {
        await service.blockUser(user.uid, targetUid);
        // ブロックは開発者にも通知されるよう、通報としても記録する。
        await service.submitReport(
          Report(
            reportId: '',
            reporterId: user.uid,
            targetType: ReportTargetType.user,
            targetId: targetUid,
            eventId: null,
            reason: ReportReason.blockedByUser,
            details: 'ユーザーがブロックされました。内容の確認をお願いします。',
            status: ReportStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
      }
    });
  }
}

final blockControllerProvider =
    AsyncNotifierProvider<BlockController, void>(BlockController.new);

class ReportController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submitReport({
    required String targetType,
    required String targetId,
    String? eventId,
    required String reason,
    String details = '',
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final report = Report(
        reportId: '',
        reporterId: user.uid,
        targetType: targetType,
        targetId: targetId,
        eventId: eventId,
        reason: reason,
        details: details,
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
      );
      await ref.read(firestoreServiceProvider).submitReport(report);
    });
  }
}

final reportControllerProvider =
    AsyncNotifierProvider<ReportController, void>(ReportController.new);

final allReportsProvider = StreamProvider<List<Report>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAllReports();
});
