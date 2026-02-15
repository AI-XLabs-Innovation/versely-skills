---
name: versely-content-pipeline
version: 1.0.0
description: >
  End-to-end content creation workflows: generate images/videos, create slideshows,
  add overlays and captions, and post or schedule to social media. Orchestrates
  multiple Versely capabilities into complete pipelines. Use when the user wants a
  full content workflow, content calendar, or multi-step creative pipeline.
allowed-tools: Bash, Read
metadata:
  agentskills.io:
    category: content-creation
    homepage: https://versely.app
    tags: ["workflow", "pipeline", "automation", "content-calendar"]
---

# Versely Content Pipeline — End-to-End Workflows

Orchestrate multiple Versely capabilities into complete content creation pipelines: generate media, edit, and publish — all in one flow.

**This skill chains the individual skills together.** For single operations, use the specific skill:
- Image/video/music generation: `versely-generate`
- Social media posting: `versely-social`
- Slideshows: `versely-slideshow`
- Multi-scene movies: `versely-movie`
- UGC video overlays/captions: `versely-ugc`

## Authentication

```bash
VERSELY_API_KEY="vsk_..."
VERSELY_API_URL="https://api.versely.app"
```

All requests use `Authorization: Bearer $VERSELY_API_KEY`. Do NOT send `user_id`.

## Before Any Pipeline — Credit Budget

Always calculate total cost BEFORE starting a multi-step pipeline. A failed mid-pipeline step wastes credits already spent on earlier steps.

```bash
# Check current balance
CREDITS=$(curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.credits')
echo "Available credits: $CREDITS"
```

**Quick cost reference:**

| Operation | Credits |
|-----------|---------|
| Image (Flux Pro Ultra) | ~2 |
| Image (Imagen 4) | ~1 |
| Video 5s (Sora 2) | ~10 |
| Video 5s (VEO 3.1) | ~4 |
| Music (Suno V5) | ~10 |
| Slideshow (5 images) | ~10 |
| Storyboard (10s, Sora 2 Pro) | ~60 |
| Social post per platform | 2 |
| UGC overlay / captions | 0 (processing only) |

**Example budget:** "Create a 5-image slideshow reel and post to Instagram + TikTok"
- 5 images x 2 credits = 10
- Video conversion = 0 (FFmpeg, no credit cost)
- 2 platforms x 2 credits = 4
- **Total: ~14 credits**

If `CREDITS < estimated total`, tell the user before starting.

## Pipeline 1: Generate & Post

Generate a single image or video and immediately post to social media.

**Steps:** Generate media → Poll → Post

```bash
# 1. Check credits
CREDITS=$(curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.credits')
echo "Credits: $CREDITS (need ~6 for image + 2 platforms)"

# 2. Generate image
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Flux Pro Ultra",
    "prompt": "Minimalist product photography of wireless earbuds on marble surface",
    "aspect_ratio": "1:1"
  }')
REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId')

# 3. Poll for completion
for i in $(seq 1 60); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$REQUEST_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo $STATUS | jq -r '.status')
  if [ "$STATE" = "completed" ]; then
    IMAGE_URL=$(echo $STATUS | jq -r '.result_url')
    echo "Image ready: $IMAGE_URL"
    break
  elif [ "$STATE" = "failed" ]; then
    echo "Generation failed"; exit 1
  fi
  sleep 5
done

# 4. Get connected accounts
ACCOUNTS=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
ACCOUNT_IDS=$(echo $ACCOUNTS | jq '[.accounts[].id]')

# 5. Post to all connected platforms
curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"caption\": \"Check out our latest product!\",
    \"media_urls\": [\"$IMAGE_URL\"],
    \"account_ids\": $ACCOUNT_IDS
  }"
```

## Pipeline 2: Social Media Reel

Generate a slideshow, add text overlays, convert to video, and post as a reel.

**Steps:** Create slideshow → Add overlays → Convert to video → Post

```bash
# 1. Create slideshow with AI images
SLIDESHOW=$(curl -s -X POST "$VERSELY_API_URL/api/v1/slideshow/create" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "5 tips for morning productivity, clean modern design",
    "num_images": 5,
    "model": "Flux Pro Ultra",
    "content_type": "reel"
  }')
SLIDESHOW_ID=$(echo $SLIDESHOW | jq -r '.data.slideshow_id')
IMAGES=$(echo $SLIDESHOW | jq -r '.data.images')

# 2. Add text overlays
OVERLAYS='[]'
TIPS=("Wake up at 6 AM" "Exercise for 20 min" "Plan your top 3 tasks" "Eat a healthy breakfast" "Start with the hardest task")
for i in $(seq 0 4); do
  IMAGE_ID=$(echo $IMAGES | jq -r ".[$i].id")
  OVERLAYS=$(echo $OVERLAYS | jq \
    --arg id "$IMAGE_ID" --arg text "${TIPS[$i]}" \
    '. + [{"image_id": $id, "text": $text, "position": "bottom", "style": "bold", "background": "gradient"}]')
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

# 4. Post to Instagram and TikTok
ACCOUNTS=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
# Filter to Instagram and TikTok only
REEL_ACCOUNTS=$(echo $ACCOUNTS | jq '[.accounts[] | select(.platform == "instagram" or .platform == "tiktok") | .id]')

curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"caption\": \"5 morning habits that changed my life! Which one will you try?\",
    \"media_urls\": [\"$VIDEO_URL\"],
    \"account_ids\": $REEL_ACCOUNTS
  }"
```

## Pipeline 3: Product Carousel

Generate multiple product image variations and post as an Instagram carousel.

**Steps:** Generate variations → Poll all → Post as carousel

```bash
# 1. Generate 4 product photo variations
MODELS=("Flux Pro Ultra" "Imagen 4 Ultra" "Recraft V3 Image" "Flux Pro Ultra")
PROMPTS=(
  "Wireless earbuds on white marble, soft lighting"
  "Wireless earbuds in use, person jogging outdoors"
  "Wireless earbuds case open, close-up detail shot"
  "Wireless earbuds flat lay with accessories"
)
REQUEST_IDS=()

for i in $(seq 0 3); do
  RESP=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
    -H "Authorization: Bearer $VERSELY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"${MODELS[$i]}\",
      \"prompt\": \"${PROMPTS[$i]}\",
      \"aspect_ratio\": \"1:1\"
    }")
  RID=$(echo $RESP | jq -r '.data.successful[0].data.requestId')
  REQUEST_IDS+=("$RID")
done

# 2. Poll all requests
IMAGE_URLS=()
for RID in "${REQUEST_IDS[@]}"; do
  for attempt in $(seq 1 60); do
    STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$RID" \
      -H "Authorization: Bearer $VERSELY_API_KEY")
    STATE=$(echo $STATUS | jq -r '.status')
    if [ "$STATE" = "completed" ]; then
      URL=$(echo $STATUS | jq -r '.result_url')
      IMAGE_URLS+=("$URL")
      break
    elif [ "$STATE" = "failed" ]; then
      echo "Warning: One image failed, continuing..."
      break
    fi
    sleep 5
  done
done

# 3. Build media_urls JSON array
MEDIA_JSON=$(printf '%s\n' "${IMAGE_URLS[@]}" | jq -R . | jq -s .)

# 4. Post as Instagram carousel
IG_ACCOUNT=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | \
  jq -r '[.accounts[] | select(.platform == "instagram") | .id][0]')

curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"caption\": \"Introducing our new wireless earbuds. Swipe to see more.\",
    \"media_urls\": $MEDIA_JSON,
    \"account_ids\": [\"$IG_ACCOUNT\"]
  }"
```

## Pipeline 4: Content Calendar

Generate a week's worth of content and schedule posts at optimal times.

**Steps:** Generate images → Write captions → Schedule posts

```bash
# Content plan: 7 days, 1 post per day
DAYS=("Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
PROMPTS=(
  "Motivational quote on clean gradient background"
  "Behind the scenes of product development"
  "Customer testimonial with happy person"
  "Product feature highlight, close-up"
  "Fun team photo, casual office setting"
  "Weekend inspiration, outdoor adventure"
  "Week ahead preview, planning theme"
)
CAPTIONS=(
  "Start the week strong. What's your #1 goal?"
  "Behind the scenes: how we build products you love"
  "Our customers say it best. Thank you for the love!"
  "Did you know? Our latest feature just dropped"
  "Meet the team behind the magic"
  "Weekend vibes. Where are you exploring?"
  "Big week ahead. Stay tuned for something special"
)

# Schedule times: 9 AM each day, starting next Monday
BASE_DATE="2026-03-02"  # Adjust to next Monday

# 1. Get Instagram account
IG_ACCOUNT=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | \
  jq -r '[.accounts[] | select(.platform == "instagram") | .id][0]')

for i in $(seq 0 6); do
  # 2. Generate image
  RESP=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
    -H "Authorization: Bearer $VERSELY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"Flux Pro Ultra\", \"prompt\": \"${PROMPTS[$i]}\", \"aspect_ratio\": \"1:1\"}")
  RID=$(echo $RESP | jq -r '.data.successful[0].data.requestId')

  # 3. Poll for image
  for attempt in $(seq 1 60); do
    STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$RID" \
      -H "Authorization: Bearer $VERSELY_API_KEY")
    if [ "$(echo $STATUS | jq -r '.status')" = "completed" ]; then
      IMG_URL=$(echo $STATUS | jq -r '.result_url')
      break
    fi
    sleep 5
  done

  # 4. Calculate schedule date (BASE_DATE + i days, 9 AM UTC)
  SCHEDULE_DATE=$(date -j -v+${i}d -f "%Y-%m-%d" "$BASE_DATE" "+%Y-%m-%dT09:00:00Z" 2>/dev/null || \
    date -d "$BASE_DATE + $i days" "+%Y-%m-%dT09:00:00Z")

  # 5. Schedule the post
  curl -s -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
    -H "Authorization: Bearer $VERSELY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"caption\": \"${CAPTIONS[$i]}\",
      \"media_urls\": [\"$IMG_URL\"],
      \"account_ids\": [\"$IG_ACCOUNT\"],
      \"scheduled_at\": \"$SCHEDULE_DATE\"
    }"

  echo "${DAYS[$i]}: Scheduled for $SCHEDULE_DATE"
done
```

**Credit cost:** 7 images (14 credits) + 7 posts x 1 platform (14 credits) = **~28 credits**.

## Pipeline 5: UGC Product Review

Generate a product video, overlay a talking-head, add auto-timed captions.

**Steps:** Generate video → Overlay talking head → Auto-caption

```bash
# 1. Generate product video
RESP=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 Text to Video",
    "prompt": "Sleek product reveal of wireless earbuds case on white surface, cinematic",
    "duration": "10",
    "aspect_ratio": "9:16"
  }')
REQUEST_ID=$(echo $RESP | jq -r '.data.successful[0].data.requestId')

# 2. Poll for product video
for i in $(seq 1 60); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$REQUEST_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  if [ "$(echo $STATUS | jq -r '.status')" = "completed" ]; then
    PRODUCT_VIDEO=$(echo $STATUS | jq -r '.result_url')
    break
  elif [ "$(echo $STATUS | jq -r '.status')" = "failed" ]; then
    echo "Video generation failed"; exit 1
  fi
  sleep 10
done

# 3. Overlay talking-head video
OVERLAY=$(curl -s -X POST "$VERSELY_API_URL/api/v1/ugc/add-video-overlay" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"slideshow_video_url\": \"$PRODUCT_VIDEO\",
    \"overlay_video_url\": \"https://example.com/my-talking-head.mp4\",
    \"position\": \"bottom-right\",
    \"overlay_size\": \"small\"
  }")
UGC_VIDEO=$(echo $OVERLAY | jq -r '.data.video_url')

# 4. Auto-caption the combined video
CAPTIONED=$(curl -s -X POST "$VERSELY_API_URL/api/v1/captions/auto" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"video_url\": \"$UGC_VIDEO\",
    \"words_per_segment\": 3,
    \"style\": {
      \"fontsize\": 56,
      \"fontcolor\": \"white\",
      \"position\": \"top\",
      \"highlight\": true
    }
  }")
FINAL_URL=$(echo $CAPTIONED | jq -r '.video_url')
echo "Final UGC video: $FINAL_URL"
```

## Pipeline 6: Music Video

Generate music, create scene images, animate them, and merge into a movie.

**Steps:** Generate music → Design scenes → Expand descriptions → Generate story → Poll

```bash
# 1. Generate background music
MUSIC_RESP=$(curl -s -X POST "$VERSELY_API_URL/api/v1/suno/generate" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "V5",
    "customMode": true,
    "instrumental": true,
    "style": "Cinematic, orchestral, epic",
    "title": "Dawn of Adventure",
    "prompt": "Instrumental epic orchestral piece building from soft piano to full orchestra crescendo"
  }')
MUSIC_RID=$(echo $MUSIC_RESP | jq -r '.data.successful[0].data.requestId')

# 2. Expand scene descriptions (can run while music generates)
SCENES=()
DESCRIPTIONS=("Sunrise over mountain peaks" "Eagle soaring through clouds" "River rushing through canyon" "Castle revealed on cliff edge")
CAMERAS=("pan_right" "tracking" "zoom_in" "dolly_in")

for i in $(seq 0 3); do
  EXPANDED=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/expand-scene" \
    -H "Authorization: Bearer $VERSELY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"description\": \"${DESCRIPTIONS[$i]}\",
      \"context\": \"Epic fantasy adventure\",
      \"style\": \"cinematic\",
      \"camera\": \"${CAMERAS[$i]}\"
    }")
  SCENE_TEXT=$(echo $EXPANDED | jq -r '.expanded')
  SCENES+=("$SCENE_TEXT")
done

# 3. Generate storyboard video
SCENES_JSON=$(printf '%s\n' "${SCENES[@]}" | jq -R '{description: ., duration: "5"}' | jq -s .)
STORY_RESP=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/story" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"Sora 2 Pro Storyboard\",
    \"scenes\": $SCENES_JSON,
    \"aspect_ratio\": \"16:9\"
  }")
STORY_RID=$(echo $STORY_RESP | jq -r '.data.successful[0].data.requestId')

# 4. Poll both music and story
for RID_NAME in "MUSIC:$MUSIC_RID" "STORY:$STORY_RID"; do
  NAME="${RID_NAME%%:*}"
  RID="${RID_NAME##*:}"
  for attempt in $(seq 1 60); do
    STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$RID" \
      -H "Authorization: Bearer $VERSELY_API_KEY")
    STATE=$(echo $STATUS | jq -r '.status')
    if [ "$STATE" = "completed" ]; then
      URL=$(echo $STATUS | jq -r '.result_url')
      echo "$NAME ready: $URL"
      if [ "$NAME" = "MUSIC" ]; then MUSIC_URL="$URL"; fi
      if [ "$NAME" = "STORY" ]; then MOVIE_URL="$URL"; fi
      break
    elif [ "$STATE" = "failed" ]; then
      echo "$NAME failed"; break
    fi
    sleep 10
  done
done

echo "Movie: $MOVIE_URL"
echo "Music: $MUSIC_URL"
# The user can combine these via a video editor or the agentic chat merge tool
```

**Credit cost:** Music (~10) + 4 scene expansions (0) + Storyboard 20s (~120) = **~130 credits**.

## Error Recovery

When a pipeline step fails:

### Step 1 fails (generation)
- **Action:** Retry once with the same model. If still failing, try a different model.
- **No credits wasted** on later steps since the pipeline hasn't continued.

### Mid-pipeline step fails (overlay, caption, video conversion)
- **Action:** The media from previous steps is already generated and available via its URL.
- **Recovery:** Retry the failed step with the same input URL. Don't re-generate earlier steps.
- **Example:** If text overlay fails, the slideshow images are still available. Retry the overlay or skip it and convert to video without overlays.

### Last step fails (social posting)
- **Action:** The media is ready — only the post failed.
- **Recovery:** Retry the post. If the platform rejects it (aspect ratio, file size), adjust the media format and try again.
- **Credits:** PostBridge auto-refunds credits on platform failures.

### General rules
1. **Never re-generate** content from earlier steps — URLs remain valid.
2. **Check credits** between expensive steps if the pipeline is long.
3. **Report partial results** to the user — a generated image without a post is still useful.
4. **Store intermediate URLs** in variables so the user can resume manually.

## Platform Optimization

When building pipelines that end with social posting, choose the right format:

| Platform | Best Format | Aspect Ratio | Content Type |
|----------|------------|--------------|--------------|
| Instagram Reels | Video | 9:16 | `"reel"` |
| Instagram Feed | Image/Carousel | 1:1 or 4:5 | `"post"` / `"portrait"` |
| TikTok | Video | 9:16 | `"reel"` |
| YouTube Shorts | Video | 9:16 | `"reel"` |
| YouTube | Video | 16:9 | `"landscape"` |
| Twitter/X | Image | 16:9 | `"landscape"` |
| LinkedIn | Image | 1:1 or 16:9 | `"post"` / `"landscape"` |
| Pinterest | Image | 2:3 or 9:16 | `"portrait"` / `"reel"` |

**Multi-platform tip:** Generate content at 9:16 for short-form video platforms (Instagram Reels, TikTok, YouTube Shorts) or 1:1 for cross-platform image posts.

## Error Handling

- **401 Unauthorized** — API key invalid or expired.
- **402 Payment Required** — Insufficient credits. Calculate total pipeline cost before starting.
- **403 Forbidden** — API key lacks required scope. Pipelines may need multiple scopes: `generate`, `post`.
- **429 Too Many Requests** — Rate limited. Wait for `X-RateLimit-Reset`.
- **500 Internal Server Error** — Retry the specific failed step once.
- **Generation timeout** (5+ min) — Try a different model for that step.

## Rate Limits

- Default: 60 requests/minute per API key
- Generation: 20 requests/minute
- Social posting: 10 requests/minute
- Status polling: 1 request every 5 seconds per request_id
- Response headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

For reusable workflow templates, see [workflow-templates.md](workflow-templates.md).
