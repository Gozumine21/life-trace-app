import 'package:flutter/material.dart';

/// 例外を、利用者が読んで次の行動が分かる日本語に置き換える。
String friendlyErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('network') || text.contains('unavailable') || text.contains('SocketException')) {
    return 'インターネットに接続できませんでした。\n通信環境を確認して、もう一度お試しください。';
  }
  if (text.contains('permission-denied')) {
    return 'この内容を表示する権限がありません。';
  }
  if (text.contains('not-found')) {
    return '見つかりませんでした。削除された可能性があります。';
  }
  return '読み込みに失敗しました。\n少し時間をおいて、もう一度お試しください。';
}

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              friendlyErrorMessage(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            // 開発時の原因調査用に、詳細は小さく残しておく。
            ExpansionTile(
              title: Text('詳細', style: Theme.of(context).textTheme.bodySmall),
              shape: const Border(),
              children: [
                SelectableText('$error', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('もう一度読み込む'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
