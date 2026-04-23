# 🌍 Global Guess Live — Architecture

A two-player, live, voice-first language-learning game. Each player sees a vector
puzzle that belongs to the *other* player and describes it in their **native
language**, while the other player tries to say the target word in the language
they are **learning**. An always-on, on-device speech recognizer fires the
winning event the moment the target word is detected — no buttons, no taps.

This document is the source of truth for the design. The code in `app/` and
`supabase/` implements it incrementally.

---

## 1. UX overview

### Screens
| Screen        | Purpose                                                        |
|---------------|----------------------------------------------------------------|
| Onboarding    | Pick native language, learning language, level                 |
| Lobby         | "Find a Partner" CTA, friends list, quick stats                |
| Matching      | Searching animation → opponent flag/country reveal             |
| **GameRoom**  | Central card + live-call status bar + STT indicator            |
| Result        | Win/lose card, newly-learned words, "Play again"               |

### GameRoom anatomy
```
┌────────────────────────────────────────┐
│ 🎙️ ●  LIVE  •  00:42        👤 Sara   │  ← live-call status bar
├────────────────────────────────────────┤
│            ┌──────────────┐            │
│            │  ☂️ vector   │            │  ← opponent's puzzle (you guess)
│            └──────────────┘            │
│   "Describe this picture in Arabic"    │
├────────────────────────────────────────┤
│ ●●●●●○○○○   remote audio waveform      │
│ 💡 Listening for: "umbrella"           │  ← shown only to you
└────────────────────────────────────────┘
```

Live-call signals:
- Pulsing red **LIVE** dot
- Real-time RMS waveform of the **remote** audio stream
- Green ring around the avatar of whoever is speaking
- Mic-mute toggle with a "this pauses the game" warning
- 3-bar connection-quality indicator from `RTCStatsReport`
- Win animation: 3-D flip of the card revealing the word in both languages,
  confetti, sound — within **<200 ms** of detection.

### Accessibility
- WCAG AA contrast (≥ 4.5:1)
- Live caption of the opponent's STT output for HoH players
- Automatic RTL/LTR layout

---

## 2. Data model (Supabase / Postgres)

See [`supabase/migrations/0001_init.sql`](../supabase/migrations/0001_init.sql).

| Table                | Notes                                                       |
|----------------------|-------------------------------------------------------------|
| `users`              | Profile + chosen languages + XP                             |
| `puzzles`            | Global puzzle bank (language-agnostic vector + slug)        |
| `puzzle_translations`| `(puzzle_id, lang_code)` PK; target word + synonyms array   |
| `rooms`              | Live rooms, status, both players, both puzzles              |
| `room_events`        | Append-only event log; broadcast via Realtime               |
| `game_results`       | Aggregated outcomes for stats / leaderboards                |
| `learned_words`      | Per-user spaced-repetition tracking                         |

Key design choices:
- **`accepted_synonyms text[]` + GIN index** — accept `umbrella`/`brolly`/`parasol`.
- **Event-sourced `room_events`** — Realtime `LISTEN/NOTIFY` over WebSocket
  delivers state changes in 50–150 ms.
- **Race-safe winner** — partial unique index
  `UNIQUE (room_id) WHERE event_type = 'won'` guarantees first-write wins.
- **Postgres trigger** — when a `won` event lands, the same transaction
  updates `rooms.winner_id`, `status='finished'`, and inserts into
  `game_results`. Single source of truth.
- **TTL** — `pg_cron` deletes `room_events` older than 7 days to stay inside
  the Supabase free tier.

### RLS in one breath
- `rooms`, `room_events`: only the two players in the room.
- `puzzles`, `puzzle_translations`: public read, service-role write.
- `learned_words`: owner-only.

---

## 3. Audio: one mic, two consumers

The hard part. Conceptually:

```
🎤 Mic ──► Audio splitter ──┬──► WebRTC PeerConnection ──► opponent
                            └──► On-device speech recognizer ──► matcher
```

### iOS (Swift)
- One `AVAudioEngine`. The same `AVAudioSession`
  (`.playAndRecord` / `.voiceChat`) is shared with `RTCAudioSession`.
- `inputNode.installTap(onBus:0, bufferSize:1024, format:nil) { buf,_ in
  request.append(buf) }` feeds an `SFSpeechAudioBufferRecognitionRequest`
  with `requiresOnDeviceRecognition = true`.
- `setPreferredIOBufferDuration(0.005)` for low latency.

### Android (Kotlin)
- WebRTC owns `AudioRecord` by default. Replace its audio module with
  `JavaAudioDeviceModule.Builder().setSamplesReadyCallback { samples ->
  stt.feed(samples.data) }`. PCM frames are tee'd to STT *after* capture
  and *before* network send.
- STT: `SpeechRecognizer` with `EXTRA_PREFER_OFFLINE = true`, or **Vosk**
  for languages Google STT does not cover.

### Detection algorithm (platform-agnostic, `app/lib/utils/`)
1. STT emits `partialResults` every ~100 ms.
2. `TextNormalizer.normalize()`: lowercase, strip Arabic diacritics, strip
   punctuation, collapse whitespace, NFC.
3. `FuzzyMatcher.match(text, candidates)`: Levenshtein distance ≤ 1
   against `target_word ∪ accepted_synonyms`.
4. On match → insert `room_events { event_type:'word_detected', ... }`.
5. **500 ms debounce** to avoid double-firing on the same utterance.
6. Anti-cheat: only run the matcher against the **remote** audio stream,
   never against the local mic — so a player can't win by saying their own
   word out loud.

---

## 4. Zero-cost strategy

| Concern             | Free choice                                              |
|---------------------|----------------------------------------------------------|
| STT                 | On-device only (`SFSpeechRecognizer` / Android STT / Vosk) |
| Voice transport     | WebRTC P2P, STUN `stun.l.google.com:19302`               |
| TURN (≈20% of NATs) | self-hosted `coturn` on a $5 VPS, or Metered.ca free 50 GB |
| Backend             | Supabase free tier (500 MB DB, 2 GB egress, 50 K MAU)    |
| Asset CDN           | SVG vectors on Cloudflare R2 (10 GB, 0 egress) or GH Pages |
| Errors / analytics  | Sentry free + PostHog free                               |
| Cost guard          | Edge-Function rate limit: 100 games / user / day         |

---

## 5. Latency budget

| Stage                | Target |
|----------------------|--------|
| STT partial result   | ~150 ms |
| Supabase Realtime    | ~150 ms |
| UI render (win flip) | <50 ms |
| **End-to-end**       | **<500 ms** |

---

## 6. Roadmap

| Milestone | Deliverable                                                       |
|-----------|-------------------------------------------------------------------|
| M0        | Project scaffold, Supabase schema, 50 puzzles × 5 languages       |
| M1        | WebRTC voice between two devices via Supabase signaling           |
| M2        | On-device STT + audio tap + win event                             |
| M3        | Full game flow + result screen                                    |
| M4        | UI polish, RTL, win animation, onboarding                         |
| M5        | Closed beta on TestFlight + Play Console                          |
| M6        | Self-hosted TURN, leaderboards, 3+ player modes                   |

---

## 7. Risks

1. STT accuracy for rare dialects — mitigate with `accepted_synonyms` and Vosk.
2. WebRTC + STT on Android < API 29 — needs the `JavaAudioDeviceModule` swap.
3. Privacy — emphasize "STT runs entirely on your device" in onboarding.
4. Self-cheating — match only the *remote* stream (see §3).
