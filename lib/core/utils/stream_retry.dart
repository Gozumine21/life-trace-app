import 'package:cloud_firestore/cloud_firestore.dart';

/// アプリ起動直後は認証トークンのFirestoreへの反映が間に合わず、
/// 一時的に permission-denied になることがある。
/// その場合のみ自動的に再購読し、ユーザーにエラー画面を見せないようにする。
Stream<T> withPermissionRetry<T>(
  Stream<T> Function() factory, {
  int retries = 3,
  Duration delay = const Duration(milliseconds: 500),
}) async* {
  var attempt = 0;
  while (true) {
    try {
      yield* factory();
      return;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied' || attempt >= retries) rethrow;
      attempt++;
      await Future.delayed(delay);
    }
  }
}
