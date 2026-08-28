import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { colors, radius, typography } from '../constants/theme';

interface Props {
  nickname: string;
  text: string;
  isMe?: boolean;
}

export function ChatBubble({ nickname, text, isMe }: Props) {
  return (
    <View style={[styles.wrap, isMe && styles.wrapMe]}>
      {!isMe && <Text style={styles.nickname}>{nickname}</Text>}
      <View style={[styles.bubble, isMe ? styles.bubbleMe : styles.bubbleOther]}>
        <Text style={[styles.text, isMe && styles.textMe]}>{text}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: 12, alignItems: 'flex-start', maxWidth: '85%' },
  wrapMe: { alignSelf: 'flex-end', alignItems: 'flex-end' },
  nickname: { ...typography.label, color: colors.textMuted, marginBottom: 4, marginLeft: 4 },
  bubble: {
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: radius.lg,
    borderBottomLeftRadius: 4,
  },
  bubbleOther: {
    backgroundColor: colors.bgElevated,
    borderWidth: 1,
    borderColor: colors.border,
  },
  bubbleMe: {
    backgroundColor: colors.primary,
    borderBottomLeftRadius: radius.lg,
    borderBottomRightRadius: 4,
  },
  text: { ...typography.body, fontSize: 15, color: colors.text },
  textMe: { color: '#fff' },
});
