import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/hashtags.dart';
import '../utils/post_text.dart';

/// Post body with optional word preview and "Read more" expand.
class PostContentText extends StatefulWidget {
  const PostContentText({
    super.key,
    required this.content,
    this.previewWords,
    this.onHashtagTap,
  });

  final String content;
  final int? previewWords;
  final void Function(String hashtag)? onHashtagTap;

  @override
  State<PostContentText> createState() => _PostContentTextState();
}

class _PostContentTextState extends State<PostContentText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final preview = widget.previewWords;
    final showToggle = preview != null && !_expanded && shouldShowReadMore(widget.content, preview);
    final displayText = showToggle ? truncateToWords(widget.content, preview) : widget.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildHashtagText(displayText, onHashtagTap: widget.onHashtagTap),
        if (showToggle)
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Read more',
                style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
