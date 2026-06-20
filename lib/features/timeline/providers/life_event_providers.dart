import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../models/comment.dart';
import '../../../models/life_event.dart';
import '../../../models/reaction.dart';
import '../../auth/providers/auth_providers.dart';

final userLifeEventsProvider =
    StreamProvider.family<List<LifeEvent>, String>((ref, authorId) {
  return ref.watch(firestoreServiceProvider).watchUserLifeEvents(authorId);
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
      createdAt: now,
      updatedAt: now,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.setLifeEvent(docRef.id, event));
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
  }

  Future<void> deleteLifeEvent(String eventId) async {
    final service = ref.read(firestoreServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.deleteLifeEvent(eventId));
  }

  Future<void> addComment(String eventId, String body) async {
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
  }

  Future<void> toggleReaction(
    String eventId,
    bool hasReacted,
    String type,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final service = ref.read(firestoreServiceProvider);
    if (hasReacted) {
      await service.removeReaction(eventId, user.uid);
    } else {
      await service.setReaction(
        eventId,
        Reaction(userId: user.uid, type: type, createdAt: DateTime.now()),
      );
    }
  }
}

final lifeEventControllerProvider =
    AsyncNotifierProvider<LifeEventController, void>(LifeEventController.new);
