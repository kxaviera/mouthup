import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_text.dart';
import '../../widgets/post_content_text.dart';
import '../../widgets/user_avatar.dart';

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
    this.onHashtagTap,
    this.commentCount,
    this.showDivider = true,
    this.previewWords = PostLimits.feedPreviewWords,
  });

  final MouthUpPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final void Function(String hashtag)? onHashtagTap;
  final int? commentCount;
  final bool showDivider;
  final int? previewWords;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final localImages = app.postImages(post.id);
    final localVideos = app.postVideos(post.id);
    final comments = commentCount ?? app.commentCount(post.id);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onAuthorTap,
                    child: UserAvatar(name: post.author, radius: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onTap: onAuthorTap,
                                child: Text(
                                  post.author,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: onAuthorTap != null ? AppColors.primary : AppColors.text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            Text(' · ${timeAgo(post.createdAt)}', style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        PostContentText(
                          content: post.content,
                          previewWords: previewWords,
                          onHashtagTap: onHashtagTap,
                        ),
                        if (localImages.isNotEmpty || post.imageUrls.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _imageGallery(localImages),
                        ],
                        if (localVideos.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _videoGallery(localVideos),
                        ],
                        const SizedBox(height: 10),
                        _actions(comments),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, thickness: 1, color: AppColors.border),
      ],
    );
  }

  Widget _imageGallery(List<Uint8List> localImages) {
    final urls = post.imageUrls;
    final total = localImages.length + urls.length;
    if (total == 0) return const SizedBox.shrink();

    if (total == 1) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: localImages.isNotEmpty
            ? Image.memory(localImages.first, height: 200, width: double.infinity, fit: BoxFit.cover)
            : Image.network(urls.first, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, e, s) => _imgPlaceholder(height: 200)),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i < localImages.length) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(localImages[i], width: 120, height: 120, fit: BoxFit.cover),
            );
          }
          final url = urls[i - localImages.length];
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(url, width: 120, height: 120, fit: BoxFit.cover, errorBuilder: (_, e, s) => _imgPlaceholder(size: 120)),
          );
        },
      ),
    );
  }

  Widget _videoGallery(List<Uint8List> videos) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline, color: AppColors.primary, size: 36),
              SizedBox(height: 4),
              Text('Video', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(int comments) {
    return Row(
      children: [
        _iconAction(Icons.chat_bubble_outline, '$comments', AppColors.textMuted, onComment ?? onTap),
        const Spacer(),
        _iconAction(
          post.userSaved ? Icons.bookmark : Icons.bookmark_outline,
          '',
          post.userSaved ? AppColors.primary : AppColors.textMuted,
          onSave,
          active: post.userSaved,
        ),
        _iconAction(Icons.share_outlined, '', AppColors.textMuted, onShare),
      ],
    );
  }

  Widget _iconAction(IconData icon, String count, Color color, VoidCallback? onTap, {bool active = false}) {
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
              Text(count, style: TextStyle(color: active ? color : AppColors.textDim, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder({double? size, double? height}) {
    final h = height ?? size ?? 48;
    final w = size ?? double.infinity;
    return Container(
      width: w,
      height: h,
      color: AppColors.bgElevated,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: AppColors.textDim, size: h * 0.35),
    );
  }
}
