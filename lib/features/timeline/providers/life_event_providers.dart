import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/constants.dart';
import '../../../models/comment.dart';
import '../../../models/life_event.dart';
import '../../../models/reaction.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';

final userLifeEventsProvider =
    StreamProvider.family<List<LifeEvent>, String>((ref, authorId) {
  return ref.watch(firestoreServiceProvider).watchUserLifeEvents(authorId);
});

/// 閲覧者に見せてよいライフイベントだけに絞った、ある人のタイムライン。
///
/// 他の人のページ・追体験・感情グラフでは、非公開の記録や
/// フォローしていない人のフォロワー限定の記録を表示しない。
final visibleUserLifeEventsProvider =
    Provider.family<AsyncValue<List<LifeEvent>>, String>((ref, authorId) {
  final events = ref.watch(userLifeEventsProvider(authorId));
  final viewerId = ref.watch(currentUserProvider)?.uid;
  if (viewerId == authorId) return events;
  final follows = ref.watch(isFollowingProvider(authorId)).valueOrNull ?? false;
  return events.whenData(
    (list) => list
        .where((e) => e.isVisibleTo(viewerId, viewerFollowsAuthor: follows))
        .toList(),
  );
});

/// ある記録に応えて書かれた、閲覧者に見せてよい記録。
final responsesProvider =
    StreamProvider.family<List<LifeEvent>, String>((ref, eventId) {
  final viewerId = ref.watch(currentUserProvider)?.uid;
  return ref.watch(firestoreServiceProvider).watchResponses(eventId).map(
        (list) => list
            .where((e) => e.isVisibleTo(viewerId, viewerFollowsAuthor: false))
            .toList(),
      );
});

final lifeEventProvider =
    StreamProvider.family<LifeEvent?, String>((ref, eventId) {
  return ref.watch(firestoreServiceProvider).watchLifeEvent(eventId);
});

final publicFeedProvider = StreamProvider<List<LifeEvent>>((ref) {
  return ref.watch(firestoreServiceProvider).watchPublicFeed();
});

final eventCommentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, eventId) {
  return ref.watch(firestoreServiceProvider).watchComments(eventId);
});

final myReactionProvider =
    StreamProvider.family<Reaction?, String>((ref, eventId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref
      .watch(firestoreServiceProvider)
      .watchMyReaction(eventId, user.uid);
});

class LifeEventController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> createLifeEvent({
    required String title,
    required String body,
    required String occurredYearMonth,
    required String category,
    required String emotionTag,
    required int emotionScore,
    required bool isTurningPoint,
    required String visibility,
    required List<String> imageUrls,
    String? respondsToEventId,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('未ログインです');
    final service = ref.read(firestoreServiceProvider);
    final docRef = service.newLifeEventRef();
    final now = DateTime.now();
    final event = LifeEvent(
      eventId: docRef.id,
      authorId: user.uid,
      title: title,
      body: body,
      occurredYearMonth: occurredYearMonth,
      category: category,
      emotionTag: emotionTag,
      emotionScore: emotionScore,
      isTurningPoint: isTurningPoint,
      imageUrls: imageUrls,
      visibility: EventVisibility.values.firstWhere((v) => v.name == visibility),
      likeCount: 0,
      commentCount: 0,
      respondsToEventId: respondsToEventId,
      createdAt: now,
      updatedAt: now,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.setLifeEvent(docRef.id, event));
    state.whenOrNull(error: (e, st) => Error.throwWithStackTrace(e, st));
    if (respondsToEventId != null && event.visibility != EventVisibility.private) {
      final original = await service.watchLifeEvent(respondsToEventId).first;
      if (original != null) {
        await _notify(
          toUid: original.authorId,
          type: NotificationType.response,
          targetEventId: docRef.id,
        );
      }
    }
    return docRef.id;
  }

  Future<void> updateLifeEvent(
    String eventId,
    Map<String, dynamic> data,
  ) async {
    final service = ref.read(firestoreServiceProvider);
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => service.updateLifeEvent(eventId, data),
    );
    state.whenOrNull(error: (e, st) => Error.throwWithStackTrace(e, st));
  }

  Future<void> deleteLifeEvent(String eventId) async {
    final service = ref.read(firestoreServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.deleteLifeEvent(eventId));
    state.whenOrNull(error: (e, st) => Error.throwWithStackTrace(e, st));
  }

  /// お知らせの送信に失敗しても、本来の操作は成功として扱う。
  Future<void> _notify({
    required String toUid,
    required String type,
    String? targetEventId,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      await ref.read(firestoreServiceProvider).sendNotification(
            toUid: toUid,
            fromUid: user.uid,
            type: type,
            targetEventId: targetEventId,
          );
    } catch (_) {}
  }

  Future<void> addComment(
    String eventId,
    String body, {
    String? eventAuthorId,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final service = ref.read(firestoreServiceProvider);
    final commentId = DateTime.now().millisecondsSinceEpoch.toString();
    await service.addComment(
      eventId,
      Comment(
        commentId: commentId,
        authorId: user.uid,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
    if (eventAuthorId != null) {
      await _notify(
        toUid: eventAuthorId,
        type: NotificationType.comment,
        targetEventId: eventId,
      );
    }
  }

  Future<void> toggleReaction(
    String eventId,
    bool hasReacted,
    String type, {
    String? eventAuthorId,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final service = ref.read(firestoreServiceProvider);
    if (hasReacted) {
      await service.removeReaction(eventId, user.uid);
    } else {
      final isNew = await service.setReaction(
        eventId,
        Reaction(userId: user.uid, type: type, createdAt: DateTime.now()),
      );
      if (isNew && eventAuthorId != null) {
        await _notify(
          toUid: eventAuthorId,
          type: NotificationType.like,
          targetEventId: eventId,
        );
      }
    }
  }
}

final lifeEventControllerProvider =
    AsyncNotifierProvider<LifeEventController, void>(LifeEventController.new);
