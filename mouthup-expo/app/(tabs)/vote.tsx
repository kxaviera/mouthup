import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { ScreenWrapper } from '../../components/ScreenWrapper';
import { PollOption } from '../../components/PollOption';
import { PrimaryButton } from '../../components/PrimaryButton';
import { useApp } from '../../context/AppContext';
import { MOODS, POLL_OPTIONS } from '../../constants/moods';
import { colors, typography, spacing } from '../../constants/theme';

export default function VoteScreen() {
  const router = useRouter();
  const { selectedMood, pollVote, setPollVote } = useApp();
  const [selected, setSelected] = useState<number | null>(pollVote);
  const [timer, setTimer] = useState(58);

  useEffect(() => {
    const interval = setInterval(() => {
      setTimer((t) => (t > 0 ? t - 1 : 0));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const mood = MOODS.find((m) => m.id === selectedMood);

  const handleVote = () => {
    if (selected === null) return;
    setPollVote(selected);
    router.push('/poll-result');
  };

  return (
    <ScreenWrapper>
      <View style={styles.timerRow}>
        <Text style={styles.timerLabel}>⏱ Poll expire ho raha hai</Text>
        <Text style={styles.timer}>{timer}s</Text>
      </View>

      {mood && (
        <View style={styles.moodTag}>
          <Text style={styles.moodEmoji}>{mood.emoji}</Text>
          <Text style={styles.moodText}>{mood.labelHi} mood</Text>
        </View>
      )}

      <Text style={styles.question}>Low feel ka reason kya lagta hai?</Text>
      <Text style={styles.sub}>Ek select karo — result turant dikhega</Text>

      <View style={styles.options}>
        {POLL_OPTIONS.map((opt) => (
          <PollOption
            key={opt.id}
            label={opt.label}
            selected={selected === opt.id}
            onPress={() => setSelected(opt.id)}
          />
        ))}
      </View>

      <View style={styles.footer}>
        <PrimaryButton
          title="Vote karo"
          onPress={handleVote}
          disabled={selected === null}
        />
      </View>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  timerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: colors.bgCard,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.lg,
    marginTop: spacing.sm,
  },
  timerLabel: { ...typography.caption, color: colors.textMuted },
  timer: { ...typography.subtitle, color: colors.accent, fontWeight: '700' },
  moodTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    alignSelf: 'flex-start',
    backgroundColor: colors.bgElevated,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    marginBottom: spacing.md,
  },
  moodEmoji: { fontSize: 18 },
  moodText: { ...typography.caption, color: colors.textMuted },
  question: { ...typography.title, fontSize: 22, color: colors.text, marginBottom: 8 },
  sub: { ...typography.body, color: colors.textMuted, marginBottom: spacing.lg },
  options: { flex: 1 },
  footer: { paddingBottom: spacing.md },
});
