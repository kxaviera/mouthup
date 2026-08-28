import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.nickname,
    required this.message,
    this.isMe = false,
    this.onNicknameTap,
  });

  final String nickname;
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onNicknameTap;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem || message.type == ChatMessageType.system) {
      return _systemBubble();
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: GestureDetector(
                  onTap: onNicknameTap,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    nickname,
                    style: TextStyle(
                      color: onNicknameTap != null ? AppColors.primary : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            _content(context),
          ],
        ),
      ),
    );
  }

  Widget _systemBubble() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.danger, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.text,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.gif:
        return _mediaBubble(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              message.mediaUrl!,
              width: 160,
              height: 120,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  width: 160,
                  height: 120,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDim)),
                );
              },
              errorBuilder: (_, e, s) => const SizedBox(
                width: 160,
                height: 80,
                child: Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textDim)),
              ),
            ),
          ),
        );
      case ChatMessageType.sticker:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(message.text, style: const TextStyle(fontSize: 56)),
        );
      case ChatMessageType.emoji:
        return _textBubble(fontSize: 32, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
      case ChatMessageType.text:
      case ChatMessageType.system:
        return _textBubble();
    }
  }

  Widget _textBubble({double fontSize = 15, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.bgElevated,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        message.text,
        style: TextStyle(color: isMe ? AppColors.onPrimary : AppColors.text, fontSize: fontSize),
      ),
    );
  }

  Widget _mediaBubble({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: child,
    );
  }
}
