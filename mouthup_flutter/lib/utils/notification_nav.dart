import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../providers/app_state.dart';

/// Maps API / legacy notification routes to in-app GoRouter paths.
String? resolveNotificationRoute(String? raw) {
  if (raw == null) return null;
  var route = raw.trim();
  if (route.isEmpty) return null;

  if (route.startsWith('/posts/')) {
    final id = route.substring('/posts/'.length).split('/').first.split('?').first;
    if (id.isNotEmpty) return '/post/$id';
  }

  if (route.startsWith('/users/')) {
    final user = route.substring('/users/'.length).split('/').first.split('?').first;
    if (user.isNotEmpty) return '/user/$user';
  }

  if (route.startsWith('/messages/') && !route.startsWith('/messages/chat')) {
    final peer = route.substring('/messages/'.length).split('/').first.split('?').first;
    if (peer.isNotEmpty && peer != 'chat') {
      return Uri(path: '/messages/chat', queryParameters: {'peer': peer}).toString();
    }
  }

  if (route.startsWith('/rooms/') || route == '/rooms') {
    return '/chats';
  }

  if (route == '/messages' || route == '/messages/') {
    return '/chats';
  }

  const known = {
    '/home',
    '/login',
    '/signup',
    '/chats',
    '/search',
    '/profile',
    '/create-post',
    '/notifications',
    '/profile/posts',
    '/profile/saved',
    '/profile/settings',
    '/profile/blocked',
    '/profile/feed-settings',
    '/profile/terms',
    '/profile/privacy',
  };

  if (known.contains(route)) return route;
  if (route.startsWith('/post/')) return route;
  if (route.startsWith('/user/')) return route;
  if (route.startsWith('/messages/chat')) return route;
  if (route.startsWith('/profile/connections')) return route;

  return null;
}

String notificationActionLabel(NotificationType type) {
  switch (type) {
    case NotificationType.listing:
      return 'View listing';
    case NotificationType.message:
      return 'Open chat';
    case NotificationType.comment:
      return 'View post';
    case NotificationType.follow:
      return 'View profile';
    case NotificationType.general:
      return 'Open';
  }
}

Future<void> openNotificationRoute(BuildContext context, AppNotification notification) async {
  final app = context.read<AppState>();
  app.markNotificationRead(notification.id);

  final route = resolveNotificationRoute(notification.route);
  if (route == null || route.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nothing to open for this notification')),
    );
    return;
  }

  if (route.startsWith('/post/') && !route.contains('/edit')) {
    final postId = route.replaceFirst('/post/', '').split('?').first.split('/').first;
    if (postId.isNotEmpty && app.getPost(postId) == null) {
      await app.loadPostDetail(postId);
    }
    if (!context.mounted) return;
    if (app.getPost(postId) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This listing is no longer available')),
      );
      return;
    }
  }

  if (route.startsWith('/user/')) {
    final username = route.replaceFirst('/user/', '').split('?').first.split('/').first;
    if (username.isNotEmpty && app.socialProfile(username) == null) {
      await app.loadPublicProfile(username);
    }
    if (!context.mounted) return;
    if (!app.canViewProfile(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This profile is unavailable')),
      );
      return;
    }
  }

  if (route.startsWith('/messages/chat')) {
    final uri = Uri.parse(route);
    final peer = uri.queryParameters['peer'] ?? '';
    if (peer.isNotEmpty && !app.canDm(peer)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open this conversation')),
      );
      return;
    }
  }

  if (!context.mounted) return;
  context.push(route);
}
