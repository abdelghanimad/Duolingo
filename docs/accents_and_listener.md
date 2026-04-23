# Accents & Universal Listener

The Speech Recognition engine (`app/lib/core/i18n/multilingual_speech_engine.dart`)
is built around three ideas:

## 1. Hot-swap the listener locale, never restart the app

When the player picks a new learning language in the
`LanguageSelectorScreen`, we call:

```dart
await speech.setLanguage(picked); // cancels current session, re-binds
```

The next call to `listenFor(...)` resolves the best supported locale on
the device (e.g. requested `ja-JP`; if the device only has `ja`, we
fall back automatically — see `_resolveLocale`). This means a user can
practise Japanese for one round, then Swahili for the next, without
relaunching anything.

## 2. Accept many spoken forms per item, not one

Every `items` row carries a `synonyms` JSONB:

```json
{ "en": ["chair", "seat"], "ar": ["كرسي", "كرسى"], "ja": ["椅子", "チェア"] }
```

The listener compares the recognised utterance against the union of
`names[lang]` ∪ `synonyms[lang]`. Adding a regional variant is a
one-row UPDATE — no code change.

## 3. Forgiving similarity, not exact match

We never compare strings character-by-character. The engine:

1. **Normalises** to lowercase and strips Unicode combining marks
   (handles Arabic diacritics, Vietnamese tone marks, Hindi nuktas).
2. **Scores** with the Sørensen–Dice coefficient over character
   bigrams. This works equally well for Latin, CJK, Arabic, and
   Devanagari without language-specific tokenisers.
3. **Compares** the score to a **per-mode threshold** stored in
   `challenge_modes.default_threshold`:

   | Mode    | Default | Beginner override |
   |---------|---------|-------------------|
   | speed   | 0.70    | 0.55              |
   | shadow  | 0.78    | 0.62              |
   | micro   | 0.82    | 0.68              |

The "Beginner override" column is what we hand to the engine for
players in their first 7 days — a heavy accent that scores 0.6 on
"chair" still wins, which is the whole point: **encourage beginners,
don't punish them for not sounding like a newsreader**.

## 4. Per-language global leaderboard

Every successful (and failed) attempt is logged in `attempts`:

```sql
INSERT INTO attempts(item_id, target_lang, mode_id, category_id,
                     duration_ms, similarity, succeeded)
VALUES ($1, 'ja', 'speed', 'home_tools', 1820, 0.91, true);
```

The `(target_lang, category_id, succeeded, duration_ms)` index makes
the headline query — *“who is the fastest person in the world to guess
home tools in Japanese?”* — a sub-millisecond range scan:

```sql
SELECT user_id, duration_ms
FROM attempts
WHERE target_lang = 'ja'
  AND category_id = 'home_tools'
  AND succeeded
ORDER BY duration_ms ASC
LIMIT 50;
```
