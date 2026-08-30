import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_label.dart';
import '../../utils/display_name.dart';
import '../../utils/geo.dart';
import '../../widgets/post_video_player.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';

/// Feed-style post card: author, location, title, media, actions.
/// Price and full description live on [PostDetailScreen].
class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.post,
    this.onTap,
    this.onLongPress,
    this.onAuthorTap,
    this.onSave,
    this.onShare,
    this.onComment,
    this.onLike,
    this.onChat,
    this.showDivider = true,
    this.authorAvatarUrl,
    this.authorVerified = false,
    this.embedded = false,
  });

  final MouthUpPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onLike;
  final VoidCallback? onChat;
  final bool showDivider;
  final String? authorAvatarUrl;
  final bool authorVerified;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final localImages = app.postImages(post.id);
    final localVideos = app.postVideos(post.id);
    final comments = app.commentCount(post.id);
    final hasMedia = post.imageUrls.isNotEmpty || post.videoUrls.isNotEmpty || localImages.isNotEmpty || localVideos.isNotEmpty;
    final locationLabel = formatPostLocationLabel(
      location: post.location,
      authorCity: post.authorCity,
      distanceKm: post.distanceKm,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(embedded ? 0 : 16, embedded ? 0 : 12, embedded ? 0 : 16, 0),
          child: _AuthorHeader(
            post: post,
            locationLabel: locationLabel,
            authorAvatarUrl: authorAvatarUrl,
            authorVerified: authorVerified,
            onAuthorTap: onAuthorTap,
          ),
        ),
        if (post.title != null && post.title!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: embedded ? 0 : 16),
            child: _TitleRow(post: post),
          ),
        ] else if (post.isListing || post.viewCount > 0) ...[
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: embedded ? 0 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.isListing) Expanded(child: _ListingChips(post: post, compact: true)),
                if (!post.isListing && post.viewCount > 0) const Spacer(),
                if (post.viewCount > 0 && (post.title == null || post.title!.trim().isEmpty))
                  _ViewCountBadge(count: post.viewCount),
              ],
            ),
          ),
        ],
        if (hasMedia) ...[
          const SizedBox(height: 10),
          _FeedMedia(
            post: post,
            localImages: localImages,
            localVideos: localVideos,
            onTap: onTap,
          ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(embedded ? 0 : 12, 8, embedded ? 0 : 12, embedded ? 0 : 4),
          child: _ActionBar(
            post: post,
            comments: comments,
            onLike: onLike,
            onComment: onComment ?? onTap,
            onSave: onSave,
            onShare: onShare,
            onChat: onChat,
          ),
        ),
        if (showDivider && !embedded)
          const Divider(height: 1, thickness: 1, color: AppColors.border),
      ],
    );

    if (embedded) return content;

    return Material(
      color: AppColors.bg,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      ),
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({
    required this.post,
    required this.locationLabel,
    this.authorAvatarUrl,
    this.authorVerified = false,
    this.onAuthorTap,
  });

  final MouthUpPost post;
  final String locationLabel;
  final String? authorAvatarUrl;
  final bool authorVerified;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onAuthorTap,
          child: UserAvatar(name: post.displayAuthor, imageUrl: authorAvatarUrl, verified: authorVerified, radius: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onAuthorTap,
                      child: UsernameWithBadge(
                        username: post.displayAuthor,
                        verified: authorVerified,
                        style: TextStyle(
                          color: onAuthorTap != null ? AppColors.primary : AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  Text(timeAgo(post.createdAt), style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                ],
              ),
              if (post.displayAuthor != post.author) ...[
                const SizedBox(height: 1),
                Text(usernameHandle(post.author), style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              ],
              if (locationLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.post});

  final MouthUpPost post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                post.title!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
              ),
            ),
            if (post.viewCount > 0) ...[
              const SizedBox(width: 10),
              _ViewCountBadge(count: post.viewCount),
            ],
          ],
        ),
        if (post.isListing) ...[
          const SizedBox(height: 8),
          _ListingChips(post: post, compact: true),
        ],
      ],
    );
  }
}

class _ViewCountBadge extends StatelessWidget {
  const _ViewCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.visibility_outlined, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ListingChips extends StatelessWidget {
  const _ListingChips({required this.post, this.compact = false});

  final MouthUpPost post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final type = post.listingTypeOption;
    final isClosed = !post.isOpen;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (type != null)
          _chip('${type.emoji} ${type.label}', AppColors.bgElevated, AppColors.text),
        if (isClosed) _chip('Closed', AppColors.bgElevated, AppColors.textMuted),
        if (!isClosed && post.isListing) _chip('Available', const Color(0xFF1A2E1A), const Color(0xFF7DCE7D)),
      ],
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _FeedMedia extends StatefulWidget {
  const _FeedMedia({
    required this.post,
    required this.localImages,
    required this.localVideos,
    this.onTap,
  });

  final MouthUpPost post;
  final List<Uint8List> localImages;
  final List<Uint8List> localVideos;
  final VoidCallback? onTap;

  @override
  State<_FeedMedia> createState() => _FeedMediaState();
}

class _FeedMediaState extends State<_FeedMedia> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.post.videoUrls.isNotEmpty || widget.localVideos.isNotEmpty;
    if (hasVideo) {
      final url = widget.post.videoUrls.isNotEmpty ? widget.post.videoUrls.first : null;
      final mediaHeight = MediaQuery.sizeOf(context).width * 5 / 4;
      return url != null
          ? PostVideoPlayer(url: url, height: mediaHeight, edgeToEdge: true)
          : SizedBox(
              height: mediaHeight,
              child: Container(
                color: AppColors.bgElevated,
                alignment: Alignment.center,
                child: const Icon(Icons.videocam_outlined, size: 48, color: AppColors.textDim),
              ),
            );
    }

    final urls = widget.post.imageUrls;
    final total = widget.localImages.length + urls.length;
    if (total == 0) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: total,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              if (i < widget.localImages.length) {
                return Image.memory(
                  widget.localImages[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                );
              }
              return _networkImage(urls[i - widget.localImages.length]);
            },
          ),
          if (total > 1)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_page + 1}/$total',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (total > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: active ? 16 : 6,
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
      ),
    );
  }

  Widget _networkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, e, s) => Container(
        color: AppColors.bgElevated,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: AppColors.textDim, size: 40),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.post,
    required this.comments,
    this.onLike,
    this.onComment,
    this.onSave,
    this.onShare,
    this.onChat,
  });

  final MouthUpPost post;
  final int comments;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _action(
          post.userLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          post.likeCount > 0 ? '${post.likeCount}' : null,
          post.userLiked ? const Color(0xFFFF4458) : AppColors.text,
          onLike,
        ),
        const SizedBox(width: 4),
        _action(Icons.chat_bubble_outline_rounded, comments > 0 ? '$comments' : null, AppColors.text, onComment),
        const Spacer(),
        if (onChat != null) ...[
          _messageButton(onChat!),
          const SizedBox(width: 6),
        ],
        _action(
          post.userSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          null,
          post.userSaved ? AppColors.primary : AppColors.text,
          onSave,
        ),
        const SizedBox(width: 4),
        _action(Icons.share_outlined, null, AppColors.text, onShare),
      ],
    );
  }

  Widget _action(IconData icon, String? count, Color color, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              if (count != null) ...[
                const SizedBox(width: 4),
                Text(count, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageButton(VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.black),
                const SizedBox(width: 5),
                Text(
                  chatShortLabelForPost(post),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black, height: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
