import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/life_event.dart';
import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../profile/providers/profile_providers.dart';
import '../../timeline/providers/life_event_providers.dart';

class EmotionGraphScreen extends ConsumerWidget {
  final String uid;

  const EmotionGraphScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(userLifeEventsProvider(uid));
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
            return const EmptyView(message: 'グラフを描くにはライフイベントが必要です');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('人生の浮き沈みグラフ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(height: 260, child: _EmotionLineChart(events: events)),
              const SizedBox(height: 32),
              const Text('カテゴリ別の割合', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(height: 240, child: _CategoryPieChart(events: events)),
              const SizedBox(height: 32),
              const Text('人生の転機', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...events.where((e) => e.isTurningPoint).map(
                    (e) => ListTile(
                      leading: const Icon(Icons.bolt, color: Colors.amber),
                      title: Text(e.title),
                      subtitle: Text('${e.occurredYearMonth} ・ ${e.emotionTag}'),
                    ),
                  ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(error: e),
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
