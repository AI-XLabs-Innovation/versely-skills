# API Reference — Versely Generate

Base URL: `$VERSELY_API_URL` (default: `https://api.versely.app`)

All endpoints require `Authorization: Bearer $VERSELY_API_KEY` header.

---

## POST /api/v1/generate/image

Generate one or more images from text (or edit with an input image).

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `model` | string \| string[] | Yes | Model name(s). Array for multi-model generation. |
| `prompt` | string | Yes* | Text description. *Not required for upscale/bg-removal models. |
| `aspect_ratio` | string | No | `"1:1"` \| `"16:9"` \| `"9:16"` \| `"4:3"` \| `"3:4"` |
| `num_images` | number | No | 1-4 images per request. Default: 1 |
| `style` | string | No | Style hint: `"realistic"` \| `"artistic"` \| `"cartoon"` etc. |
| `image_url` | string | No | Input image URL for editing models |
| `images` | string[] | No | Array of input image URLs |
| `image_urls` | string[] | No | Array of input image URLs (alias) |
| `scale` | string \| number | No | Upscale factor: `"2x"` \| `"4x"` \| `2` \| `4` |

### Response

```json
{
  "success": true,
  "data": {
    "successful": [
      {
        "success": true,
        "data": {
          "requestId": "abc123",
          "status": "IN_QUEUE",
          "queuePosition": 0,
          "model": "Flux Pro Ultra",
          "isVideoModel": false,
          "recordId": "uuid-1234"
        },
        "message": "FAL generation request submitted successfully"
      }
    ],
    "failed": [],
    "total": 1,
    "successCount": 1,
    "failCount": 0
  }
}
```

### curl Example

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Flux Pro Ultra",
    "prompt": "A cozy coffee shop interior, warm lighting, photorealistic",
    "aspect_ratio": "16:9"
  }'
```

---

## POST /api/v1/generate/video

Generate video from text or an input image.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `model` | string \| string[] | Yes | Video model name(s) |
| `prompt` | string | Yes* | Video description |
| `duration` | string \| number | No | Seconds: `"5"` \| `"10"` \| `"15"` |
| `aspect_ratio` | string | No | `"1:1"` \| `"16:9"` \| `"9:16"` |
| `resolution` | string | No | `"720p"` \| `"1080p"` \| `"4k"` |
| `image_url` | string | No | Input image for I2V models |
| `image_urls` | string[] | No | Multiple input images |
| `first_frame_url` | string | No | First frame (VEO models) |
| `last_frame_url` | string | No | Last frame (VEO models) |
| `video_url` | string | No | Input video for V2V models |
| `audio_url` | string | No | Audio for lipsync models |
| `negative_prompt` | string | No | What to avoid (Kling models) |
| `cfg_scale` | number | No | Guidance scale (Kling models) |
| `generate_audio` | boolean | No | Auto-generate audio (Kling) |

### Response

Same structure as image generation. Use `requestId` from `data.successful[0].data.requestId` to poll status.

### curl Example — Text-to-Video

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 Text to Video Pro",
    "prompt": "A drone shot flying over a mountain lake at sunrise",
    "duration": "10",
    "aspect_ratio": "16:9",
    "resolution": "1080p"
  }'
```

### curl Example — Image-to-Video

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 Image to Video",
    "prompt": "Gentle parallax zoom with light particles",
    "image_url": "https://example.com/landscape.jpg",
    "duration": "5"
  }'
```

---

## POST /api/v1/generate/lipsync

Generate lipsync video from an image and audio.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `model` | string | Yes | Lipsync model name |
| `image_url` | string | Model-dependent | Face/person image |
| `image_urls` | string[] | Model-dependent | Multiple images |
| `audio_url` | string | Most models | Audio URL |
| `prompt` | string | No | Description |
| `resolution` | string | No | `"HD"` \| `"720p"` \| `"1080p"` |
| `avatar_id` | string | No | Pre-configured avatar (Kling/Veed) |

### curl Example

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/lipsync" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Infini Talk",
    "image_urls": ["https://example.com/face.jpg"],
    "audio_url": "https://example.com/speech.mp3"
  }'
```

---

## POST /api/v1/generate/story

Generate multi-scene videos (storyboard mode).

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `model` | string | Yes | `"Sora 2 Pro Storyboard"` \| `"Kling 2.5 Turbo"` \| `"VEO 3.1 First Last Frame"` |
| `scenes` | array | Yes (Sora) | `[{ description: "...", duration: "5" }]` |
| `image_urls` | string[] | No | Reference images |
| `aspect_ratio` | string | No | `"16:9"` \| `"9:16"` |
| `first_frame_url` | string | No | First frame (VEO) |
| `last_frame_url` | string | No | Last frame (VEO) |
| `prompt` | string | No | Overall prompt (VEO) |

### curl Example

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/story" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 Pro Storyboard",
    "scenes": [
      {"description": "A person walks into a sunlit room", "duration": "5"},
      {"description": "They sit down and open a book", "duration": "5"}
    ],
    "image_urls": ["https://example.com/reference.jpg"],
    "aspect_ratio": "16:9"
  }'
```

---

## POST /api/v1/suno/generate

Generate music using Suno AI.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `model` | string | Yes | `"V3_5"` \| `"V4"` \| `"V4_5"` \| `"V4_5PLUS"` \| `"V5"` |
| `instrumental` | boolean | Yes | `true` = no vocals |
| `customMode` | boolean | No | `true` enables style/title fields |
| `prompt` | string | Yes | Lyrics (custom) or description (simple). Max 3000-5000 chars. |
| `style` | string | No | Genre/style tags. Max 200-1000 chars. |
| `title` | string | No | Track title. Max 80 chars. |
| `negativeTags` | string | No | Things to avoid |
| `vocalGender` | string | No | `"m"` \| `"f"` |
| `styleWeight` | number | No | 0.00-1.00 |

### Response

```json
{
  "success": true,
  "message": "Music generation task submitted successfully",
  "data": {
    "taskId": "task_abc123",
    "dbRecordId": "uuid-1234"
  }
}
```

### curl Example

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/generate" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "V5",
    "customMode": true,
    "instrumental": false,
    "style": "Pop, upbeat, electronic",
    "title": "Summer Dreams",
    "prompt": "Walking down the beach at sunset, feeling alive"
  }'
```

---

## POST /api/v1/audio/sound-effect

Generate sound effects.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `prompt` | string | Yes | Sound effect description |
| `duration` | number | No | Duration in seconds |

### curl Example

```bash
curl -X POST "$VERSELY_API_URL/api/v1/audio/sound-effect" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Thunder rolling across mountains", "duration": 5}'
```

---

## POST /api/v1/generate/image-upscale

Upscale an image.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `model` | string | Yes | Upscale model name |
| `image_url` | string | Yes | Image to upscale |
| `scale` | string \| number | No | `"2x"` \| `"4x"` \| `2` \| `4` |

---

## POST /api/v1/generate/background-removal

Remove background from image or video.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `model` | string | Yes | Background removal model |
| `image_url` | string | Yes | Image/video URL |

---

## POST /api/v1/generate/expand-scene

Expand a brief description into a cinematic scene prompt.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `description` | string | Yes | Brief scene description |
| `context` | string | No | Story context |
| `style` | string | No | Visual style |
| `camera` | string | No | `static` \| `pan_left` \| `pan_right` \| `zoom_in` \| `zoom_out` \| `dolly_in` \| `orbit` \| `tracking` |

### Response

```json
{
  "success": true,
  "expanded": "A wide establishing shot of a warmly lit room at golden hour..."
}
```

---

## GET /api/v1/status/:requestId

Check generation status.

### Response

```json
{
  "success": true,
  "status": "generating | completed | failed",
  "type": "images | videos | audios | music",
  "model": "Flux Pro Ultra",
  "result_url": "https://cdn.versely.app/...",
  "result_urls": ["https://cdn.versely.app/..."],
  "created_at": "2026-02-15T10:00:00Z"
}
```

---

## GET /api/v1/user/me

Get current user info and credit balance.

### Response

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "credits": 450,
  "username": "johndoe"
}
```

---

## Rate Limits

| Scope | Limit |
|-------|-------|
| Default (per API key) | 60 req/min |
| Generation endpoints | 20 req/min |
| Status polling | Recommended: 1 req/5s per request_id |

Response headers on every request:
- `X-RateLimit-Limit` — Maximum requests allowed
- `X-RateLimit-Remaining` — Requests remaining in window
- `X-RateLimit-Reset` — Unix timestamp when window resets

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "error": "Error message here"
}
```

| Status | Meaning |
|--------|---------|
| 400 | Bad request — missing required fields |
| 401 | Unauthorized — invalid/expired/revoked API key |
| 402 | Payment required — insufficient credits |
| 403 | Forbidden — API key lacks required scope |
| 429 | Rate limited — check `X-RateLimit-Reset` header |
| 500 | Server error — retry once after 10s |
