import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { ScreenWrapper } from '../components/ScreenWrapper';
import { PrimaryButton } from '../components/PrimaryButton';
import { colors, typography, spacing } from '../constants/theme';

export default function WelcomeScreen() {
  const router = useRouter();

  return (
    <ScreenWrapper>
      <View style={styles.content}>
        <View style={styles.hero}>
          <Text style={styles.logo}>SameHo</Text>
          <Text style={styles.tagline}>Abhi kaisa feel ho raha hai?</Text>
          <Text style={styles.desc}>
            Anonymous mood pulse + instant connect with people feeling the same right now.
          </Text>
        </View>

        <View style={styles.pills}>
          {['Anonymous', 'Safe', '15 min rooms'].map((pill) => (
            <View key={pill} style={styles.pill}>
              <Text style={styles.pillText}>{pill}</Text>
            </View>
          ))}
        </View>

        <View style={styles.liveBadge}>
          <View style={styles.dot} />
          <Text style={styles.liveText}>12,847 log online abhi</Text>
        </View>
      </View>

      <View style={styles.footer}>
        <PrimaryButton title="Shuru karo" onPress={() => router.push('/onboarding/nickname')} />
        <Text style={styles.disclaimer}>18+ • Not a medical app • Peer support only</Text>
      </View>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  content: { flex: 1, justifyContent: 'center' },
  hero: { marginBottom: spacing.xl },
  logo: {
    ...typography.hero,
    color: colors.text,
    fontSize: 48,
    marginBottom: spacing.sm,
  },
  tagline: {
    ...typography.title,
    color: colors.primary,
    marginBottom: spacing.md,
  },
  desc: {
    ...typography.body,
    color: colors.textMuted,
    lineHeight: 26,
  },
  pills: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: spacing.xl },
  pill: {
    backgroundColor: colors.bgCard,
    borderRadius: 20,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: colors.border,
  },
  pillText: { ...typography.caption, color: colors.secondary },
  liveBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: colors.bgCard,
    alignSelf: 'flex-start',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: colors.border,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.success,
  },
  liveText: { ...typography.caption, color: colors.textMuted },
  footer: { gap: 12, paddingBottom: spacing.md },
  disclaimer: {
    ...typography.caption,
    color: colors.textDim,
    textAlign: 'center',
  },
});
