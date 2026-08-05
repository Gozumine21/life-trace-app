import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../models/report.dart';
import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../providers/moderation_providers.dart';

class ReportManagementScreen extends ConsumerWidget {
  const ReportManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('通報管理')),
        body: const Center(child: Text('この画面を表示する権限がありません')),
      );
    }

    final reportsAsync = ref.watch(allReportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('通報管理')),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const EmptyView(message: '通報はありません', icon: Icons.flag_outlined);
          }
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              r.status == ReportStatus.pending ? '未対応' : '対応済み',
                            ),
                            backgroundColor: r.status == ReportStatus.pending
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            r.targetType == ReportTargetType.lifeEvent ? '投稿' : 'ユーザー',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('理由: ${ReportReason.labelFor(r.reason)}'),
                      if (r.details.isNotEmpty) Text('詳細: ${r.details}'),
                      Text(
                        DateFormat('yyyy/MM/dd HH:mm').format(r.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              if (r.targetType == ReportTargetType.lifeEvent) {
                                context.push('/life-event/${r.targetId}');
                              } else {
                                context.push('/user/${r.targetId}');
                              }
                            },
                            child: const Text('対象を見る'),
                          ),
                          if (r.targetType == ReportTargetType.lifeEvent)
                            TextButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('投稿を削除しますか？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('削除'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await ref
                                      .read(firestoreServiceProvider)
                                      .deleteLifeEvent(r.targetId);
                                  await ref
                                      .read(firestoreServiceProvider)
                                      .resolveReport(r.reportId);
                                }
                              },
                              child: const Text('投稿を削除'),
                            ),
                          if (r.status == ReportStatus.pending)
                            TextButton(
                              onPressed: () => ref
                                  .read(firestoreServiceProvider)
                                  .resolveReport(r.reportId),
                              child: const Text('対応済みにする'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(error: e, onRetry: () => ref.invalidate(allReportsProvider)),
      ),
    );
  }
}
