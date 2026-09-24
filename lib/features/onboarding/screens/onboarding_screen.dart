import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/onboarding_providers.dart';

class _GuidePage {
  final String emoji;
  final String title;
  final String body;

  const _GuidePage(this.emoji, this.title, this.body);
}

const _pages = [
  _GuidePage(
    '📖',
    'LifeTraceへようこそ',
    'あなたの人生の出来事を「ライフイベント」として記録し、あとから振り返れるアプリです。',
  ),
  _GuidePage(
    '✍️',
    '出来事を記録する',
    '画面下の「記録する」ボタンから、\nいつ・何があって・どう感じたかを残せます。\n公開範囲を「非公開」にすれば、自分だけの日記になります。',
  ),
  _GuidePage(
    '📈',
    '感情グラフで振り返る',
    '記録した気持ちが「人生の浮き沈みグラフ」になります。\n転機になった出来事もひと目で分かります。',
  ),
  _GuidePage(
    '🤝',
    '誰かの人生を追体験する',
    'ほかの人のライフラインを読んで、\n「いいね」「わかる」「感動した」で気持ちを伝えましょう。',
  ),
];

/// アプリの使い方を紹介する画面。
///
/// 初回起動時に表示されるほか、設定の「使い方ガイド」からいつでも開ける。
class OnboardingScreen extends ConsumerStatefulWidget {
  /// 設定から開いた場合は true。完了時に前の画面へ戻る。
  final bool isReplay;

  const OnboardingScreen({super.key, this.isReplay = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (widget.isReplay) {
      context.pop();
      return;
    }
    // 完了を保存すると、ルーターがログイン画面（またはホーム）へ移動させる。
    await ref.read(onboardingCompletedProvider.notifier).complete();
  }

  void _next() {
    if (_isLastPage) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(widget.isReplay ? '閉じる' : 'スキップ'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Text(page.emoji, style: const TextStyle(fontSize: 64)),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.7,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage ? colorScheme.primary : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLastPage ? (widget.isReplay ? '閉じる' : 'はじめる') : '次へ'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
