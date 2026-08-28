import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onAuthorTap,
    this.onSave,
    this.onShare,
    this.onComment,
    this.commentCount,
    this.showActions = true,
  });

  final MouthUpPost post;
  final VoidCallback? onTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final int? commentCount;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final localImages = app.postImages(post.id);
    final comments = commentCount ?? app.commentCount(post.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(post.content, style: const TextStyle(color: AppColors.text, fontSize: 15, height: 1.4)),
            ),
            if (localImages.isNotEmpty || post.imageUrls.isNotEmpty) _imageGallery(localImages),
            if (showActions) _actions(comments),
          ],
        ),
      ),
    );
  }

  Widget _imageGallery(List<Uint8List> localImages) {
    final urls = post.imageUrls;
    final total = localImages.length + urls.length;
    if (total == 0) return const SizedBox.shrink();

    if (total == 1) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: localImages.isNotEmpty
              ? Image.memory(localImages.first, height: 220, width: double.infinity, fit: BoxFit.cover)
              : Image.network(urls.first, height: 220, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, e, s) => _imgPlaceholder(height: 220)),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        itemCount: total,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
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
            child: Image.network(url, width: 140, height: 140, fit: BoxFit.cover, errorBuilder: (_, e, s) => _imgPlaceholder(size: 140)),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          UserAvatar(name: post.author, radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onAuthorTap,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    post.author,
                    style: TextStyle(
                      color: onAuthorTap != null ? AppColors.primary : AppColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(timeAgo(post.createdAt), style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(int comments) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          _actionBtn(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble_outline,
            label: '$comments',
            active: false,
            color: AppColors.textMuted,
            onTap: onComment ?? onTap,
          ),
          _actionBtn(
            icon: Icons.bookmark_outline,
            activeIcon: Icons.bookmark,
            label: post.userSaved ? 'Saved' : 'Save',
            active: post.userSaved,
            color: AppColors.primary,
            onTap: onSave,
          ),
          _actionBtn(
            icon: Icons.share_outlined,
            activeIcon: Icons.share_outlined,
            label: 'Share',
            active: false,
            color: AppColors.textMuted,
            onTap: onShare,
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool active,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(active ? activeIcon : icon, size: 20, color: active ? color : AppColors.textDim),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: active ? color : AppColors.textDim, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
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
