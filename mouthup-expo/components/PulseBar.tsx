import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { MOODS, MoodId } from '../constants/moods';
import { colors, radius, typography } from '../constants/theme';

interface Props {
  moodId: MoodId;
  percent: number;
  highlight?: boolean;
}

export function PulseBar({ moodId, percent, highlight }: Props) {
  const mood = MOODS.find((m) => m.id === moodId)!;

  return (
    <View style={styles.row}>
      <Text style={styles.emoji}>{mood.emoji}</Text>
      <View style={styles.barWrap}>
        <View style={styles.labelRow}>
          <Text style={[styles.label, highlight && styles.labelHighlight]}>
            {mood.labelHi}
          </Text>
          <Text style={[styles.percent, highlight && { color: mood.color }]}>
            {percent}%
          </Text>
        </View>
        <View style={styles.track}>
          <View
            style={[
              styles.fill,
              { width: `${percent}%`, backgroundColor: mood.color },
              highlight && styles.fillHighlight,
            ]}
          />
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 12 },
  emoji: { fontSize: 22, width: 32 },
  barWrap: { flex: 1 },
  labelRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6 },
  label: { ...typography.caption, color: colors.textMuted },
  labelHighlight: { color: colors.text, fontWeight: '700' },
  percent: { ...typography.caption, color: colors.textMuted },
  track: {
    height: 8,
    backgroundColor: colors.bgElevated,
    borderRadius: radius.full,
    overflow: 'hidden',
  },
  fill: { height: '100%', borderRadius: radius.full },
  fillHighlight: { shadowColor: colors.secondary, shadowOpacity: 0.5, shadowRadius: 6 },
});
