---
name: versely-ugc
version: 1.0.0
description: >
  Create UGC-style videos with video overlays, text captions, and auto-timed
  captions from speech. Overlay a talking-head video on product footage, add
  styled captions, remove backgrounds, and generate voiceovers.
  Use when the user wants to create UGC content, add captions, or overlay videos.
allowed-tools: Bash, Read
metadata:
  agentskills.io:
    category: content-creation
    homepage: https://versely.studio
    tags: ["ugc", "captions", "video-overlay", "user-generated-content"]
---

# Versely UGC — User Generated Content Video Creation

Create UGC-style videos: overlay talking-head video on product footage, add styled captions, auto-time captions from speech, and generate voiceovers.

## Authentication

```bash
VERSELY_API_KEY="vsk_..."
VERSELY_API_URL="https://api.versely.studio"
```

For `/api/v1/ugc/*` endpoints: do NOT send `user_id` — the API key resolves the user server-side.

**Exception:** `/api/v1/captions/auto` and `/api/v1/captions/tts-voiceover` REQUIRE `user_id` in the body (the captions routes don't apply the `enforceUserId` middleware). `/captions/preview` and `/captions/edit` accept it but don't enforce it. To stay consistent, always include `user_id` when calling `/captions/*`.

## Required API Key Scope

**Scope:** `ugc`. Covers both `/ugc/*` (overlay, captions, background removal, compose) and `/captions/*` (auto, preview, edit, tts-voiceover).

Create a key with `{"scopes": ["ugc"]}` via `POST /api/v1/auth/api-keys`. Live scope catalog: `GET /api/v1/auth/api-keys/scopes`.

## Video Overlay

**Endpoint:** `POST /api/v1/ugc/add-video-overlay`

Overlay one video on top of another (e.g., talking-head on product demo).

```bash
curl -X POST "$VERSELY_API_URL/api/v1/ugc/add-video-overlay" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "slideshow_video_url": "https://example.com/product-demo.mp4",
    "overlay_video_url": "https://example.com/talking-head.mp4",
    "position": "bottom-right",
    "overlay_size": "medium",
    "remove_black_background": false
  }'
```

**Fields:**
- `slideshow_video_url` (required): Base/background video URL
- `overlay_video_url` (required): Video to overlay on top
- `position` (required): `"top-left"` | `"top-right"` | `"bottom-left"` | `"bottom-right"` | `"center"`
- `overlay_size` (optional): `"small"` (25%) | `"medium"` (30%, default) | `"large"` (45%) — overlay size as a percentage of the base video
- `overlay_scale` (optional): Numeric scale percentage (20-200). Takes priority over `overlay_size` if provided.
- `overlay_x`, `overlay_y` (optional): Custom pixel position; overrides `position` when both are set
- `remove_black_background` (optional): Remove black pixels from overlay video
- `background_image_url` (optional): Custom background when removing black
- `key_similarity` (optional): 0.01-0.40, default 0.15 — how close a pixel must be to pure black to be removed (only used when `remove_black_background` is true)
- `key_blend` (optional): 0.0-0.5, default 0.10 — softness of the alpha edge (only used when `remove_black_background` is true)

**Response:**
```json
{
  "success": true,
  "data": {
    "ugc_video_id": "uuid",
    "video_url": "https://...",
    "position": "bottom-right",
    "overlay_size": "medium"
  }
}
```

## Add Text Captions

**Endpoint:** `POST /api/v1/ugc/add-captions`

Burn static text captions onto a video.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/ugc/add-captions" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "video_url": "https://example.com/video.mp4",
    "caption_text": "This product changed my life!",
    "position": "bottom",
    "font_size": 48,
    "font_color": "white",
    "background": "gradient"
  }'
```

**Fields:**
- `video_url` (required): Video to caption
- `caption_text` (required): Text content (max 500 characters)
- `position` (required): `"top"` | `"middle"` | `"bottom"`
- `font_size` (optional): 8-200 pixels, default 48
- `font_family` (optional): Font name, default `"Arial"`
- `font_color` (optional): Color name (`white`, `black`, `red`, `yellow`, `green`, `blue`, `orange`, `cyan`) or hex (`#FF0000`). Default: `"white"`
- `background` (optional): `"solid"` (~50% opacity black box, default) | `"gradient"` (~75% opacity black box) | `"none"`
- `outline_width` (optional): Pixels — outline/stroke around text characters
- `outline_color` (optional): Color name or hex for the text outline

**Response:**
```json
{
  "success": true,
  "data": {
    "video_url": "https://...",
    "caption_text": "This product changed my life!",
    "position": "bottom",
    "font_size": 48,
    "font_color": "white",
    "background": "gradient"
  }
}
```

## Auto-Timed Captions (Speech-to-Text)

**Endpoint:** `POST /api/v1/captions/auto`

Automatically detect speech in a video, generate timed captions, and burn them in.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/captions/auto" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "<your-user-uuid>",
    "video_url": "https://example.com/talking-video.mp4",
    "words_per_segment": 3,
    "return_srt": true,
    "style": {
      "fontsize": 56,
      "fontcolor": "yellow",
      "position": "bottom",
      "highlight": true
    }
  }'
```

**Fields:**
- `video_url` (required): Video with speech
- `words_per_segment` (optional): Words per caption segment, default 3
- `return_srt` (optional): Return SRT subtitle file URL
- `style` (optional):
  - `fontsize`: Caption font size (default 48)
  - `fontcolor`: Color (default `"white"`)
  - `position`: `"top"` | `"middle"` | `"bottom"` (default)
  - `highlight`: Highlight words as spoken (default `false`)

**Response:**
```json
{
  "success": true,
  "video_url": "https://...",
  "srt_url": "https://...",
  "caption_count": 12,
  "word_count": 36,
  "segments": [
    { "text": "This product changed", "start": 0.5, "end": 1.2 },
    { "text": "my life completely", "start": 1.2, "end": 2.0 }
  ]
}
```

## Preview Captions (Without Burning)

**Endpoint:** `POST /api/v1/captions/preview`

Get transcript and timing without burning captions — useful for previewing or editing.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/captions/preview" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "video_url": "https://example.com/video.mp4",
    "words_per_segment": 3
  }'
```

**Response includes both segments and individual words with timestamps.**

## Edit Caption Timing

**Endpoint:** `POST /api/v1/captions/edit`

Apply manually-edited caption timing to a video.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/captions/edit" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "video_url": "https://example.com/video.mp4",
    "segments": [
      { "text": "Custom caption", "start": 0.0, "end": 2.5 },
      { "text": "Another line", "start": 3.0, "end": 5.0 }
    ],
    "style": { "fontsize": 56, "fontcolor": "white", "position": "bottom" }
  }'
```

## TTS Voiceover + Captions

**Endpoint:** `POST /api/v1/captions/tts-voiceover`

Generate text-to-speech voiceover, overlay it on a video, and auto-sync captions.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/captions/tts-voiceover" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "<your-user-uuid>",
    "video_url": "https://example.com/background-video.mp4",
    "text": "This product is amazing. Let me show you why.",
    "voice_id": "Wise_Woman",
    "style": { "fontsize": 48, "position": "bottom" }
  }'
```

**Response:**
```json
{
  "success": true,
  "video_url": "https://...",
  "audio_url": "https://...",
  "caption_count": 4,
  "duration": 8.5,
  "segments": [...]
}
```

## Compose-With-Overlay (Multi-Clip Base)

**Endpoint:** `POST /api/v1/ugc/compose-with-overlay`

The newer, more flexible overlay endpoint. Stitches together a series of base clips (mix of images and videos), applies a single talking-head/overlay video on top, with per-clip trim ranges and unified output aspect.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/ugc/compose-with-overlay" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "base_media": [
      { "kind": "image", "url": "https://example.com/intro.jpg",   "duration_sec": 2 },
      { "kind": "video", "url": "https://example.com/clipA.mp4",   "start_sec": 0, "end_sec": 5 },
      { "kind": "video", "url": "https://example.com/clipB.mp4" }
    ],
    "overlay_video_url": "https://example.com/talking-head.mp4",
    "position": "bottom-right",
    "overlay_size": "medium",
    "remove_black_background": true,
    "output_aspect": "9:16"
  }'
```

**Fields:**
- `base_media` (required): Non-empty array of `{ kind: "image" | "video", url, duration_sec?, start_sec?, end_sec? }`
  - Images: `duration_sec` (>0, ≤600s) is required — how long to hold the image
  - Videos: `start_sec` and `end_sec` are optional but must be set together; `end_sec > start_sec`. If omitted, the full clip plays.
- `overlay_video_url` (required): Talking-head / overlay video
- `position`, `overlay_size`, `overlay_scale`, `overlay_x/y`, `remove_black_background`, `background_image_url`, `key_similarity`, `key_blend` — same as `/add-video-overlay`
- `output_aspect` (optional): `"9:16"` (default) | `"16:9"` | `"1:1"` | `"4:5"`

Use this instead of `/add-video-overlay` when your base is a mix of images and videos, or when you need per-clip trims.

## Timestamped Captions (Pre-Computed Segments)

**Endpoint:** `POST /api/v1/ugc/add-timestamped-captions`

Burn captions onto a video using a pre-computed segment list (no STT runs). Use this when you already have transcript timing — e.g., from an external tool, manual edit, or chaining `/captions/preview` → human edit → burn.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/ugc/add-timestamped-captions" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "<your-user-id>",
    "video_url": "https://example.com/video.mp4",
    "captions": [
      { "start_sec": 0.0, "end_sec": 1.5, "text": "Hello world" },
      { "start_sec": 1.5, "end_sec": 3.2, "text": "Welcome to the demo" }
    ],
    "caption_size": "medium",
    "position": "bottom",
    "font_color": "white",
    "font_family": "Arial",
    "outline_width": 2,
    "outline_color": "black"
  }'
```

**Fields:**
- `user_id` (required) — `/ugc/*` enforces it via middleware, but the controller also validates it explicitly
- `video_url` (required)
- `captions` (required): Non-empty array of `{ start_sec, end_sec, text }`. `end_sec > start_sec`, text 1-200 chars
- `caption_size` (optional): `small` | `medium` (default) | `large` | `xl`
- `position` (optional): `top` | `middle` | `bottom` (default)
- `font_color`, `font_family`, `outline_width`, `outline_color` — styling, same as static captions

Errors: `400` for invalid timing/text; `402` for insufficient credits.

This is the burn-side counterpart to `/captions/preview` (which produces but doesn't burn).

## Remove Black Background

**Endpoint:** `POST /api/v1/ugc/remove-black-background`

Remove black pixels from a video (useful for overlay cleanup).

```bash
curl -X POST "$VERSELY_API_URL/api/v1/ugc/remove-black-background" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "video_url": "https://example.com/video-with-black-bg.mp4",
    "background_image_url": "https://example.com/custom-background.jpg"
  }'
```

## Full UGC Pipeline Example

Create a UGC product review: generate product video → add talking head → add captions.

```bash
# 1. Generate a product video (using versely-generate skill)
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 Text to Video",
    "prompt": "Sleek product reveal of a wireless earbuds case on white surface",
    "duration": "10",
    "aspect_ratio": "9:16"
  }')
REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId')

# 2. Wait for product video
for i in $(seq 1 60); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$REQUEST_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo $STATUS | jq -r '.status')
  if [ "$STATE" = "completed" ]; then
    PRODUCT_VIDEO=$(echo $STATUS | jq -r '.result_url')
    break
  fi
  sleep 10
done

# 3. Overlay talking-head video
OVERLAY=$(curl -s -X POST "$VERSELY_API_URL/api/v1/ugc/add-video-overlay" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"slideshow_video_url\": \"$PRODUCT_VIDEO\",
    \"overlay_video_url\": \"https://example.com/talking-head.mp4\",
    \"position\": \"bottom-right\",
    \"overlay_size\": \"small\"
  }")
UGC_VIDEO=$(echo $OVERLAY | jq -r '.data.video_url')

# 4. Add captions
CAPTIONED=$(curl -s -X POST "$VERSELY_API_URL/api/v1/ugc/add-captions" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"video_url\": \"$UGC_VIDEO\",
    \"caption_text\": \"These earbuds are a game changer!\",
    \"position\": \"top\",
    \"font_size\": 56,
    \"font_color\": \"white\",
    \"background\": \"gradient\"
  }")
FINAL_VIDEO=$(echo $CAPTIONED | jq -r '.data.video_url')
echo "Final UGC video: $FINAL_VIDEO"
```

## Avatar Discovery — `/api/v1/avatar/*`

Read-only discovery endpoints for avatar-driven flows (HeyGen lipsync, talking-head presets). Use these to populate avatar pickers before calling `/generate/video` (with a HeyGen lipsync model) or `/generate/lipsync`.

**Scope note:** `/avatar/*` is mounted under the `generate` scope, not `ugc`. If your UGC pipeline uses avatars, your API key needs **both** `ugc` AND `generate` scopes.

```bash
# Versely's curated avatar URL list (cached in Redis)
curl "$VERSELY_API_URL/api/v1/avatar" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

**Response:**
```json
{
  "success": true,
  "data": [
    { "name": "...", "url": "https://..." },
    ...
  ],
  "message": "Avatar URLs fetched successfully"
}
```

```bash
# HeyGen avatars — the canonical name list FAL accepts, plus HeyGen preview images
curl "$VERSELY_API_URL/api/v1/avatar/heygen" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# HeyGen voices — FAL-accepted voice names with HeyGen metadata
curl "$VERSELY_API_URL/api/v1/avatar/heygen/voices" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

The `name` returned by `/avatar/heygen` is what you pass as the `avatar_name` parameter when generating HeyGen lipsync videos via `/generate/video`. Same for `voice_name` from `/avatar/heygen/voices`. Both are cached server-side; FAL's schema is the source of truth for which names are actually valid (the response intersects FAL + HeyGen).

## Error Handling

- **401 Unauthorized** — API key invalid or expired.
- **400 Bad Request** — Missing required fields (e.g., `video_url`, `caption_text`, `position`; for `/captions/auto` and `/captions/tts-voiceover` also `user_id`).
- **403 Forbidden** — API key lacks the `ugc` scope (covers both `/ugc/*` and `/captions/*`), OR account balance ≤ 0 at request entry, OR `user_id` mismatch (for `/ugc/*`).
- **402 Payment Required** — Per-call flat-cost deduction failed: `/ugc/add-video-overlay` (10), `/ugc/add-captions` (5), `/ugc/remove-black-background` (10). Captions endpoints (`/captions/auto`, `/captions/preview`, `/captions/edit`, `/captions/tts-voiceover`) do not deduct credits.
- **429 Too Many Requests** — Rate limited. Check `X-RateLimit-Reset`.
- **500 Internal Server Error** — FFmpeg processing failed. Retry once.
- **File too large** — Max 500MB per video download.
- **Timeout** — FFmpeg has a 5-minute processing timeout.

## Rate Limits

- Default: 60 requests/minute per API key
- Response headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

For complete API schemas, see [api-reference.md](api-reference.md).
