import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenWrapper } from '../../components/ScreenWrapper';
import { PrimaryButton } from '../../components/PrimaryButton';
import { useApp } from '../../context/AppContext';
import { colors, typography, spacing, radius } from '../../constants/theme';

const RULES = [
  { icon: 'videocam-off-outline' as const, text: 'No photos / videos' },
  { icon: 'chatbubble-outline' as const, text: 'No private DMs' },
  { icon: 'time-outline' as const, text: 'Rooms 15 min me band' },
  { icon: 'flag-outline' as const, text: 'Report anytime' },
  { icon: 'heart-outline' as const, text: 'Peer support — medical advice nahi' },
];

export default function SafetyScreen() {
  const router = useRouter();
  const { completeOnboarding } = useApp();

  const handleContinue = () => {
    completeOnboarding();
    router.replace('/(tabs)/pulse');
  };

  return (
    <ScreenWrapper>
      <Text style={styles.step}>Step 2 of 2</Text>
      <Text style={styles.title}>Safe space rules</Text>
      <Text style={styles.subtitle}>SameHo ek judgment-free zone hai</Text>

      <View style={styles.rules}>
        {RULES.map((rule) => (
          <View key={rule.text} style={styles.rule}>
            <View style={styles.iconWrap}>
              <Ionicons name={rule.icon} size={22} color={colors.secondary} />
            </View>
            <Text style={styles.ruleText}>{rule.text}</Text>
          </View>
        ))}
      </View>

      <View style={styles.helpline}>
        <Ionicons name="call-outline" size={18} color={colors.accent} />
        <Text style={styles.helplineText}>
          Crisis me: iCall 9152987821 • Vandrevala 1860-2662-345
        </Text>
      </View>

      <View style={styles.footer}>
        <PrimaryButton title="Samajh gaya — Pulse dekho" onPress={handleContinue} />
      </View>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  step: { ...typography.label, color: colors.secondary, marginBottom: 8, marginTop: spacing.md },
  title: { ...typography.title, color: colors.text, marginBottom: 8 },
  subtitle: { ...typography.body, color: colors.textMuted, marginBottom: spacing.xl },
  rules: { gap: 12, marginBottom: spacing.xl },
  rule: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    backgroundColor: colors.bgCard,
    padding: 16,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
  },
  iconWrap: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.bgElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  ruleText: { ...typography.body, fontSize: 15, color: colors.text, flex: 1 },
  helpline: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    backgroundColor: 'rgba(251, 191, 36, 0.1)',
    padding: 14,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: 'rgba(251, 191, 36, 0.25)',
    marginBottom: spacing.xl,
  },
  helplineText: { ...typography.caption, color: colors.accent, flex: 1, lineHeight: 20 },
  footer: { marginTop: 'auto' },
});
