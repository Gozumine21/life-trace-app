import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_profile.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  // ログイン済みユーザーが検出された直後はFirestoreへ渡すIDトークンの
  // 準備が間に合わず permission-denied になることがあるため、
  // トークン取得が完了してから値を流す。
  return ref.watch(authServiceProvider).authStateChanges().asyncMap((user) async {
    if (user != null) {
      await user.getIdToken();
    }
    return user;
  });
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).asData?.value;
});

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).signInWithEmail(email, password);
    });
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await ref
          .read(authServiceProvider)
          .signUpWithEmail(email, password);
      final uid = credential.user!.uid;
      final now = DateTime.now();
      await ref.read(firestoreServiceProvider).createUserProfile(
            UserProfile(
              uid: uid,
              displayName: displayName,
              iconUrl: null,
              bio: '',
              birthYearMonth: null,
              // 書いてから公開を判断できるよう、最初は非公開にしておく。
              defaultVisibility: 'private',
              followerCount: 0,
              followingCount: 0,
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
    });
  }

  /// 本人確認のうえ、ライフイベントなど本人のデータをすべて消してからアカウントを削除する。
  Future<void> deleteAccount(String password) async {
    final auth = ref.read(authServiceProvider);
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    await auth.reauthenticate(password);
    await ref.read(firestoreServiceProvider).deleteAllUserData(uid);
    await auth.deleteAccount();
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
