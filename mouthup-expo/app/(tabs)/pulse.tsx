import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { ScreenWrapper } from '../../components/ScreenWrapper';
import { MoodCard } from '../../components/MoodCard';
import { PulseBar } from '../../components/PulseBar';
import { PrimaryButton } from '../../components/PrimaryButton';
import { useApp } from '../../context/AppContext';
import { MOODS, LIVE_PULSE, MoodId } from '../../constants/moods';
import { colors, typography, spacing } from '../../constants/theme';

export default function PulseScreen() {
  const router = useRouter();
  const { city, selectedMood, setSelectedMood } = useApp();
  const [localMood, setLocalMood] = useState<MoodId | null>(selectedMood);

  const handleMoodSelect = (id: MoodId) => {
    setLocalMood(id);
    setSelectedMood(id);
  };

  const handleContinue = () => {
    if (localMood) router.push('/stats');
  };

  const currentMood = MOODS.find((m) => m.id === localMood);

  return (
    <ScreenWrapper padded={false}>
      <ScrollView
        contentContainerStyle={styles.scroll}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Text style={styles.greeting}>SameHo</Text>
          <View style={styles.cityBadge}>
            <Text style={styles.cityText}>📍 {city}</Text>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.question}>Abhi tum kaisa feel kar rahe ho?</Text>
          <View style={styles.moodGrid}>
            {MOODS.map((mood) => (
              <MoodCard
                key={mood.id}
                mood={mood}
                selected={localMood === mood.id}
                onPress={() => handleMoodSelect(mood.id)}
              />
            ))}
          </View>
        </View>

        {localMood && currentMood && (
          <View style={styles.selectedBanner}>
            <Text style={styles.selectedEmoji}>{currentMood.emoji}</Text>
            <View>
              <Text style={styles.selectedLabel}>Tumhara mood: {currentMood.labelHi}</Text>
              <Text style={styles.selectedSub}>
                {LIVE_PULSE.find((p) => p.moodId === localMood)?.percent}% log bhi aisa feel kar rahe
              </Text>
            </View>
          </View>
        )}

        <View style={styles.section}>
          <View style={styles.pulseHeader}>
            <Text style={styles.sectionTitle}>Live Pulse — {city}</Text>
            <View style={styles.liveDot}>
              <View style={styles.dot} />
              <Text style={styles.liveLabel}>LIVE</Text>
            </View>
          </View>
          <View style={styles.pulseCard}>
            {LIVE_PULSE.map((p) => (
              <PulseBar
                key={p.moodId}
                moodId={p.moodId}
                percent={p.percent}
                highlight={localMood === p.moodId}
              />
            ))}
          </View>
        </View>

        <View style={styles.statsRow}>
          <View style={styles.statBox}>
            <Text style={styles.statNum}>12,847</Text>
            <Text style={styles.statLabel}>Online abhi</Text>
          </View>
          <View style={styles.statBox}>
            <Text style={styles.statNum}>3,201</Text>
            <Text style={styles.statLabel}>{city} me</Text>
          </View>
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <PrimaryButton
          title={localMood ? 'Aage badho →' : 'Pehle mood select karo'}
          onPress={handleContinue}
          disabled={!localMood}
        />
      </View>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  scroll: { paddingHorizontal: 20, paddingBottom: 100 },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.lg,
    marginTop: spacing.sm,
  },
  greeting: { ...typography.title, color: colors.text },
  cityBadge: {
    backgroundColor: colors.bgCard,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: colors.border,
  },
  cityText: { ...typography.caption, color: colors.textMuted },
  section: { marginBottom: spacing.lg },
  question: {
    ...typography.subtitle,
    color: colors.text,
    marginBottom: spacing.md,
  },
  moodGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  selectedBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    backgroundColor: colors.primarySoft,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.primary,
    padding: 16,
    marginBottom: spacing.lg,
  },
  selectedEmoji: { fontSize: 36 },
  selectedLabel: { ...typography.subtitle, fontSize: 15, color: colors.text },
  selectedSub: { ...typography.caption, color: colors.textMuted, marginTop: 2 },
  pulseHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: { ...typography.subtitle, fontSize: 16, color: colors.text },
  liveDot: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  dot: { width: 7, height: 7, borderRadius: 4, backgroundColor: colors.danger },
  liveLabel: { ...typography.label, color: colors.danger, fontSize: 10 },
  pulseCard: {
    backgroundColor: colors.bgCard,
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: colors.border,
  },
  statsRow: { flexDirection: 'row', gap: 12 },
  statBox: {
    flex: 1,
    backgroundColor: colors.bgCard,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
  },
  statNum: { ...typography.title, fontSize: 22, color: colors.secondary },
  statLabel: { ...typography.caption, color: colors.textMuted, marginTop: 4 },
  footer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    paddingHorizontal: 20,
    paddingBottom: 16,
    paddingTop: 12,
    backgroundColor: 'rgba(15, 11, 26, 0.95)',
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
});
