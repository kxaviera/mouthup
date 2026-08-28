# MouthUp — Flutter

Anonymous social space for honest conversation (Flutter version).

## Run

```bash
cd mouthup_flutter
flutter pub get
flutter run -d chrome --web-port=57400
flutter run              # Connected device/emulator
```

If `flutter run -d chrome` fails with a debug websocket error on Windows, use web-server mode and open the URL manually:

```bash
flutter run -d web-server --web-port=57400 --web-hostname=localhost
```

Then open http://localhost:57400 in Chrome.

## App flow

Splash → Login / Sign up → Email verify → Onboarding → Feed

## Features

- Anonymous feed with comment-only engagement
- Direct messages, save & share
- Demo account: `demo@mouthup.app` / `demo123`

## Stack

- Flutter + Dart
- go_router (navigation)
- provider (state)
- dio + shared_preferences (API + session)
- Backend: `mouthup-api` at `http://localhost:3000/api/v1`

Set API URL when building:

```bash
flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api/v1
```
