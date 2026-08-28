import React from 'react';
import { TouchableOpacity, Text, StyleSheet, View } from 'react-native';
import { Mood } from '../constants/moods';
import { colors, radius, typography } from '../constants/theme';

interface Props {
  mood: Mood;
  selected?: boolean;
  onPress: () => void;
  compact?: boolean;
}

export function MoodCard({ mood, selected, onPress, compact }: Props) {
  return (
    <TouchableOpacity
      onPress={onPress}
      activeOpacity={0.75}
      style={[
        styles.card,
        compact && styles.compact,
        selected && { borderColor: mood.color, backgroundColor: `${mood.color}22` },
      ]}
    >
      <Text style={[styles.emoji, compact && styles.emojiCompact]}>{mood.emoji}</Text>
      <Text style={styles.label}>{mood.labelHi}</Text>
      {!compact && <Text style={styles.labelEn}>{mood.label}</Text>}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    minWidth: '30%',
    backgroundColor: colors.bgCard,
    borderRadius: radius.lg,
    borderWidth: 1.5,
    borderColor: colors.border,
    paddingVertical: 16,
    paddingHorizontal: 8,
    alignItems: 'center',
    gap: 4,
  },
  compact: {
    paddingVertical: 12,
    minWidth: '28%',
  },
  emoji: { fontSize: 32 },
  emojiCompact: { fontSize: 26 },
  label: { ...typography.subtitle, fontSize: 14, color: colors.text },
  labelEn: { ...typography.caption, color: colors.textMuted },
});
