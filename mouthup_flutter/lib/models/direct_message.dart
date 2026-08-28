import 'chat_message.dart';

class DirectMessage {
  const DirectMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.text,
    required this.createdAt,
    this.type = ChatMessageType.text,
    this.mediaUrl,
  });

  final String id;
  final String from;
  final String to;
  final String text;
  final DateTime createdAt;
  final ChatMessageType type;
  final String? mediaUrl;

  bool isFromMe(String myNickname) => from == myNickname;

  factory DirectMessage.fromJson(Map<String, dynamic> json, String peer, String myNickname) {
    final fromMe = json['fromMe'] as bool? ?? false;
    final author = json['author'] as String? ?? peer;
    return DirectMessage(
      id: json['id'] as String,
      from: fromMe ? myNickname : author,
      to: fromMe ? author : myNickname,
      text: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: _parseType(json['type'] as String?),
      mediaUrl: json['mediaUrl'] as String?,
    );
  }

  static ChatMessageType _parseType(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'EMOJI':
        return ChatMessageType.emoji;
      case 'GIF':
        return ChatMessageType.gif;
      case 'STICKER':
        return ChatMessageType.sticker;
      default:
        return ChatMessageType.text;
    }
  }
}

class DmConversation {
  const DmConversation({
    required this.peerNickname,
    required this.lastMessage,
    required this.updatedAt,
    this.unread = 0,
  });

  final String peerNickname;
  final String lastMessage;
  final DateTime updatedAt;
  final int unread;

  factory DmConversation.fromJson(Map<String, dynamic> json) => DmConversation(
        peerNickname: json['peer'] as String,
        lastMessage: json['lastMessage'] as String? ?? '',
        updatedAt: DateTime.parse(json['lastAt'] as String),
        unread: json['unread'] as int? ?? 0,
      );
}

Map<String, List<DirectMessage>> mockDmThreads(String myNickname) {
  final now = DateTime.now();
  return {
    'SilentOwl': [
      DirectMessage(
        id: 'dm1',
        from: 'SilentOwl',
        to: myNickname,
        text: 'Hey, saw your post — same mood here if you wanna talk',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      DirectMessage(
        id: 'dm2',
        from: myNickname,
        to: 'SilentOwl',
        text: 'Yeah for sure, thanks for reaching out',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
      DirectMessage(
        id: 'dm3',
        from: 'SilentOwl',
        to: myNickname,
        text: 'No problem 🫂',
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
    ],
    'NightWalker': [
      DirectMessage(
        id: 'dm4',
        from: 'NightWalker',
        to: myNickname,
        text: 'That exam stress post was relatable',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ],
  };
}
