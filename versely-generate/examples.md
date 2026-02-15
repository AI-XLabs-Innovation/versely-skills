# Examples — Versely Generate

Real workflow examples using the Versely generation API.

## Example 1: Generate a Product Photo

```bash
# 1. Check credits
CREDITS=$(curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.credits')
echo "Available credits: $CREDITS"

# 2. Generate the image
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Flux Pro Ultra",
    "prompt": "Professional product photo of a minimalist white coffee mug on a marble surface, soft studio lighting, 4K, commercial photography",
    "aspect_ratio": "1:1"
  }')

REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId')
echo "Request ID: $REQUEST_ID"

# 3. Poll for result
for i in $(seq 1 30); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$REQUEST_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo $STATUS | jq -r '.status')
  if [ "$STATE" = "completed" ]; then
    echo "Image URL: $(echo $STATUS | jq -r '.result_url')"
    break
  elif [ "$STATE" = "failed" ]; then
    echo "Generation failed"
    break
  fi
  echo "Generating... (attempt $i)"
  sleep 5
done
```

## Example 2: Generate Multiple Image Variations

Generate the same prompt with 3 different models to compare:

```bash
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": ["Flux Pro Ultra", "Imagen 4 Ultra", "Midjourney V7"],
    "prompt": "A futuristic city skyline at dusk, neon lights reflecting on water",
    "aspect_ratio": "16:9"
  }')

# Extract all request IDs
echo $RESPONSE | jq '.data.successful[] | {model: .data.model, requestId: .data.requestId}'
```

## Example 3: Edit an Image

```bash
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Nano Banana Edit",
    "prompt": "Change the background to a tropical beach sunset",
    "image_url": "https://example.com/original-photo.jpg"
  }')

REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId')
```

## Example 4: Generate and Upscale

```bash
# 1. Generate a base image with a fast model
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Imagen 4 Fast",
    "prompt": "Detailed fantasy map of an imaginary kingdom"
  }')

REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId')

# 2. Wait for completion
for i in $(seq 1 30); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$REQUEST_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo $STATUS | jq -r '.status')
  if [ "$STATE" = "completed" ]; then
    IMAGE_URL=$(echo $STATUS | jq -r '.result_url')
    break
  fi
  sleep 5
done

# 3. Upscale the result
UPSCALE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image-upscale" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"Topaz Upscale Image\",
    \"image_url\": \"$IMAGE_URL\",
    \"scale\": \"4x\"
  }")

UPSCALE_ID=$(echo $UPSCALE | jq -r '.data.successful[0].data.requestId')
echo "Upscaling... Request ID: $UPSCALE_ID"
```

## Example 5: Create a Short Video Ad

```bash
# Generate a 10-second product video
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 Text to Video Pro",
    "prompt": "Sleek product reveal of a smartwatch rotating on a dark surface, dramatic lighting, cinematic, 4K quality",
    "duration": "10",
    "aspect_ratio": "9:16",
    "resolution": "1080p"
  }')

REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId')

# Poll (videos take longer)
for i in $(seq 1 60); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$REQUEST_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo $STATUS | jq -r '.status')
  if [ "$STATE" = "completed" ]; then
    echo "Video URL: $(echo $STATUS | jq -r '.result_url')"
    break
  elif [ "$STATE" = "failed" ]; then
    echo "Video generation failed"
    break
  fi
  echo "Generating video... ($i/60)"
  sleep 10
done
```

## Example 6: Music Generation

```bash
# Generate a pop song
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/suno/generate" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "V5",
    "customMode": true,
    "instrumental": false,
    "style": "Pop, catchy, upbeat, summer vibes",
    "title": "Golden Hour",
    "prompt": "Verse 1:\nDriving down the coast with the windows down\nSun is setting painting the whole town\n\nChorus:\nGolden hour, golden hour\nEverything is ours right now",
    "vocalGender": "f"
  }')

echo $RESPONSE | jq '.data'
```

## Example 7: Generate Image Then Post to Social Media

Cross-skill workflow using versely-generate + versely-social:

```bash
# 1. Generate an image
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Flux Pro Ultra",
    "prompt": "Motivational quote card: Dream big, start small, act now. Modern gradient background.",
    "aspect_ratio": "1:1"
  }')
REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId')

# 2. Wait for image
for i in $(seq 1 30); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/status/$REQUEST_ID" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo $STATUS | jq -r '.status')
  if [ "$STATE" = "completed" ]; then
    IMAGE_URL=$(echo $STATUS | jq -r '.result_url')
    break
  fi
  sleep 5
done

# 3. Get social accounts
ACCOUNTS=$(curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
ACCOUNT_IDS=$(echo $ACCOUNTS | jq '[.accounts[].id]')

# 4. Post to all platforms
curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"caption\": \"Dream big, start small, act now. What's your goal for today?\",
    \"media_urls\": [\"$IMAGE_URL\"],
    \"account_ids\": $ACCOUNT_IDS
  }"
```
