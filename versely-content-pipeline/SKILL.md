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
    homepage: https://versely.studio
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
VERSELY_API_URL="https://api.versely.studio"
```

All requests use `Authorization: Bearer $VERSELY_API_KEY`. Do NOT send `user_id` for most endpoints — the API key resolves the user server-side via `enforceUserId` middleware.

**Exception — `/api/v1/captions/*`**: `/captions/auto` and `/captions/tts-voiceover` REQUIRE `user_id` in the body (these routes don't apply `enforceUserId`). When pipelines call captions endpoints, set:

```bash
USER_ID=$(curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.user.id')
```

## Required API Key Scopes

Pipelines span multiple scopes. The right set depends on which steps your pipeline uses:

| Scope | Needed for |
|---|---|
| `generate` | Image / video / music / sound-effect / movie generation |
| `post` | Creating, scheduling, listing, deleting social posts |
| `manage_accounts` | Listing/refreshing/connecting social accounts |
| `slideshow` | Slideshow creation, text overlays, video conversion |
| `ugc` | UGC overlays, captions (`/ugc/*`, `/captions/*`) |
| `workflows` | Saved/scheduled workflow execution (`/workflows/*`) |

For full coverage of every example in this skill, create a key with all six: `{"scopes": ["generate", "post", "manage_accounts", "slideshow", "ugc", "workflows"]}` — or use `{"scopes": ["all"]}` to grant every available scope. Live scope catalog: `GET /api/v1/auth/api-keys/scopes`.

## API Key Management — `/api/v1/auth/api-keys/*`

These endpoints let your code introspect and revoke keys. Key creation requires JWT auth (you can't make keys *with* a key — by design); list and revoke work with both JWT and API key auth.

```bash
# List all your active + revoked keys (works with API key auth)
curl "$VERSELY_API_URL/api/v1/auth/api-keys" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Discover the live scope catalog (definitions, prefixes, and the "all" sentinel)
curl "$VERSELY_API_URL/api/v1/auth/api-keys/scopes" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Revoke a key (soft-delete — sets revoked_at)
curl -X DELETE "$VERSELY_API_URL/api/v1/auth/api-keys/$KEY_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

**`POST /api/v1/auth/api-keys` — JWT-only**, used at onboarding from the dashboard:

```bash
# This will FAIL with API key auth — must use a session JWT
curl -X POST "$VERSELY_API_URL/api/v1/auth/api-keys" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production key",
    "scopes": ["generate", "post", "slideshow"],
    "rate_limit_rpm": 60,
    "credit_limit": 1000,
    "expires_at": "2027-01-01T00:00:00Z"
  }'
```

**Body:**
- `name` (required, max 100 chars)
- `scopes` (required, non-empty array — empty arrays are rejected). Pass `["all"]` to grant every scope (expanded server-side to the literal list, so audit logs reflect what was granted).
- `rate_limit_rpm` (optional, default 60)
- `credit_limit` (optional)
- `expires_at` (optional, ISO 8601)

**Response includes the raw `vsk_...` key ONLY ONCE.** Save it immediately — it's never stored in plaintext on the backend.

```json
{
  "success": true,
  "api_key": "vsk_<40-hex-chars>",
  "key_record": { "id": "...", "key_prefix": "vsk_abc123", "name": "...", "scopes": [...], "created_at": "..." }
}
```

**Errors:**
- `400` — empty / invalid scopes (the response lists valid scopes).
- `401` — JWT required for create.
- `404` (on revoke) — key not found or already revoked.

## User Profile & Generated Media — `/api/v1/user/*`

The `read` scope (or any scope you have, since `/user/me` is auth-only without scope check) gets you account info; per-userId data routes verify ownership against your authenticated identity.

```bash
# Profile + credit balance (the canonical "who am I?" call)
curl "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "email": "...",
    "credits": 1234,
    "full_name": "...",
    "avatar_id": "..."
  }
}
```

### Per-User Data Routes

Every `/user/:userId/*` route requires `:userId` to match your authenticated user (otherwise `403`). Pull your ID from `/user/me` and reuse:

```bash
USER_ID=$(curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.user.id')

# Credits balance (subset of /user/me)
curl "$VERSELY_API_URL/api/v1/user/$USER_ID/credits" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Generated media (paginated; supports session_id, batch_id filters)
curl "$VERSELY_API_URL/api/v1/user/$USER_ID/images?limit=20&offset=0" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
curl "$VERSELY_API_URL/api/v1/user/$USER_ID/videos?limit=20" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
curl "$VERSELY_API_URL/api/v1/user/$USER_ID/audios?limit=20" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
curl "$VERSELY_API_URL/api/v1/user/$USER_ID/music?limit=20" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
curl "$VERSELY_API_URL/api/v1/user/$USER_ID/slideshows?limit=20" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
curl "$VERSELY_API_URL/api/v1/user/$USER_ID/ugc?limit=20" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# In-flight generations for a content type (image | video | audio | music)
curl "$VERSELY_API_URL/api/v1/user/$USER_ID/image/scheduledjobs?limit=10&offset=0" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Single image lookup by image ID
curl "$VERSELY_API_URL/api/v1/user/$IMAGE_ID/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Delete a single generation (type: image | video | audio | music | slideshow | ugc)
curl -X DELETE "$VERSELY_API_URL/api/v1/user/generation/image/$ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

### Projects (folder-style grouping for your generations)

```bash
# Create
curl -X POST "$VERSELY_API_URL/api/v1/user/create-project" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "name": "Q3 campaign", "user_id": "'"$USER_ID"'", "urls": ["https://...", "https://..."] }'

# List (POST — passes filters in body; pass include="creations" to embed creation rows)
curl -X POST "$VERSELY_API_URL/api/v1/user/get-projects" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "userId": "'"$USER_ID"'", "include": "creations" }'

# Single project
curl -X POST "$VERSELY_API_URL/api/v1/user/get-project-by-id" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "projectId": "'"$PROJECT_ID"'", "user_id": "'"$USER_ID"'" }'

# Append URLs to a project
curl -X POST "$VERSELY_API_URL/api/v1/user/save-urls-to-project" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "projectId": "'"$PROJECT_ID"'", "user_id": "'"$USER_ID"'", "urls": ["https://..."] }'
```

### Account-Level

```bash
# Purchase history (credit top-ups, subscriptions)
curl "$VERSELY_API_URL/api/v1/user/purchase-history" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Profile avatar
curl "$VERSELY_API_URL/api/v1/user/avatar/$USER_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

curl -X POST "$VERSELY_API_URL/api/v1/user/avatar" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "user_id": "'"$USER_ID"'", "avatar_id": "<heygen-or-uploaded-avatar-id>" }'

# Add credits (typically gated to internal flows / Stripe webhook)
curl -X POST "$VERSELY_API_URL/api/v1/user/add-credits" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "user_id": "'"$USER_ID"'", "credits": 100 }'

# Hard-delete the account (irreversible — confirm with the user first)
curl -X POST "$VERSELY_API_URL/api/v1/user/delete-account/$USER_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

⚠ `delete-account` is destructive. Before calling it programmatically, get explicit user confirmation — there is no soft-delete equivalent.

## Stock B-Roll — `/api/v1/broll/*`

Source viral-format stock footage to use as raw material for slideshows, UGC overlays, or movie scene fills. Backed by DanSUGC. Mounted under the `generate` scope (B-roll counts as content creation), not its own scope.

### Search & browse

```bash
# Free B-roll clips Versely ships
curl "$VERSELY_API_URL/api/v1/broll/free" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Search the paid catalog (most query params pass through to DanSUGC)
curl "$VERSELY_API_URL/api/v1/broll/search?search=morning+routine&emotion=happy&gender=female&limit=20&offset=0" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Viral TikTok formats (themed packs)
curl "$VERSELY_API_URL/api/v1/broll/formats?niche=fitness&difficulty=easy&limit=20" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Single video detail
curl "$VERSELY_API_URL/api/v1/broll/$VIDEO_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

**Search query params (all optional):** `search`, `semantic_search`, `emotion`, `gender`, `limit`, `offset`, `page`, `location`, `age_range`, `hair_color`, `outfit`, `model_id`, `min_virality`, `difficulty`, `min_difficulty`, `max_difficulty`, `featured`, `is_daily_drop`, `sort_by`, `sort_order`.

**Format query params:** `niche`, `category`, `difficulty`, `min_difficulty`, `max_difficulty`, `featured`, `limit`, `offset`.

### Stream a free clip directly

```bash
# Streams the file through Versely's backend (avoids signed-URL issues on mobile)
curl "$VERSELY_API_URL/api/v1/broll/stream/$KEY" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -o clip.mp4
```

`$KEY` must be from the free-broll manifest (`/broll/free` returns the keys you can stream). Arbitrary-key access is rejected with 404.

### Purchase paid clips

```bash
curl -X POST "$VERSELY_API_URL/api/v1/broll/purchase" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "video_ids": ["vid_abc", "vid_def"] }'
```

Charges credits up front (`CREDITS_PER_VIDEO × video_ids.length`). Backend deducts → calls DanSUGC purchase → refunds on DanSUGC failure. Response includes the purchased URLs.

### Purchase history

```bash
curl "$VERSELY_API_URL/api/v1/broll/purchases?search=&customer_email=&start_date=&end_date=&page=1&limit=20" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Same passthrough filters as search, plus `customer_email`, `start_date`, `end_date`.

### B-Roll → UGC pipeline pattern

```bash
# 1. Find a clip
HIT=$(curl -s "$VERSELY_API_URL/api/v1/broll/search?search=cooking&limit=1" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
VIDEO_URL=$(echo "$HIT" | jq -r '.data[0].video_url')

# 2. Use it as the base of a UGC compose-with-overlay (see versely-ugc)
curl -X POST "$VERSELY_API_URL/api/v1/ugc/compose-with-overlay" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"base_media\": [{ \"kind\": \"video\", \"url\": \"$VIDEO_URL\" }],
    \"overlay_video_url\": \"https://example.com/talking-head.mp4\",
    \"position\": \"bottom-right\",
    \"output_aspect\": \"9:16\"
  }"
```

**Tip:** prefer free clips for iteration. Only call `/broll/purchase` once you've validated the rest of the pipeline produces what you want.

## Before Any Pipeline — Credit Budget

Always calculate total cost BEFORE starting a multi-step pipeline. A failed mid-pipeline step wastes credits already spent on earlier steps.

```bash
# Check current balance
CREDITS=$(curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.user.credits')
echo "Available credits: $CREDITS"
```

**Quick cost reference** (API keys get 2x pricing — half of in-app costs):

| Operation | Credits |
|-----------|---------|
| Image (Flux Pro Ultra) | ~1 |
| Image (Imagen 4) | ~1 |
| Video 5s (Sora 2) | ~5 |
| Video 5s (VEO 3.1) | ~2 |
| Music (Suno V5) | ~5 |
| Slideshow (5 images) | ~5 |
| Storyboard (10s, Sora 2 Pro) | ~30 |
| Social post per platform | 1 |
| UGC overlay / captions | 0 (processing only) |

**Example budget:** "Create a 5-image slideshow reel and post to Instagram + TikTok"
- 5 images x 1 credit = 5
- Video conversion = 0 (FFmpeg, no credit cost)
- 2 platforms x 1 credit = 2
- **Total: ~7 credits**

If `CREDITS < estimated total`, tell the user before starting.

## Pipeline 1: Generate & Post

Generate a single image or video and immediately post to social media.

**Steps:** Generate media → Poll → Post

```bash
# 1. Check credits
CREDITS=$(curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.user.credits')
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
ACCOUNTS=$(curl -s "$VERSELY_API_URL/api/v1/social/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
ACCOUNT_IDS=$(echo $ACCOUNTS | jq '[.accounts[].id]')

# 5. Post to all connected platforms
curl -X POST "$VERSELY_API_URL/api/v1/social/posts" \
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
ACCOUNTS=$(curl -s "$VERSELY_API_URL/api/v1/social/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
# Filter to Instagram and TikTok only
REEL_ACCOUNTS=$(echo $ACCOUNTS | jq '[.accounts[] | select(.platform == "instagram" or .platform == "tiktok") | .id]')

curl -X POST "$VERSELY_API_URL/api/v1/social/posts" \
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
IG_ACCOUNT=$(curl -s "$VERSELY_API_URL/api/v1/social/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | \
  jq -r '[.accounts[] | select(.platform == "instagram") | .id][0]')

curl -X POST "$VERSELY_API_URL/api/v1/social/posts" \
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
IG_ACCOUNT=$(curl -s "$VERSELY_API_URL/api/v1/social/accounts" \
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
  curl -s -X POST "$VERSELY_API_URL/api/v1/social/posts" \
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

**Credit cost:** 7 images (7 credits) + 7 posts x 1 platform (7 credits) = **~14 credits**.

## Pipeline 5: UGC Product Review

Generate a product video, overlay a talking-head, add auto-timed captions.

**Steps:** Generate video → Overlay talking head → Auto-caption

```bash
# 0. Resolve USER_ID — required because /api/v1/captions/auto enforces user_id in body
USER_ID=$(curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.user.id')

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
    \"user_id\": \"$USER_ID\",
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
MUSIC_RID=$(echo $MUSIC_RESP | jq -r '.data.taskId')  # Suno returns {data: {taskId, dbRecordId}}, NOT the fal-style data.successful[]

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

**Credit cost:** Music (~5) + 4 scene expansions (0) + Storyboard 20s (~60) = **~65 credits**.

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
- **Credits:** Post for Me auto-refunds credits on platform failures.

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
- **403 Forbidden** — API key lacks a required scope (pipelines often need multiple: `generate`, `post`, `slideshow`, `ugc`), OR account balance ≤ 0 at request entry, OR `user_id` mismatch. Calculate total pipeline cost before starting.
- **402 Payment Required** — Per-call credit deduction failed mid-pipeline (balance dropped between request entry and deduction). Earlier successful steps remain — don't re-generate them.
- **429 Too Many Requests** — Rate limited. Wait for `X-RateLimit-Reset`.
- **500 Internal Server Error** — Retry the specific failed step once.
- **Generation timeout** (5+ min) — Try a different model for that step.

## Rate Limits

- Default: 60 requests/minute per API key
- Generation (`/generate`, `/suno`, `/audio`): 30 requests/minute, IP-based (cost-sensitive)
- Social posting (`/social/posts`): 10 requests/minute per user
- Account refresh (`/social/accounts/refresh`): 5 requests/minute per user
- `/slideshow/*` and `/ugc/*` and `/captions/*`: only the per-API-key 60/min default — no cost-sensitive limiter
- Status polling: 1 request every 5 seconds per request_id
- Response headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

For reusable workflow templates, see [workflow-templates.md](workflow-templates.md).

## Saved Workflows — run, poll, retrieve outputs

Saved workflows live at `/api/v1/workflows/*` and have two execution modes that look identical to callers from this side:

| Mode | What it is | Backed by |
|---|---|---|
| `scenes` | Versely scene workflows (multi-scene video, the modern flow) | `video_workflow_runs` + `video_workflow_run_scenes` |
| `steps` | Legacy step-based workflows | `background_tasks` |

**Required scope:** `workflows`.

### Trigger a run

```bash
RUN=$(curl -s -X POST "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID/run" \
  -H "Authorization: Bearer $VERSELY_API_KEY")

RUN_ID=$(echo "$RUN" | jq -r '.run_id')
MODE=$(echo "$RUN" | jq -r '.mode')        # "scenes" or "steps"
POLL_URL=$(echo "$RUN" | jq -r '.poll_url')  # /api/v1/workflows/runs/<run_id>
echo "Started $MODE run $RUN_ID — poll $POLL_URL"
```

The `run_id` field is unified across both modes, and the response includes a `poll_url` you can use directly. No need to dispatch on `mode` for polling — only for interpreting the response shape.

### Poll until done

```bash
for i in $(seq 1 120); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/workflows/runs/$RUN_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo "$STATUS" | jq -r '.run.status')
  echo "Run $RUN_ID: $STATE"

  case "$STATE" in
    completed|succeeded|finished)
      break
      ;;
    failed|error|cancelled)
      echo "Run failed: $(echo "$STATUS" | jq -r '.run.error_message')"
      exit 1
      ;;
  esac
  sleep 10
done
```

### Read outputs

The `mode` field at the top level tells you which response shape to expect:

**`mode: "scenes"`** — final output and per-scene assets:
```bash
# Final stitched video URL (set when status = completed and the combine step ran)
echo "$STATUS" | jq -r '.run.final_video_url'

# Per-scene output videos + status
echo "$STATUS" | jq '.scenes[] | {order: .scene_order, status, video: .output_video_url, image: .output_image_url}'
```

If `final_video_url` is null but every scene shows `status: "completed"`, manually trigger the merge:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/video-workflows/runs/$RUN_ID/combine?wait=true" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

To retry a single failed scene without re-running the whole workflow:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/video-workflows/runs/$RUN_ID/scenes/$SCENE_ORDER/retry" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

**`mode: "steps"`** — per-step outputs in `step_results`:
```bash
# Each step's output is keyed by step_id
echo "$STATUS" | jq '.run.step_results'

# Current progress
echo "$STATUS" | jq '{step: .run.current_step_index, total: .run.total_steps}'
```

### List a workflow's runs

`GET /api/v1/workflows/$WORKFLOW_ID/runs` returns BOTH manual and scheduled runs across BOTH modes, merged chronologically. Each entry is tagged with `mode` so you can tell them apart:

```bash
curl -s "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID/runs?limit=20" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq '.runs[] | {mode, id, status, created_at}'
```

### Common gotchas

- **`media_assets` on the workflow row is unrelated to scene-run outputs.** That column is the workflow's reference-asset bag (input). Per-run outputs live on `video_workflow_run_scenes.output_video_url` (read via `/workflows/runs/:id`), not on the workflow.
- **Don't poll Post-for-Me-style HTTP webhooks.** Workflow runs are pull-based — keep polling `/workflows/runs/:id` until the status reaches a terminal state.
- **Don't try to cancel via DELETE.** Use `POST /api/v1/video-workflows/runs/:id/cancel` for in-flight cancellation. `DELETE /workflows/:id` deletes the saved workflow itself, not a single run.

### Saved Workflow CRUD

```bash
# Create
curl -X POST "$VERSELY_API_URL/api/v1/workflows" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Daily reel pipeline",
    "description": "Generate slideshow → convert → post",
    "mode": "scenes",
    "definition": { ... },
    "asset_map": { "logo": "asset_xxx" },
    "schedule": { "frequency": "daily", "hour": 9 }
  }'

# List
curl "$VERSELY_API_URL/api/v1/workflows" -H "Authorization: Bearer $VERSELY_API_KEY"

# Get one (full definition + assets)
curl "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Update — PATCH (NOT PUT)
curl -X PATCH "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "name": "Renamed", "description": "..." }'

# Granular updates (each is a separate PATCH endpoint to avoid clobbering)
curl -X PATCH "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID/mode" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "mode": "scenes" }'

curl -X PATCH "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID/schedule" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "schedule": { "frequency": "weekly", "day": "monday", "hour": 9 } }'

curl -X PATCH "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID/dates" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "scheduled_dates": ["2026-05-12", "2026-05-15"] }'

curl -X PATCH "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID/assets" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "asset_map": { "logo": "asset_xyz", "intro": "asset_abc" } }'

# Duplicate (clones definition + assets, returns new workflow_id)
curl -X POST "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID/duplicate" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Export (download portable JSON)
curl "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID/export" \
  -H "Authorization: Bearer $VERSELY_API_KEY" > workflow.json

# Delete
curl -X DELETE "$VERSELY_API_URL/api/v1/workflows/$WORKFLOW_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

## Workflow Assets — `/api/v1/workflow-assets/*`

User-scoped reusable asset bags referenced by workflows through their `asset_map` (e.g., your brand logo, B-roll footage, voiceover snippets). Required scope: `workflows`.

```bash
# Create
curl -X POST "$VERSELY_API_URL/api/v1/workflow-assets" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Brand logo set",
    "kind": "images",
    "images": [
      "https://example.com/logo-light.png",
      "https://example.com/logo-dark.png"
    ],
    "metadata": { "tags": ["logo", "brand"] }
  }'

# List
curl "$VERSELY_API_URL/api/v1/workflow-assets" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Get one
curl "$VERSELY_API_URL/api/v1/workflow-assets/$ASSET_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Update metadata / name (replaces fields you supply)
curl -X PATCH "$VERSELY_API_URL/api/v1/workflow-assets/$ASSET_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "name": "Renamed asset" }'

# Append images (additive — does not replace)
curl -X POST "$VERSELY_API_URL/api/v1/workflow-assets/$ASSET_ID/images" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "images": ["https://example.com/new-logo.png"] }'

# Delete
curl -X DELETE "$VERSELY_API_URL/api/v1/workflow-assets/$ASSET_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Reference assets in workflow `asset_map`:
```json
{ "asset_map": { "logo": "asset_xxx", "broll": "asset_yyy" } }
```

## Video-Workflow Templates — `/api/v1/video-workflows/*`

Template + run model used internally by the saved-workflow `scenes` mode. Most users go through `/workflows/*` instead, but `/video-workflows/*` is exposed if you want to drive scene runs directly.

### Templates

```bash
# CRUD
curl -X POST "$VERSELY_API_URL/api/v1/video-workflows/templates" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "name": "Reel pipeline", "definition": { ... } }'

curl "$VERSELY_API_URL/api/v1/video-workflows/templates" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

curl "$VERSELY_API_URL/api/v1/video-workflows/templates/$TEMPLATE_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

curl -X PATCH "$VERSELY_API_URL/api/v1/video-workflows/templates/$TEMPLATE_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY" -H "Content-Type: application/json" \
  -d '{ "name": "Renamed" }'

curl -X DELETE "$VERSELY_API_URL/api/v1/video-workflows/templates/$TEMPLATE_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

### Runs (scene-by-scene)

```bash
# Start a run
curl -X POST "$VERSELY_API_URL/api/v1/video-workflows/runs" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "template_id": "tmpl_...", "inputs": { ... } }'

# List
curl "$VERSELY_API_URL/api/v1/video-workflows/runs" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Detail (includes per-scene state)
curl "$VERSELY_API_URL/api/v1/video-workflows/runs/$RUN_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Cancel an in-flight run
curl -X POST "$VERSELY_API_URL/api/v1/video-workflows/runs/$RUN_ID/cancel" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Manually trigger combine (auto-fires when last scene completes; call this only if it didn't)
curl -X POST "$VERSELY_API_URL/api/v1/video-workflows/runs/$RUN_ID/combine?wait=true" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Retry a specific scene by 1-indexed order
curl -X POST "$VERSELY_API_URL/api/v1/video-workflows/runs/$RUN_ID/scenes/2/retry" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

## Built-in Templates — `/api/v1/templates/*`

A higher-level abstraction over saved workflows: pre-built, parameterized template runs the platform ships with. Required scope: `workflows`.

```bash
# List available built-in templates
curl "$VERSELY_API_URL/api/v1/templates" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Start a template run with inputs
curl -X POST "$VERSELY_API_URL/api/v1/templates/runs" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": "tmpl_reel_5slide",
    "inputs": { "topic": "5 productivity tips", "style": "minimal" }
  }'

# List your past template runs
curl "$VERSELY_API_URL/api/v1/templates/runs" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Poll a single template run
curl "$VERSELY_API_URL/api/v1/templates/runs/$RUN_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

## Public Workflow Templates — `/api/v1/public-workflows/*`

Anonymous-readable gallery of public/community workflow templates. Cloning a public template into your account requires auth + the `workflows` scope.

```bash
# List public templates (no auth needed)
curl "$VERSELY_API_URL/api/v1/public-workflows"

# Get a single template by slug or ID (no auth needed)
curl "$VERSELY_API_URL/api/v1/public-workflows/reel-5slide-tips"

# Clone into your account (auth required) — returns the new workflow_id
curl -X POST "$VERSELY_API_URL/api/v1/public-workflows/reel-5slide-tips/clone" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

After cloning, the workflow is yours — edit it, schedule it, run it like any other saved workflow.
