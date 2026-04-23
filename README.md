# 🌍 Global Guess Live

A two-player, live, voice-first language-learning game.

Each player sees a vector puzzle that belongs to the **other** player and
describes it in their **native language**. The other player tries to say the
target word in the language they're **learning**. An always-on, on-device
speech recognizer fires the winning event the moment the target word is
detected — no buttons, no taps, no cloud bills.

> Inspired by Duolingo's pedagogy, but built around live voice interaction
> between two real humans.

---

## Repository layout

```
.
├── docs/
│   └── ARCHITECTURE.md          # Source-of-truth design doc
├── supabase/
│   ├── migrations/
│   │   └── 0001_init.sql        # Tables, indexes, RLS, win-trigger
│   └── seed.sql                 # 10 puzzles × 5 languages
├── core/                        # Pure-Dart domain layer (testable, no Flutter)
│   ├── lib/global_guess_live_core.dart
│   ├── lib/src/{models,utils,services}/
│   └── test/                    # 33 unit tests, run with `dart test`
└── app/                         # Flutter app (iOS / Android)
    ├── lib/{screens,widgets,services,theme}/
    └── pubspec.yaml             # Depends on core/
```

The pure-Dart `core/` package contains the **win-detection logic** —
text normalization (Arabic-aware), bounded Levenshtein fuzzy matching,
debouncer and `WinDetector` — and is fully unit-tested **without** a Flutter
toolchain.

---

## Quick start

### 1. Database

Anything that speaks Postgres ≥ 14 works (Supabase, local, Docker).

```bash
psql -d your_db -f supabase/migrations/0001_init.sql
psql -d your_db -f supabase/seed.sql
```

The migration is portable: when run **inside Supabase**, the real
`auth.uid()` is used. When run **outside Supabase** (CI, local dev), a
no-op stub is created so the RLS policies still parse and apply.

### 2. Domain layer (pure Dart, no Flutter required)

```bash
cd core
dart pub get
dart test           # 33 tests
dart analyze        # 0 issues
```

### 3. Flutter app

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
≥ 3.22 and platform tooling (Xcode for iOS, Android Studio for Android).

```bash
cd app
flutter pub get
flutter run         # picks an attached device
```

Live voice (WebRTC) and on-device STT need a real device — the simulator
mics are unreliable. The `GameRoomScreen` ships with a "(dev) Simulate
win event" button so the full flow is walkable without a partner.

---

## What's implemented vs. designed

| Layer                                             | Status |
|---------------------------------------------------|--------|
| Architecture document                             | ✅ `docs/ARCHITECTURE.md` |
| Postgres schema, indexes, RLS, win-trigger        | ✅ runs & passes functional test |
| Race-safe winner (`UNIQUE … WHERE event_type='won'`) | ✅ verified in CI |
| Seed data (10 puzzles × 5 languages)              | ✅ |
| Text normalization (Arabic, punctuation, casing)  | ✅ tested |
| Fuzzy matcher (bounded Levenshtein, multi-word)   | ✅ tested |
| Win-detection pipeline + debouncer                | ✅ tested |
| Flutter UI scaffold (5 screens, 3 widgets, theme) | ✅ |
| Service interfaces (`SupabaseService`, `WebRtcService`, `SpeechService`) | ✅ |
| Native WebRTC plumbing (iOS `AVAudioEngine` tap, Android `JavaAudioDeviceModule`) | 📐 documented |
| Self-hosted `coturn` TURN server                  | 📐 documented |

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design,
including the audio-pipeline single-source-to-two-paths recipe and the
zero-cost operations strategy.

---

## License

TBD.
