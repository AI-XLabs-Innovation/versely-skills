# API Reference — Versely Slideshow

Base URL: `$VERSELY_API_URL` (default: `https://api.versely.app`)

All endpoints require `Authorization: Bearer $VERSELY_API_KEY`.

---

## POST /api/v1/slideshow/create

Create a new slideshow with AI-generated images.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `prompt` | string | Yes | Main prompt for all images |
| `num_images` | number | No | 0-20, default 5 |
| `model` | string | No | Default: `"Flux Pro Ultra"`. Also: `"Recraft V3 Image"`, `"Reve Text to Image"`, `"Imagen 4 Ultra"` |
| `content_type` | string | No | `"reel"` (9:16), `"story"` (9:16), `"post"` (1:1), `"landscape"` (16:9), `"portrait"` (4:5) |
| `aspect_ratio` | string | No | Override content_type: `"9:16"`, `"16:9"`, `"1:1"`, `"4:5"` |
| `style` | string | No | Visual style: `"cinematic"`, `"minimal"`, etc. |
| `theme` | string | No | Theme: `"fantasy"`, `"nature"`, `"urban"` |

### Response

```json
{
  "success": true,
  "data": {
    "slideshow_id": "uuid",
    "status": "completed | partial | failed",
    "total_requested": 5,
    "total_generated": 5,
    "total_failed": 0,
    "images": [
      { "id": "uuid", "order": 1, "url": "https://...", "prompt": "..." }
    ],
    "settings": {
      "model": "Flux Pro Ultra",
      "aspect_ratio": "9:16",
      "content_type": "reel"
    }
  }
}
```

---

## GET /api/v1/slideshow/:id

Get slideshow details with all images.

### Response

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "prompt": "...",
    "num_images": 5,
    "model": "Flux Pro Ultra",
    "status": "completed",
    "aspect_ratio": "9:16",
    "content_type": "reel",
    "images": [
      { "id": "uuid", "image_url": "https://...", "prompt": "...", "order_index": 1, "media_type": "image" }
    ],
    "video_url": "https://... | null",
    "has_edited_images": false,
    "created_at": "ISO 8601"
  }
}
```

---

## POST /api/v1/slideshow/:id/images

Add more AI-generated images to an existing slideshow.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `prompt` | string | No | Uses slideshow's prompt if not provided |
| `num_images` | number | No | Default: 3 |
| `model` | string | No | Uses slideshow's model if not provided |

---

## PUT /api/v1/slideshow/:id/reorder

Reorder slideshow images.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `image_order` | array | Yes | `[{ "image_id": "uuid", "order_index": 1 }]` |

---

## POST /api/v1/slideshow/:id/upload-media

Upload custom image or video to slideshow.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `media_data` | string | Yes | Base64-encoded binary data |
| `media_type` | string | No | `"image"` (default) or `"video"` |
| `mime_type` | string | No | e.g., `"image/jpeg"`, `"video/mp4"` |
| `duration` | number | Videos | Duration in seconds (required for videos) |

---

## POST /api/v1/slideshow/:id/upload-audio

Upload audio for video generation.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `audio_data` | string | Yes | Base64-encoded audio |
| `mime_type` | string | No | e.g., `"audio/mpeg"` |

### Response

```json
{
  "success": true,
  "data": { "audio_url": "https://...", "filename": "...", "file_size": 12345 }
}
```

---

## POST /api/v1/slideshow/:id/text-overlay

Add text overlays to slideshow images. Creates edited copies; originals preserved.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `overlays` | array | Yes | Array of overlay objects (see below) |

**Overlay object:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `image_id` | string | Yes | Image ID from slideshow |
| `text` | string | Yes | Text content |
| `position` | string | No | `"top"` \| `"center"` \| `"bottom"` (default) |
| `x` | number | No | Custom X position (0-100%) |
| `y` | number | No | Custom Y position (0-100%) |
| `font_size` | number | No | `< 1` = % of height, `>= 1` = pixels |
| `font_family` | string | No | Font name |
| `style` | string | No | `"default"` \| `"bold"` \| `"light"` \| `"shadow"` \| `"outline"` |
| `background` | string | No | `"none"` \| `"solid"` \| `"gradient"` |
| `background_padding` | number | No | 0.1-0.8 (default: 0.3) |
| `rotation` | number | No | 0-360 degrees |
| `stroke_color` | string | No | Hex color, e.g., `"#000000"` |
| `stroke_width` | number | No | 0-10 pixels (default: 2) |

### Response

```json
{
  "success": true,
  "data": {
    "slideshow_id": "uuid",
    "total_processed": 5,
    "success_count": 5,
    "fail_count": 0,
    "images": [
      { "success": true, "image_id": "uuid", "original_url": "...", "edited_url": "...", "text": "...", "position": "bottom" }
    ]
  }
}
```

---

## GET /api/v1/slideshow/:id/edited

Get all edited (text-overlaid) images.

### Response

```json
{
  "success": true,
  "data": {
    "slideshow_id": "uuid",
    "has_edited_images": true,
    "edited_images": [
      { "id": "uuid", "original_image_url": "...", "edited_image_url": "...", "overlay_text": "...", "text_position": "bottom", "order_index": 1 }
    ],
    "total_count": 5
  }
}
```

---

## DELETE /api/v1/slideshow/:id/edited

Delete all edited versions (preserves originals).

---

## POST /api/v1/slideshow/:id/video

Convert slideshow to video.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `duration_per_image` | number | No | 0.5-30 seconds, default: 3 |
| `transition` | string | No | `"none"` (default) \| `"fade"` \| `"crossfade"` |
| `output_resolution` | string | No | `"720p"` \| `"1080p"` (default) \| `"4k"` |
| `use_edited_images` | boolean | No | Use text-overlaid versions. Default: `false` |
| `voiceover_url` | string | No | Voiceover audio (100% volume) |
| `music_url` | string | No | Background music (30% volume) |
| `aspect_ratio` | string | No | Override slideshow aspect ratio |

### Response

```json
{
  "success": true,
  "data": {
    "slideshow_id": "uuid",
    "video_url": "https://...",
    "duration_seconds": 15,
    "resolution": "1080p",
    "image_count": 5,
    "has_audio": true
  }
}
```

### Resolution Mapping

| Setting | 16:9 | 9:16 |
|---------|------|------|
| 720p | 1280x720 | 720x1280 |
| 1080p | 1920x1080 | 1080x1920 |
| 4k | 3840x2160 | 2160x3840 |

---

## GET /api/v1/slideshow/:id/video

Check if video exists and get details.

---

## POST /api/v1/slideshow/user/list

List user's slideshows (paginated).

### Query Parameters

| Param | Default | Description |
|-------|---------|-------------|
| `limit` | 20 | Results per page |
| `offset` | 0 | Pagination offset |

---

## DELETE /api/v1/slideshow/:id

Delete a slideshow and all its images/videos.

---

## GET /api/v1/slideshow/models

Get supported models and aspect ratios.

### Response

```json
{
  "success": true,
  "data": {
    "models": ["Flux Pro Ultra", "Recraft V3 Image", "Reve Text to Image", "Imagen 4 Ultra"],
    "aspect_ratios": {
      "reel": "9:16",
      "story": "9:16",
      "post": "1:1",
      "landscape": "16:9",
      "portrait": "4:5"
    },
    "content_types": ["reel", "story", "post", "landscape", "portrait"]
  }
}
```

---

## Rate Limits

| Scope | Limit |
|-------|-------|
| Default (per API key) | 60 req/min |
| Generation endpoints | 20 req/min |

## Error Codes

| Status | Meaning |
|--------|---------|
| 400 | Missing required fields |
| 401 | Invalid/expired API key |
| 402 | Insufficient credits |
| 403 | API key lacks scope |
| 404 | Slideshow not found |
| 429 | Rate limited |
| 500 | Server error |
