import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_profile.dart';
import '../../auth/providers/auth_providers.dart';

final userProfileProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).watchUserProfile(uid);
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).watchUserProfile(user.uid);
});

final isFollowingProvider =
    StreamProvider.family<bool, String>((ref, targetUid) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(false);
  return ref
      .watch(firestoreServiceProvider)
      .watchIsFollowing(user.uid, targetUid);
});

class FollowController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggleFollow(String targetUid, bool isCurrentlyFollowing) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(firestoreServiceProvider);
      if (isCurrentlyFollowing) {
        await service.unfollow(user.uid, targetUid);
      } else {
        await service.follow(user.uid, targetUid);
      }
    });
  }
}

final followControllerProvider =
    AsyncNotifierProvider<FollowController, void>(FollowController.new);
