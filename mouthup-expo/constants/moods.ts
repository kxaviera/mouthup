export type MoodId = 'anxious' | 'low' | 'angry' | 'good' | 'confused' | 'excited';

export interface Mood {
  id: MoodId;
  emoji: string;
  label: string;
  labelHi: string;
  color: string;
}

export const MOODS: Mood[] = [
  { id: 'anxious', emoji: '😰', label: 'Anxious', labelHi: 'Bechain', color: '#818CF8' },
  { id: 'low', emoji: '😔', label: 'Low', labelHi: 'Udaas', color: '#6366F1' },
  { id: 'angry', emoji: '😤', label: 'Angry', labelHi: 'Gussa', color: '#F87171' },
  { id: 'good', emoji: '😊', label: 'Good', labelHi: 'Theek', color: '#34D399' },
  { id: 'confused', emoji: '🤔', label: 'Confused', labelHi: 'Confused', color: '#FBBF24' },
  { id: 'excited', emoji: '🔥', label: 'Excited', labelHi: 'Excited', color: '#FB923C' },
];

export const POLL_OPTIONS = [
  { id: 0, label: 'Work / Career', percent: 34 },
  { id: 1, label: 'Relationship', percent: 22 },
  { id: 2, label: 'Health', percent: 18 },
  { id: 3, label: 'Money', percent: 16 },
  { id: 4, label: 'Pata nahi', percent: 10 },
];

export const LIVE_PULSE = [
  { moodId: 'low' as MoodId, percent: 41 },
  { moodId: 'anxious' as MoodId, percent: 28 },
  { moodId: 'good' as MoodId, percent: 15 },
  { moodId: 'confused' as MoodId, percent: 9 },
  { moodId: 'angry' as MoodId, percent: 4 },
  { moodId: 'excited' as MoodId, percent: 3 },
];

export const MOCK_MESSAGES = [
  { id: '1', nickname: 'SilentOwl', text: 'Same yaar, work pressure bahut hai aaj', isMe: false },
  { id: '2', nickname: 'CoolBreeze47', text: 'Haan boss ne aaj meeting me...', isMe: true },
  { id: '3', nickname: 'NightWalker', text: 'Main bhi same feel kar raha hoon', isMe: false },
  { id: '4', nickname: 'CalmRiver', text: 'Koi baat nahi, hum sab saath hain 💜', isMe: false },
];
