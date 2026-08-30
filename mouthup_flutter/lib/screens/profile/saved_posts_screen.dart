import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_share.dart';
import '../../widgets/post_tile.dart';
import '../../widgets/screen_wrapper.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadSavedPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final saved = app.savedPosts;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/profile');
      },
      child: ScreenWrapper(
        padding: false,
        bottomSafe: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.go('/profile'), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                  const Text('Saved', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                ],
              ),
            ),
            Expanded(
              child: saved.isEmpty
                  ? const Center(child: Text('No saved posts yet', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      itemCount: saved.length,
                      itemBuilder: (_, i) {
                        final post = saved[i];
                        final profile = app.socialProfile(post.author);
                        return PostTile(
                          post: post,
                          authorAvatarUrl: profile?.avatarUrl ?? app.avatarForUser(post.author, displayName: post.displayAuthor),
                          authorVerified: post.authorIsVerified || (profile?.verified ?? false),
                          showDivider: i < saved.length - 1,
                          onTap: () => context.push('/post/${post.id}'),
                          onSave: () async {
                            await app.toggleSavePost(post.id);
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
