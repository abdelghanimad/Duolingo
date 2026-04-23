# Duolingo — Universal Language Engine

A "global communication bridge": learn **any** language by guessing
**any** image. Not a localised app — a localisation *engine*.

## Repository layout

```
supabase/
  migrations/0001_universal_language_engine.sql   ← items, categories,
                                                    challenge_modes,
                                                    attempts (+ leaderboard
                                                    index), RLS
  seed/0001_seed_chair.sql                        ← demo: "chair" in 60
                                                    languages, satisfies the
                                                    50-language CHECK
app/lib/
  core/i18n/
    languages.dart                       ← 50+ supported learning languages
                                            (BCP-47, native name, flag,
                                            speech tag, RTL flag)
    multilingual_speech_engine.dart      ← hot-swap STT + accent-tolerant
                                            similarity scoring
  features/language_selector/
    language_selector_screen.dart        ← icon-first global selector UI
docs/
  visual_assets_strategy.md              ← shipping 1,000 images without
                                            slowing the app
  accents_and_listener.md                ← multilingual STT + leaderboard
```

## How the pieces fit together

1. **Items** are stored once with **all** translations inline in
   `items.names` (JSONB, ≥ 50 languages enforced by a CHECK constraint),
   and a `synonyms` JSONB for the speech recogniser's accept-set.
2. The **Flutter Language Selector** uses flag emoji + each language's
   own native name, so a brand-new user from any country can navigate
   before we know which UI locale to render.
3. The **Multilingual Speech Engine** re-binds the platform recogniser
   to the chosen language's `speechTag` instantly, scores utterances
   with a script-agnostic Dice coefficient, and accepts any of
   `names[lang] ∪ synonyms[lang]` over a per-mode forgiving threshold.
4. **Challenge modes** (`speed`, `shadow`, `micro`) just pick a
   different image variant from Storage — no extra image downloads,
   one ingest, one DB row each.
5. **Per-language leaderboards** are a single composite index on
   `attempts(target_lang, category_id, succeeded, duration_ms)`.