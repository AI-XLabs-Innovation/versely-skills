# API Reference — Versely Movie

Base URL: `$VERSELY_API_URL` (default: `https://api.versely.app`)

All endpoints require `Authorization: Bearer $VERSELY_API_KEY`.

---

## POST /api/v1/generate/story

Generate a multi-scene storyboard video.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `model` | string | Yes | `"Sora 2 Pro Storyboard"` \| `"Kling 2.5 Turbo"` \| `"VEO 3.1 First Last Frame"` |
| `scenes` | array | Yes (Sora) | `[{ description: "...", duration: "5" }]` — min 2 scenes |
| `image_urls` | string[] | No | Reference images for visual consistency |
| `aspect_ratio` | string | No | `"16:9"` (default) \| `"9:16"` |
| `total_duration` | string | No | `"10"` \| `"15"` \| `"25"` |
| `audio_url` | string | No | Background audio URL |
| `prompt` | string | No | Overall prompt (VEO models) |
| `first_frame_url` | string | No | First frame image (VEO First Last Frame) |
| `last_frame_url` | string | No | Last frame image (VEO First Last Frame) |
| `duration` | string | No | Duration for Kling models |

### Response

Same as `POST /api/v1/generate/video` — returns `requestId` for polling.

```json
{
  "success": true,
  "data": {
    "successful": [
      {
        "data": {
          "requestId": "abc123",
          "model": "Sora 2 Pro Storyboard",
          "isVideoModel": true
        }
      }
    ]
  }
}
```

### curl Example — Sora Storyboard

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/story" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 Pro Storyboard",
    "scenes": [
      {"description": "A drone shot over a mountain lake at sunrise", "duration": "5"},
      {"description": "Camera descends to water level, reflections shimmer", "duration": "5"}
    ],
    "aspect_ratio": "16:9"
  }'
```

### curl Example — VEO First Last Frame

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/story" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "VEO 3.1 First Last Frame",
    "prompt": "Smooth cinematic transition from day to night",
    "first_frame_url": "https://example.com/day.jpg",
    "last_frame_url": "https://example.com/night.jpg"
  }'
```

---

## POST /api/v1/generate/expand-scene

Expand a brief description into a detailed cinematic scene prompt.

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `description` | string | Yes | Brief scene idea |
| `context` | string | No | Story genre/context |
| `style` | string | No | Visual style |
| `camera` | string | No | `static` \| `pan_left` \| `pan_right` \| `zoom_in` \| `zoom_out` \| `tilt_up` \| `tilt_down` \| `dolly_in` \| `orbit` \| `tracking` |
| `characters` | string | No | Characters in the scene |

### Response

```json
{
  "success": true,
  "expanded": "A wide establishing shot of..."
}
```

### curl Example

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/expand-scene" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Car chase through a city",
    "context": "Action thriller",
    "style": "cinematic",
    "camera": "tracking"
  }'
```

---

## GET /api/v1/status/:requestId

Poll generation status (same as versely-generate skill).

### Response

```json
{
  "success": true,
  "status": "generating | completed | failed",
  "type": "videos",
  "model": "Sora 2 Pro Storyboard",
  "result_url": "https://...",
  "result_urls": ["https://..."]
}
```

---

## Merge Scenes (Agentic Tool)

Available through the agentic chat system as `merge_movie_scenes`. Uses the Segmind Multi Video Merge API.

### Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `video_urls` | string[] | Yes | Video URLs to merge in order |
| `transition_type` | string | No | `"concat"` \| `"fade"` (default) \| `"dissolve"` \| `"wipe"` |
| `transition_duration` | number | No | Seconds between scenes (default: 0.5) |
| `audio_handling` | string | No | `"merge"` (default) \| `"first"` \| `"none"` |

### Underlying API (Segmind)

```json
{
  "video_urls": ["url1", "url2"],
  "width": 1920,
  "height": 1080,
  "fps": 30,
  "transition_type": "fade",
  "transition_duration": 0.5,
  "maintain_aspect_ratio": true,
  "audio_handling": "merge"
}
```

---

## GET /api/v1/generate/story-models

List available story/storyboard models.

### Response

```json
{
  "success": true,
  "models": ["Sora 2 Pro Storyboard", "Kling 2.5 Turbo", "VEO 3.1 First Last Frame"]
}
```

---

## Credit Costs

| Model | Billing | ~Credits |
|-------|---------|----------|
| Sora 2 Pro Storyboard | $0.30/second | 6/second |
| Kling 2.5 Turbo | $0.21 base + $0.042/s | ~5 for 5s |
| VEO 3.1 First Last Frame | $0.10-$0.15 flat | 2-3 |

---

## Rate Limits

| Scope | Limit |
|-------|-------|
| Default | 60 req/min |
| Generation | 20 req/min |
| Concurrent video | 2 recommended |

## Error Codes

| Status | Meaning |
|--------|---------|
| 400 | Missing scenes or invalid model |
| 401 | Invalid API key |
| 402 | Insufficient credits |
| 403 | Missing `generate` scope |
| 429 | Rate limited |
| 500 | Server error |
