import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/constants.dart';
import '../../../widgets/common/app_image.dart';
import '../../../widgets/common/empty_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../timeline/providers/life_event_providers.dart';

class ExperienceModeScreen extends ConsumerStatefulWidget {
  final String uid;

  const ExperienceModeScreen({super.key, required this.uid});

  @override
  ConsumerState<ExperienceModeScreen> createState() => _ExperienceModeScreenState();
}

class _ExperienceModeScreenState extends ConsumerState<ExperienceModeScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _recordView(String eventId) {
    final viewer = ref.read(currentUserProvider);
    if (viewer == null) return;
    ref.read(firestoreServiceProvider).recordExperienceView(
          viewerId: viewer.uid,
          targetUserId: widget.uid,
          eventId: eventId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(userLifeEventsProvider(widget.uid));
    final profileAsync = ref.watch(userProfileProvider(widget.uid));

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (p) => Text('${p?.displayName ?? ''} の追体験'),
          loading: () => const Text('追体験モード'),
          error: (e, st) => const Text('追体験モード'),
        ),
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const EmptyView(message: '追体験できるライフイベントがありません');
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _recordView(events.first.eventId);
          });
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: events.length,
            onPageChanged: (index) => _recordView(events[index].eventId),
            itemBuilder: (context, index) {
              final event = events[index];
              final myReactionAsync = ref.watch(myReactionProvider(event.eventId));
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (index + 1) / events.length,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${index + 1} / ${events.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 8),
                    Text(
                      event.occurredYearMonth,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (event.imageUrls.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AppImage(url: event.imageUrls.first, height: 200, fit: BoxFit.cover, width: double.infinity),
                      ),
                    const SizedBox(height: 16),
                    Text(event.body, style: const TextStyle(fontSize: 16, height: 1.6)),
                    const SizedBox(height: 24),
                    Text('この出来事に気持ちを送る', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ReactionType.all.map((type) {
                        return myReactionAsync.when(
                          data: (reaction) {
                            final selected = reaction?.type == type;
                            return ActionChip(
                              avatar: Icon(
                                selected ? Icons.check_circle : Icons.add_circle_outline,
                                size: 16,
                              ),
                              label: Text('${ReactionType.emojiFor(type)} ${ReactionType.labelFor(type)}'),
                              onPressed: () => ref
                                  .read(lifeEventControllerProvider.notifier)
                                  .toggleReaction(event.eventId, selected, type),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (e, st) => const SizedBox.shrink(),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            index == events.length - 1 ? Icons.flag_outlined : Icons.keyboard_double_arrow_up,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          Text(
                            index == events.length - 1
                                ? '最後まで読みました'
                                : '上にスワイプして次の出来事へ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(error: e, onRetry: () => ref.invalidate(userLifeEventsProvider(widget.uid))),
      ),
    );
  }
}
