-- =====================================================================
-- Universal Language Engine — base schema
-- =====================================================================
-- Goals:
--   1. One row per real-world "thing" (e.g. a chair) — language-agnostic.
--   2. All translations live in a single JSONB column (`names`) keyed by
--      BCP-47 language tag, e.g. {"ar":"كرسي","en":"chair","ja":"椅子",...}.
--      This avoids 50 join rows per word and lets the client request
--      `names ->> 'ja'` in a single query.
--   3. Visual assets are referenced by stable storage paths, never by
--      raw bytes, so we can swap CDNs / regenerate thumbnails freely.
--   4. Per-language global leaderboards via a composite (lang, item_id)
--      index — see end of file.
-- =====================================================================

-- Local-friendly auth.uid() stub (no-op when running outside Supabase).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
    CREATE SCHEMA auth;
    CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $f$
      SELECT NULL::uuid;
    $f$;
  END IF;
END$$;

-- ---------------------------------------------------------------------
-- Categories: "home tools", "tech", "space", "sport", "professions" …
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
  id          text PRIMARY KEY,                  -- stable slug, e.g. 'home_tools'
  icon        text NOT NULL,                     -- icon name (Material / custom set)
  -- Localized display names, same JSONB shape as items.names below.
  names       jsonb NOT NULL DEFAULT '{}'::jsonb,
  sort_order  int  NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Items: one row per real-world concept, with all translations inline.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS items (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id   text NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,

  -- Canonical machine-readable key (English snake_case). NEVER shown to
  -- users; only used for analytics / debugging.
  slug          text NOT NULL UNIQUE,

  -- ===== Multilingual payload =======================================
  -- Shape: { "<bcp47>": "<word>", ... }   e.g.
  --   { "ar":"كرسي","en":"chair","fr":"chaise","ja":"椅子","zh":"椅子",
  --     "es":"silla","de":"Stuhl","ru":"стул","tr":"sandalye", ... }
  -- Must contain at least 50 keys for production rows (enforced below).
  names         jsonb NOT NULL,

  -- Optional alternative spellings / synonyms per language, used by the
  -- speech recogniser to broaden the accept-set for accents/dialects:
  --   { "en":["chair","seat"], "ar":["كرسي","كرسى"] }
  synonyms      jsonb NOT NULL DEFAULT '{}'::jsonb,

  -- ===== Visual asset references (NOT raw bytes) ====================
  -- We store storage paths under the `visual-assets` Supabase bucket.
  -- The client builds a public/CDN URL on demand and requests the
  -- correct variant (thumb / medium / full / shadow / microscopic).
  image_path        text NOT NULL,                    -- e.g. 'home_tools/chair.webp'
  image_attribution text,                             -- license / author
  variants          text[] NOT NULL DEFAULT
                      ARRAY['thumb','medium','full']::text[],

  difficulty    smallint NOT NULL DEFAULT 1
                  CHECK (difficulty BETWEEN 1 AND 5),
  created_at    timestamptz NOT NULL DEFAULT now(),

  -- 50-language minimum: refuse to insert under-localised production rows.
  -- Subqueries are forbidden in CHECK constraints, so we count keys via
  -- jsonb_path_query_array() which is just a (immutable) function call.
  CONSTRAINT items_min_50_languages
    CHECK (jsonb_typeof(names) = 'object'
           AND jsonb_array_length(
                 jsonb_path_query_array(names, '$.keyvalue().key')
               ) >= 50)
);

CREATE INDEX IF NOT EXISTS items_category_idx ON items(category_id);

-- GIN index on `names` so we can efficiently search/filter by any
-- language tag, e.g.  WHERE names ? 'ja'  or  names @> '{"ja":"椅子"}'.
CREATE INDEX IF NOT EXISTS items_names_gin ON items USING gin (names);
CREATE INDEX IF NOT EXISTS items_synonyms_gin ON items USING gin (synonyms);

-- ---------------------------------------------------------------------
-- Challenge modes (Speed / Shadow / Microscopic / …)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS challenge_modes (
  id          text PRIMARY KEY,             -- 'speed' | 'shadow' | 'micro' | ...
  icon        text NOT NULL,
  -- variant the client should request from storage for this mode.
  -- 'speed' uses normal images on a tight timer; 'shadow' uses the
  -- silhouette variant; 'micro' uses an extreme zoom crop.
  asset_variant text NOT NULL,
  -- Per-mode similarity threshold for the speech recogniser. Lower =
  -- more forgiving. We start beginners at 0.55 to encourage them.
  default_threshold numeric(3,2) NOT NULL DEFAULT 0.75
                      CHECK (default_threshold BETWEEN 0 AND 1)
);

INSERT INTO challenge_modes(id, icon, asset_variant, default_threshold) VALUES
  ('speed',  'flash',     'medium',      0.70),
  ('shadow', 'eclipse',   'shadow',      0.78),
  ('micro',  'microscope','microscopic', 0.82)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------
-- Per-language global leaderboard
-- ---------------------------------------------------------------------
-- One row per (player, item, target-language, mode) attempt.  The
-- composite index makes the "fastest player in the world to guess
-- 'home tools' in Japanese" query O(log n).
CREATE TABLE IF NOT EXISTS attempts (
  id              bigserial PRIMARY KEY,
  user_id         uuid NOT NULL DEFAULT auth.uid(),
  item_id         uuid NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  target_lang     text NOT NULL,                   -- BCP-47, e.g. 'ja'
  mode_id         text NOT NULL REFERENCES challenge_modes(id),
  category_id     text NOT NULL REFERENCES categories(id),
  duration_ms     int  NOT NULL CHECK (duration_ms >= 0),
  similarity      numeric(4,3) NOT NULL CHECK (similarity BETWEEN 0 AND 1),
  succeeded       boolean NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Critical leaderboard index: "fastest in the world for <lang>+<category>".
CREATE INDEX IF NOT EXISTS attempts_leaderboard_idx
  ON attempts (target_lang, category_id, succeeded, duration_ms);

CREATE INDEX IF NOT EXISTS attempts_user_idx ON attempts(user_id);

-- ---------------------------------------------------------------------
-- Convenience view: best time per (user, language, category).
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_leaderboard AS
SELECT
  target_lang,
  category_id,
  user_id,
  min(duration_ms) AS best_ms,
  count(*)         AS attempts,
  avg(similarity)::numeric(4,3) AS avg_similarity
FROM attempts
WHERE succeeded
GROUP BY target_lang, category_id, user_id;

-- =====================================================================
-- RLS — players can only insert their own attempts; everyone reads
-- items / categories / leaderboard.
-- =====================================================================
ALTER TABLE attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS attempts_insert_own ON attempts;
CREATE POLICY attempts_insert_own ON attempts
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS attempts_select_all ON attempts;
CREATE POLICY attempts_select_all ON attempts
  FOR SELECT USING (true);
