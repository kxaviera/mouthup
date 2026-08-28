import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenWrapper } from '../../components/ScreenWrapper';
import { PrimaryButton } from '../../components/PrimaryButton';
import { useApp } from '../../context/AppContext';
import { colors, typography, spacing, radius } from '../../constants/theme';

const CITIES = ['Delhi', 'Mumbai', 'Bangalore', 'Pune', 'Hyderabad', 'Other'];
const NICKNAMES = ['CoolBreeze47', 'SilentOwl', 'NightWalker', 'CalmRiver', 'StarGazer22'];

export default function NicknameScreen() {
  const router = useRouter();
  const { nickname, setNickname, city, setCity } = useApp();
  const [localNick, setLocalNick] = useState(nickname);

  const shuffleNick = () => {
    const next = NICKNAMES[Math.floor(Math.random() * NICKNAMES.length)];
    setLocalNick(next);
    setNickname(next);
  };

  return (
    <ScreenWrapper>
      <ScrollView showsVerticalScrollIndicator={false}>
        <TouchableOpacity onPress={() => router.back()} style={styles.back}>
          <Ionicons name="arrow-back" size={24} color={colors.textMuted} />
        </TouchableOpacity>

        <Text style={styles.step}>Step 1 of 2</Text>
        <Text style={styles.title}>Aaj ka naam</Text>
        <Text style={styles.subtitle}>Real name nahi — sirf anonymous nickname</Text>

        <View style={styles.nickRow}>
          <TextInput
            style={styles.input}
            value={localNick}
            onChangeText={(t) => {
              setLocalNick(t);
              setNickname(t);
            }}
            placeholderTextColor={colors.textDim}
            placeholder="Nickname"
          />
          <TouchableOpacity onPress={shuffleNick} style={styles.shuffle}>
            <Ionicons name="shuffle" size={22} color={colors.secondary} />
          </TouchableOpacity>
        </View>

        <Text style={styles.label}>City</Text>
        <View style={styles.cityGrid}>
          {CITIES.map((c) => (
            <TouchableOpacity
              key={c}
              onPress={() => setCity(c)}
              style={[styles.cityChip, city === c && styles.cityChipActive]}
            >
              <Text style={[styles.cityText, city === c && styles.cityTextActive]}>{c}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <View style={styles.ageBox}>
          <Ionicons name="checkmark-circle" size={22} color={colors.success} />
          <Text style={styles.ageText}>Main 18 saal ya usse zyada ka hoon</Text>
        </View>
      </ScrollView>

      <PrimaryButton
        title="Aage badho"
        onPress={() => router.push('/onboarding/safety')}
        style={{ marginTop: spacing.md }}
      />
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  back: { marginBottom: spacing.lg, marginTop: spacing.sm },
  step: { ...typography.label, color: colors.secondary, marginBottom: 8 },
  title: { ...typography.title, color: colors.text, marginBottom: 8 },
  subtitle: { ...typography.body, color: colors.textMuted, marginBottom: spacing.xl },
  nickRow: { flexDirection: 'row', gap: 10, marginBottom: spacing.xl },
  input: {
    flex: 1,
    backgroundColor: colors.bgCard,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    paddingHorizontal: 16,
    paddingVertical: 16,
    color: colors.text,
    ...typography.subtitle,
    fontSize: 16,
  },
  shuffle: {
    backgroundColor: colors.bgCard,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    width: 52,
    alignItems: 'center',
    justifyContent: 'center',
  },
  label: { ...typography.label, color: colors.textMuted, marginBottom: 12 },
  cityGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: spacing.xl },
  cityChip: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: radius.full,
    backgroundColor: colors.bgCard,
    borderWidth: 1,
    borderColor: colors.border,
  },
  cityChipActive: {
    borderColor: colors.primary,
    backgroundColor: colors.primarySoft,
  },
  cityText: { ...typography.caption, color: colors.textMuted },
  cityTextActive: { color: colors.primary, fontWeight: '700' },
  ageBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: colors.bgCard,
    padding: 16,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
  },
  ageText: { ...typography.body, fontSize: 14, color: colors.text, flex: 1 },
});
