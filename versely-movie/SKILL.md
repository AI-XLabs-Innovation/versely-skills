---
name: versely-movie
version: 1.0.0
description: >
  Create multi-scene AI movies and storyboards. Expand brief scene ideas into
  cinematic descriptions, generate video for each scene, and merge into a final movie.
  Use when the user wants to create a short film, storyboard, or multi-scene video.
allowed-tools: Bash, Read
metadata:
  agentskills.io:
    category: content-creation
    homepage: https://versely.studio
    tags: ["movie", "storyboard", "video", "scenes"]
---

# Versely Movie — Multi-Scene AI Movie Creation

Create multi-scene AI movies: expand scene ideas into cinematic descriptions, generate video per scene, and merge into a final movie.

**Typical workflow:** Design Scenes → Expand Descriptions → Generate Story Video → Poll → Merge Scenes

## Authentication

```bash
VERSELY_API_KEY="vsk_..."
VERSELY_API_URL="https://api.versely.studio"
```

Do NOT send `user_id` — the API key resolves the user server-side.

## Step 1: Design Scenes

Plan 2+ scenes with descriptions and durations before generating.

```
Scene 1: "A lone traveler walks through a misty forest at dawn" (5s)
Scene 2: "They discover an ancient stone bridge over a river" (5s)
Scene 3: "Crossing the bridge, they see a castle in the distance" (5s)
```

## Step 2: Expand Scene Descriptions (Optional)

**Endpoint:** `POST /api/v1/generate/expand-scene`

Expand brief ideas into detailed cinematic prompts optimized for AI video generation.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/expand-scene" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "A lone traveler walks through a misty forest",
    "context": "Fantasy adventure opening",
    "style": "cinematic",
    "camera": "tracking"
  }'
```

**Response:**
```json
{
  "success": true,
  "expanded": "A wide tracking shot follows a lone traveler in a dark cloak through a misty ancient forest at dawn. Volumetric fog drifts between towering moss-covered trees. Dappled golden light breaks through the canopy, casting long shadows. The camera glides smoothly at waist height, maintaining a medium distance..."
}
```

**Fields:**
- `description` (required): Brief scene idea
- `context` (optional): Story genre/context
- `style` (optional): Visual style
- `camera` (optional): `static` | `pan_left` | `pan_right` | `zoom_in` | `zoom_out` | `tilt_up` | `tilt_down` | `dolly_in` | `orbit` | `tracking`
- `characters` (optional): Characters in the scene

**Tip:** Expand all scenes before generating — better prompts produce dramatically better videos.

## Step 3: Generate Story Video

**Endpoint:** `POST /api/v1/generate/story`

Generate a multi-scene storyboard video.

```bash
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/story" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 Pro Storyboard",
    "scenes": [
      {
        "description": "A wide tracking shot follows a lone traveler through misty ancient forest...",
        "duration": "5"
      },
      {
        "description": "The traveler discovers an ancient stone bridge spanning a crystal-clear river...",
        "duration": "5"
      }
    ],
    "image_urls": ["https://example.com/reference-character.jpg"],
    "aspect_ratio": "16:9"
  }')

REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId')
echo "Request ID: $REQUEST_ID"
```

**Key fields:**
- `model` (required): `"Sora 2 Pro Storyboard"` | `"Kling 2.5 Turbo"` | `"VEO 3.1 First Last Frame"`
- `scenes` (required for Sora): Array of `{ description, duration }` — minimum 2 scenes
- `image_urls` (optional): Reference images for visual consistency
- `aspect_ratio` (optional): `"16:9"` (default) | `"9:16"`
- `audio_url` (optional): Background audio URL

**For VEO First/Last Frame model:**
```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/story" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "VEO 3.1 First Last Frame",
    "prompt": "Smooth cinematic transition between two locations",
    "first_frame_url": "https://example.com/frame1.jpg",
    "last_frame_url": "https://example.com/frame2.jpg",
    "aspect_ratio": "16:9"
  }'
```

**Credit cost:** Sora 2 Pro Storyboard costs ~$0.30/second → ~3 credits/second via API. A 10-second storyboard ≈ 30 credits.

## Step 4: Poll for Completion

Use the status endpoint to check when the video is ready:

```bash
for i in $(seq 1 60); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$REQUEST_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo $STATUS | jq -r '.status')
  if [ "$STATE" = "completed" ]; then
    VIDEO_URL=$(echo $STATUS | jq -r '.result_url')
    echo "Video ready: $VIDEO_URL"
    break
  elif [ "$STATE" = "failed" ]; then
    echo "Generation failed"
    break
  fi
  echo "Generating... ($i/60)"
  sleep 10
done
```

**Typical generation time:** 2-5 minutes for storyboard videos.

## Step 5: Merge Multiple Scenes (Optional)

If you generated scenes separately (e.g., different models per scene), merge them into one video.

This is available through the agentic chat system's `merge_movie_scenes` tool, which uses the Segmind Multi Video Merge API.

**Merge parameters:**
- `video_urls` (required): Array of video URLs in order
- `transition_type` (optional): `"concat"` | `"fade"` (default) | `"dissolve"` | `"wipe"`
- `transition_duration` (optional): Seconds between scenes (default: 0.5)
- `audio_handling` (optional): `"merge"` (default) | `"first"` | `"none"`

## Full Pipeline Example

```bash
# 1. Check credits (storyboard is expensive)
CREDITS=$(curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.credits')
echo "Credits: $CREDITS (need ~30 for 10s storyboard via API)"

# 2. Expand scenes
SCENE1=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/expand-scene" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"description": "Person enters a dark room", "style": "cinematic", "camera": "dolly_in"}')
EXPANDED1=$(echo $SCENE1 | jq -r '.expanded')

SCENE2=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/expand-scene" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"description": "They find a glowing artifact on a table", "style": "cinematic", "camera": "zoom_in"}')
EXPANDED2=$(echo $SCENE2 | jq -r '.expanded')

# 3. Generate storyboard
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/story" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"Sora 2 Pro Storyboard\",
    \"scenes\": [
      {\"description\": \"$EXPANDED1\", \"duration\": \"5\"},
      {\"description\": \"$EXPANDED2\", \"duration\": \"5\"}
    ],
    \"aspect_ratio\": \"16:9\"
  }")
REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId')

# 4. Poll for completion
for i in $(seq 1 60); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$REQUEST_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo $STATUS | jq -r '.status')
  if [ "$STATE" = "completed" ]; then
    VIDEO_URL=$(echo $STATUS | jq -r '.result_url')
    echo "Movie ready: $VIDEO_URL"
    break
  elif [ "$STATE" = "failed" ]; then
    echo "Failed"; break
  fi
  sleep 10
done
```

## Available Story Models

| Model | Best For | ~Credits (10s, API) |
|-------|----------|---------------------|
| Sora 2 Pro Storyboard | Best quality, multi-scene | ~30 |
| Kling 2.5 Turbo | Good quality, faster | ~5 |
| VEO 3.1 First Last Frame | Transition between 2 frames | ~2-4 |

## Error Handling

- **401 Unauthorized** — API key invalid or expired.
- **402 Payment Required** — Insufficient credits. Storyboards are expensive — check first.
- **403 Forbidden** — API key lacks `generate` scope.
- **429 Too Many Requests** — Rate limited. Video generation: max 2 concurrent per key.
- **Generation timeout** (5+ min) — Report as failed, suggest retrying with a different model.
- **500 Internal Server Error** — Retry once after 10 seconds.

## Rate Limits

- Default: 60 requests/minute per API key
- Generation: 20 requests/minute
- Video generation: recommended max 2 concurrent requests
- Response headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

For complete API schemas, see [api-reference.md](api-reference.md).
