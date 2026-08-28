import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../models/post_comment.dart';
import '../../providers/app_state.dart';
import '../../utils/user_profile_nav.dart';
import '../../utils/nav_back.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_share.dart';
import '../../widgets/post_tile.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/user_avatar.dart';
import 'not_found_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<AppState>().loadPostDetail(widget.postId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment(AppState app) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final blocked = await app.addComment(widget.postId, text);
    if (!mounted) return;
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked.userMessage), backgroundColor: AppColors.danger.withValues(alpha: 0.9)),
      );
      return;
    }
    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _confirmDeletePost(AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete post?', style: TextStyle(color: AppColors.text)),
        content: const Text('This cannot be undone.', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: AppColors.text),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await app.deletePost(widget.postId);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.go('/home');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
  }

  void _confirmDeleteComment(AppState app, PostComment c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete reply?', style: TextStyle(color: AppColors.text)),
        content: const Text('This reply will be removed.', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: AppColors.text),
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await app.deleteComment(c.id);
              if (!context.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _postMenu(AppState app, MouthUpPost post) {
    final isAuthor = app.isPostAuthor(post.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAuthor) ...[
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
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePost(app);
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.textMuted),
                title: const Text('Report post', style: TextStyle(color: AppColors.text)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final error = await app.reportPost(post.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Post reported — thanks')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _commentMenu(AppState app, PostComment c) {
    final isAuthor = app.isCommentAuthor(c.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAuthor)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Delete reply', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteComment(app, c);
                },
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.block, color: AppColors.textMuted),
                title: Text('Block ${c.author}', style: const TextStyle(color: AppColors.text)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final error = await app.blockUser(c.author);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Blocked ${c.author}')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.textMuted),
                title: const Text('Report reply', style: TextStyle(color: AppColors.text)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final error = await app.reportComment(c.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Reply reported — thanks')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final post = app.getPost(widget.postId);

    if (_loading) {
      return const ScreenWrapper(
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (post == null) {
      return NotFoundScreen(message: 'This post was deleted or doesn\'t exist.');
    }

    final postComments = app.commentsForPost(widget.postId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrGo(context, '/home');
      },
      child: ScreenWrapper(
        padding: false,
        bottomSafe: false,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => popOrGo(context, '/home'), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                  const Expanded(child: Text('Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text))),
                  IconButton(
                    onPressed: () => _postMenu(app, post),
                    icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  PostTile(
                    post: post,
                    showDivider: true,
                    previewWords: null,
                    onSave: () async {
                      final wasSaved = post.userSaved;
                      await app.toggleSavePost(post.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(wasSaved ? 'Removed from saved' : 'Post saved')),
                      );
                    },
                    onShare: () => sharePost(context, post),
                    onAuthorTap: () => openUserProfile(context, app, post.author),
                    commentCount: postComments.length,
                  ),
                  if (postComments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No replies yet — start the conversation', style: TextStyle(color: AppColors.textDim, fontSize: 13))),
                    )
                  else
                    ...postComments.asMap().entries.map((e) {
                      final i = e.key;
                      final c = e.value;
                      return _commentTile(context, app, c, showDivider: i < postComments.length - 1);
                    }),
                ],
              ),
            ),
            _commentInput(app),
          ],
        ),
      ),
    );
  }

  Widget _commentInput(AppState app) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          UserAvatar(name: app.nickname, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Post your reply',
                filled: true,
                fillColor: AppColors.bgElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border)),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(app),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _submitComment(app),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size(40, 40),
            ),
            icon: const Icon(Icons.arrow_upward_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _commentTile(BuildContext context, AppState app, PostComment c, {required bool showDivider}) {
    final canOpenProfile = app.canViewProfile(c.author);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: canOpenProfile ? () => openUserProfile(context, app, c.author) : null,
                child: UserAvatar(name: c.author, radius: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: canOpenProfile ? () => openUserProfile(context, app, c.author) : null,
                          child: Text(
                            c.author,
                            style: TextStyle(
                              color: canOpenProfile ? AppColors.text : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(' · ${timeAgo(c.createdAt)}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(c.text, style: const TextStyle(color: AppColors.text, fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _commentMenu(app, c),
                icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textDim),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, thickness: 1, color: AppColors.border),
      ],
    );
  }
}
