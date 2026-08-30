import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/listing_types.dart';
import '../../models/social_profile.dart';
import '../../models/post.dart';
import '../../models/post_comment.dart';
import '../../providers/app_state.dart';
import '../../utils/user_profile_nav.dart';
import '../../utils/nav_back.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_share.dart';
import '../../utils/geo.dart';
import '../../utils/chat_label.dart';
import '../../widgets/post_content_text.dart';
import '../../widgets/post_video_player.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';
import 'not_found_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _pageCtrl = PageController();
  bool _loading = true;
  int _imagePage = 0;

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
    _pageCtrl.dispose();
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
        title: const Text('Delete listing?', style: TextStyle(color: AppColors.text)),
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
              if (post.isListing)
                ListTile(
                  leading: Icon(post.isOpen ? Icons.lock_outline : Icons.lock_open_outlined, color: AppColors.text),
                  title: Text(post.isOpen ? 'Mark as closed' : 'Mark as open', style: const TextStyle(color: AppColors.text)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final error = await app.toggleListingStatus(post.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? (post.isOpen ? 'Listing closed' : 'Listing reopened'))),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.text),
                title: const Text('Edit listing', style: TextStyle(color: AppColors.text)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/post/${post.id}/edit');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Delete listing', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePost(app);
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.textMuted),
                title: const Text('Report listing', style: TextStyle(color: AppColors.text)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final error = await app.reportPost(post.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Reported — thank you')),
                  );
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
    final post = app.getPost(widget.postId);

    if (_loading) {
      return const ScreenWrapper(child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (post == null) {
      return NotFoundScreen(message: 'This listing was deleted or doesn\'t exist.');
    }

    final comments = app.commentsForPost(widget.postId);
    final profile = app.socialProfile(post.author);
    final localImages = app.postImages(post.id);
    final localVideos = app.postVideos(post.id);
    final hasVideo = post.videoUrls.isNotEmpty || localVideos.isNotEmpty;
    final imageCount = localImages.length + post.imageUrls.length;
    final type = post.listingTypeOption;
    final locationLabel = formatPostLocationLabel(
      location: post.location,
      authorCity: post.authorCity,
      distanceKm: post.distanceKm,
    );
    final isAuthor = app.isPostAuthor(post.id);
    final hasMedia = hasVideo || imageCount > 0;

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
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (hasMedia)
                    SliverToBoxAdapter(child: _mediaHero(post, localImages, localVideos, hasVideo, imageCount))
                  else
                    SliverToBoxAdapter(child: _noMediaHeader(post, type)),
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: Offset(0, hasMedia ? -12 : 0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, hasMedia ? 28 : 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasMedia) ...[
                                _badges(type, post),
                                const SizedBox(height: 14),
                              ],
                              if (post.title != null && post.title!.isNotEmpty)
                                Text(
                                  post.title!,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              _detailsSection(post, type, locationLabel),
                              const SizedBox(height: 20),
                              _sellerCard(app, post, profile, isAuthor),
                              const SizedBox(height: 20),
                              _quickActions(app, post),
                              const SizedBox(height: 28),
                              _discussionHeader(comments.length),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (comments.isEmpty)
                    SliverToBoxAdapter(child: _emptyComments())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _commentTile(context, app, comments[i]),
                        childCount: comments.length,
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                ],
              ),
            ),
            _bottomBar(app, post, isAuthor),
          ],
        ),
      ),
    );
  }

  Widget _mediaHero(MouthUpPost post, List<Uint8List> localImages, List<Uint8List> localVideos, bool hasVideo, int imageCount) {
    return Stack(
      children: [
        SizedBox(
          height: 340,
          width: double.infinity,
          child: hasVideo
              ? PostVideoPlayer(url: post.videoUrls.first, height: 340)
              : PageView.builder(
                  controller: _pageCtrl,
                  itemCount: imageCount,
                  onPageChanged: (i) => setState(() => _imagePage = i),
                  itemBuilder: (_, i) {
                    if (i < localImages.length) {
                      return Image.memory(localImages[i], fit: BoxFit.cover, width: double.infinity);
                    }
                    return Image.network(
                      post.imageUrls[i - localImages.length],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      errorBuilder: (_, e, s) => Container(color: AppColors.bgElevated, child: const Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textDim)),
                    );
                  },
                ),
        ),
        Positioned(
          top: 8,
          left: 4,
          child: _circleBtn(Icons.arrow_back, () => popOrGo(context, '/home')),
        ),
        Positioned(
          top: 8,
          right: 4,
          child: Row(
            children: [
              _circleBtn(Icons.share_outlined, () => sharePost(context, post)),
              const SizedBox(width: 6),
              _circleBtn(Icons.more_horiz, () => _postMenu(context.read<AppState>(), post)),
            ],
          ),
        ),
        if (!hasVideo && imageCount > 1)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imageCount, (i) {
                final active = i == _imagePage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _noMediaHeader(MouthUpPost post, ListingTypeOption? type) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          IconButton(onPressed: () => popOrGo(context, '/home'), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
          Expanded(child: Text(type?.label ?? 'Listing', style: const TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700))),
          IconButton(onPressed: () => sharePost(context, post), icon: const Icon(Icons.share_outlined, color: AppColors.text)),
          IconButton(onPressed: () => _postMenu(context.read<AppState>(), post), icon: const Icon(Icons.more_horiz, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, color: Colors.white, size: 20)),
      ),
    );
  }

  Widget _badges(ListingTypeOption? type, MouthUpPost post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (type != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Text('${type.emoji} ${type.label}', style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          if (post.isListing) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: post.isOpen ? const Color(0xFF1A2E1A) : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: post.isOpen ? const Color(0xFF2D4A2D) : AppColors.border),
              ),
              child: Text(
                post.isOpen ? 'Available' : 'Closed',
                style: TextStyle(color: post.isOpen ? const Color(0xFF7DCE7D) : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailsSection(MouthUpPost post, ListingTypeOption? type, String locationLabel) {
    final rows = <Widget>[];

    if (post.priceLabel != null) {
      rows.add(_detailRow('Price', post.priceLabel!, highlight: true));
    }
    if (type != null) {
      rows.add(_detailRow('Type', '${type.emoji} ${type.label}'));
    }
    if (post.isListing) {
      rows.add(_detailRow('Status', post.isOpen ? 'Available' : 'Closed'));
    }
    if (locationLabel.isNotEmpty) {
      rows.add(_detailRow('Location', locationLabel));
    }
    if (post.swapFor != null && post.swapFor!.trim().isNotEmpty) {
      rows.add(_detailRow('Looking to swap for', post.swapFor!.trim()));
    }
    rows.add(_detailRow('Posted', timeAgo(post.createdAt)));
    if (post.viewCount > 0) {
      rows.add(_detailRow('Views', '${post.viewCount}'));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            rows[i],
          ],
          if (post.content.trim().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),
            const Text(
              'Description',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            PostContentText(content: post.content, previewWords: null),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool highlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.text : AppColors.text,
              fontSize: highlight ? 22 : 14,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sellerCard(AppState app, MouthUpPost post, SocialProfile? profile, bool isAuthor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => openUserProfile(context, app, post.author),
            child: UserAvatar(
              name: post.displayAuthor,
              imageUrl: app.avatarForUser(post.author, displayName: post.displayAuthor),
              verified: post.authorIsVerified || (profile?.verified ?? false),
              radius: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seller', style: TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => openUserProfile(context, app, post.author),
                  child: UsernameWithBadge(
                    username: post.displayAuthor,
                    verified: post.authorIsVerified || (profile?.verified ?? false),
                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          if (!isAuthor)
            IconButton(
              onPressed: () => openUserProfile(context, app, post.author),
              icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _quickActions(AppState app, MouthUpPost post) {
    return Row(
      children: [
        _pillAction(
          icon: post.userLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: post.likeCount > 0 ? '${post.likeCount}' : 'Like',
          active: post.userLiked,
          onTap: () => app.toggleLikePost(post.id),
        ),
        const SizedBox(width: 8),
        _pillAction(
          icon: post.userSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          label: post.userSaved ? 'Saved' : 'Save',
          active: post.userSaved,
          onTap: () async {
            final was = post.userSaved;
            await app.toggleSavePost(post.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(was ? 'Removed from saved' : 'Saved')));
          },
        ),
        const SizedBox(width: 8),
        _pillAction(icon: Icons.share_outlined, label: 'Share', onTap: () => sharePost(context, post)),
      ],
    );
  }

  Widget _pillAction({required IconData icon, required String label, required VoidCallback onTap, bool active = false}) {
    return Expanded(
      child: Material(
        color: active ? AppColors.bgElevated : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: active ? AppColors.text : AppColors.textMuted),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: active ? AppColors.text : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _discussionHeader(int count) {
    return Row(
      children: [
        const Text('Questions & replies', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
          child: Text('$count', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _emptyComments() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: const Column(
          children: [
            Icon(Icons.forum_outlined, size: 32, color: AppColors.textDim),
            SizedBox(height: 8),
            Text('No questions yet', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Ask about price, condition, or pickup', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _commentTile(BuildContext context, AppState app, PostComment c) {
    final canOpen = app.canViewProfile(c.author);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(name: c.author, imageUrl: app.avatarForUser(c.author), radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: canOpen ? () => openUserProfile(context, app, c.author) : null,
                          child: Text(c.author, style: TextStyle(color: canOpen ? AppColors.text : AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      Text(timeAgo(c.createdAt), style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(c.text, style: const TextStyle(color: AppColors.text, fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(AppState app, MouthUpPost post, bool isAuthor) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              UserAvatar(name: app.displayName, imageUrl: app.profileAvatarUrl ?? app.avatarForUser(app.nickname, displayName: app.displayName), radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ask a question…',
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _submitComment(app),
                ),
              ),
            ],
          ),
          if (!isAuthor && app.canDm(post.author)) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => openDirectChat(context, app, post.author, postId: post.id),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(chatShortLabelForPost(post)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
