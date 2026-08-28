import React, { useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { ScreenWrapper } from '../../components/ScreenWrapper';
import { PrimaryButton } from '../../components/PrimaryButton';
import { colors, typography, spacing, radius } from '../../constants/theme';

export default function RoomCloseScreen() {
  const router = useRouter();
  const [feltBetter, setFeltBetter] = useState<boolean | null>(null);

  return (
    <ScreenWrapper>
      <View style={styles.content}>
        <Text style={styles.emoji}>💜</Text>
        <Text style={styles.title}>Room band ho gaya</Text>
        <Text style={styles.sub}>15 min complete — messages delete ho gaye</Text>

        <Text style={styles.question}>Kya thoda better feel hua?</Text>
        <View style={styles.buttons}>
          <PrimaryButton
            title="Haan 😊"
            variant={feltBetter === true ? 'primary' : 'secondary'}
            onPress={() => setFeltBetter(true)}
            style={styles.halfBtn}
          />
          <PrimaryButton
            title="Nahi"
            variant={feltBetter === false ? 'primary' : 'secondary'}
            onPress={() => setFeltBetter(false)}
            style={styles.halfBtn}
          />
        </View>

        {feltBetter !== null && (
          <View style={styles.statBox}>
            <Text style={styles.statText}>
              Aaj <Text style={styles.highlight}>68%</Text> log ne connect ke baad better feel report kiya
            </Text>
          </View>
        )}
      </View>

      <View style={styles.footer}>
        <PrimaryButton
          title="Wapas Pulse pe"
          onPress={() => router.replace('/(tabs)/pulse')}
        />
        <PrimaryButton
          title="Kal reminder set karo"
          variant="ghost"
          onPress={() => router.replace('/(tabs)/pulse')}
        />
      </View>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  content: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  emoji: { fontSize: 64, marginBottom: spacing.lg },
  title: { ...typography.title, color: colors.text, marginBottom: 8 },
  sub: { ...typography.body, color: colors.textMuted, textAlign: 'center', marginBottom: spacing.xxl },
  question: { ...typography.subtitle, color: colors.text, marginBottom: spacing.md },
  buttons: { flexDirection: 'row', gap: 12, width: '100%' },
  halfBtn: { flex: 1 },
  statBox: {
    marginTop: spacing.xl,
    backgroundColor: colors.bgCard,
    borderRadius: radius.lg,
    padding: 16,
    borderWidth: 1,
    borderColor: colors.success,
    width: '100%',
  },
  statText: { ...typography.body, color: colors.textMuted, textAlign: 'center', lineHeight: 24 },
  highlight: { color: colors.success, fontWeight: '700' },
  footer: { gap: 8, paddingBottom: spacing.md },
});
