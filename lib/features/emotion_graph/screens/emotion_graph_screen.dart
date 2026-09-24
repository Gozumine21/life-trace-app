import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/constants.dart';

import '../../../models/life_event.dart';
import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../timeline/providers/life_event_providers.dart';

class EmotionGraphScreen extends ConsumerWidget {
  final String uid;

  const EmotionGraphScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(visibleUserLifeEventsProvider(uid));
    final profileAsync = ref.watch(userProfileProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (p) => Text('${p?.displayName ?? ''} の感情グラフ'),
          loading: () => const Text('感情グラフ'),
          error: (e, st) => const Text('感情グラフ'),
        ),
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            final isSelf = ref.watch(currentUserProvider)?.uid == uid;
            return EmptyView(
              message: 'ライフイベントを記録すると、\n気持ちの浮き沈みがグラフになります。',
              icon: Icons.show_chart,
              actionLabel: isSelf ? 'ライフイベントを記録する' : null,
              actionIcon: Icons.edit_note,
              onAction: isSelf ? () => context.push('/life-event/new') : null,
            );
          }
          final turningPoints = events.where((e) => e.isTurningPoint).toList();
          final recoveries = findRecoveries(events);
          final isSelf = ref.watch(currentUserProvider)?.uid == uid;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _ChartHeader(
                title: '人生の浮き沈みグラフ',
                help: '上に行くほど嬉しかった出来事、下に行くほどつらかった出来事です。'
                    '点をタップすると出来事の名前が表示されます。黄色の点は「転機」です。',
              ),
              SizedBox(height: 260, child: _EmotionLineChart(events: events)),
              const SizedBox(height: 32),
              _ChartHeader(
                title: '谷からの回復',
                help: isSelf
                    ? 'つらい出来事のあと、気持ちが上向いた出来事です。ここにあなたの立ち直り方が表れています。'
                        '同じ谷にいる誰かにとって、最も役に立つ経験です。'
                    : 'つらい出来事のあと、どうやって気持ちが上向いたかをたどれます。',
              ),
              if (recoveries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('まだ「谷」から「山」への流れは見つかっていません。'),
                ),
              for (final (valley, peak) in recoveries)
                _RecoveryTile(
                  valley: valley,
                  peak: peak,
                  showShareHint: isSelf && peak.visibility == EventVisibility.private,
                ),
              const SizedBox(height: 32),
              const _ChartHeader(
                title: 'ジャンル別の割合',
                help: 'どんなジャンルの出来事を多く記録しているかが分かります。',
              ),
              SizedBox(height: 240, child: _CategoryPieChart(events: events)),
              const SizedBox(height: 32),
              const _ChartHeader(
                title: '人生の転機',
                help: '記録時に「人生の転機」としてマークした出来事です。タップで詳しく読めます。',
              ),
              if (turningPoints.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('まだ転機としてマークされた出来事はありません。'),
                ),
              ...turningPoints.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bolt, color: Colors.amber),
                  title: Text(e.title),
                  subtitle: Text('${e.occurredYearMonth} ・ ${EmotionTag.emojiFor(e.emotionTag)} ${e.emotionTag}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/life-event/${e.eventId}'),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(error: e, onRetry: () => ref.invalidate(userLifeEventsProvider(uid))),
      ),
    );
  }
}

/// 「谷」（気持ちが -3 以下）の出来事と、そのあと最初に気持ちが上向いた（+2 以上）出来事の組。
List<(LifeEvent, LifeEvent)> findRecoveries(List<LifeEvent> events) {
  final result = <(LifeEvent, LifeEvent)>[];
  for (var i = 0; i < events.length; i++) {
    if (events[i].emotionScore > -3) continue;
    // 谷が続く場合は、最後の谷から数える。
    if (i + 1 < events.length && events[i + 1].emotionScore <= -3) continue;
    for (var j = i + 1; j < events.length; j++) {
      if (events[j].emotionScore >= 2) {
        result.add((events[i], events[j]));
        break;
      }
    }
  }
  return result;
}

class _RecoveryTile extends StatelessWidget {
  final LifeEvent valley;
  final LifeEvent peak;
  final bool showShareHint;

  const _RecoveryTile({required this.valley, required this.peak, required this.showShareHint});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget row(LifeEvent e) => InkWell(
          onTap: () => context.push('/life-event/${e.eventId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(EmotionTag.emojiFor(e.emotionTag), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(e.occurredYearMonth, style: textTheme.bodySmall),
              ],
            ),
          ),
        );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(valley),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.south, size: 16),
            ),
            row(peak),
            if (showShareHint)
              Text(
                '回復の記録は非公開です。気持ちが落ち着いていれば、公開を考えてみませんか？',
                style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartHeader extends StatelessWidget {
  final String title;
  final String help;

  const _ChartHeader({required this.title, required this.help});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            help,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmotionLineChart extends StatelessWidget {
  final List<LifeEvent> events;

  const _EmotionLineChart({required this.events});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < events.length; i++)
        FlSpot(i.toDouble(), events[i].emotionScore.toDouble()),
    ];

    return LineChart(
      LineChartData(
        minY: -5,
        maxY: 5,
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= events.length) return const SizedBox.shrink();
                if (events.length > 8 && index % (events.length ~/ 8) != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    events[index].occurredYearMonth,
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final event = events[s.x.round()];
              return LineTooltipItem('${event.title}\n${event.emotionTag}', const TextStyle(color: Colors.white));
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.deepPurple,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final isTurningPoint = events[index].isTurningPoint;
                return FlDotCirclePainter(
                  radius: isTurningPoint ? 6 : 3,
                  color: isTurningPoint ? Colors.amber : Colors.deepPurple,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(show: true, color: Colors.deepPurple.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<LifeEvent> events;

  const _CategoryPieChart({required this.events});

  static const _colors = [
    Colors.deepPurple,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.blue,
    Colors.green,
    Colors.brown,
    Colors.indigo,
    Colors.red,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final e in events) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    final categories = counts.keys.toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: [
                for (var i = 0; i < categories.length; i++)
                  PieChartSectionData(
                    value: counts[categories[i]]!.toDouble(),
                    title: '${counts[categories[i]]}',
                    color: _colors[i % _colors.length],
                    radius: 70,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < categories.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, color: _colors[i % _colors.length]),
                      const SizedBox(width: 6),
                      Text(categories[i], style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
