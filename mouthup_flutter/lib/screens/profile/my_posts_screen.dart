import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_share.dart';
import '../../widgets/post_tile.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadMyPosts();
    });
  }

  void _postActions(BuildContext context, AppState app, MouthUpPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new, color: AppColors.text),
              title: const Text('View post', style: TextStyle(color: AppColors.text)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/post/${post.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.text),
              title: const Text('Edit post', style: TextStyle(color: AppColors.text)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/post/${post.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Delete post', style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(ctx);
                final error = await app.deletePost(post.id);
                if (!context.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final myPosts = app.myPosts;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/profile');
      },
      child: ScreenWrapper(
        padding: false,
        bottomSafe: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.go('/profile'), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                  const Expanded(child: Text('My posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text))),
                  IconButton(
                    tooltip: 'New post',
                    onPressed: () => context.push('/create-post'),
                    icon: const Icon(Icons.add, color: AppColors.text),
                  ),
                ],
              ),
            ),
            Expanded(
              child: myPosts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined, size: 48, color: AppColors.textDim),
                            const SizedBox(height: 16),
                            const Text('Nothing posted yet', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            const Text('Share your first thought with the community', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 24),
                            PrimaryButton(title: 'Create post', onPressed: () => context.push('/create-post')),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: myPosts.length,
                      itemBuilder: (_, i) {
                        final post = myPosts[i];
                        return PostTile(
                          post: post,
                          showDivider: i < myPosts.length - 1,
                          onTap: () => context.push('/post/${post.id}'),
                          onLongPress: () => _postActions(context, app, post),
                          onSave: () {
                            final wasSaved = post.userSaved;
                            app.toggleSavePost(post.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(wasSaved ? 'Removed from saved' : 'Post saved')),
                            );
                          },
                          onComment: () => context.push('/post/${post.id}'),
                          onShare: () => sharePost(context, post),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
