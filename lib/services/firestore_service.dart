import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/stream_retry.dart';
import '../models/block.dart';
import '../models/comment.dart';
import '../models/follow.dart';
import '../models/life_event.dart';
import '../models/notification.dart';
import '../models/reaction.dart';
import '../models/report.dart';
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

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _db.collection('blocks');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  // ---------------- users ----------------

  Future<void> createUserProfile(UserProfile profile) {
    return _users.doc(profile.uid).set(profile.toMap());
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    // update() はドキュメントが存在しない場合に失敗するため set(merge:true) を使う
    return _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    return withPermissionRetry(() => _users.doc(uid).snapshots().map((snap) {
          if (!snap.exists) return null;
          return UserProfile.fromMap(snap.id, snap.data()!);
        }));
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

  /// 1件のライフイベント。存在しないか、公開範囲の外で読めないときは null。
  Stream<LifeEvent?> watchLifeEvent(String eventId) {
    return _lifeEvents
        .doc(eventId)
        .snapshots()
        .map<LifeEvent?>((snap) {
          if (!snap.exists) return null;
          return LifeEvent.fromMap(snap.id, snap.data()!);
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              if (error is FirebaseException && error.code == 'permission-denied') {
                sink.add(null);
              } else {
                sink.addError(error, stackTrace);
              }
            },
          ),
        );
  }

  /// 1人のライフイベントを発生年月の昇順で取得（タイムライン・グラフ用）。
  ///
  /// 他の人の記録を読むときは、Security Rules を満たすよう [visibilities] で
  /// 公開範囲を絞り込む（本人なら null）。複合インデックスを使わないよう、並べ替えは手元で行う。
  Stream<List<LifeEvent>> watchUserLifeEvents(
    String authorId, {
    List<String>? visibilities,
  }) {
    Query<Map<String, dynamic>> query = _lifeEvents.where('authorId', isEqualTo: authorId);
    if (visibilities != null) {
      query = query.where('visibility', whereIn: visibilities);
    }
    return withPermissionRetry(() => query.snapshots().map(
          (snap) => snap.docs.map((d) => LifeEvent.fromMap(d.id, d.data())).toList()
            ..sort((a, b) {
              final byMonth = a.occurredYearMonth.compareTo(b.occurredYearMonth);
              return byMonth != 0 ? byMonth : a.createdAt.compareTo(b.createdAt);
            }),
        ));
  }

  /// ホームフィード：公開ライフイベントを新着順で取得。
  Stream<List<LifeEvent>> watchPublicFeed({int limit = 30}) {
    return withPermissionRetry(() => _lifeEvents
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => LifeEvent.fromMap(d.id, d.data())).toList(),
        ));
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

  /// ある記録に「応えて」書かれた記録を取得（応答記録）。
  Stream<List<LifeEvent>> watchResponses(String eventId) {
    return _lifeEvents
        .where('respondsToEventId', isEqualTo: eventId)
        .where('visibility', isEqualTo: 'public')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => LifeEvent.fromMap(d.id, d.data())).toList()
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
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

  /// リアクションを付ける（種類の変更も含む）。新しく付けたときは true を返す。
  Future<bool> setReaction(String eventId, Reaction reaction) async {
    final ref = _reactions(eventId).doc(reaction.userId);
    final existing = await ref.get();
    await ref.set(reaction.toMap());
    if (!existing.exists) {
      await incrementLikeCount(eventId, 1);
    }
    return !existing.exists;
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
    return withPermissionRetry(() => _follows
        .where('followerId', isEqualTo: followerId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => d.data()['followeeId'] as String).toList(),
        ));
  }

  // ---------------- notifications (サブコレクション) ----------------

  CollectionReference<Map<String, dynamic>> _notifications(String uid) =>
      _users.doc(uid).collection('notifications');

  Future<void> addNotification(String uid, AppNotification notification) {
    return _notifications(uid)
        .doc(notification.notificationId)
        .set(notification.toMap());
  }

  /// [toUid] にお知らせを届ける。自分自身の操作では送らない。
  Future<void> sendNotification({
    required String toUid,
    required String fromUid,
    required String type,
    String? targetEventId,
  }) {
    if (toUid == fromUid) return Future.value();
    final ref = _notifications(toUid).doc();
    return ref.set(
      AppNotification(
        notificationId: ref.id,
        type: type,
        fromUserId: fromUid,
        targetEventId: targetEventId,
        isRead: false,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<void> markNotificationRead(String uid, String notificationId) {
    return _notifications(uid).doc(notificationId).update({'isRead': true});
  }

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return withPermissionRetry(() => _notifications(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromMap(d.id, d.data()))
              .toList(),
        ));
  }

  // ---------------- account ----------------

  /// アカウント削除の前に、本人のデータを消す。
  ///
  /// ライフイベント（とそのコメント・リアクション）、フォロー、ブロック、
  /// 追体験の履歴、お知らせ、プロフィールを削除する。
  Future<void> deleteAllUserData(String uid) async {
    final events = await _lifeEvents.where('authorId', isEqualTo: uid).get();
    for (final event in events.docs) {
      await _deleteAll(_comments(event.id));
      await _deleteAll(_reactions(event.id));
      await event.reference.delete();
    }
    final following = await _follows.where('followerId', isEqualTo: uid).get();
    for (final doc in following.docs) {
      await unfollow(uid, doc.data()['followeeId'] as String);
    }
    await _deleteAll(_blocks.where('blockerId', isEqualTo: uid));
    await _deleteAll(_experienceLogs.where('viewerId', isEqualTo: uid));
    await _deleteAll(_notifications(uid));
    await _deleteAll(_fcmTokens(uid));
    await _users.doc(uid).delete();
  }

  Future<void> _deleteAll(Query<Map<String, dynamic>> query) async {
    final snap = await query.get();
    // バッチは1回あたり500件まで。
    for (var i = 0; i < snap.docs.length; i += 400) {
      final batch = _db.batch();
      for (final doc in snap.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // ---------------- fcmTokens (サブコレクション) ----------------

  CollectionReference<Map<String, dynamic>> _fcmTokens(String uid) =>
      _users.doc(uid).collection('fcmTokens');

  Future<void> saveFcmToken(String uid, String token) {
    return _fcmTokens(uid).doc(token).set({
      'token': token,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteFcmToken(String uid, String token) {
    return _fcmTokens(uid).doc(token).delete();
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

  // ---------------- blocks ----------------

  Future<void> blockUser(String blockerId, String blockedId) {
    final id = Block.idFor(blockerId, blockedId);
    final block = Block(
      blockId: id,
      blockerId: blockerId,
      blockedId: blockedId,
      createdAt: DateTime.now(),
    );
    return _blocks.doc(id).set(block.toMap());
  }

  Future<void> unblockUser(String blockerId, String blockedId) {
    final id = Block.idFor(blockerId, blockedId);
    return _blocks.doc(id).delete();
  }

  Stream<List<String>> watchBlockedUserIds(String blockerId) {
    return withPermissionRetry(() => _blocks
        .where('blockerId', isEqualTo: blockerId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => d.data()['blockedId'] as String).toList(),
        ));
  }

  // ---------------- reports ----------------

  Future<void> submitReport(Report report) {
    return _reports.doc().set(report.toMap());
  }

  Stream<List<Report>> watchAllReports() {
    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Report.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> resolveReport(String reportId) {
    return _reports.doc(reportId).update({'status': ReportStatus.resolved});
  }
}
