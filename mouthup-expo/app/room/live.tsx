import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenWrapper } from '../../components/ScreenWrapper';
import { ChatBubble } from '../../components/ChatBubble';
import { useApp } from '../../context/AppContext';
import { MOODS, POLL_OPTIONS, MOCK_MESSAGES } from '../../constants/moods';
import { colors, typography, spacing, radius } from '../../constants/theme';

export default function LiveRoomScreen() {
  const router = useRouter();
  const { nickname, selectedMood, pollVote } = useApp();
  const mood = MOODS.find((m) => m.id === selectedMood);
  const vote = pollVote !== null ? POLL_OPTIONS[pollVote] : null;
  const [timeLeft, setTimeLeft] = useState(14 * 60 + 22);
  const [message, setMessage] = useState('');
  const [messages, setMessages] = useState(MOCK_MESSAGES);
  const scrollRef = useRef<ScrollView>(null);

  useEffect(() => {
    const interval = setInterval(() => {
      setTimeLeft((t) => {
        if (t <= 1) {
          clearInterval(interval);
          router.replace('/room/close');
          return 0;
        }
        return t - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const mins = Math.floor(timeLeft / 60);
  const secs = timeLeft % 60;
  const timerStr = `${mins}:${secs.toString().padStart(2, '0')}`;

  const sendMessage = () => {
    if (!message.trim()) return;
    setMessages((prev) => [
      ...prev,
      { id: Date.now().toString(), nickname, text: message.trim(), isMe: true },
    ]);
    setMessage('');
    setTimeout(() => scrollRef.current?.scrollToEnd({ animated: true }), 100);
  };

  return (
    <ScreenWrapper padded={false}>
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <Text style={styles.timer}>⏱ {timerStr}</Text>
          <Text style={styles.roomTag}>
            {mood?.emoji} {mood?.labelHi} • {vote?.label}
          </Text>
        </View>
        <TouchableOpacity onPress={() => router.replace('/room/close')} style={styles.exitBtn}>
          <Text style={styles.exitText}>Exit</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.members}>
        {['🦉', '🌊', '🌙', '⭐', '🔥'].map((e, i) => (
          <View key={i} style={styles.memberDot}>
            <Text style={styles.memberEmoji}>{e}</Text>
          </View>
        ))}
        <Text style={styles.memberCount}>5 log room me</Text>
      </View>

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={90}
      >
        <ScrollView
          ref={scrollRef}
          style={styles.messages}
          contentContainerStyle={styles.messagesContent}
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.systemMsg}>
            <Text style={styles.systemText}>
              Room shuru hua. Anonymous chat — 15 min me band ho jayega.
            </Text>
          </View>
          {messages.map((msg) => (
            <ChatBubble
              key={msg.id}
              nickname={msg.nickname}
              text={msg.text}
              isMe={msg.isMe}
            />
          ))}
        </ScrollView>

        <View style={styles.inputRow}>
          <TouchableOpacity style={styles.iconBtn}>
            <Ionicons name="flag-outline" size={20} color={colors.danger} />
          </TouchableOpacity>
          <TextInput
            style={styles.input}
            placeholder="Message likho..."
            placeholderTextColor={colors.textDim}
            value={message}
            onChangeText={setMessage}
            onSubmitEditing={sendMessage}
          />
          <TouchableOpacity onPress={sendMessage} style={styles.sendBtn}>
            <Ionicons name="send" size={20} color="#fff" />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingHorizontal: 20,
    paddingTop: spacing.sm,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  headerLeft: { flex: 1 },
  timer: { ...typography.subtitle, color: colors.accent, fontWeight: '700' },
  roomTag: { ...typography.caption, color: colors.textMuted, marginTop: 4 },
  exitBtn: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
  exitText: { ...typography.caption, color: colors.textMuted },
  members: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 10,
    gap: 4,
  },
  memberDot: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: colors.bgElevated,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: -4,
    borderWidth: 2,
    borderColor: colors.bg,
  },
  memberEmoji: { fontSize: 14 },
  memberCount: { ...typography.caption, color: colors.textDim, marginLeft: 12 },
  messages: { flex: 1 },
  messagesContent: { paddingHorizontal: 20, paddingVertical: 12 },
  systemMsg: {
    alignSelf: 'center',
    backgroundColor: colors.bgElevated,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: radius.full,
    marginBottom: 16,
  },
  systemText: { ...typography.caption, color: colors.textDim, fontSize: 12 },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    gap: 8,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    backgroundColor: colors.bgCard,
  },
  iconBtn: { padding: 8 },
  input: {
    flex: 1,
    backgroundColor: colors.bgElevated,
    borderRadius: radius.full,
    paddingHorizontal: 16,
    paddingVertical: 10,
    color: colors.text,
    ...typography.body,
    fontSize: 15,
  },
  sendBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
