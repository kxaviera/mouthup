import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenWrapper } from '../../components/ScreenWrapper';
import { useApp } from '../../context/AppContext';
import { colors, typography, spacing, radius } from '../../constants/theme';

const MENU_ITEMS = [
  { icon: 'person-outline' as const, label: 'Change nickname', sub: 'Daily rename allowed' },
  { icon: 'ban-outline' as const, label: 'Blocked users', sub: '0 blocked' },
  { icon: 'notifications-outline' as const, label: 'Notifications', sub: '9 PM Pulse reminder' },
  { icon: 'call-outline' as const, label: 'Crisis helplines', sub: 'iCall, Vandrevala, 112' },
  { icon: 'trash-outline' as const, label: 'Delete account', sub: 'All data removed' },
];

export default function ProfileScreen() {
  const router = useRouter();
  const { nickname, city } = useApp();

  return (
    <ScreenWrapper>
      <ScrollView showsVerticalScrollIndicator={false}>
        <Text style={styles.title}>Profile</Text>

        <View style={styles.avatarCard}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{nickname[0]?.toUpperCase()}</Text>
          </View>
          <View>
            <Text style={styles.nickname}>{nickname}</Text>
            <Text style={styles.city}>📍 {city} • Anonymous</Text>
          </View>
        </View>

        <View style={styles.menu}>
          {MENU_ITEMS.map((item) => (
            <TouchableOpacity key={item.label} style={styles.menuItem} activeOpacity={0.7}>
              <View style={styles.menuIcon}>
                <Ionicons name={item.icon} size={20} color={colors.secondary} />
              </View>
              <View style={styles.menuText}>
                <Text style={styles.menuLabel}>{item.label}</Text>
                <Text style={styles.menuSub}>{item.sub}</Text>
              </View>
              <Ionicons name="chevron-forward" size={18} color={colors.textDim} />
            </TouchableOpacity>
          ))}
        </View>

        <TouchableOpacity
          style={styles.logout}
          onPress={() => router.replace('/')}
        >
          <Text style={styles.logoutText}>Logout</Text>
        </TouchableOpacity>

        <Text style={styles.version}>SameHo v1.0 • UI Preview</Text>
      </ScrollView>
    </ScreenWrapper>
  );
}

const styles = StyleSheet.create({
  title: { ...typography.title, color: colors.text, marginTop: spacing.sm, marginBottom: spacing.lg },
  avatarCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
    backgroundColor: colors.bgCard,
    borderRadius: radius.lg,
    padding: 20,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.xl,
  },
  avatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: { ...typography.title, color: '#fff', fontSize: 24 },
  nickname: { ...typography.subtitle, color: colors.text },
  city: { ...typography.caption, color: colors.textMuted, marginTop: 2 },
  menu: { gap: 8 },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.bgCard,
    borderRadius: radius.md,
    padding: 14,
    borderWidth: 1,
    borderColor: colors.border,
    gap: 12,
  },
  menuIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: colors.bgElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  menuText: { flex: 1 },
  menuLabel: { ...typography.body, fontSize: 15, color: colors.text },
  menuSub: { ...typography.caption, color: colors.textDim, marginTop: 1 },
  logout: {
    marginTop: spacing.xl,
    alignItems: 'center',
    padding: 14,
  },
  logoutText: { ...typography.body, color: colors.danger },
  version: {
    ...typography.caption,
    color: colors.textDim,
    textAlign: 'center',
    marginTop: spacing.md,
    marginBottom: spacing.xl,
  },
});
