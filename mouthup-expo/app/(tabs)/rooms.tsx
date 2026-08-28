import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenWrapper } from '../../components/ScreenWrapper';
import { PrimaryButton } from '../../components/PrimaryButton';
import { useApp } from '../../context/AppContext';
import { MOODS, POLL_OPTIONS } from '../../constants/moods';
import { colors, typography, spacing, radius } from '../../constants/theme';

const ACTIVE_ROOMS = [
  { mood: '😔 Low', topic: 'Work stress', members: 5, timeLeft: '11 min' },
  { mood: '😰 Anxious', topic: 'Exam pressure', members: 4, timeLeft: '8 min' },
  { mood: '😤 Angry', topic: 'Family issue', members: 3, timeLeft: '14 min' },
];

export default function RoomsScreen() {
  const router = useRouter();
  const { selectedMood, pollVote } = useApp();
  const mood = MOODS.find((m) => m.id === selectedMood);
  const vote = pollVote !== null ? POLL_OPTIONS[pollVote] : null;

  return (
    <ScreenWrapper>
      <ScrollView showsVerticalScrollIndicator={false}>
        <Text style={styles.title}>Rooms</Text>
        <Text style={styles.sub}>Same feel wale log — 15 min anonymous chat</Text>

        {mood && vote && (
          <View style={styles.yourRoom}>
            <Text style={styles.yourLabel}>Tumhara match</Text>
            <Text style={styles.yourMatch}>
              {mood.emoji} {mood.labelHi} + {vote.label}
            </Text>
            <PrimaryButton
              title="Connect abhi →"
              onPress={() => router.push('/room-match')}
              style={{ marginTop: 12 }}
            />
          </View>
        )}

        <Text style={styles.sectionTitle}>Active rooms — Delhi</Text>
        {ACTIVE_ROOMS.map((room, i) => (
          <View key={i} style={styles.roomCard}>
            <View style={styles.roomLeft}>
              <Text style={styles.roomMood}>{room.mood}</Text>
              <Text style={styles.roomTopic}>{room.topic}</Text>
              <View style={styles.roomMeta}>
                <Ionicons name="people" size={14} color={colors.textMuted} />
                <Text style={styles.roomMetaText}>{room.members} log</Text>
                <Text style={styles.roomDot}>•</Text>
                <Text style={styles.roomMetaText}>{room.timeLeft} left</Text>
              </View>
            </View>
            <View style={styles.joinBadge}>
              <Text style={styles.joinText}>FULL</Text>
            </View>
          </View>
        ))}

        <View style={styles.emptyHint}>
          <Ionicons name="information-circle-outline" size={20} color={colors.textDim} />
          <Text style={styles.emptyText}>
            Pehle Pulse me mood select karo, phir Vote karo — tab match milega
          </Text>
        </View>
      </ScrollView>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  title: { ...typography.title, color: colors.text, marginTop: spacing.sm },
  sub: { ...typography.body, color: colors.textMuted, marginBottom: spacing.lg },
  yourRoom: {
    backgroundColor: colors.primarySoft,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.primary,
    padding: 16,
    marginBottom: spacing.xl,
  },
  yourLabel: { ...typography.label, color: colors.primary },
  yourMatch: { ...typography.subtitle, color: colors.text, marginTop: 4 },
  sectionTitle: { ...typography.subtitle, fontSize: 16, color: colors.text, marginBottom: 12 },
  roomCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.bgCard,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 16,
    marginBottom: 10,
  },
  roomLeft: { flex: 1 },
  roomMood: { ...typography.subtitle, fontSize: 15, color: colors.text },
  roomTopic: { ...typography.caption, color: colors.textMuted, marginTop: 2 },
  roomMeta: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 8 },
  roomMetaText: { ...typography.caption, color: colors.textMuted, fontSize: 12 },
  roomDot: { color: colors.textDim },
  joinBadge: {
    backgroundColor: colors.bgElevated,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
  },
  joinText: { ...typography.label, color: colors.textDim, fontSize: 10 },
  emptyHint: {
    flexDirection: 'row',
    gap: 10,
    marginTop: spacing.lg,
    padding: 14,
    backgroundColor: colors.bgCard,
    borderRadius: radius.md,
  },
  emptyText: { ...typography.caption, color: colors.textDim, flex: 1, lineHeight: 18 },
});
