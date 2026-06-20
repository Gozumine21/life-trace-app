import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment.dart';
import '../models/follow.dart';
import '../models/life_event.dart';
import '../models/notification.dart';
import '../models/reaction.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _lifeEvents =>
      _db.collection('lifeEvents');

  CollectionReference<Map<String, dynamic>> get _follows =>
      _db.collection('follows');

  CollectionReference<Map<String, dynamic>> get _experienceLogs =>
      _db.collection('experienceLogs');

  // ---------------- users ----------------

  Future<void> createUserProfile(UserProfile profile) {
    return _users.doc(profile.uid).set(profile.toMap());
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).update(data);
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromMap(snap.id, snap.data()!);
    });
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.id, snap.data()!);
  }

  // ---------------- lifeEvents ----------------

  DocumentReference<Map<String, dynamic>> newLifeEventRef() =>
      _lifeEvents.doc();

  Future<void> setLifeEvent(String eventId, LifeEvent event) {
    return _lifeEvents.doc(eventId).set(event.toMap());
  }

  Future<void> updateLifeEvent(String eventId, Map<String, dynamic> data) {
    return _lifeEvents.doc(eventId).update(data);
  }

  Future<void> deleteLifeEvent(String eventId) {
    return _lifeEvents.doc(eventId).delete();
  }

  Stream<LifeEvent?> watchLifeEvent(String eventId) {
    return _lifeEvents.doc(eventId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return LifeEvent.fromMap(snap.id, snap.data()!);
    });
  }

  /// 1人のライフイベントを発生年月の昇順で取得（タイムライン・グラフ用）。
  Stream<List<LifeEvent>> watchUserLifeEvents(String authorId) {
    return _lifeEvents
        .where('authorId', isEqualTo: authorId)
        .orderBy('occurredYearMonth')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => LifeEvent.fromMap(d.id, d.data())).toList(),
        );
  }

  /// ホームフィード：公開ライフイベントを新着順で取得。
  Stream<List<LifeEvent>> watchPublicFeed({int limit = 30}) {
    return _lifeEvents
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => LifeEvent.fromMap(d.id, d.data())).toList(),
        );
  }

  /// カテゴリで検索（公開イベントのみ）。
  Stream<List<LifeEvent>> watchByCategory(String category) {
    return _lifeEvents
        .where('visibility', isEqualTo: 'public')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => LifeEvent.fromMap(d.id, d.data())).toList(),
        );
  }

  /// 感情タグで検索（公開イベントのみ）。
  Stream<List<LifeEvent>> watchByEmotionTag(String emotionTag) {
    return _lifeEvents
        .where('visibility', isEqualTo: 'public')
        .where('emotionTag', isEqualTo: emotionTag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => LifeEvent.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> incrementLikeCount(String eventId, int delta) {
    return _lifeEvents.doc(eventId).update({
      'likeCount': FieldValue.increment(delta),
    });
  }

  Future<void> incrementCommentCount(String eventId, int delta) {
    return _lifeEvents.doc(eventId).update({
      'commentCount': FieldValue.increment(delta),
    });
  }

  // ---------------- comments (サブコレクション) ----------------

  CollectionReference<Map<String, dynamic>> _comments(String eventId) =>
      _lifeEvents.doc(eventId).collection('comments');

  Future<void> addComment(String eventId, Comment comment) async {
    await _comments(eventId).doc(comment.commentId).set(comment.toMap());
    await incrementCommentCount(eventId, 1);
  }

  Future<void> deleteComment(String eventId, String commentId) async {
    await _comments(eventId).doc(commentId).delete();
    await incrementCommentCount(eventId, -1);
  }

  Stream<List<Comment>> watchComments(String eventId) {
    return _comments(eventId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Comment.fromMap(d.id, d.data())).toList(),
        );
  }

  // ---------------- reactions (サブコレクション) ----------------

  CollectionReference<Map<String, dynamic>> _reactions(String eventId) =>
      _lifeEvents.doc(eventId).collection('reactions');

  Future<void> setReaction(String eventId, Reaction reaction) async {
    final ref = _reactions(eventId).doc(reaction.userId);
    final existing = await ref.get();
    await ref.set(reaction.toMap());
    if (!existing.exists) {
      await incrementLikeCount(eventId, 1);
    }
  }

  Future<void> removeReaction(String eventId, String userId) async {
    final ref = _reactions(eventId).doc(userId);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.delete();
      await incrementLikeCount(eventId, -1);
    }
  }

  Stream<Reaction?> watchMyReaction(String eventId, String userId) {
    return _reactions(eventId).doc(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Reaction.fromMap(snap.id, snap.data()!);
    });
  }

  // ---------------- follows ----------------

  Future<void> follow(String followerId, String followeeId) async {
    final id = Follow.idFor(followerId, followeeId);
    final follow = Follow(
      followId: id,
      followerId: followerId,
      followeeId: followeeId,
      createdAt: DateTime.now(),
    );
    await _follows.doc(id).set(follow.toMap());
    await _users.doc(followerId).update({
      'followingCount': FieldValue.increment(1),
    });
    await _users.doc(followeeId).update({
      'followerCount': FieldValue.increment(1),
    });
  }

  Future<void> unfollow(String followerId, String followeeId) async {
    final id = Follow.idFor(followerId, followeeId);
    final ref = _follows.doc(id);
    final existing = await ref.get();
    if (!existing.exists) return;
    await ref.delete();
    await _users.doc(followerId).update({
      'followingCount': FieldValue.increment(-1),
    });
    await _users.doc(followeeId).update({
      'followerCount': FieldValue.increment(-1),
    });
  }

  Stream<bool> watchIsFollowing(String followerId, String followeeId) {
    final id = Follow.idFor(followerId, followeeId);
    return _follows.doc(id).snapshots().map((snap) => snap.exists);
  }

  Stream<List<String>> watchFollowingIds(String followerId) {
    return _follows
        .where('followerId', isEqualTo: followerId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => d.data()['followeeId'] as String).toList(),
        );
  }

  // ---------------- notifications (サブコレクション) ----------------

  CollectionReference<Map<String, dynamic>> _notifications(String uid) =>
      _users.doc(uid).collection('notifications');

  Future<void> addNotification(String uid, AppNotification notification) {
    return _notifications(uid)
        .doc(notification.notificationId)
        .set(notification.toMap());
  }

  Future<void> markNotificationRead(String uid, String notificationId) {
    return _notifications(uid).doc(notificationId).update({'isRead': true});
  }

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _notifications(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ---------------- experienceLogs ----------------

  Future<void> recordExperienceView({
    required String viewerId,
    required String targetUserId,
    required String eventId,
  }) async {
    final id = '${viewerId}_$targetUserId';
    final ref = _experienceLogs.doc(id);
    final snap = await ref.get();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!snap.exists) {
      await ref.set({
        'viewerId': viewerId,
        'targetUserId': targetUserId,
        'lastViewedEventId': eventId,
        'viewedEventIds': [eventId],
        'createdAt': now,
        'updatedAt': now,
      });
    } else {
      await ref.update({
        'lastViewedEventId': eventId,
        'viewedEventIds': FieldValue.arrayUnion([eventId]),
        'updatedAt': now,
      });
    }
  }
}
