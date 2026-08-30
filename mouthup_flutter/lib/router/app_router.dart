import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_state.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/chats/chats_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/edit_post_screen.dart';
import '../screens/home_shell.dart';
import '../screens/messages/dm_chat_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/onboarding/account_type_screen.dart';
import '../screens/onboarding/city_screen.dart';
import '../screens/onboarding/choose_name_screen.dart';
import '../screens/onboarding/profession_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/profile/blocked_users_screen.dart';
import '../screens/profile/connections_screen.dart';
import '../screens/profile/feed_settings_screen.dart';
import '../screens/profile/privacy_policy_screen.dart';
import '../screens/profile/profile_settings_screen.dart';
import '../screens/profile/terms_screen.dart';
import '../screens/profile/my_posts_screen.dart';
import '../screens/profile/notifications_screen.dart';
import '../screens/profile/saved_posts_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tabs/feed_screen.dart';
import '../screens/tabs/search_screen.dart';
import '../screens/tabs/profile_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AppState app) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: app,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      const public = {'/', '/login', '/signup', '/forgot-password'};

      if (!app.isLoggedIn) {
        if (public.contains(loc) || loc.startsWith('/reset-password')) return null;
        return '/login';
      }

      if (!app.emailVerified) {
        if (loc == '/verify-email') return null;
        return '/verify-email';
      }

      if (!app.onboardingDone) {
        if (loc.startsWith('/onboarding/')) return null;
        if (loc == '/login' || loc == '/signup' || loc == '/verify-email') {
          return '/onboarding/nickname';
        }
        if (public.contains(loc)) return null;
        if (loc.startsWith('/reset-password') || loc == '/forgot-password') return '/onboarding/nickname';
        return '/onboarding/nickname';
      }

      if (loc == '/signup') return null;

      if (loc == '/login' ||
          loc == '/verify-email' ||
          loc.startsWith('/onboarding/') ||
          loc == '/forgot-password' ||
          loc.startsWith('/reset-password')) {
        return '/home';
      }

      return null;
    },
    errorBuilder: (_, state) => NotFoundScreen(message: state.error?.toString()),
    routes: [
      GoRoute(path: '/', builder: (_, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, s) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, s) => const SignupScreen()),
      GoRoute(path: '/verify-email', builder: (_, s) => const VerifyEmailScreen()),
      GoRoute(path: '/forgot-password', builder: (_, s) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (_, s) => ResetPasswordScreen(email: s.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(path: '/onboarding/nickname', builder: (_, s) => const ChooseNameScreen()),
      GoRoute(path: '/onboarding/account-type', builder: (_, s) => const AccountTypeScreen()),
      GoRoute(path: '/onboarding/profession', builder: (_, s) => const ProfessionScreen()),
      GoRoute(path: '/onboarding/city', builder: (_, s) => const CityScreen()),
      GoRoute(path: '/onboarding/welcome', builder: (_, s) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/safety', redirect: (_, s) => '/onboarding/welcome'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, state) => const NoTransitionPage(child: FeedScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (_, state) => const NoTransitionPage(child: SearchScreen(inTabShell: true)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                pageBuilder: (_, state) => const NoTransitionPage(child: ChatsScreen(inTabShell: true)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (_, state) => const NoTransitionPage(child: ProfileScreen(inTabShell: true)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/profile/posts', builder: (_, s) => const MyPostsScreen()),
      GoRoute(path: '/profile/saved', builder: (_, s) => const SavedPostsScreen()),
      GoRoute(path: '/profile/blocked', builder: (_, s) => const BlockedUsersScreen()),
      GoRoute(path: '/profile/settings', builder: (_, s) => const ProfileSettingsScreen()),
      GoRoute(
        path: '/profile/connections',
        builder: (_, s) {
          final type = s.uri.queryParameters['type'] ?? 'following';
          final user = s.uri.queryParameters['user'] ?? app.nickname;
          return ConnectionsScreen(username: user, showFollowers: type == 'followers');
        },
      ),
      GoRoute(path: '/profile/terms', builder: (_, s) => const TermsScreen()),
      GoRoute(path: '/profile/privacy', builder: (_, s) => const PrivacyPolicyScreen()),
      GoRoute(path: '/profile/feed-settings', builder: (_, s) => const FeedSettingsScreen()),
      GoRoute(path: '/notifications', builder: (_, s) => const NotificationsScreen()),
      GoRoute(path: '/rooms', redirect: (_, s) => '/chats'),
      GoRoute(path: '/messages', redirect: (_, s) => '/chats'),
      GoRoute(path: '/create-post', builder: (_, s) => const CreatePostScreen()),
      GoRoute(
        path: '/post/:id/edit',
        builder: (_, s) => EditPostScreen(postId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (_, s) => PostDetailScreen(postId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/user/:username',
        builder: (_, s) => UserProfileScreen(username: s.pathParameters['username']!),
      ),
      GoRoute(
        path: '/messages/chat',
        builder: (_, s) => DmChatScreen(
          peer: s.uri.queryParameters['peer'] ?? '',
          postId: s.uri.queryParameters['postId'],
        ),
      ),
    ],
  );
}
