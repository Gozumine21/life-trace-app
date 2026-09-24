import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../providers/onboarding_providers.dart';

class _GuideAction {
  final String label;
  final IconData icon;

  /// ログイン中のユーザーIDを受け取り、移動先のパスを返す。
  final String Function(String uid) path;

  /// true ならタブ切り替え（go）、false なら画面を重ねる（push）。
  final bool isTab;

  const _GuideAction(this.label, this.icon, this.path, {this.isTab = false});
}

class _GuideSection {
  final String emoji;
  final String title;
  final String lead;
  final List<String> points;
  final _GuideAction? action;

  const _GuideSection({
    required this.emoji,
    required this.title,
    required this.lead,
    required this.points,
    this.action,
  });
}

final _sections = [
  _GuideSection(
    emoji: '✍️',
    title: '自分の人生を記録する',
    lead: 'まずは、あなたが歩んできた道のりを1つずつ残していきましょう。',
    points: const [
      '入学・就職・引っ越し・出会い・別れなど、人生の節目から書くと始めやすいです',
      '年月はおおよそで大丈夫。思い出した順に書いても、グラフは年月順に並びます',
      'うまく書こうとしなくて大丈夫です。そのとき何があり、どう感じたかを素直に',
      '特に大きな出来事は「人生の転機」としてマークしておきましょう',
    ],
    action: _GuideAction('記録してみる', Icons.edit_note, (_) => '/life-event/new'),
  ),
  _GuideSection(
    emoji: '📈',
    title: '自分の人生を振り返る',
    lead: '記録がたまると、あなたの人生の「山」と「谷」が見えてきます。',
    points: const [
      '「感情グラフ」では、選んだ気持ちが人生の浮き沈みの線になります',
      'つらい時期のあとに何があったか、どうやって乗り越えたかに気づけます',
      'ジャンル別の割合から、何を大切にしてきたかが分かります',
    ],
    action: _GuideAction('感情グラフを見る', Icons.show_chart, (uid) => '/emotion-graph/$uid'),
  ),
  _GuideSection(
    emoji: '🌱',
    title: '経験を分かち合う',
    lead: 'あなたの経験は、同じような場面にいる誰かの支えやヒントになります。',
    points: const [
      '全体公開：すべてのユーザーに届きます。誰かの参考になってほしい経験に',
      'フォロワー限定：家族や友人など、身近な人にだけ伝えたい経験に',
      '非公開：自分だけの日記に。公開範囲はあとからいつでも変えられます',
      '他人の実名や、住所・勤務先など個人が分かる情報は書かないようにしましょう',
    ],
  ),
  _GuideSection(
    emoji: '📖',
    title: 'ほかの人の人生にふれる',
    lead: '自分では経験できなかった人生を、その人の目線で追体験できます。',
    points: const [
      '「ホーム」には、みんなが公開した新しいライフイベントが並びます',
      '「さがす」では、ジャンルや気持ちで探せます。「挫折」や「不安」で探すと、同じ悩みを経験した人に出会えます',
      'ユーザーのページで「追体験する」を押すと、その人の人生を古い順に1つずつ読めます',
      '共感した人はフォローしておくと、あとから読み返しやすくなります',
    ],
    action: _GuideAction('さがしてみる', Icons.search, (_) => '/search', isTab: true),
  ),
  _GuideSection(
    emoji: '🤝',
    title: '気持ちを伝え合う',
    lead: '読んだ感想を送ると、書いた人の励みになります。',
    points: const [
      '❤️ いいね・🤝 わかる・🥹 感動した の3つから、気持ちに近いものを選べます',
      'コメントでは、はげましや自分の似た経験を伝えましょう',
      '人生の選択に正解はありません。相手の経験を否定せず、尊重して言葉を選びましょう',
    ],
  ),
  _GuideSection(
    emoji: '🛡️',
    title: '安心して使うために',
    lead: '無理なく、自分のペースで使ってください。',
    points: const [
      '表示名はニックネームでも大丈夫です（設定のプロフィール編集で変更できます）',
      '見たくない投稿をするユーザーは、ユーザーページ右上の「︙」からブロックできます',
      '不適切な投稿やユーザーは、「通報する」から運営に知らせてください',
    ],
  ),
];

const _useCases = [
  ('🧭', '進路や転職に迷ったとき、同じ道を歩んだ人の経験を読む'),
  ('☀️', 'つらい時期を乗り越えた人の記録から、前に進む勇気をもらう'),
  ('👪', '自分の歩みを「フォロワー限定」で家族に残す'),
  ('🗓️', '誕生日や年末に、これまでの人生をグラフで振り返る'),
];

/// LifeTrace の考え方と具体的な使い方を、読み物として説明する画面。
class HowToUseScreen extends ConsumerWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ログイン前や、はじめのガイドの途中で開いたときは、操作ボタンを出さない。
    final canAct = ref.watch(onboardingCompletedProvider);
    final uid = canAct ? ref.watch(currentUserProvider)?.uid : null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('LifeTraceの使い方')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '人生は、誰かのヒントになる',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LifeTraceは、あなたが歩んできた人生の出来事を記録し、ほかの人と分かち合うアプリです。\n\n'
                    'うれしかったことも、つらかったことも、あなたの経験は同じような場面にいる誰かの支えになります。'
                    'そして、ほかの人の人生にふれることで、自分では経験できなかった人生を追体験し、'
                    'これからの自分の生き方のヒントを見つけられます。',
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.7,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('使い方は、この循環です', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const _CycleDiagram(),
          const SizedBox(height: 8),
          for (var i = 0; i < _sections.length; i++)
            _SectionCard(number: i + 1, section: _sections[i], uid: uid),
          const SizedBox(height: 16),
          Text('こんな使い方も', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final (emoji, text) in _useCases)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(emoji, style: const TextStyle(fontSize: 24)),
              title: Text(text),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/guide'),
            icon: const Icon(Icons.slideshow_outlined),
            label: const Text('はじめのガイドをもう一度見る'),
          ),
        ],
      ),
    );
  }
}

/// 記録 → 振り返り → 共有 → 追体験 → 共感 の流れを示す図。
class _CycleDiagram extends StatelessWidget {
  const _CycleDiagram();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const steps = [('✍️', '記録'), ('📈', '振り返り'), ('🌱', '共有'), ('📖', '追体験'), ('🤝', '共感')];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 8,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Chip(
            avatar: Text(steps[i].$1),
            label: Text(steps[i].$2),
            visualDensity: VisualDensity.compact,
          ),
          Icon(
            i == steps.length - 1 ? Icons.replay : Icons.arrow_forward,
            size: 16,
            color: colorScheme.outline,
            semanticLabel: i == steps.length - 1 ? '最初に戻る' : '次へ',
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final int number;
  final _GuideSection section;
  final String? uid;

  const _SectionCard({required this.number, required this.section, required this.uid});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final action = section.action;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(section.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$number. ${section.title}',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(section.lead, style: textTheme.bodyMedium?.copyWith(height: 1.6)),
            const SizedBox(height: 8),
            for (final point in section.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 8),
                      child: Icon(Icons.circle, size: 6, color: colorScheme.primary),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (action != null && uid != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    final path = action.path(uid!);
                    action.isTab ? context.go(path) : context.push(path);
                  },
                  icon: Icon(action.icon),
                  label: Text(action.label),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
