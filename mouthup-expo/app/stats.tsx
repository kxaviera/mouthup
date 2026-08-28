import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { ScreenWrapper } from '../components/ScreenWrapper';
import { PrimaryButton } from '../components/PrimaryButton';
import { useApp } from '../context/AppContext';
import { MOODS, LIVE_PULSE } from '../constants/moods';
import { colors, typography, spacing, radius } from '../constants/theme';

export default function StatsScreen() {
  const router = useRouter();
  const { city, selectedMood } = useApp();
  const mood = MOODS.find((m) => m.id === selectedMood);
  const percent = LIVE_PULSE.find((p) => p.moodId === selectedMood)?.percent ?? 0;

  if (!mood) {
    router.replace('/(tabs)/pulse');
    return null;
  }

  return (
    <ScreenWrapper>
      <View style={styles.content}>
        <Text style={styles.emoji}>{mood.emoji}</Text>
        <Text style={styles.headline}>Tum akela nahi ho</Text>
        <Text style={styles.bigNum}>12,847</Text>
        <Text style={styles.desc}>
          log abhi <Text style={styles.highlight}>"{mood.labelHi}"</Text> feel kar rahe hain
        </Text>

        <View style={styles.cityBox}>
          <Text style={styles.cityLabel}>{city} me abhi</Text>
          <Text style={styles.cityNum}>3,201 log</Text>
          <Text style={styles.cityPercent}>{percent}% same mood</Text>
        </View>

        <View style={styles.divider} />

        <Text style={styles.nextLabel}>Agla step</Text>
        <Text style={styles.nextText}>Ek chhota poll — phir same feel wale se connect</Text>
      </View>

      <View style={styles.footer}>
        <PrimaryButton title="Abhi vote karo →" onPress={() => router.push('/(tabs)/vote')} />
        <PrimaryButton
          title="Skip — seedha Pulse dekho"
          variant="ghost"
          onPress={() => router.replace('/(tabs)/pulse')}
        />
      </View>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  content: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  emoji: { fontSize: 72, marginBottom: spacing.lg },
  headline: { ...typography.subtitle, color: colors.textMuted, marginBottom: 8 },
  bigNum: {
    ...typography.hero,
    fontSize: 56,
    color: colors.secondary,
    marginBottom: 8,
  },
  desc: {
    ...typography.body,
    color: colors.textMuted,
    textAlign: 'center',
    lineHeight: 26,
    paddingHorizontal: 20,
  },
  highlight: { color: colors.text, fontWeight: '700' },
  cityBox: {
    marginTop: spacing.xl,
    backgroundColor: colors.bgCard,
    borderRadius: radius.lg,
    padding: 20,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
    width: '100%',
  },
  cityLabel: { ...typography.caption, color: colors.textMuted },
  cityNum: { ...typography.title, color: colors.text, marginTop: 4 },
  cityPercent: { ...typography.caption, color: colors.primary, marginTop: 4 },
  divider: {
    width: 40,
    height: 2,
    backgroundColor: colors.border,
    marginVertical: spacing.xl,
  },
  nextLabel: { ...typography.label, color: colors.primary },
  nextText: { ...typography.body, color: colors.textMuted, textAlign: 'center', marginTop: 6 },
  footer: { gap: 8, paddingBottom: spacing.md },
});
