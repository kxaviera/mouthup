import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post.dart';

Future<void> sharePost(BuildContext context, MouthUpPost post) async {
  final link = Uri.base.replace(path: '/post/${post.id}', query: '', fragment: '').toString();
  final excerpt = post.content.length > 280 ? '${post.content.substring(0, 277)}...' : post.content;
  final text = '@${post.author} on MouthUp\n\n$excerpt\n\n$link';

  await Clipboard.setData(ClipboardData(text: text));

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post copied — paste anywhere to share')),
    );
  }
}
