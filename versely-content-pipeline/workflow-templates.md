# Workflow Templates — Versely Content Pipeline

Reusable templates with variable placeholders. Replace `{{variables}}` with actual values.

---

## Template: Quick Generate & Post

Generate one piece of content and post immediately. Simplest pipeline.

**Variables:** `{{PROMPT}}`, `{{MODEL}}`, `{{ASPECT_RATIO}}`, `{{CAPTION}}`, `{{PLATFORMS}}`

```bash
# Budget: ~4-12 credits (2 for image + 2 per platform)

# Generate
RESP=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "{{MODEL}}", "prompt": "{{PROMPT}}", "aspect_ratio": "{{ASPECT_RATIO}}"}')
RID=$(echo $RESP | jq -r '.data.successful[0].data.requestId')

# Poll
for i in $(seq 1 60); do
  S=$(curl -s "$VERSELY_API_URL/api/v1/status/$RID" -H "Authorization: Bearer $VERSELY_API_KEY")
  [ "$(echo $S | jq -r '.status')" = "completed" ] && { URL=$(echo $S | jq -r '.result_url'); break; }
  [ "$(echo $S | jq -r '.status')" = "failed" ] && { echo "Failed"; exit 1; }
  sleep 5
done

# Post (filter accounts by platform)
ACCOUNTS=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
# {{PLATFORMS}} example: "instagram", "tiktok"
IDS=$(echo $ACCOUNTS | jq '[.accounts[] | select(.platform == "{{PLATFORMS}}") | .id]')

curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"caption\": \"{{CAPTION}}\", \"media_urls\": [\"$URL\"], \"account_ids\": $IDS}"
```

---

## Template: Slideshow Reel

AI-generated slideshow → text overlays → video → post as reel.

**Variables:** `{{PROMPT}}`, `{{NUM_IMAGES}}`, `{{OVERLAY_TEXTS}}` (array), `{{CAPTION}}`, `{{DURATION_PER_IMAGE}}`

```bash
# Budget: ~{{NUM_IMAGES}} * 2 + 4 credits (images + 2 platforms)

# Create slideshow
SS=$(curl -s -X POST "$VERSELY_API_URL/api/v1/slideshow/create" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "{{PROMPT}}", "num_images": {{NUM_IMAGES}}, "content_type": "reel"}')
SSID=$(echo $SS | jq -r '.data.slideshow_id')
IMGS=$(echo $SS | jq -r '.data.images')

# Add text overlays (one per image)
# {{OVERLAY_TEXTS}} = ["Text 1", "Text 2", ...]
OVL='[]'
for i in $(seq 0 $(({{NUM_IMAGES}} - 1))); do
  IID=$(echo $IMGS | jq -r ".[$i].id")
  TXT=$(echo '{{OVERLAY_TEXTS}}' | jq -r ".[$i]")
  OVL=$(echo $OVL | jq --arg id "$IID" --arg t "$TXT" \
    '. + [{"image_id": $id, "text": $t, "position": "bottom", "style": "bold", "background": "gradient"}]')
done
curl -s -X POST "$VERSELY_API_URL/api/v1/slideshow/$SSID/text-overlay" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"overlays\": $OVL}"

# Convert to video
VID=$(curl -s -X POST "$VERSELY_API_URL/api/v1/slideshow/$SSID/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"duration_per_image": {{DURATION_PER_IMAGE}}, "transition": "crossfade", "use_edited_images": true}')
VURL=$(echo $VID | jq -r '.data.video_url')

# Post as reel
ACCOUNTS=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
RIDS=$(echo $ACCOUNTS | jq '[.accounts[] | select(.platform == "instagram" or .platform == "tiktok") | .id]')
curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"caption\": \"{{CAPTION}}\", \"media_urls\": [\"$VURL\"], \"account_ids\": $RIDS}"
```

---

## Template: Product Carousel

Multiple product image variations → Instagram carousel.

**Variables:** `{{PRODUCT_PROMPTS}}` (array of 3-10 prompts), `{{CAPTION}}`

```bash
# Budget: ~2 credits per image + 2 credits for Instagram

RIDS=()
for PROMPT in {{PRODUCT_PROMPTS}}; do
  R=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
    -H "Authorization: Bearer $VERSELY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"Flux Pro Ultra\", \"prompt\": \"$PROMPT\", \"aspect_ratio\": \"1:1\"}")
  RIDS+=($(echo $R | jq -r '.data.successful[0].data.requestId'))
done

# Poll all
URLS=()
for RID in "${RIDS[@]}"; do
  for a in $(seq 1 60); do
    S=$(curl -s "$VERSELY_API_URL/api/v1/status/$RID" -H "Authorization: Bearer $VERSELY_API_KEY")
    if [ "$(echo $S | jq -r '.status')" = "completed" ]; then
      URLS+=($(echo $S | jq -r '.result_url')); break
    fi
    sleep 5
  done
done

MEDIA=$(printf '%s\n' "${URLS[@]}" | jq -R . | jq -s .)
IG=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | \
  jq -r '[.accounts[] | select(.platform == "instagram") | .id][0]')

curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"caption\": \"{{CAPTION}}\", \"media_urls\": $MEDIA, \"account_ids\": [\"$IG\"]}"
```

---

## Template: UGC Video

Product video + talking head overlay + auto-captions.

**Variables:** `{{PRODUCT_PROMPT}}`, `{{TALKING_HEAD_URL}}`, `{{OVERLAY_POSITION}}`, `{{CAPTION_STYLE}}`

```bash
# Budget: ~10 credits (video generation) + 0 (UGC processing)

# Generate product video
R=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "Sora 2 Text to Video", "prompt": "{{PRODUCT_PROMPT}}", "duration": "10", "aspect_ratio": "9:16"}')
RID=$(echo $R | jq -r '.data.successful[0].data.requestId')

for i in $(seq 1 60); do
  S=$(curl -s "$VERSELY_API_URL/api/v1/status/$RID" -H "Authorization: Bearer $VERSELY_API_KEY")
  [ "$(echo $S | jq -r '.status')" = "completed" ] && { PVID=$(echo $S | jq -r '.result_url'); break; }
  sleep 10
done

# Overlay talking head
OVL=$(curl -s -X POST "$VERSELY_API_URL/api/v1/ugc/add-video-overlay" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"slideshow_video_url\": \"$PVID\",
    \"overlay_video_url\": \"{{TALKING_HEAD_URL}}\",
    \"position\": \"{{OVERLAY_POSITION}}\",
    \"overlay_size\": \"small\"
  }")
UGCVID=$(echo $OVL | jq -r '.data.video_url')

# Auto-caption
CAP=$(curl -s -X POST "$VERSELY_API_URL/api/v1/captions/auto" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"video_url\": \"$UGCVID\", \"words_per_segment\": 3, \"style\": {{CAPTION_STYLE}}}")
echo "Final: $(echo $CAP | jq -r '.video_url')"
```

---

## Template: Scheduled Content Week

7 posts scheduled across a week at optimal posting times.

**Variables:** `{{PROMPTS}}` (7 items), `{{CAPTIONS}}` (7 items), `{{START_DATE}}`, `{{PLATFORM}}`

```bash
# Budget: 7 * 2 (images) + 7 * 2 (posts) = ~28 credits

ACCT=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | \
  jq -r "[.accounts[] | select(.platform == \"{{PLATFORM}}\") | .id][0]")

# Optimal times per day (UTC)
TIMES=("14:00" "12:00" "15:00" "11:00" "13:00" "10:00" "16:00")

for i in $(seq 0 6); do
  # Generate
  R=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
    -H "Authorization: Bearer $VERSELY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"Flux Pro Ultra\", \"prompt\": \"$(echo '{{PROMPTS}}' | jq -r ".[$i]")\", \"aspect_ratio\": \"1:1\"}")
  RID=$(echo $R | jq -r '.data.successful[0].data.requestId')

  for a in $(seq 1 60); do
    S=$(curl -s "$VERSELY_API_URL/api/v1/status/$RID" -H "Authorization: Bearer $VERSELY_API_KEY")
    [ "$(echo $S | jq -r '.status')" = "completed" ] && { IMG=$(echo $S | jq -r '.result_url'); break; }
    sleep 5
  done

  SCHED=$(date -j -v+${i}d -f "%Y-%m-%d" "{{START_DATE}}" "+%Y-%m-%dT${TIMES[$i]}:00Z" 2>/dev/null || \
    date -d "{{START_DATE}} + $i days" "+%Y-%m-%dT${TIMES[$i]}:00Z")

  curl -s -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
    -H "Authorization: Bearer $VERSELY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"caption\": \"$(echo '{{CAPTIONS}}' | jq -r ".[$i]")\",
      \"media_urls\": [\"$IMG\"],
      \"account_ids\": [\"$ACCT\"],
      \"scheduled_at\": \"$SCHED\"
    }"

  echo "Day $((i+1)): Scheduled for $SCHED"
done
```

---

## Template: TTS Voiceover Reel

Generate a video, add AI voiceover with auto-synced captions.

**Variables:** `{{VIDEO_PROMPT}}`, `{{VOICEOVER_TEXT}}`, `{{VOICE_ID}}`, `{{CAPTION}}`

```bash
# Budget: ~10 credits (video) + 0 (TTS/captions) + 4 (2 platforms)

# Generate background video
R=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "VEO 3.1 Fast", "prompt": "{{VIDEO_PROMPT}}", "duration": "10", "aspect_ratio": "9:16"}')
RID=$(echo $R | jq -r '.data.successful[0].data.requestId')

for i in $(seq 1 60); do
  S=$(curl -s "$VERSELY_API_URL/api/v1/status/$RID" -H "Authorization: Bearer $VERSELY_API_KEY")
  [ "$(echo $S | jq -r '.status')" = "completed" ] && { VID=$(echo $S | jq -r '.result_url'); break; }
  sleep 10
done

# Add TTS voiceover + captions
TTS=$(curl -s -X POST "$VERSELY_API_URL/api/v1/captions/tts-voiceover" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"video_url\": \"$VID\",
    \"text\": \"{{VOICEOVER_TEXT}}\",
    \"voice_id\": \"{{VOICE_ID}}\",
    \"style\": {\"fontsize\": 48, \"position\": \"bottom\"}
  }")
FINAL=$(echo $TTS | jq -r '.video_url')

# Post to short-form platforms
ACCTS=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | \
  jq '[.accounts[] | select(.platform == "instagram" or .platform == "tiktok") | .id]')

curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"caption\": \"{{CAPTION}}\", \"media_urls\": [\"$FINAL\"], \"account_ids\": $ACCTS}"
```

---

## Template: Multi-Platform Batch

Same content, adapted for different platforms simultaneously.

**Variables:** `{{TOPIC}}`, `{{CAPTION_SHORT}}` (Twitter/Bluesky), `{{CAPTION_LONG}}` (LinkedIn/YouTube)

```bash
# Budget: ~6 credits (3 images) + ~14 (7 platforms) = ~20 credits

# Generate 3 versions: square, landscape, vertical
for SPEC in "1:1:post" "16:9:landscape" "9:16:reel"; do
  AR="${SPEC%%:*:*}"
  AR="${SPEC%:*}"
  CT="${SPEC##*:}"
  R=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
    -H "Authorization: Bearer $VERSELY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"Flux Pro Ultra\", \"prompt\": \"{{TOPIC}}\", \"aspect_ratio\": \"$AR\"}")
  RID=$(echo $R | jq -r '.data.successful[0].data.requestId')
  # Store RID for polling...
done

# After polling, post to each platform with the right aspect ratio:
# Instagram (1:1), Twitter (16:9), TikTok (9:16), LinkedIn (1:1), etc.
```

---

## Credit Calculator

Quick formula to estimate pipeline costs:

```
Total = (num_images × image_cost) + (num_videos × video_cost) + (num_music × music_cost) + (num_platforms × 2)
```

| Variable | Typical Value |
|----------|---------------|
| `image_cost` | 2 (Flux Pro Ultra) |
| `video_cost` | 10 (Sora 2, 5s) |
| `music_cost` | 10 (Suno V5) |
| `platform_cost` | 2 per platform |
| UGC processing | 0 |
| Slideshow video conversion | 0 |
| Scene expansion | 0 |
