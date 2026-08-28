export const colors = {
  bg: '#0F0B1A',
  bgCard: '#1A1429',
  bgElevated: '#241C38',
  primary: '#FF6B6B',
  primarySoft: 'rgba(255, 107, 107, 0.15)',
  secondary: '#A78BFA',
  accent: '#FBBF24',
  text: '#F8F4FF',
  textMuted: '#9B8FB5',
  textDim: '#6B5F80',
  border: '#2E2545',
  success: '#34D399',
  danger: '#F87171',
  gradientStart: '#1A0F2E',
  gradientMid: '#2D1B4E',
  gradientEnd: '#0F0B1A',
};

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const radius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  full: 999,
};

export const typography = {
  hero: { fontSize: 32, fontWeight: '700' as const, lineHeight: 40 },
  title: { fontSize: 24, fontWeight: '700' as const, lineHeight: 32 },
  subtitle: { fontSize: 18, fontWeight: '600' as const, lineHeight: 26 },
  body: { fontSize: 16, fontWeight: '400' as const, lineHeight: 24 },
  caption: { fontSize: 13, fontWeight: '500' as const, lineHeight: 18 },
  label: { fontSize: 12, fontWeight: '600' as const, lineHeight: 16, letterSpacing: 0.5 },
};
