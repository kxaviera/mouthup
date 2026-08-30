import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_label.dart';
import '../../utils/post_text.dart';
import '../../utils/display_name.dart';
import '../../utils/profile_labels.dart';
import '../../widgets/post_content_text.dart';
import '../../widgets/post_video_player.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';

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
    this.onHashtagTap,
    this.commentCount,
    this.showDivider = true,
    this.previewWords = PostLimits.feedPreviewWords,
    this.authorAvatarUrl,
    this.authorVerified = false,
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
  final void Function(String hashtag)? onHashtagTap;
  final int? commentCount;
  final bool showDivider;
  final int? previewWords;
  final String? authorAvatarUrl;
  final bool authorVerified;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final localImages = app.postImages(post.id);
    final localVideos = app.postVideos(post.id);
    final comments = commentCount ?? app.commentCount(post.id);
    final hasMedia = post.imageUrls.isNotEmpty || post.videoUrls.isNotEmpty || localImages.isNotEmpty || localVideos.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Material(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (post.isListing) _listingHeader(context),
                    if (post.isListing) const SizedBox(height: 12),
                    _authorSection(),
                    if (post.title != null && post.title!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        post.title!,
                        style: const TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700, height: 1.25),
                      ),
                    ],
                    if (post.priceLabel != null || post.location != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (post.priceLabel != null)
                            Text(
                              post.priceLabel!,
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          if (post.priceLabel != null && post.location != null)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('·', style: TextStyle(color: AppColors.textDim)),
                            ),
                          if (post.location != null)
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      post.location!,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (hasMedia) ...[
                      const SizedBox(height: 12),
                      if (post.videoUrls.isNotEmpty || localVideos.isNotEmpty)
                        _videoGallery(localVideos)
                      else
                        _imageGallery(localImages),
                    ],
                    const SizedBox(height: 10),
                    _bodyText(),
                    const SizedBox(height: 12),
                    _actions(comments),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider) const SizedBox(height: 12),
      ],
    );
  }

  Widget _listingHeader(BuildContext context) {
    final type = post.listingTypeOption;
    if (type == null) return const SizedBox.shrink();

    final isClosed = !post.isOpen;
    final app = context.read<AppState>();
    final isAuthor = app.isPostAuthor(post.id);

    Widget statusChip() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isClosed ? AppColors.bgElevated : const Color(0xFF1A2E1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isClosed ? AppColors.border : const Color(0xFF2D4A2D)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isClosed ? 'Closed' : 'Open',
              style: TextStyle(
                color: isClosed ? AppColors.textMuted : const Color(0xFF7DCE7D),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isAuthor) ...[
              const SizedBox(width: 4),
              Icon(Icons.swap_horiz, size: 14, color: isClosed ? AppColors.textDim : const Color(0xFF7DCE7D)),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${type.emoji} ${type.label}',
            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        if (isAuthor)
          GestureDetector(
            onTap: () async {
              final error = await app.toggleListingStatus(post.id);
              if (!context.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              final nowOpen = !isClosed;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(nowOpen ? 'Listing marked as open' : 'Listing marked as closed')),
              );
            },
            child: statusChip(),
          )
        else
          statusChip(),
      ],
    );
  }

  Widget _authorSection() {
    final subtitle = profileSubtitle(
      accountType: post.authorAccountType,
      profession: post.authorProfession,
      city: post.location != null ? null : post.authorCity,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onAuthorTap,
          child: UserAvatar(name: post.displayAuthor, imageUrl: authorAvatarUrl, verified: authorVerified, radius: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
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
              if (post.displayAuthor != post.author) ...[
                const SizedBox(height: 1),
                Text(
                  usernameHandle(post.author),
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(timeAgo(post.createdAt), style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
      ],
    );
  }

  Widget _bodyText() {
    return PostContentText(
      content: post.content,
      previewWords: previewWords,
      onHashtagTap: onHashtagTap,
    );
  }

  Widget _imageGallery(List<Uint8List> localImages, {double height = 200}) {
    final urls = post.imageUrls;
    final total = localImages.length + urls.length;
    if (total == 0) return const SizedBox.shrink();

    if (total == 1) {
      final url = urls.isNotEmpty ? urls.first : null;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: localImages.isNotEmpty
              ? Image.memory(localImages.first, fit: BoxFit.cover)
              : _networkImage(url!, height: height),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i < localImages.length) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(localImages[i], width: 140, height: 140, fit: BoxFit.cover),
            );
          }
          final url = urls[i - localImages.length];
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _networkImage(url, height: 140, width: 140),
          );
        },
      ),
    );
  }

  Widget _networkImage(String url, {required double height, double? width}) {
    return Image.network(
      url,
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, e, s) => Container(
        height: height,
        width: width ?? double.infinity,
        color: AppColors.bgElevated,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: AppColors.textDim),
      ),
    );
  }

  Widget _videoGallery(List<Uint8List> localVideos, {double height = 200}) {
    final urls = post.videoUrls;
    if (urls.length == 1 && localVideos.isEmpty) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: PostVideoPlayer(url: urls.first, height: height));
    }
    return const SizedBox.shrink();
  }

  Widget _actions(int comments) {
    return Row(
      children: [
        _iconAction(
          post.userLiked ? Icons.favorite : Icons.favorite_border,
          post.likeCount > 0 ? '${post.likeCount}' : '',
          post.userLiked ? const Color(0xFFFF4458) : AppColors.textMuted,
          onLike,
        ),
        _iconAction(Icons.chat_bubble_outline, comments > 0 ? '$comments' : '', AppColors.textMuted, onComment ?? onTap),
        if (post.viewCount > 0)
          _iconAction(Icons.visibility_outlined, '${post.viewCount}', AppColors.textMuted, onTap),
        const Spacer(),
        if (onChat != null) _chatBoxButton(),
        if (onChat != null) const SizedBox(width: 8),
        _iconAction(Icons.bookmark_outline, '', post.userSaved ? AppColors.primary : AppColors.textMuted, onSave),
        _iconAction(Icons.share_outlined, '', AppColors.textMuted, onShare),
      ],
    );
  }

  Widget _chatBoxButton() {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onChat,
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

  Widget _iconAction(IconData icon, String count, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (count.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(count, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
