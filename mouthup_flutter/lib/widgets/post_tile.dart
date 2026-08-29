import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_text.dart';
import '../../utils/youtube.dart';
import '../../widgets/post_content_text.dart';
import '../../widgets/post_translate_link.dart';
import '../../widgets/post_video_player.dart';
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

  bool get _hasMedia =>
      post.imageUrls.isNotEmpty || post.videoUrls.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final localImages = app.postImages(post.id);
    final localVideos = app.postVideos(post.id);
    final comments = commentCount ?? app.commentCount(post.id);
    final hasMedia = _hasMedia || localImages.isNotEmpty || localVideos.isNotEmpty;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, hasMedia ? 12 : 14, 16, 12),
              child: hasMedia ? _mediaFirstLayout(context, localImages, localVideos, comments) : _textLayout(localImages, localVideos, comments),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, thickness: 1, color: AppColors.border),
      ],
    );
  }

  Widget _textLayout(List<Uint8List> localImages, List<Uint8List> localVideos, int comments) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _authorAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _authorRow(),
              const SizedBox(height: 4),
              _bodyText(),
              PostTranslateLink(content: post.content),
              if (localImages.isNotEmpty || post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                _imageGallery(localImages, height: 200),
              ],
              if (localVideos.isNotEmpty || post.videoUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                _videoGallery(localVideos),
              ],
              const SizedBox(height: 10),
              _actions(comments),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mediaFirstLayout(
    BuildContext context,
    List<Uint8List> localImages,
    List<Uint8List> localVideos,
    int comments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _authorAvatar(),
            const SizedBox(width: 12),
            Expanded(child: _authorRow()),
            if (_topicTag() != null) _topicChip(_topicTag()!),
          ],
        ),
        const SizedBox(height: 12),
        if (post.videoUrls.isNotEmpty || localVideos.isNotEmpty)
          _videoGallery(localVideos, height: 240)
        else
          _imageGallery(localImages, height: 240),
        if ((post.videoUrls.isNotEmpty || localVideos.isNotEmpty) &&
            (post.imageUrls.isNotEmpty || localImages.isNotEmpty)) ...[
          const SizedBox(height: 8),
          _imageGallery(localImages, height: 140),
        ],
        const SizedBox(height: 10),
        _bodyText(previewWords: 35),
        PostTranslateLink(content: post.content),
        const SizedBox(height: 10),
        _actions(comments),
      ],
    );
  }

  String? _topicTag() {
    for (final tag in post.hashtags) {
      if (tag == 'latest') continue;
      if (RegExp(r'^\d').hasMatch(tag)) continue;
      return '#$tag';
    }
    return post.hashtags.isNotEmpty ? '#${post.hashtags.first}' : null;
  }

  Widget _topicChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(tag, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _authorAvatar() {
    return GestureDetector(onTap: onAuthorTap, child: UserAvatar(name: post.author, radius: 20));
  }

  Widget _authorRow() {
    return Row(
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
    );
  }

  Widget _bodyText({int? previewWords}) {
    return PostContentText(
      content: post.content,
      previewWords: previewWords ?? this.previewWords,
      onHashtagTap: onHashtagTap,
    );
  }

  Widget _imageGallery(List<Uint8List> localImages, {double height = 200}) {
    final urls = post.imageUrls;
    final total = localImages.length + urls.length;
    if (total == 0) return const SizedBox.shrink();

    if (total == 1) {
      final url = urls.isNotEmpty ? urls.first : null;
      final ytId = url != null ? youtubeVideoId(url) : null;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: height,
                width: double.infinity,
                child: localImages.isNotEmpty
                    ? Image.memory(localImages.first, fit: BoxFit.cover)
                    : _networkImage(url!, height: height),
              ),
              if (ytId != null || (url != null && isYoutubeThumbnailUrl(url)))
                Container(
                  color: Colors.black26,
                  child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
                ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height.clamp(120, 160),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i < localImages.length) {
            return _framedImage(
              child: Image.memory(localImages[i], width: height, height: height, fit: BoxFit.cover),
              size: height,
            );
          }
          final url = urls[i - localImages.length];
          return _framedImage(
            child: _networkImage(url, height: height, width: height),
            size: height,
          );
        },
      ),
    );
  }

  Widget _framedImage({required Widget child, required double size}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _networkImage(String url, {required double height, double? width}) {
    return Image.network(
      url,
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          width: width ?? double.infinity,
          color: AppColors.bgElevated,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        );
      },
      errorBuilder: (_, e, s) => _imgPlaceholder(height: height, size: width),
    );
  }

  Widget _videoGallery(List<Uint8List> localVideos, {double height = 220}) {
    final urls = post.videoUrls;
    final total = localVideos.length + urls.length;
    if (total == 0) return const SizedBox.shrink();

    if (total == 1 && urls.length == 1 && localVideos.isEmpty) {
      return PostVideoPlayer(url: urls.first, height: height);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < localVideos.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _localVideoPlaceholder(height: height * 0.7),
        ],
        for (var i = 0; i < urls.length; i++) ...[
          if (localVideos.isNotEmpty || i > 0) const SizedBox(height: 8),
          PostVideoPlayer(url: urls[i], height: height),
        ],
      ],
    );
  }

  Widget _localVideoPlaceholder({double height = 120}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, color: AppColors.primary, size: 40),
          SizedBox(height: 4),
          Text('Video', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
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
