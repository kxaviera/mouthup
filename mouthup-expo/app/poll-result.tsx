import React from 'react';
import { View, Text, StyleSheet, Share } from 'react-native';
import { useRouter } from 'expo-router';
import { ScreenWrapper } from '../components/ScreenWrapper';
import { PollOption } from '../components/PollOption';
import { PrimaryButton } from '../components/PrimaryButton';
import { useApp } from '../context/AppContext';
import { MOODS, POLL_OPTIONS } from '../constants/moods';
import { colors, typography, spacing, radius } from '../constants/theme';

export default function PollResultScreen() {
  const router = useRouter();
  const { selectedMood, pollVote, city } = useApp();
  const mood = MOODS.find((m) => m.id === selectedMood);
  const vote = pollVote !== null ? POLL_OPTIONS[pollVote] : null;

  const handleShare = async () => {
    await Share.share({
      message: `SameHo Pulse: ${city} me aaj ${POLL_OPTIONS[0].percent}% log Work stress se Low feel kar rahe hain. Tumhara mood kya hai?`,
    });
  };

  return (
    <ScreenWrapper>
      <View style={styles.header}>
        <Text style={styles.live}>● LIVE RESULT</Text>
        <Text style={styles.title}>Poll Result</Text>
        {mood && vote && (
          <Text style={styles.match}>
            {mood.emoji} {mood.labelHi} + {vote.label}
          </Text>
        )}
      </View>

      <View style={styles.results}>
        {POLL_OPTIONS.map((opt) => (
          <PollOption
            key={opt.id}
            label={opt.label}
            percent={opt.percent}
            selected={pollVote === opt.id}
            onPress={() => {}}
          />
        ))}
      </View>

      <View style={styles.votersBox}>
        <Text style={styles.votersNum}>4,102</Text>
        <Text style={styles.votersLabel}>log ne abhi vote kiya</Text>
      </View>

      <View style={styles.footer}>
        <PrimaryButton
          title="Same feel wale se connect →"
          onPress={() => router.push('/room-match')}
        />
        <PrimaryButton title="WhatsApp pe share" variant="secondary" onPress={handleShare} />
      </View>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  header: { marginTop: spacing.md, marginBottom: spacing.lg },
  live: { ...typography.label, color: colors.danger, marginBottom: 8 },
  title: { ...typography.title, color: colors.text },
  match: { ...typography.caption, color: colors.textMuted, marginTop: 6 },
  results: { flex: 1 },
  votersBox: {
    alignItems: 'center',
    backgroundColor: colors.bgCard,
    borderRadius: radius.lg,
    padding: 16,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.lg,
  },
  votersNum: { ...typography.title, color: colors.secondary },
  votersLabel: { ...typography.caption, color: colors.textMuted, marginTop: 2 },
  footer: { gap: 10, paddingBottom: spacing.md },
});
