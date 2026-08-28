import React, { useEffect, useState, useRef } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { useRouter } from 'expo-router';
import { ScreenWrapper } from '../components/ScreenWrapper';
import { useApp } from '../context/AppContext';
import { MOODS, POLL_OPTIONS } from '../constants/moods';
import { colors, typography, spacing } from '../constants/theme';

export default function RoomMatchScreen() {
  const router = useRouter();
  const { selectedMood, pollVote } = useApp();
  const mood = MOODS.find((m) => m.id === selectedMood);
  const vote = pollVote !== null ? POLL_OPTIONS[pollVote] : null;
  const [matched, setMatched] = useState(0);
  const pulse = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 1.15, duration: 600, useNativeDriver: true }),
        Animated.timing(pulse, { toValue: 1, duration: 600, useNativeDriver: true }),
      ])
    ).start();

    const interval = setInterval(() => {
      setMatched((m) => {
        if (m >= 5) {
          clearInterval(interval);
          setTimeout(() => router.replace('/room/live'), 800);
          return 5;
        }
        return m + 1;
      });
    }, 700);

    return () => clearInterval(interval);
  }, []);

  return (
    <ScreenWrapper>
      <View style={styles.content}>
        <Animated.View style={[styles.ring, { transform: [{ scale: pulse }] }]}>
          <Text style={styles.ringEmoji}>{mood?.emoji ?? '💜'}</Text>
        </Animated.View>

        <Text style={styles.title}>Matching...</Text>
        {mood && vote && (
          <Text style={styles.sub}>
            {mood.labelHi} + {vote.label}
          </Text>
        )}

        <View style={styles.dots}>
          {[0, 1, 2, 3, 4].map((i) => (
            <View
              key={i}
              style={[styles.dot, i < matched && styles.dotActive]}
            />
          ))}
        </View>

        <Text style={styles.count}>{matched}/5 log mile</Text>
        <Text style={styles.hint}>Same city • Same mood • Same reason</Text>
      </View>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  content: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  ring: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: colors.primarySoft,
    borderWidth: 2,
    borderColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.xl,
  },
  ringEmoji: { fontSize: 48 },
  title: { ...typography.title, color: colors.text, marginBottom: 8 },
  sub: { ...typography.body, color: colors.textMuted, marginBottom: spacing.xl },
  dots: { flexDirection: 'row', gap: 10, marginBottom: 16 },
  dot: {
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: colors.bgElevated,
    borderWidth: 1,
    borderColor: colors.border,
  },
  dotActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  count: { ...typography.subtitle, color: colors.secondary },
  hint: { ...typography.caption, color: colors.textDim, marginTop: 8 },
});
