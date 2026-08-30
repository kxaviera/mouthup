import 'dart:ui' show Color;

import '../models/chat_message.dart';

enum MoodId { anxious, low, angry, good, confused, excited }

class Mood {
  const Mood({
    required this.id,
    required this.emoji,
    required this.label,
    required this.labelHi,
    required this.color,
  });

  final MoodId id;
  final String emoji;
  final String label;
  final String labelHi;
  final Color color;
}

const moods = [
  Mood(id: MoodId.anxious, emoji: '😰', label: 'Anxious', labelHi: 'Anxious', color: Color(0xFFCCCCCC)),
  Mood(id: MoodId.low, emoji: '😔', label: 'Sad', labelHi: 'Sad', color: Color(0xFFAAAAAA)),
  Mood(id: MoodId.angry, emoji: '😤', label: 'Angry', labelHi: 'Angry', color: Color(0xFF888888)),
  Mood(id: MoodId.good, emoji: '😊', label: 'Happy', labelHi: 'Happy', color: Color(0xFFFFFFFF)),
  Mood(id: MoodId.confused, emoji: '😐', label: 'Bored', labelHi: 'Bored', color: Color(0xFF777777)),
  Mood(id: MoodId.excited, emoji: '🔥', label: 'Excited', labelHi: 'Excited', color: Color(0xFFDDDDDD)),
];

/// Tap a tag on feed to filter posts by mood category.
class MoodTag {
  const MoodTag({required this.id, required this.label, this.moodId});
  final String id;
  final String label;
  final MoodId? moodId;
}

const moodTags = [
  MoodTag(id: 'all', label: 'All'),
  MoodTag(id: 'sad', label: 'Sad', moodId: MoodId.low),
  MoodTag(id: 'bored', label: 'Bored', moodId: MoodId.confused),
  MoodTag(id: 'anxious', label: 'Anxious', moodId: MoodId.anxious),
  MoodTag(id: 'angry', label: 'Angry', moodId: MoodId.angry),
  MoodTag(id: 'happy', label: 'Happy', moodId: MoodId.good),
  MoodTag(id: 'excited', label: 'Excited', moodId: MoodId.excited),
];

class PollOptionData {
  const PollOptionData({required this.id, required this.label, required this.percent});
  final int id;
  final String label;
  final int percent;
}

const pollOptions = [
  PollOptionData(id: 0, label: 'Work / Career', percent: 34),
  PollOptionData(id: 1, label: 'Relationship', percent: 22),
  PollOptionData(id: 2, label: 'Health', percent: 18),
  PollOptionData(id: 3, label: 'Money', percent: 16),
  PollOptionData(id: 4, label: 'Not sure', percent: 10),
];

const livePulse = [
  (MoodId.low, 41),
  (MoodId.anxious, 28),
  (MoodId.good, 15),
  (MoodId.confused, 9),
  (MoodId.angry, 4),
  (MoodId.excited, 3),
];

Mood moodById(MoodId id) => moods.firstWhere((m) => m.id == id);

String moodToApi(MoodId id) {
  switch (id) {
    case MoodId.anxious:
      return 'ANXIOUS';
    case MoodId.low:
      return 'LOW';
    case MoodId.angry:
      return 'ANGRY';
    case MoodId.good:
      return 'GOOD';
    case MoodId.confused:
      return 'CONFUSED';
    case MoodId.excited:
      return 'EXCITED';
  }
}

MoodId? moodIdFromApi(String? value) {
  switch (value?.toUpperCase()) {
    case 'ANXIOUS':
      return MoodId.anxious;
    case 'LOW':
      return MoodId.low;
    case 'ANGRY':
      return MoodId.angry;
    case 'GOOD':
      return MoodId.good;
    case 'CONFUSED':
      return MoodId.confused;
    case 'EXCITED':
      return MoodId.excited;
    default:
      return null;
  }
}

const nicknames = ['CoolBreeze47', 'SilentOwl', 'NightWalker', 'CalmRiver', 'StarGazer22'];
