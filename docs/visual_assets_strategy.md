# Visual Assets Strategy — shipping 1,000 images without slowing the app

> Goal: a global player on a low-end Android in a 3G area must still
> open the app in **< 3 s** and see her first image-guessing card in
> **< 500 ms** after that.

## 1. Storage layout

We never bundle the 1,000 source images inside the APK/IPA. Instead:

```
Supabase Storage bucket: visual-assets/
  ├─ home_tools/
  │    ├─ chair.webp                ← source (≤ 1024×1024, WebP q=80)
  │    ├─ chair@thumb.webp          ← 96×96    (~3 KB)
  │    ├─ chair@medium.webp         ← 384×384  (~15 KB)
  │    ├─ chair@shadow.webp         ← silhouette for "shadow" mode
  │    └─ chair@micro.webp          ← extreme zoom crop for "micro" mode
  ├─ tech/…
  ├─ space/…
  ├─ sport/…
  └─ professions/…
```

`items.image_path` stores **only** the source path (`home_tools/chair.webp`).
The client appends a variant suffix at request time, so we can add new
variants later (e.g. `@blur`, `@mosaic`) without a DB migration.

## 2. Pipeline for adding 1,000 images

A one-shot Node/Deno script (`tools/ingest_assets.ts`) runs locally:

1. Reads a CSV: `slug,category,source_url,license,attribution`.
2. Downloads source (or pulls from Iconify / Noun Project / Unsplash via
   API — all free-tier friendly).
3. Uses `sharp` to produce the four variants above (WebP, q=80, strip
   EXIF). Total size budget: **≤ 25 KB per item across all variants**
   → 1,000 items × 25 KB = **~25 MB total** in Storage.
4. Uploads via Supabase Storage SDK with `cacheControl: '31536000,
   immutable'` so the CDN caches forever. Filenames are content-hashed
   on rebuild to bust caches when an image actually changes.
5. Inserts/updates the `items` row including the JSONB `names` payload
   produced by step 6.

### 6. Translating one item into 50+ languages

We do **not** ask humans to type 50 translations per item. Instead the
ingest script calls a single bulk-translate endpoint (DeepL / Google
Translate / NLLB-200 self-hosted) **once per item**, then a human
reviewer only spot-checks the three or four right-to-left and CJK rows.
The output is shoved straight into `items.names` (JSONB) so the
50-language `CHECK` constraint passes on first insert.

## 3. Client delivery

* **CDN.** Supabase Storage is fronted by a global CDN; we always
  request the public URL pattern `…/visual-assets/<path>?variant=thumb`.
* **HTTP/2 + WebP.** A 96×96 thumb is ~3 KB, so an entire 20-card
  "speed round" fits in **~60 KB** — one round-trip on 3G.
* **Lazy load + prefetch one ahead.** The card view loads the *current*
  card at `medium`, prefetches the *next* card at `thumb`, and only
  upgrades to `full` when the user requests "see the full picture".
* **On-device cache.** `cached_network_image` (or a small Hive box for
  bytes) keeps the last ~20 MB on disk. With 25 KB / item that is
  ~800 items cached locally — most of the catalogue.
* **Variant per challenge mode.** The client maps
  `challenge_modes.asset_variant` → URL suffix:
  `speed→@medium`, `shadow→@shadow`, `micro→@micro`. This is why the
  variant list is column-typed (`text[]`) on `items` — adding a new
  mode is a one-row insert in `challenge_modes` plus an ingest re-run
  for the new suffix.

## 4. Why this scales past 1,000

| Concern                         | Mitigation                                              |
|---------------------------------|---------------------------------------------------------|
| App size bloat                  | Zero images in the binary. Ship icons only (Material).  |
| First-paint latency             | 3 KB thumbnails over HTTP/2.                            |
| Bandwidth cost on Supabase free | 25 MB total source × CDN cache → near-zero egress.      |
| Adding category #6 later        | New folder + insert into `categories`. No DB migration. |
| Image takedown / license issue  | Update one Storage object; CDN purge by path.           |
| Offline play                    | Hive cache + "download pack" button per category.       |

## 5. UI principles (icon-first)

The selector and home screens deliberately use **emoji + Material
Icons** instead of localised strings, so a brand-new user from any
country can navigate before we know which language to render UI chrome
in. See `app/lib/features/language_selector/language_selector_screen.dart`:
the AppBar title is literally `🌐 → 🗣️`, and each language card shows
flag + the language's *own* name in its *own* script.
