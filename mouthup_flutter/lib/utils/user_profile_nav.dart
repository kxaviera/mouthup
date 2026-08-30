import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_state.dart';

void openUserProfile(BuildContext context, AppState app, String username) {
  if (app.isSelf(username)) {
    context.go('/profile');
    return;
  }
  if (!app.canViewProfile(username)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This profile is unavailable')),
    );
    return;
  }
  context.push('/user/${Uri.encodeComponent(username)}');
}

void openDirectChat(BuildContext context, AppState app, String username, {String? postId}) {
  if (!app.canDm(username)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot message this user')),
    );
    return;
  }
  final params = {'peer': username, if (postId != null) 'postId': postId};
  context.push(Uri(path: '/messages/chat', queryParameters: params).toString());
}
