import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { ScreenWrapper } from '../../components/ScreenWrapper';
import { MOODS } from '../../constants/moods';
import { colors, typography, spacing, radius } from '../../constants/theme';

const WEEK_DATA = [
  { day: 'Mon', mood: '😊', height: 40 },
  { day: 'Tue', mood: '😔', height: 70 },
  { day: 'Wed', mood: '😰', height: 55 },
  { day: 'Thu', mood: '😊', height: 35 },
  { day: 'Fri', mood: '😔', height: 80 },
  { day: 'Sat', mood: '😊', height: 45 },
  { day: 'Sun', mood: '😔', height: 90 },
];

export default function MyMoodScreen() {
  return (
    <ScreenWrapper>
      <ScrollView showsVerticalScrollIndicator={false}>
        <Text style={styles.title}>My Mood</Text>
        <Text style={styles.sub}>Private diary — koi aur nahi dekhega</Text>

        <View style={styles.insightCard}>
          <Text style={styles.insightLabel}>Pattern detected</Text>
          <Text style={styles.insightText}>
            Mostly <Text style={styles.highlight}>Low 😔</Text> on Sunday nights
          </Text>
          <Text style={styles.insightSub}>Work stress linked — 4 of 5 times</Text>
        </View>

        <Text style={styles.sectionTitle}>This week</Text>
        <View style={styles.chart}>
          {WEEK_DATA.map((d) => (
            <View key={d.day} style={styles.barCol}>
              <Text style={styles.barEmoji}>{d.mood}</Text>
              <View style={styles.barTrack}>
                <View
                  style={[
                    styles.barFill,
                    {
                      height: d.height,
                      backgroundColor: d.mood === '😔' ? '#6366F1' : '#34D399',
                    },
                  ]}
                />
              </View>
              <Text style={styles.barDay}>{d.day}</Text>
            </View>
          ))}
        </View>

        <Text style={styles.sectionTitle}>Mood breakdown</Text>
        {MOODS.slice(0, 4).map((m) => (
          <View key={m.id} style={styles.moodRow}>
            <Text style={styles.moodEmoji}>{m.emoji}</Text>
            <Text style={styles.moodName}>{m.labelHi}</Text>
            <View style={styles.moodBarTrack}>
              <View
                style={[
                  styles.moodBarFill,
                  {
                    width: `${m.id === 'low' ? 45 : m.id === 'anxious' ? 25 : m.id === 'good' ? 20 : 10}%`,
                    backgroundColor: m.color,
                  },
                ]}
              />
            </View>
          </View>
        ))}

        <View style={styles.streakBox}>
          <Text style={styles.streakNum}>5 🔥</Text>
          <Text style={styles.streakLabel}>Day mood streak</Text>
        </View>
      </ScrollView>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  title: { ...typography.title, color: colors.text, marginTop: spacing.sm },
  sub: { ...typography.body, color: colors.textMuted, marginBottom: spacing.lg },
  insightCard: {
    backgroundColor: colors.bgCard,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.secondary,
    padding: 16,
    marginBottom: spacing.xl,
  },
  insightLabel: { ...typography.label, color: colors.secondary },
  insightText: { ...typography.subtitle, color: colors.text, marginTop: 8 },
  highlight: { color: '#6366F1' },
  insightSub: { ...typography.caption, color: colors.textMuted, marginTop: 4 },
  sectionTitle: { ...typography.subtitle, fontSize: 16, color: colors.text, marginBottom: 14 },
  chart: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: colors.bgCard,
    borderRadius: radius.lg,
    padding: 16,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.xl,
    height: 160,
    alignItems: 'flex-end',
  },
  barCol: { alignItems: 'center', flex: 1 },
  barEmoji: { fontSize: 16, marginBottom: 4 },
  barTrack: { height: 90, justifyContent: 'flex-end', width: 24 },
  barFill: { width: '100%', borderRadius: 6, minHeight: 8 },
  barDay: { ...typography.caption, color: colors.textDim, marginTop: 6, fontSize: 11 },
  moodRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginBottom: 12,
  },
  moodEmoji: { fontSize: 20, width: 28 },
  moodName: { ...typography.caption, color: colors.textMuted, width: 70 },
  moodBarTrack: {
    flex: 1,
    height: 8,
    backgroundColor: colors.bgElevated,
    borderRadius: 4,
    overflow: 'hidden',
  },
  moodBarFill: { height: '100%', borderRadius: 4 },
  streakBox: {
    alignItems: 'center',
    backgroundColor: colors.bgCard,
    borderRadius: radius.lg,
    padding: 20,
    marginTop: spacing.md,
    borderWidth: 1,
    borderColor: colors.border,
  },
  streakNum: { ...typography.hero, fontSize: 36, color: colors.accent },
  streakLabel: { ...typography.caption, color: colors.textMuted, marginTop: 4 },
});
