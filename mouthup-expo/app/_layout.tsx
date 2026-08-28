import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { AppProvider } from '../context/AppContext';

export default function RootLayout() {
  return (
    <AppProvider>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: '#0F0B1A' },
          animation: 'slide_from_right',
        }}
      >
        <Stack.Screen name="index" />
        <Stack.Screen name="onboarding/nickname" />
        <Stack.Screen name="onboarding/safety" />
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="stats" />
        <Stack.Screen name="poll-result" />
        <Stack.Screen name="room-match" />
        <Stack.Screen name="room/live" />
        <Stack.Screen name="room/close" />
      </Stack>
    </AppProvider>
  );
}
