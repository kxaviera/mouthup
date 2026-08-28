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
import '../screens/onboarding/choose_name_screen.dart';
import '../screens/onboarding/safety_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/profile/blocked_users_screen.dart';
import '../screens/profile/privacy_policy_screen.dart';
import '../screens/profile/terms_screen.dart';
import '../screens/profile/my_posts_screen.dart';
import '../screens/profile/notifications_screen.dart';
import '../screens/profile/saved_posts_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/splash_screen.dart';
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

      if (loc == '/login' ||
          loc == '/signup' ||
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
      GoRoute(path: '/onboarding/safety', builder: (_, s) => const SafetyScreen()),
      GoRoute(path: '/home', builder: (_, s) => const HomeShell()),
      GoRoute(path: '/profile', builder: (_, s) => const ProfileScreen()),
      GoRoute(path: '/profile/posts', builder: (_, s) => const MyPostsScreen()),
      GoRoute(path: '/profile/saved', builder: (_, s) => const SavedPostsScreen()),
      GoRoute(path: '/profile/blocked', builder: (_, s) => const BlockedUsersScreen()),
      GoRoute(path: '/profile/terms', builder: (_, s) => const TermsScreen()),
      GoRoute(path: '/profile/privacy', builder: (_, s) => const PrivacyPolicyScreen()),
      GoRoute(path: '/notifications', builder: (_, s) => const NotificationsScreen()),
      GoRoute(path: '/chats', builder: (_, s) => const ChatsScreen()),
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
        builder: (_, s) => DmChatScreen(peer: s.uri.queryParameters['peer'] ?? ''),
      ),
    ],
  );
}
