# SameHo — UI Preview

Anonymous mood pulse + instant connect app (Opinion + Moment Match combined).

## Run

```bash
cd sameho
npm run web      # Browser me dekho (fastest)
npm run android  # Android emulator/device
npm start        # Expo Go QR code
```

## App flow

1. **Welcome** → Onboarding (nickname, city, safety)
2. **Pulse** → Mood select + live city stats
3. **Stats** → "Tum akela nahi ho" screen
4. **Vote** → 60 sec expiring poll
5. **Poll Result** → Live results + share
6. **Room Match** → Finding same-feel users
7. **Live Room** → 15 min anonymous chat
8. **Room Close** → Feedback + back to Pulse

## Tabs

- Pulse | Vote | Rooms | My Mood | Profile

## Stack

- Expo SDK 57 + React Native
- Expo Router (file-based navigation)
- TypeScript
- Mock data (no backend yet)
