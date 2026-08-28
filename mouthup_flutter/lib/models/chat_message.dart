enum ChatMessageType { text, emoji, gif, sticker, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.nickname,
    required this.text,
    this.isMe = false,
    this.type = ChatMessageType.text,
    this.mediaUrl,
    this.isSystem = false,
  });

  final String id;
  final String nickname;
  final String text;
  final bool isMe;
  final ChatMessageType type;
  final String? mediaUrl;
  final bool isSystem;

  bool get isMedia => type == ChatMessageType.gif || type == ChatMessageType.sticker;
}
