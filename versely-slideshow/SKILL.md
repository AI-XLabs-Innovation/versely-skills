---
name: versely-slideshow
version: 1.0.0
description: >
  Create AI-generated slideshows and convert them to videos. Generate multiple
  images from a prompt, add text overlays, upload custom media, and export as
  video with transitions and audio. Use when the user wants to create a slideshow,
  reel, carousel, or multi-image presentation.
allowed-tools: Bash, Read
metadata:
  agentskills.io:
    category: content-creation
    homepage: https://versely.app
    tags: ["slideshow", "video", "presentation", "reel", "carousel"]
---

# Versely Slideshow — AI Slideshow to Video Pipeline

Create AI-generated slideshows with multiple images, add text overlays, and convert to video with transitions and audio.

**Typical workflow:** Create Slideshow → Add Text Overlays (optional) → Convert to Video → Post to Social

## Authentication

```bash
VERSELY_API_KEY="vsk_..."
VERSELY_API_URL="https://api.versely.app"
```

Every request:
```bash
-H "Authorization: Bearer $VERSELY_API_KEY"
-H "Content-Type: application/json"
```

Do NOT send `user_id` — the API key resolves the user server-side.

## Step 1: Create a Slideshow

**Endpoint:** `POST /api/v1/slideshow/create`

Generates multiple AI images from a prompt and organizes them into a slideshow.

```bash
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/slideshow/create" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A magical forest adventure through enchanted woods",
    "num_images": 5,
    "model": "Flux Pro Ultra",
    "content_type": "reel"
  }')

SLIDESHOW_ID=$(echo $RESPONSE | jq -r '.data.slideshow_id')
echo "Slideshow ID: $SLIDESHOW_ID"
```

**Key fields:**
- `prompt` (required): Main description for all images
- `num_images` (optional): 0-20, default 5. Use 0 for upload-only slideshows.
- `model` (optional): `"Flux Pro Ultra"` (default) | `"Recraft V3 Image"` | `"Reve Text to Image"` | `"Imagen 4 Ultra"`
- `content_type` (optional): Controls aspect ratio
  - `"reel"` → 9:16 (Instagram/TikTok Reels) — **default**
  - `"story"` → 9:16 (Stories)
  - `"post"` → 1:1 (Square)
  - `"landscape"` → 16:9 (YouTube)
  - `"portrait"` → 4:5 (Instagram portrait)
- `aspect_ratio` (optional): Override content_type with custom ratio like `"9:16"`, `"16:9"`
- `style` (optional): Visual style — `"cinematic"`, `"minimal"`, `"vibrant"`
- `theme` (optional): Theme — `"fantasy"`, `"nature"`, `"urban"`

**Response:**
```json
{
  "success": true,
  "data": {
    "slideshow_id": "uuid-1234",
    "status": "completed",
    "total_requested": 5,
    "total_generated": 5,
    "images": [
      { "id": "img-1", "order": 1, "url": "https://...", "prompt": "..." }
    ],
    "settings": { "model": "Flux Pro Ultra", "aspect_ratio": "9:16", "content_type": "reel" }
  }
}
```

**Credit cost:** Same as image generation (~2 credits per image for Flux Pro Ultra).

## Step 2: Add Text Overlays (Optional)

**Endpoint:** `POST /api/v1/slideshow/:id/text-overlay`

Add text captions to slideshow images. Creates edited copies — originals are preserved.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/slideshow/$SLIDESHOW_ID/text-overlay" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "overlays": [
      {
        "image_id": "img-1",
        "text": "Once upon a time...",
        "position": "bottom",
        "style": "shadow",
        "font_size": 0.06
      },
      {
        "image_id": "img-2",
        "text": "Deep in the enchanted forest",
        "position": "center",
        "style": "bold",
        "background": "gradient"
      }
    ]
  }'
```

**Overlay fields:**
- `image_id` (required): Image ID from the slideshow
- `text` (required): Overlay text content
- `position` (optional): `"top"` | `"center"` | `"bottom"` (default)
- `x`, `y` (optional): Custom position (0-100, percentage)
- `font_size` (optional): `< 1` = percentage of height, `>= 1` = pixels
- `font_family` (optional): `"Arial"`, `"Times New Roman"`, etc.
- `style` (optional): `"default"` | `"bold"` | `"light"` | `"shadow"` | `"outline"`
- `background` (optional): `"none"` | `"solid"` | `"gradient"`
- `background_padding` (optional): 0.1-0.8 (default 0.3)
- `rotation` (optional): 0-360 degrees
- `stroke_color` (optional): Hex color (e.g., `"#000000"`)
- `stroke_width` (optional): 0-10 pixels

## Step 3: Convert to Video

**Endpoint:** `POST /api/v1/slideshow/:id/video`

Creates a video from slideshow images with transitions and optional audio.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/slideshow/$SLIDESHOW_ID/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "duration_per_image": 3,
    "transition": "fade",
    "output_resolution": "1080p",
    "use_edited_images": true
  }'
```

**Key fields:**
- `duration_per_image` (optional): 0.5-30 seconds, default 3
- `transition` (optional): `"none"` | `"fade"` | `"crossfade"` (default: `"none"`)
- `output_resolution` (optional): `"720p"` | `"1080p"` (default) | `"4k"`
- `use_edited_images` (optional): `true` to use text-overlaid versions
- `voiceover_url` (optional): Voiceover audio URL (plays at 100% volume)
- `music_url` (optional): Background music URL (plays at 30% volume)
- `aspect_ratio` (optional): Override slideshow's aspect ratio

**Response:**
```json
{
  "success": true,
  "data": {
    "slideshow_id": "uuid-1234",
    "video_url": "https://...",
    "duration_seconds": 15,
    "resolution": "1080p",
    "image_count": 5,
    "has_audio": true
  }
}
```

## Additional Operations

### Add More Images

```bash
curl -X POST "$VERSELY_API_URL/api/v1/slideshow/$SLIDESHOW_ID/images" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "A mysterious castle at night", "num_images": 3}'
```

### Upload Custom Media

Upload your own images or videos to the slideshow:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/slideshow/$SLIDESHOW_ID/upload-media" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "media_data": "<base64-encoded-data>",
    "media_type": "image",
    "mime_type": "image/jpeg"
  }'
```

For videos, include `duration` (in seconds) and set `media_type: "video"`.

### Upload Audio

```bash
curl -X POST "$VERSELY_API_URL/api/v1/slideshow/$SLIDESHOW_ID/upload-audio" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "audio_data": "<base64-encoded-audio>",
    "mime_type": "audio/mpeg"
  }'
```

### Reorder Images

```bash
curl -X PUT "$VERSELY_API_URL/api/v1/slideshow/$SLIDESHOW_ID/reorder" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "image_order": [
      {"image_id": "img-3", "order_index": 1},
      {"image_id": "img-1", "order_index": 2},
      {"image_id": "img-2", "order_index": 3}
    ]
  }'
```

### Get Slideshow Details

```bash
curl -s "$VERSELY_API_URL/api/v1/slideshow/$SLIDESHOW_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

### List User's Slideshows

```bash
curl -s -X POST "$VERSELY_API_URL/api/v1/slideshow/user/list?limit=20&offset=0" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

### Delete Slideshow

```bash
curl -X DELETE "$VERSELY_API_URL/api/v1/slideshow/$SLIDESHOW_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

### Get Available Models

```bash
curl -s "$VERSELY_API_URL/api/v1/slideshow/models" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

## Full Pipeline Example

Create a reel: generate images → add captions → convert to video → post to social:

```bash
# 1. Create slideshow
SLIDESHOW=$(curl -s -X POST "$VERSELY_API_URL/api/v1/slideshow/create" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "5 tips for better productivity",
    "num_images": 5,
    "content_type": "reel",
    "style": "minimal"
  }')
SLIDESHOW_ID=$(echo $SLIDESHOW | jq -r '.data.slideshow_id')
IMAGES=$(echo $SLIDESHOW | jq -r '.data.images')

# 2. Add text overlays (one per image)
OVERLAYS='[]'
TIPS=("Tip 1: Start early" "Tip 2: Focus on one task" "Tip 3: Take breaks" "Tip 4: Stay hydrated" "Tip 5: Review your day")
for i in $(seq 0 4); do
  IMAGE_ID=$(echo $IMAGES | jq -r ".[$i].id")
  OVERLAYS=$(echo $OVERLAYS | jq ". + [{\"image_id\": \"$IMAGE_ID\", \"text\": \"${TIPS[$i]}\", \"position\": \"bottom\", \"style\": \"bold\", \"background\": \"gradient\"}]")
done

curl -s -X POST "$VERSELY_API_URL/api/v1/slideshow/$SLIDESHOW_ID/text-overlay" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"overlays\": $OVERLAYS}"

# 3. Convert to video
VIDEO=$(curl -s -X POST "$VERSELY_API_URL/api/v1/slideshow/$SLIDESHOW_ID/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "duration_per_image": 3,
    "transition": "crossfade",
    "output_resolution": "1080p",
    "use_edited_images": true
  }')
VIDEO_URL=$(echo $VIDEO | jq -r '.data.video_url')

# 4. Post to social (using versely-social skill)
ACCOUNTS=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
ACCOUNT_IDS=$(echo $ACCOUNTS | jq '[.accounts[].id]')

curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"caption\": \"5 tips for better productivity! Which one is your favorite?\",
    \"media_urls\": [\"$VIDEO_URL\"],
    \"account_ids\": $ACCOUNT_IDS
  }"
```

## Error Handling

- **401 Unauthorized** — API key invalid or expired.
- **402 Payment Required** — Insufficient credits for image generation.
- **403 Forbidden** — API key lacks required scope.
- **429 Too Many Requests** — Rate limited. Check `X-RateLimit-Reset`.
- **Partial success** — Some images may fail. Check `total_generated` vs `total_requested`.
- **Video generation timeout** — FFmpeg has a 5-minute timeout. Reduce `num_images` or resolution.
- **500 Internal Server Error** — Retry once after 10 seconds.

## Rate Limits

- Default: 60 requests/minute per API key
- Generation: 20 requests/minute (cost-sensitive)
- Response headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

For complete API schemas, see [api-reference.md](api-reference.md).
