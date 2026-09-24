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
    lead: '出来事だけでなく、「そのとき何を考え、どう選んだか」を残すと、誰かのヒントになります。',
    points: const [
      '最初の30分で、入学・就職・引っ越しなど人生の節目を10件ほど。本文は1〜2文で十分です',
      'タイトルは「出来事＋変化」で。例：「10年勤めた会社を辞めて、未経験の業界へ」',
      '本文に迷ったら「書き方のヒント（5つの問い）」ボタンで、状況・迷い・選択・その後・今思うことを順に',
      '気持ちは「今」ではなく「そのとき」のものを。転機マークは、生き方が変わった出来事だけ（全体の1割ほど）に',
    ],
    action: _GuideAction('記録してみる', Icons.edit_note, (_) => '/life-event/new'),
  ),
  _GuideSection(
    emoji: '📈',
    title: '自分の人生を振り返る',
    lead: '感情グラフは成績表ではなく、「自分がどう回復してきたか」の地図です。',
    points: const [
      '谷のあとに何が起きたか。「谷からの回復」に、あなたの立ち直り方が表れます',
      '転機の前と後で、波の大きさやジャンルがどう変わったかを見てみましょう',
      '誕生月と12月には、ホームに一年のふり返りの案内が出ます',
    ],
    action: _GuideAction('感情グラフを見る', Icons.show_chart, (uid) => '/emotion-graph/$uid'),
  ),
  _GuideSection(
    emoji: '🌱',
    title: '経験を分かち合う',
    lead: '「非公開 → フォロワー限定 → 全体公開」の順に、気持ちの整理がついたものから広げていきます。',
    points: const [
      '非公開：まだ整理できていない経験や下書きに。新しい記録は、最初は非公開で始まります',
      'フォロワー限定：家族や友人など、身近な人に知ってほしい経験に',
      '全体公開：同じ場面にいる誰かの参考になってほしい経験に。公開範囲はあとから何度でも変えられます',
      '谷だけでなく、回復までの2〜3件を流れとして公開すると、物語として伝わります',
    ],
  ),
  _GuideSection(
    emoji: '📖',
    title: 'ほかの人の人生にふれる',
    lead: '「目的を決めて探す」と「一人の人生を通して読む」を使い分けましょう。',
    points: const [
      '「さがす」の「今の状況から探す」で、転職の迷いや不安など、自分に近い経験に出会えます',
      'ジャンル・気持ち・出来事が起きた年代を組み合わせて絞り込めます',
      '「追体験する」では、まず感情グラフで山と谷をつかみ、谷から次の山までを丁寧に読みましょう',
      '「転機だけ」を選ぶと、その人の人生の分かれ道だけをたどれます',
    ],
    action: _GuideAction('さがしてみる', Icons.search, (_) => '/search', isTab: true),
  ),
  _GuideSection(
    emoji: '🤝',
    title: '気持ちを伝え合う',
    lead: '反応は、経験を公開した人にとって「誰かに届いた」という唯一の手応えです。',
    points: const [
      '❤️ いいね：読んでよかった・応援したい　🤝 わかる：自分にも似た経験がある　🥹 感動した：自分にはない経験に心を動かされた',
      'コメントは「心に残ったところ → 自分のこと（任意） → 感謝」の3文で十分です',
      '評価や助言、比較、個人的な質問は避け、「読んで私はこう感じた」を伝えましょう',
      '自分の記録にコメントが届いたら、一言でも返信しましょう',
    ],
  ),
  _GuideSection(
    emoji: '🔁',
    title: '経験で応える',
    lead: 'コメントが「言葉の返事」なら、応答記録は「人生の返事」です。',
    points: const [
      '心が動いた記録の「この記録に応えて、自分の経験を記録する」から、似た出来事を記録できます',
      '公開すると元の記録の下に並び、書いた人にお知らせが届きます',
      '「私は逆の道を選んだ」という記録も、読む人の選択肢を広げます',
    ],
  ),
  _GuideSection(
    emoji: '🛡️',
    title: '安心して使うために',
    lead: '自分と、記録に登場する人の両方を守りましょう。',
    points: const [
      '実名・学校名・勤務先・住所は書かず、「当時の上司」「地元の高校」のように書きかえましょう',
      '電話番号やメールアドレスなどが含まれていると、公開する前にお知らせします',
      'まだ渦中にいる経験は、非公開で書くだけに。読んでいてつらくなったら、アプリから離れて大丈夫です',
      '嫌なコメントやユーザーは、ユーザーページ右上の「︙」から通報・ブロックできます',
    ],
  ),
];

const _useCases = [
  ('🧭', '進路や転職に迷ったとき、同じ道を歩んだ人の経験を読む'),
  ('☀️', 'つらい時期を乗り越えた人の記録から、前に進む勇気をもらう'),
  ('👪', '自分の歩みを「フォロワー限定」で家族に残す'),
  ('🗓️', '週に1回は3件に反応、月に1回は1件記録、年に1回はグラフでふり返る'),
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
