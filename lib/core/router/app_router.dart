import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/emotion_graph/screens/emotion_graph_screen.dart';
import '../../features/experience_mode/screens/experience_mode_screen.dart';
import '../../features/home/screens/feed_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/life_event_form/screens/life_event_form_screen.dart';
import '../../features/moderation/screens/report_management_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/onboarding/providers/onboarding_providers.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/timeline/screens/life_event_detail_screen.dart';
import '../../features/timeline/screens/my_page_screen.dart';
import '../../features/timeline/screens/user_timeline_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      // 使い方ガイドはログイン前でも開けるようにする。
      final isPublicRoute = isAuthRoute || state.matchedLocation == '/guide';

      if (authState.isLoading) return null;
      // 初回起動時は、まずアプリの使い方を紹介する。
      if (!onboardingCompleted) return isOnboardingRoute ? null : '/onboarding';
      if (isOnboardingRoute) return isLoggedIn ? '/' : '/login';
      if (!isLoggedIn && !isPublicRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: '/guide',
        builder: (context, state) => const OnboardingScreen(isReplay: true),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (authState.isLoading) return const SplashScreen();
          return const _HomeShellRoot();
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/mypage', builder: (context, state) => const MyPageScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/life-event/new',
        builder: (context, state) => const LifeEventFormScreen(),
      ),
      GoRoute(
        path: '/life-event/:eventId',
        builder: (context, state) =>
            LifeEventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/life-event/:eventId/edit',
        builder: (context, state) =>
            LifeEventFormScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/user/:uid',
        builder: (context, state) =>
            UserTimelineScreen(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: '/emotion-graph/:uid',
        builder: (context, state) =>
            EmotionGraphScreen(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: '/experience/:uid',
        builder: (context, state) =>
            ExperienceModeScreen(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const ReportManagementScreen(),
      ),
    ],
  );
});

class _HomeShellRoot extends StatelessWidget {
  const _HomeShellRoot();

  @override
  Widget build(BuildContext context) {
    // ルートの '/' はログイン済みなら即座に '/feed' へ。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoRouter.of(context).go('/feed');
    });
    return const SplashScreen();
  }
}
