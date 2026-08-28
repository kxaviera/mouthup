import React from 'react';
import { TouchableOpacity, Text, StyleSheet, View } from 'react-native';
import { colors, radius, typography } from '../constants/theme';

interface Props {
  label: string;
  percent?: number;
  selected?: boolean;
  onPress: () => void;
}

export function PollOption({ label, percent, selected, onPress }: Props) {
  return (
    <TouchableOpacity
      onPress={onPress}
      activeOpacity={0.8}
      style={[styles.option, selected && styles.selected]}
    >
      <View style={styles.left}>
        <View style={[styles.radio, selected && styles.radioSelected]}>
          {selected && <View style={styles.radioDot} />}
        </View>
        <Text style={[styles.label, selected && styles.labelSelected]}>{label}</Text>
      </View>
      {percent !== undefined && (
        <Text style={[styles.percent, selected && styles.percentSelected]}>{percent}%</Text>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  option: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.bgCard,
    borderRadius: radius.md,
    borderWidth: 1.5,
    borderColor: colors.border,
    padding: 16,
    marginBottom: 10,
  },
  selected: {
    borderColor: colors.primary,
    backgroundColor: colors.primarySoft,
  },
  left: { flexDirection: 'row', alignItems: 'center', gap: 12, flex: 1 },
  radio: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    borderColor: colors.textDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  radioSelected: { borderColor: colors.primary },
  radioDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: colors.primary,
  },
  label: { ...typography.body, fontSize: 15, color: colors.text, flex: 1 },
  labelSelected: { fontWeight: '600' },
  percent: { ...typography.caption, color: colors.textMuted },
  percentSelected: { color: colors.primary, fontWeight: '700' },
});
