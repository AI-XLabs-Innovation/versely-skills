---
name: versely-generate
version: 1.0.0
description: >
  Generate AI images, videos, music, and sound effects using Versely's API.
  Supports 50+ image models (Flux Pro Ultra, Imagen 4, GPT Image, Midjourney V7),
  30+ video models (Sora 2, Kling, VEO 3.1, Hailuo), and music generation (Suno V3.5-V5).
  Use when the user wants to create, generate, or produce visual/audio content.
allowed-tools: Bash, Read
metadata:
  agentskills.io:
    category: content-creation
    homepage: https://versely.studio
    tags: ["image-generation", "video-generation", "music-generation", "ai-content"]
---

# Versely Generate — AI Content Generation

Generate images, videos, music, sound effects, and more using Versely's unified API.

## Authentication

All requests use a scoped API key (`vsk_` prefix). Never hardcode keys — always use the environment variable.

```bash
# Required environment variables
VERSELY_API_KEY="vsk_..."          # Create at Settings > API Keys
VERSELY_API_URL="https://api.versely.studio"  # Default base URL
```

Every request includes:
```bash
-H "Authorization: Bearer $VERSELY_API_KEY"
-H "Content-Type: application/json"
```

**Important:** Do NOT send `user_id` in the request body. The API key resolves the user server-side.

## Before Generating — Credit Check

Always check available credits before generating:

```bash
curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq '.credits'
```

**Approximate credit costs** (API keys get 2x pricing — half of in-app costs):

| Type | Model | Credits |
|------|-------|---------|
| Image | Imagen 4, GPT Image 1 | ~1 |
| Image | Flux Pro Ultra, Imagen 4 Ultra | ~1 |
| Image | Midjourney V7 | ~1 |
| Video (5s) | Sora 2 Text to Video | ~5 |
| Video (5s) | VEO 3.1 (no audio) | ~2 |
| Video (5s) | VEO 3.1 (with audio) | ~4 |
| Video (5s) | Kling 2.5 Turbo | ~3 |
| Music | Suno V5 | ~5 |
| Upscale | Topaz Upscale | ~1 |
| Social Post | Per platform | 1 |

If `credits < estimated cost`, inform the user BEFORE generating.

For full credit costs, see [models-reference.md](models-reference.md).

## Image Generation

**Endpoint:** `POST /api/v1/generate/image`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Flux Pro Ultra",
    "prompt": "a beautiful sunset over mountains, golden hour lighting",
    "aspect_ratio": "16:9"
  }'
```

**Key fields:**
- `model` (required): Model name string, or array for multi-model generation
- `prompt` (required for most): Text description of the image
- `aspect_ratio` (optional): `"1:1"` | `"16:9"` | `"9:16"` | `"4:3"` | `"3:4"`
- `num_images` (optional): 1-4 images per request

**Response** contains `request_id` — use it to poll for results (see Polling section).

### Image Editing (Image-to-Image)

Same endpoint, but include an input image:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Nano Banana Edit",
    "prompt": "Make the sky more dramatic with storm clouds",
    "image_url": "https://example.com/photo.jpg"
  }'
```

**Edit models:** Nano Banana Edit, GPT Image 1 Edit, Reve Edit, Flux Kontext, Seedream Edit, Qwen Image Edit

### Image Upscaling

**Endpoint:** `POST /api/v1/generate/image-upscale`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/image-upscale" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Topaz Upscale Image",
    "image_url": "https://example.com/lowres.jpg",
    "scale": "4x"
  }'
```

**Models:** Topaz Upscale Image, SeedVR Upscale, Clarity Crystal Upscaler, Crystal Upscale

### Background Removal

**Endpoint:** `POST /api/v1/generate/background-removal`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/background-removal" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BRIO Video Background Removal",
    "image_url": "https://example.com/photo.jpg"
  }'
```

## Video Generation

**Endpoint:** `POST /api/v1/generate/video`

### Text-to-Video

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 Text to Video Pro",
    "prompt": "A person walking through an autumn forest, cinematic",
    "duration": "10",
    "aspect_ratio": "16:9",
    "resolution": "1080p"
  }'
```

**Key fields:**
- `model` (required): Video model name
- `prompt` (required): Video description
- `duration` (optional): Seconds — `"5"` | `"10"` | `"15"`
- `aspect_ratio` (optional): `"1:1"` | `"16:9"` | `"9:16"`
- `resolution` (optional): `"720p"` | `"1080p"` | `"4k"`

### Image-to-Video

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 Image to Video",
    "prompt": "Gentle camera zoom with leaves blowing",
    "image_url": "https://example.com/landscape.jpg",
    "duration": "5"
  }'
```

**I2V models:** Sora 2 Image to Video, Wan Video 2.5 I2V, Kling O1 Standard I2V, Pixverse Image to Video, Seedance 1 Pro

### First/Last Frame Video (VEO)

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "VEO First Last Frame",
    "prompt": "Smooth cinematic transition",
    "first_frame_url": "https://example.com/frame1.jpg",
    "last_frame_url": "https://example.com/frame2.jpg"
  }'
```

## Music Generation

**Endpoint:** `POST /api/v1/suno/generate`

### Custom Mode (with lyrics/style)

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/generate" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "V4_5PLUS",
    "customMode": true,
    "instrumental": false,
    "style": "Pop, upbeat, electronic",
    "title": "Summer Dreams",
    "prompt": "Verse 1: Walking down the beach at sunset..."
  }'
```

### Simple Mode (description only)

```bash
curl -X POST "$VERSELY_API_URL/api/v1/suno/generate" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "V5",
    "customMode": false,
    "instrumental": true,
    "prompt": "Epic orchestral soundtrack with dramatic crescendos"
  }'
```

**Suno models:** `V3_5` | `V4` | `V4_5` | `V4_5PLUS` | `V5`

**Key fields:**
- `model` (required): Suno version
- `instrumental` (required): `true` = no vocals
- `customMode` (optional): `true` enables `style` and `title` fields
- `prompt` (required): Lyrics (custom mode) or description (simple mode)
- `style` (optional, custom mode): Genre/style tags
- `title` (optional, custom mode): Track title

## Sound Effects

**Endpoint:** `POST /api/v1/audio/sound-effect`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/audio/sound-effect" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Thunder rolling across a mountain valley",
    "duration": 5
  }'
```

## Scene Expansion (Prompt Enhancement)

**Endpoint:** `POST /api/v1/generate/expand-scene`

Expands a brief description into a cinematic scene description for video generation:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/expand-scene" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Person walks into a room",
    "style": "cinematic",
    "camera": "dolly_in"
  }'
```

**Camera options:** `static` | `pan_left` | `pan_right` | `zoom_in` | `zoom_out` | `tilt_up` | `tilt_down` | `dolly_in` | `orbit` | `tracking`

## Polling for Results

All generation is async. After submitting a request, poll the status endpoint:

```bash
# 1. Submit generation and extract request_id
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "Flux Pro Ultra", "prompt": "..."}')

# Response contains nested request IDs
REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId')

# 2. Poll status endpoint (5-second intervals, max 60 attempts)
for i in $(seq 1 60); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$REQUEST_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo $STATUS | jq -r '.status')

  if [ "$STATE" = "completed" ]; then
    RESULT_URL=$(echo $STATUS | jq -r '.result_url')
    echo "Done: $RESULT_URL"
    break
  elif [ "$STATE" = "failed" ]; then
    echo "Failed"
    break
  fi
  sleep 5
done
```

**Status endpoint response:**
```json
{
  "success": true,
  "status": "generating" | "completed" | "failed",
  "type": "images" | "videos" | "audios" | "music",
  "model": "Flux Pro Ultra",
  "result_url": "https://...",
  "result_urls": ["https://..."],
  "created_at": "2026-02-15T10:00:00Z"
}
```

**Important:** Always use `GET /api/v1/status/:requestId` — never poll user media tables directly. The status endpoint is scoped to a single request and avoids race conditions.

**Typical generation times:**
- Images: 5-30 seconds
- Videos: 30 seconds - 5 minutes
- Music: 30-120 seconds

## Model Selection Guide

| Use Case | Recommended Model | Why |
|----------|-------------------|-----|
| Best quality image | Flux Pro Ultra | Consistent, photorealistic |
| Fast cheap image | Imagen 4 | 1 credit, quick |
| Image editing | Nano Banana Edit | Natural edits |
| Best video | Sora 2 Text to Video Pro | Cinematic quality |
| Fast video | VEO 3.1 Fast | Quick generation |
| Video with audio | VEO 3.1 | Built-in audio |
| Image to video | Sora 2 Image to Video | Best I2V quality |
| Music with vocals | Suno V5 | Latest, best quality |
| Instrumental | Suno V4_5PLUS | Great instrumentals |
| Upscale | Topaz Upscale Image | Best quality |

For the full model catalog with pricing, see [models-reference.md](models-reference.md).

## Error Handling

- **401 Unauthorized** — API key invalid, expired, or revoked. Ask user to check Settings > API Keys.
- **402 Payment Required** — Insufficient credits. Tell user their balance and estimated cost.
- **403 Forbidden** — API key lacks required scope. Tell user which scope is needed (e.g., `generate`).
- **429 Too Many Requests** — Rate limited. Check `X-RateLimit-Reset` header, wait, retry once.
- **500 Internal Server Error** — Server error. Retry once after 10 seconds.
- **Generation timeout** (5+ min with no completion) — Report as failed, suggest retrying with a different model.
- **Network error** — Verify `$VERSELY_API_URL` is correct. Retry once.

## Rate Limits

- Default: 60 requests/minute per API key (configurable per key)
- Generation endpoints: 20 requests/minute (cost-sensitive rate limiter)
- Status polling: recommended max 1 request every 5 seconds per request_id
- Response headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

For complete API schemas with all fields, see [api-reference.md](api-reference.md).
For real workflow examples, see [examples.md](examples.md).
