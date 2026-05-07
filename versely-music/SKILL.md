---
name: versely-music
version: 1.0.0
description: >
  Full Suno music API — generate, extend, mashup, replace sections, separate
  vocals, generate covers/personas/MIDI, and create sound effects. Covers all
  ~24 Suno endpoints. Use when the user wants to make music, modify existing
  tracks, separate stems, or generate sound effects.
allowed-tools: Bash, Read
metadata:
  agentskills.io:
    category: content-creation
    homepage: https://versely.studio
    tags: ["music", "audio", "suno", "lyrics", "vocals", "stems", "midi", "sound-effects"]
---

# Versely Music — Suno-Powered Music & Audio

The full Suno surface, separated from `versely-generate` because there's a lot of it.

**What lives here:**
1. **Music** — generate, extend, mashup, replace section, cover-from-upload
2. **Lyrics** — generate, fetch timestamped lyrics
3. **Audio processing** — separate vocals, convert to WAV, generate MIDI, add instrumental, add vocals
4. **Style/persona** — boost-style, generate-persona
5. **Cover artwork** — generate-cover
6. **Sound effects** — generate-sounds (V5 / V5_5 or legacy)

For non-Suno audio (lipsync TTS, voiceover via Cartesia/RunPod, generic audio generation) use **versely-generate** or **versely-ugc**.

## Authentication

```bash
VERSELY_API_KEY="vsk_..."
VERSELY_API_URL="${VERSELY_API_URL:-https://api.versely.studio}"
```

All requests use `Authorization: Bearer $VERSELY_API_KEY`.

**Note on `user_id`:** the `/suno/*` controllers explicitly check `user_id` in the body. The `enforceUserId` middleware injects it from your API key automatically, so you don't need to send it — but if you do, it must match the key's user.

## Required API Key Scope

**Scope:** `generate`. Same scope as `/generate/*`. No separate `music` scope.

Create with `{"scopes": ["generate"]}` via `POST /api/v1/auth/api-keys`. Live catalog: `GET /api/v1/auth/api-keys/scopes`.

## Suno Models — `model` field

Valid models for any endpoint that accepts `model`: `V3_5`, `V4`, `V4_5`, `V4_5PLUS`, `V4_5ALL`, `V5`, `V5_5`.

Pricing scales with model — V5/V5_5 are the most expensive but highest quality.

## Universal Polling Pattern — `taskId`

Every async Suno endpoint returns `{ data: { taskId, dbRecordId? } }`. Suno does NOT return the FAL/RunPod-style `data.successful[].data.requestId` — it's just `data.taskId` at the top level.

Two ways to poll:

```bash
# 1. Suno-native task status (richer payload — model-specific fields)
curl "$VERSELY_API_URL/api/v1/suno/task-status?taskId=$TASK_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# 2. Unified status endpoint (works for /suno/generate, /suno/extend, /suno/mashup, /suno/upload-cover, /suno/upload-extend, /suno/replace-section, /suno/add-instrumental, /suno/add-vocals, /suno/generate-sounds)
curl "$VERSELY_API_URL/api/v1/status/$TASK_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Most endpoints have a *dedicated detail endpoint* for richer per-feature output. Use these when polling for a specific feature's outputs (lyrics segments, WAV download, vocal-stem URLs, MIDI URL, sound-effect URL, cover artwork):

| Feature | Detail endpoint |
|---|---|
| Lyrics | `GET /api/v1/suno/lyrics-details?taskId=…` |
| WAV conversion | `GET /api/v1/suno/wav-details?taskId=…` |
| Vocal separation | `GET /api/v1/suno/vocal-separation-details?taskId=…` |
| Cover (artwork) | `GET /api/v1/suno/cover-details?taskId=…` |
| MIDI | `GET /api/v1/suno/midi-details?taskId=…` |
| Sound effects | `GET /api/v1/suno/sound-details?taskId=…` |

---

# 1. Music Generation

## POST /api/v1/suno/generate

The headline endpoint. Two modes:

### Custom mode — full control over style, title, and lyrics

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/generate" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "V5",
    "customMode": true,
    "instrumental": false,
    "style": "Pop, upbeat, electronic, female vocals",
    "title": "Summer Dreams",
    "prompt": "[Verse 1]\nWalking down the beach at sunset\nWith the waves crashing softly\n[Chorus]\nThis is summer dreams..."
  }'
```

**Custom-mode rules:**
- `style` required — max 200 chars for `V3_5`/`V4`, 1000 chars otherwise
- `title` required — max 80 chars
- `prompt` (lyrics) required when `instrumental: false`; max 3000 chars for `V3_5`/`V4`, 5000 chars otherwise

### Simple mode — describe the song, Suno writes everything

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/generate" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "V5",
    "customMode": false,
    "instrumental": true,
    "prompt": "Epic orchestral soundtrack with dramatic crescendos for a movie trailer"
  }'
```

`prompt` max 500 chars in simple mode.

### Optional advanced fields (both modes)

| Field | Type | Notes |
|---|---|---|
| `personaId` | string | Reuse a persona from `/generate-persona` |
| `negativeTags` | string | Styles to avoid |
| `vocalGender` | `"m"` \| `"f"` | |
| `styleWeight` | number 0-1 | How strongly to follow the style |
| `weirdnessConstraint` | number 0-1 | Higher = more experimental |
| `audioWeight` | number 0-1 | |
| `session_id`, `batch_id` | string | Optional grouping for downstream queries |

**Response:** `{ success: true, data: { taskId, dbRecordId } }`. Poll via `/api/v1/status/$TASK_ID`.

## POST /api/v1/suno/extend

Continue an existing generated track from a specific timestamp.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/extend" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "V5",
    "audioId": "<audioId-from-prior-track>",
    "continueAt": 90,
    "prompt": "[Verse 3] Now the night begins to fall...",
    "style": "Pop, upbeat",
    "title": "Summer Dreams (Extended)"
  }'
```

`audioId` comes from the parent track's task-status response (Suno returns one or more `audioId`s per track in its result).

## POST /api/v1/suno/mashup

Mash two existing audio URLs together. Exactly 2 URLs in `uploadUrlList`.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/mashup" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "V5",
    "customMode": true,
    "instrumental": false,
    "uploadUrlList": [
      "https://example.com/song-a.mp3",
      "https://example.com/song-b.mp3"
    ],
    "style": "Indie pop, lo-fi",
    "title": "A meets B",
    "prompt": "..."
  }'
```

## POST /api/v1/suno/replace-section

Re-generate a section of an existing track within a 6-60 second window.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/replace-section" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "<original-track-taskId>",
    "audioId": "<original-track-audioId>",
    "title": "Summer Dreams (v2)",
    "tags": "pop, female vocals",
    "infillStartS": 30,
    "infillEndS": 60,
    "prompt": "Replacement lyrics for this section",
    "fullLyrics": "Optional: full song lyrics for context"
  }'
```

`infillEndS - infillStartS` must be between 6 and 60 seconds.

## POST /api/v1/suno/upload-cover

"Cover" an uploaded audio track using a Suno model — re-render in a different style.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/upload-cover" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "audioUrl": "https://example.com/original.mp3",
    "model": "V5",
    "customMode": true,
    "instrumental": false,
    "style": "Acoustic, fingerstyle guitar",
    "title": "Original Song (Acoustic)",
    "prompt": "<lyrics>"
  }'
```

## POST /api/v1/suno/upload-extend

Extend an uploaded audio track beyond its original length.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/upload-extend" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "audioUrl": "https://example.com/30sec-clip.mp3",
    "model": "V5",
    "customMode": false,
    "instrumental": true,
    "prompt": "Continue the same dreamy synth feel for another 90 seconds"
  }'
```

---

# 2. Lyrics

## POST /api/v1/suno/lyrics

Generate lyrics from a description (no music — just text).

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/lyrics" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "prompt": "A melancholic indie folk song about losing summer" }'
```

Costs 1 credit. Returns `taskId`. Fetch the result with:

```bash
curl "$VERSELY_API_URL/api/v1/suno/lyrics-details?taskId=$TASK_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

## POST /api/v1/suno/timestamped-lyrics

Get word-level timing (karaoke-style) for an existing track.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/timestamped-lyrics" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "taskId": "<track-taskId>", "audioId": "<track-audioId>" }'
```

---

# 3. Audio Processing

## POST /api/v1/suno/separate-vocals

Split a track into vocals + instrumental, or full stem split.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/separate-vocals" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "<track-taskId>",
    "audioId": "<track-audioId>",
    "type": "separate_vocal"
  }'
```

`type`: `"separate_vocal"` (default) or `"split_stem"` (full stems). Result via `/suno/vocal-separation-details`.

## POST /api/v1/suno/convert-wav

Convert an existing track to WAV.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/convert-wav" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "taskId": "<track-taskId>", "audioId": "<track-audioId>" }'
```

Result via `/suno/wav-details`.

## POST /api/v1/suno/generate-midi

Generate MIDI notation from a track.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/generate-midi" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "taskId": "<track-taskId>", "audioId": "<track-audioId>" }'
```

Result via `/suno/midi-details`.

## POST /api/v1/suno/add-instrumental

Add an AI-generated instrumental backing to an uploaded vocal-only audio.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/add-instrumental" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "audioUrl": "https://example.com/acapella.mp3",
    "model": "V4_5",
    "style": "Hip-hop, trap, 808 bass"
  }'
```

## POST /api/v1/suno/add-vocals

Add AI-generated vocals to an uploaded instrumental audio.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/add-vocals" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "audioUrl": "https://example.com/instrumental.mp3",
    "model": "V4_5",
    "style": "Soulful R&B vocals",
    "prompt": "<lyrics>"
  }'
```

---

# 4. Style & Persona

## POST /api/v1/suno/boost-style

Synchronous (no taskId) — enhances a short style description into a richer prompt:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/boost-style" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "content": "lofi chill" }'
```

**Response:** `{ success: true, data: { enhancedStyle: "..." } }`.

## POST /api/v1/suno/generate-persona

Save a "voice fingerprint" from an existing track that can be reused via `personaId` in `/suno/generate`.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/generate-persona" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "<track-taskId>",
    "audioId": "<track-audioId>",
    "name": "Indie female lead",
    "description": "Soft, breathy female vocal with vibrato",
    "vocalStart": 30,
    "vocalEnd": 50
  }'
```

`vocalEnd - vocalStart` must be 10-30 seconds. Synchronous — returns `{ data: { personaId, name, description } }`.

---

# 5. Cover Artwork

## POST /api/v1/suno/generate-cover

Generate album/cover artwork for an existing track.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/generate-cover" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "taskId": "<track-taskId>" }'
```

Result via `/suno/cover-details`.

## POST /api/v1/suno/create-music-video

Render a music video from an existing track (different controller — `general.controller#createMusicVideo`).

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/create-music-video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "taskId": "<track-taskId>", "audioId": "<track-audioId>" }'
```

---

# 6. Sound Effects

## POST /api/v1/suno/generate-sounds

Generate non-music sound effects.

```bash
# Modern API (V5 / V5_5) — preferred
curl -X POST "$VERSELY_API_URL/api/v1/suno/generate-sounds" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "V5",
    "prompt": "Heavy thunder rolling across a mountain valley",
    "soundLoop": false,
    "soundTempo": 60,
    "soundKey": "Am",
    "grabLyrics": false
  }'

# Legacy (no model field — falls back to old endpoint)
curl -X POST "$VERSELY_API_URL/api/v1/suno/generate-sounds" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Heavy thunder rolling across a mountain valley",
    "duration": 5,
    "isLoop": false,
    "bpm": 60,
    "key": "Am"
  }'
```

`prompt` max 500 chars. Result via `/suno/sound-details`.

---

## Common Pipelines

### Full song with cover + WAV

```bash
# 1. Generate the song
TASK=$(curl -s -X POST "$VERSELY_API_URL/api/v1/suno/generate" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "model": "V5", "customMode": false, "instrumental": false,
        "prompt": "Upbeat indie anthem about chasing dreams" }' \
  | jq -r '.data.taskId')

# 2. Poll until done
for i in $(seq 1 60); do
  STATE=$(curl -s "$VERSELY_API_URL/api/v1/status/$TASK" \
    -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.status')
  [ "$STATE" = "completed" ] && break
  sleep 5
done

# 3. Get audioId from suno task-status
DETAIL=$(curl -s "$VERSELY_API_URL/api/v1/suno/task-status?taskId=$TASK" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
AUDIO_ID=$(echo "$DETAIL" | jq -r '.data.response.sunoData[0].id')

# 4. Convert to WAV (parallel) + generate cover artwork (parallel)
curl -X POST "$VERSELY_API_URL/api/v1/suno/convert-wav" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -d "{\"taskId\":\"$TASK\",\"audioId\":\"$AUDIO_ID\"}"

curl -X POST "$VERSELY_API_URL/api/v1/suno/generate-cover" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -d "{\"taskId\":\"$TASK\"}"
```

### Vocals + AI instrumental from your own a cappella

```bash
TASK=$(curl -s -X POST "$VERSELY_API_URL/api/v1/suno/add-instrumental" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "audioUrl": "https://example.com/vox.mp3", "model": "V5", "style": "Funk, brass, groovy" }' \
  | jq -r '.data.taskId')
```

### Section re-generation

Use when one verse comes out worse than the rest:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/replace-section" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId":"$TASK","audioId":"$AUDIO_ID",
    "title":"Replaced verse 2","tags":"pop, female vocals",
    "infillStartS": 60, "infillEndS": 90,
    "prompt": "[Verse 2] Better lyrics this time...",
    "fullLyrics":"<full song lyrics>"
  }'
```

---

---

# Alternative Provider — Google Lyria 3 (`/api/v1/lyria/*`)

Google's music model. Different quality / pricing trade-off vs. Suno — Lyria 3 is synchronous (no taskId polling), produces a finished MP3/WAV in one call, and supports image conditioning. Same `generate` scope.

| Model | Duration | Output | Notes |
|---|---|---|---|
| **Lyria 3 Pro** | up to ~184s | MP3 + WAV | Full songs with verses, choruses, bridges |
| **Lyria 3 Clip** | 30s fixed | MP3 | Faster, optimized for high-volume / shorter assets |

## POST /api/v1/lyria/generate-pro

```bash
curl -X POST "$VERSELY_API_URL/api/v1/lyria/generate-pro" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "An uplifting indie pop anthem about chasing dreams, with bright synth and driving drums"
  }'
```

## POST /api/v1/lyria/generate-clip

Same body shape — produces a 30-second clip:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/lyria/generate-clip" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Lo-fi chill loop with soft piano and rain ambience"
  }'
```

**Body (both endpoints):**
- `prompt` (required if no `image_url`) — text description; can include lyrics
- `image_url` (optional) — Lyria conditions the music on the image's mood. Either `prompt` or `image_url` must be set; both can be supplied.

**Response — synchronous, includes the final URL:**
```json
{
  "success": true,
  "audio_url": "https://...mp3",
  "lyrics": "Verse 1: ...",
  "model": "Lyria 3 Pro",
  "credits_charged": 5,
  "id": "<user_audios row id>"
}
```

Because Lyria is synchronous, **don't poll `/status/:id`** — the URL is in the response. Insufficient credits return `402`; if Lyria's API returns no audio, the backend auto-refunds and returns `500`.

## GET /api/v1/lyria/models

```bash
curl "$VERSELY_API_URL/api/v1/lyria/models" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Returns the static catalog (id, description, duration, supports_images, supports_lyrics).

### Lyria vs Suno — picking one

| Want | Use |
|---|---|
| Async with rich post-processing (extend, mashup, replace-section, stems, MIDI, persona) | **Suno** (`/suno/generate`) |
| Quick synchronous full song from a prompt | **Lyria 3 Pro** |
| 30s clip with image conditioning | **Lyria 3 Clip** |
| Karaoke timing, vocal separation, cover artwork | **Suno** (Lyria has no equivalents) |

---

## Error Handling

- `400` — missing required field (most endpoints require `user_id`, `taskId`, `audioId`, or model-specific params).
- `401` — invalid / expired API key.
- `402` — insufficient credits.
- `403` — wrong scope (need `generate`).
- `500` — Suno upstream error or "No taskId returned" (credits are auto-refunded).

## Rate Limits

- Default: 60 req/min per API key.
- Generation endpoints (`/suno/*` POST that triggers a Suno API call): 30 req/min, IP-based (cost-sensitive).
- Detail endpoints (`/suno/*-details`, `/suno/task-status`): default bucket only.

## Credit Costs (approximate)

| Endpoint | Cost |
|---|---|
| `/suno/generate` (V5, V5_5) | ~5 credits/track via API |
| `/suno/generate` (V4_5, V4_5PLUS, V4_5ALL) | ~3 credits/track |
| `/suno/generate` (V3_5, V4) | ~2 credits/track |
| `/suno/lyrics` | 1 credit |
| `/suno/separate-vocals`, `/convert-wav`, `/generate-midi`, `/generate-cover`, `/generate-persona` | 1 credit each |
| `/suno/replace-section`, `/extend`, `/mashup`, `/upload-cover`, `/upload-extend`, `/add-instrumental`, `/add-vocals` | model-priced (same as `/generate`) |
| `/suno/generate-sounds` (V5/V5_5) | ~2 credits |
| `/suno/generate-sounds` (legacy) | 1 credit |
| `/suno/boost-style` | free (synchronous helper) |
