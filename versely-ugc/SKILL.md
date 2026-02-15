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
    homepage: https://versely.app
    tags: ["ugc", "captions", "video-overlay", "user-generated-content"]
---

# Versely UGC — User Generated Content Video Creation

Create UGC-style videos: overlay talking-head video on product footage, add styled captions, auto-time captions from speech, and generate voiceovers.

## Authentication

```bash
VERSELY_API_KEY="vsk_..."
VERSELY_API_URL="https://api.versely.app"
```

Do NOT send `user_id` — the API key resolves the user server-side.

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
- `overlay_size` (optional): `"small"` (70%) | `"medium"` (90%, default) | `"large"` (110%)
- `remove_black_background` (optional): Remove black pixels from overlay video
- `background_image_url` (optional): Custom background when removing black

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
- `background` (optional): `"solid"` (50% opacity, default) | `"gradient"` (70% opacity) | `"none"`

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

## Error Handling

- **401 Unauthorized** — API key invalid or expired.
- **400 Bad Request** — Missing required fields (video_url, caption_text, position).
- **403 Forbidden** — API key lacks required scope.
- **429 Too Many Requests** — Rate limited. Check `X-RateLimit-Reset`.
- **500 Internal Server Error** — FFmpeg processing failed. Retry once.
- **File too large** — Max 500MB per video download.
- **Timeout** — FFmpeg has a 5-minute processing timeout.

## Rate Limits

- Default: 60 requests/minute per API key
- Response headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

For complete API schemas, see [api-reference.md](api-reference.md).
