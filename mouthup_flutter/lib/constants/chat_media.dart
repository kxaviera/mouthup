class ChatGif {
  const ChatGif({required this.id, required this.url, required this.label});

  final String id;
  final String url;
  final String label;
}

class ChatSticker {
  const ChatSticker({
    required this.id,
    required this.label,
    this.emoji,
    this.imageUrl,
  });

  final String id;
  final String label;
  final String? emoji;
  final String? imageUrl;

  bool get isEmoji => emoji != null;
}

const chatGifs = [
  ChatGif(id: 'g1', url: 'https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif', label: 'Thumbs up'),
  ChatGif(id: 'g2', url: 'https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif', label: 'Hug'),
  ChatGif(id: 'g3', url: 'https://media.giphy.com/media/26BRuo6sKon-oQyBU/giphy.gif', label: 'Heart'),
  ChatGif(id: 'g4', url: 'https://media.giphy.com/media/3o6Zt481isNVkb8iyQ/giphy.gif', label: 'Clap'),
  ChatGif(id: 'g5', url: 'https://media.giphy.com/media/13CoXDiaCcCoyq/giphy.gif', label: 'Celebrate'),
  ChatGif(id: 'g6', url: 'https://media.giphy.com/media/26u4cqiYI30juCOGY/giphy.gif', label: 'Laugh'),
  ChatGif(id: 'g7', url: 'https://media.giphy.com/media/26BRv0ThflsHCplus/giphy.gif', label: 'Support'),
  ChatGif(id: 'g8', url: 'https://media.giphy.com/media/l0HlBO7eyX5Xm4hwc/giphy.gif', label: 'Wave'),
];

const chatStickers = [
  ChatSticker(id: 's1', label: 'Heart', emoji: '❤️'),
  ChatSticker(id: 's2', label: 'Hug', emoji: '🤗'),
  ChatSticker(id: 's3', label: 'Strong', emoji: '💪'),
  ChatSticker(id: 's4', label: 'Sparkle', emoji: '✨'),
  ChatSticker(id: 's5', label: 'Rainbow', emoji: '🌈'),
  ChatSticker(id: 's6', label: 'Star', emoji: '⭐'),
  ChatSticker(id: 's7', label: 'Fire', emoji: '🔥'),
  ChatSticker(id: 's8', label: '100', emoji: '💯'),
  ChatSticker(id: 's9', label: 'Party', emoji: '🎉'),
  ChatSticker(id: 's10', label: 'Peace', emoji: '✌️'),
  ChatSticker(id: 's11', label: 'Thinking', emoji: '🤔'),
  ChatSticker(id: 's12', label: 'Cool', emoji: '😎'),
];
