import '../constants/moods.dart';
import 'chat_message.dart';

class ChatRoomSession {
  ChatRoomSession({
    required this.postId,
    this.timeLeftSeconds = 15 * 60,
    List<ChatMessage>? messages,
    this.safetyNoticeShown = false,
  }) : messages = messages ?? List.from(mockMessages);

  final String postId;
  int timeLeftSeconds;
  List<ChatMessage> messages;
  bool safetyNoticeShown;

  void addMessage(ChatMessage msg) => messages.add(msg);

  void extendMinutes(int minutes) {
    timeLeftSeconds += minutes * 60;
  }
}

/// Demo room when joining via quick match (no post).
const demoRoomPostId = 'demo-room';

String moodRoomId(MoodId mood) => 'mood-${mood.name}';

bool isMoodRoomId(String roomId) => roomId.startsWith('mood-');

MoodId? moodIdFromRoom(String roomId) {
  if (!isMoodRoomId(roomId)) return null;
  final name = roomId.substring(5);
  for (final mood in MoodId.values) {
    if (mood.name == name) return mood;
  }
  return null;
}

List<ChatMessage> moodRoomSeedMessages(MoodId mood) {
  final label = moodById(mood).label;
  return [
    ChatMessage(id: 'm0', nickname: 'MouthUp', text: 'Welcome to the $label room — anonymous & 15 min ⏱', isSystem: true),
    ChatMessage(id: 'm1', nickname: 'SilentOwl', text: 'Glad I found people feeling the same right now'),
    ChatMessage(id: 'm2', nickname: 'NightWalker', text: '🫂 Same $label mood tonight', type: ChatMessageType.emoji),
  ];
}
