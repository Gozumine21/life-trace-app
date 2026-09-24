import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/report.dart';
import '../providers/moderation_providers.dart';

/// 通報ダイアログを表示し、送信できたら true を返す。
Future<bool> showReportDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String targetType,
  required String targetId,
  String? eventId,
}) async {
  String reason = ReportReason.spam;
  final detailsController = TextEditingController();

  final submitted = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('通報する'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('理由を選択してください'),
                  RadioGroup<String>(
                    groupValue: reason,
                    onChanged: (v) => setState(() => reason = v!),
                    child: Column(
                      children: ReportReason.all
                          .map(
                            (r) => RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(ReportReason.labelFor(r)),
                              value: r,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: '詳細（任意）',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('通報する'),
              ),
            ],
          );
        },
      );
    },
  );

  if (submitted == true) {
    await ref.read(reportControllerProvider.notifier).submitReport(
          targetType: targetType,
          targetId: targetId,
          eventId: eventId,
          reason: reason,
          details: detailsController.text.trim(),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通報を受け付けました。24時間以内に対応します。')),
      );
    }
    return true;
  }
  return false;
}
