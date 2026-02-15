# API Reference — Versely UGC

Base URL: `$VERSELY_API_URL` (default: `https://api.versely.app`)

All endpoints require `Authorization: Bearer $VERSELY_API_KEY`.

---

## POST /api/v1/ugc/add-video-overlay

Overlay one video on top of another.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `slideshow_video_url` | string | Yes | Base/background video URL |
| `overlay_video_url` | string | Yes | Video to overlay on top |
| `position` | string | Yes | `"top-left"` \| `"top-right"` \| `"bottom-left"` \| `"bottom-right"` \| `"center"` |
| `overlay_size` | string | No | `"small"` (70%) \| `"medium"` (90%, default) \| `"large"` (110%) |
| `remove_black_background` | boolean | No | Remove black pixels from overlay |
| `background_image_url` | string | No | Custom background when removing black |

### Response

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

---

## POST /api/v1/ugc/add-captions

Burn static text captions onto a video.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `video_url` | string | Yes | Video URL to caption |
| `caption_text` | string | Yes | Text content (max 500 chars) |
| `position` | string | Yes | `"top"` \| `"middle"` \| `"bottom"` |
| `font_size` | number | No | 8-200 pixels, default 48 |
| `font_family` | string | No | Font name, default `"Arial"` |
| `font_color` | string | No | Color name or hex `#RRGGBB`, default `"white"` |
| `background` | string | No | `"solid"` (default) \| `"gradient"` \| `"none"` |

### Response

```json
{
  "success": true,
  "data": {
    "video_url": "https://...",
    "caption_text": "...",
    "position": "bottom",
    "font_size": 48,
    "font_color": "white",
    "background": "gradient"
  }
}
```

---

## POST /api/v1/ugc/remove-black-background

Remove black pixels from a video.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `video_url` | string | Yes | Video to process |
| `background_image_url` | string | No | Custom replacement background |

### Response

```json
{
  "success": true,
  "data": {
    "ugc_video_id": "uuid",
    "video_url": "https://...",
    "has_custom_background": true
  }
}
```

---

## GET /api/v1/ugc/:id

Get a single UGC video by ID.

### Response

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "slideshow_video_url": "https://...",
    "overlay_video_url": "https://...",
    "position": "bottom-right",
    "overlay_size": 90,
    "final_video_url": "https://...",
    "status": "completed",
    "created_at": "ISO 8601"
  }
}
```

---

## POST /api/v1/ugc/user/:userId

List user's UGC videos (paginated).

### Request Body

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | number | 20 | Max 100 |
| `offset` | number | 0 | Pagination offset |

### Response

```json
{
  "success": true,
  "data": {
    "videos": [...],
    "total": 15,
    "limit": 20,
    "offset": 0
  }
}
```

---

## POST /api/v1/captions/auto

Auto-detect speech and burn timed captions.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `video_url` | string | Yes | Video with speech |
| `words_per_segment` | number | No | Words per caption group (default: 3) |
| `return_srt` | boolean | No | Return SRT file URL |
| `style.fontsize` | number | No | Font size (default: 48) |
| `style.fontcolor` | string | No | Color (default: `"white"`) |
| `style.position` | string | No | `"top"` \| `"middle"` \| `"bottom"` (default) |
| `style.highlight` | boolean | No | Highlight words as spoken |

### Response

```json
{
  "success": true,
  "video_url": "https://...",
  "srt_url": "https://...",
  "caption_count": 12,
  "word_count": 36,
  "segments": [
    { "text": "Hello everyone", "start": 0.5, "end": 1.2 }
  ]
}
```

---

## POST /api/v1/captions/preview

Preview captions without burning (transcript + timing only).

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `video_url` | string | Yes | Video to analyze |
| `words_per_segment` | number | No | Words per segment (default: 3) |

### Response

```json
{
  "success": true,
  "caption_count": 12,
  "word_count": 36,
  "segments": [{ "text": "...", "start": 0.5, "end": 1.2 }],
  "words": [{ "word": "Hello", "start": 0.5, "end": 0.7 }]
}
```

---

## POST /api/v1/captions/edit

Apply manually-edited caption timing.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `video_url` | string | Yes | Video to caption |
| `segments` | array | Yes | `[{ text: "...", start: 0.0, end: 2.5 }]` |
| `style` | object | No | Font/position settings (same as auto) |

### Response

```json
{
  "success": true,
  "video_url": "https://...",
  "caption_count": 5,
  "segments": [...]
}
```

---

## POST /api/v1/captions/tts-voiceover

Generate TTS voiceover, overlay on video, and auto-sync captions.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `video_url` | string | Yes | Background video |
| `text` | string | Yes | Voiceover script |
| `voice_id` | string | Yes | TTS voice ID (e.g., `"Wise_Woman"`) |
| `style.fontsize` | number | No | Caption font size (default: 48) |
| `style.position` | string | No | Caption position (default: `"bottom"`) |

### Response

```json
{
  "success": true,
  "video_url": "https://...",
  "audio_url": "https://...",
  "caption_count": 8,
  "duration": 12.5,
  "segments": [...]
}
```

---

## Supported Colors

Named colors: `white`, `black`, `red`, `yellow`, `green`, `blue`, `orange`, `cyan`

Hex colors: Any `#RRGGBB` format (e.g., `#FF6B35`)

---

## File Limits

| Limit | Value |
|-------|-------|
| Max video download | 500 MB |
| Download timeout | 60 seconds |
| FFmpeg processing timeout | 5 minutes |
| Max caption length | 500 characters |
| Font size range | 8-200 pixels |

---

## Rate Limits

| Scope | Limit |
|-------|-------|
| Default (per API key) | 60 req/min |

## Error Codes

| Status | Meaning |
|--------|---------|
| 400 | Missing required fields |
| 401 | Invalid API key |
| 403 | Access denied / wrong scope |
| 404 | UGC video not found |
| 429 | Rate limited |
| 500 | FFmpeg processing error |
