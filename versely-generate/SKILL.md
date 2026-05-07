---
name: versely-generate
version: 1.0.0
description: >
  Generate AI images, videos, music, and sound effects using Versely's API.
  Supports 100+ image models (Flux 2, Imagen 4, Nano Banana 2, Midjourney V7, GPT Image 2, Recraft 4),
  60+ video models (Sora 2, VEO 3.1, Kling 2.5, Hailuo 2.3, Seedance 2.0, LTX 2.3, Wan 2.7, Pixverse V6),
  and music generation (Suno V3.5–V5.5). Use `GET /api/v1/generate/models` for the live model list.
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

## Required API Key Scope

**Scope:** `generate`. Covers `/generate/*`, `/suno/*`, `/audio/*`, `/movie/*`, `/lyria/*`, `/avatar/*`, `/inworld/*`, `/broll/*`, `/ltx-batch/*`, `/runpod/*`, `/replicate/*`.

Create a key at Settings > API Keys, or via `POST /api/v1/auth/api-keys` with `{"scopes": ["generate"]}`. Empty scope arrays are rejected; use `"all"` to grant every scope explicitly. Live scope catalog: `GET /api/v1/auth/api-keys/scopes`.

## Before Generating — Credit Check

Always check available credits before generating:

```bash
curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq '.user.credits'
```

**Approximate credit costs** (API keys are charged at half the in-app rate — `CREDITS_PER_USD_API = 10` vs `CREDITS_PER_USD_APP = 20`). The numbers below are stale and will be corrected in a follow-up; for accurate per-call cost, read `credits_charged` on slideshow / social responses, or compute from `pricing.ts` on the backend:

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

Same endpoint, but include input images. Edit / reference / I2V models take **`images` (array of URLs)**, not `image_url` (singular). The singular form is reserved for the upscale and background-removal endpoints.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Nano Banana Edit",
    "prompt": "Make the sky more dramatic with storm clouds",
    "images": ["https://example.com/photo.jpg"]
  }'
```

**Edit / reference-image models** (all take `images: [url, ...]`): Nano Banana Edit, Nano Banana 2 Edit, GPT Image 1 Edit, GPT Image 2 Edit, Reve Edit, Flux Kontext, Seedream Edit, Qwen Image Edit, Runway Gen4 Image, Midjourney V7 I2V.

| Field | Singular `image_url` | Array `images: [...]` |
|---|---|---|
| Used by | `/generate/image-upscale`, `/generate/background-removal` | `/generate/image` (edit/reference models), `/generate/video` (I2V/reference models), `/generate/lipsync` |

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

### Video Upscaling

**Endpoint:** `POST /api/v1/generate/video-upscale`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/video-upscale" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Bytedance Upscaler Video",
    "video_url": "https://example.com/clip.mp4"
  }'
```

### Discovering Models for Each Endpoint

```bash
# All models (optionally filter by provider)
curl "$VERSELY_API_URL/api/v1/generate/models" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
curl "$VERSELY_API_URL/api/v1/generate/models?provider=fal" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Per-capability model lists
curl "$VERSELY_API_URL/api/v1/generate/models/background-removal" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
curl "$VERSELY_API_URL/api/v1/generate/models/image-upscale" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
curl "$VERSELY_API_URL/api/v1/generate/models/video-upscale" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
curl "$VERSELY_API_URL/api/v1/generate/story-models" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Find which provider serves a model (image | video | lipsync | audio | story | background_removal | image_upscale | video_upscale)
curl "$VERSELY_API_URL/api/v1/generate/provider-check?model=Flux+Pro+Ultra&type=image" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
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

I2V models take **`images` (array)**, not `image_url` (singular). Catalog names — confirm against `GET /api/v1/generate/models` since the live catalog is the canonical list.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/video" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Sora 2 I2V",
    "prompt": "Gentle camera zoom with leaves blowing",
    "images": ["https://example.com/landscape.jpg"],
    "duration": "5"
  }'
```

**I2V models** (all take `images: [url]`): Sora 2 I2V, Sora 2 Pro I2V, VEO 3.1 Image to Video, Kling V3 Pro I2V, Kling O3 I2V family, Wan 2.5/2.6/2.7 I2V, Pixverse V6 I2V, Hailuo 2.3 I2V, Seedance 1 Pro / 2.0 I2V, LTX 2.3 I2V, Happy Horse 1.0 I2V, Midjourney V7 I2V.

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

## Lipsync (Speech-Driven Video)

**Endpoint:** `POST /api/v1/generate/lipsync`

Generate a video where a person in an image lip-syncs to an audio track.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/generate/lipsync" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Infini Talk",
    "prompt": "Person speaking on a podcast",
    "image_urls": ["https://example.com/face.jpg"],
    "audio_url": "https://example.com/voice.mp3",
    "resolution": "HD"
  }'
```

**Lipsync models:** `Infini Talk`, `Kling Lipsync`, `Wan 2.2 Speech Turbo`, etc. Discover via `provider-check?type=lipsync` or the unified `/ai-models` registry.

## Music Generation

**Endpoint:** `POST /api/v1/suno/generate`

> **For the full music surface** (lyrics, extend, mashup, vocal separation, MIDI, sound effects, covers, etc. — ~24 endpoints) — use the dedicated **versely-music** skill. The block below is a quick start; if you need anything beyond `/suno/generate`, switch skills.

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

**Suno models:** `V3_5` | `V4` | `V4_5` | `V4_5PLUS` | `V4_5ALL` | `V5` | `V5_5`

**Key fields:**
- `model` (required): Suno version
- `instrumental` (required): `true` = no vocals
- `customMode` (optional): `true` enables `style` and `title` fields
- `prompt` (required): Lyrics (custom mode) or description (simple mode)
- `style` (optional, custom mode): Genre/style tags
- `title` (optional, custom mode): Track title

**Response shape (different from `/generate/*`):** Suno does NOT return `data.successful[]`. Extract the request id from `data.taskId`:

```bash
TASK_ID=$(echo $RESPONSE | jq -r '.data.taskId')
# Then poll the unified status endpoint:
curl -s "$VERSELY_API_URL/api/v1/status/$TASK_ID" -H "Authorization: Bearer $VERSELY_API_KEY"
```

## Sound Effects

**Endpoint:** `POST /api/v1/audio/sound-effect`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/audio/sound-effect" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Thunder rolling across a mountain valley",
    "duration_seconds": 5
  }'
```

## Audio & Voice — Full `/api/v1/audio/*` Surface

The audio router covers TTS, STT, voice cloning, voice changing, voice library access, dubbing, and voice design. All endpoints share the `generate` scope.

**Note on `userId`:** the audio routes go through `enforceUserId`, which auto-injects from your API key. You'll see `userId` referenced in some bodies — leave it out and the middleware fills it in.

### Audio File Storage (use `/bucket/*` first if you don't already have a public URL)

```bash
# Upload audio (multipart form)
curl -X POST "$VERSELY_API_URL/api/v1/audio/upload" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -F "files=@track.mp3"

# List your stored audio
curl -X POST "$VERSELY_API_URL/api/v1/audio/list" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'

# Delete a stored file
curl -X POST "$VERSELY_API_URL/api/v1/audio/delete" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "fileName": "track.mp3" }'
```

Allowed types: `audio/mpeg`, `audio/mp4`, `audio/wav`, `audio/x-wav`, `audio/aac`, `audio/ogg`, `audio/flac`, `audio/webm`.

### Speech-to-Text

**Endpoint:** `POST /api/v1/audio/speech-to-text`

```bash
# Multipart upload — field name MUST be "file"
curl -X POST "$VERSELY_API_URL/api/v1/audio/speech-to-text" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -F "file=@recording.webm"

# Or pass base64 in JSON body
curl -X POST "$VERSELY_API_URL/api/v1/audio/speech-to-text" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "audio_base64": "...", "audio_format": "webm" }'
```

Returns `{ success, transcript, segments?: [...] }`.

### Text-to-Speech (MiniMax-style — RunPod TTS)

**Endpoint:** `POST /api/v1/audio/text-to-speech`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/audio/text-to-speech" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Hello, this is a generated voice line.",
    "voice_id": "Wise_Woman",
    "speed": 1,
    "volume": 1,
    "pitch": 0,
    "emotion": "happy",
    "english_normalization": false
  }'
```

Returns synchronously with `{ success: true, audio_url: "https://..." }`. `voice_id` defaults to `Wise_Woman`. `speed` 0.5-2, `pitch` -12 to 12, `emotion` ∈ `happy | sad | angry | fearful | disgusted | surprised | neutral`.

### Cartesia TTS

**Endpoint:** `POST /api/v1/audio/tts-cartesia`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/audio/tts-cartesia" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "transcript": "Welcome to Versely.",
    "model_id": "sonic-2",
    "voice_id": "<cartesia-voice-id>",
    "language": "en",
    "speed": 1.0,
    "format": "wav"
  }'
```

`speed`: 0.6-1.5. `format`: `wav` | `mp3`. Returns `{ success, audio_url }` synchronously.

### Gemini TTS (single & multi-speaker)

```bash
# Single speaker
curl -X POST "$VERSELY_API_URL/api/v1/audio/tts-gemini" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Welcome to Versely.",
    "model": "gemini-2.5-flash-tts",
    "voice": "Kore",
    "language": "en-US",
    "style_prompt": "Speak warmly with a slow, encouraging tone"
  }'

# Multi-speaker (min 2 speakers — for podcasts/dialogue)
curl -X POST "$VERSELY_API_URL/api/v1/audio/tts-gemini-multi" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Alice: Welcome!\nBob: Glad to be here.\nAlice: Let'"'"'s dive in.",
    "model": "gemini-2.5-flash-tts",
    "speakers": [
      { "name": "Alice", "voice": "Kore" },
      { "name": "Bob",   "voice": "Charon" }
    ],
    "language": "en-US"
  }'

# Discover available voices/models
curl "$VERSELY_API_URL/api/v1/audio/gemini-tts-config" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

### Voice Discovery / Library

```bash
# Cartesia public voices (paginated)
curl "$VERSELY_API_URL/api/v1/audio/cartesia-voices?limit=50" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Single Cartesia voice
curl "$VERSELY_API_URL/api/v1/audio/cartesia-voices/<voice_id>" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Full Cartesia public library (cached 24h on the backend)
curl "$VERSELY_API_URL/api/v1/audio/cartesia-library" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# ElevenLabs library (cached 24h)
curl "$VERSELY_API_URL/api/v1/audio/elevenlabs-voices" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# RunPod TTS voices grouped by language (from internal storage bucket)
curl "$VERSELY_API_URL/api/v1/audio/voices-by-language?language=en" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Your own cloned Cartesia voices
curl "$VERSELY_API_URL/api/v1/audio/my-clones" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

### Voice Cloning (Cartesia)

**Endpoint:** `POST /api/v1/audio/cartesia-voice-clone`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/audio/cartesia-voice-clone" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -F "files=@sample.wav" \
  -F "name=My Voice" \
  -F "description=Recorded sample, neutral tone" \
  -F "language=en" \
  -F "base_voice_id=<optional-existing-voice-id>"
```

The cloned voice is then usable by its returned `voice_id` in `/audio/tts-cartesia`.

### Voice Localization (Cartesia)

**Endpoint:** `POST /api/v1/audio/cartesia-voice-localize`

Re-render an existing Cartesia voice in a different language / dialect.

```bash
curl -X POST "$VERSELY_API_URL/api/v1/audio/cartesia-voice-localize" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "voice_id": "<existing-voice-id>",
    "name": "Voice (Spanish)",
    "description": "Spanish localization",
    "language": "es",
    "original_speaker_gender": "female",
    "dialect": "neutral"
  }'
```

### Voice Changer (apply a voice to your own audio)

**Endpoint:** `POST /api/v1/audio/voice-changer`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/audio/voice-changer" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -F "files=@source.wav" \
  -F "voice_id=<target-voice-id>" \
  -F "output_format_container=mp3" \
  -F "output_format_sample_rate=44100" \
  -F "output_format_bit_rate=128"
```

For streaming output (Server-Sent Events), use `POST /api/v1/audio/voice-changer-sse` with the same body.

### Voice Design (Qwen 3 — generate a custom voice from a style prompt)

**Endpoint:** `POST /api/v1/audio/voice-design`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/audio/voice-design" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello! Welcome to the show.",
    "prompt": "An upbeat young female radio host with warm energy",
    "language": "Auto",
    "temperature": 0.7,
    "top_k": 50,
    "top_p": 0.9
  }'
```

### Audio Dubbing (STT → translate → TTS)

**Endpoint:** `POST /api/v1/audio/dub`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/audio/dub" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -F "file=@english-narration.mp3" \
  -F "target_language=es" \
  -F "voice_id=<voice-id>" \
  -F "provider=cartesia" \
  -F "model=<optional-tts-model>"
```

`provider`: `cartesia` (default), or other supported TTS providers.

### Inworld TTS — `/api/v1/inworld/*`

Alternative TTS provider with voice cloning. Same `generate` scope.

```bash
# Synthesize speech
curl -X POST "$VERSELY_API_URL/api/v1/inworld/tts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello, this is Inworld voice generation.",
    "voiceId": "<inworld-voice-id>",
    "modelId": "inworld-tts-1"
  }'
```

Credits scale with text length (`calculateTTScredits("inworld-tts", text)`). Returns synchronously with the generated audio.

```bash
# List Inworld voices (raw, no cache)
curl "$VERSELY_API_URL/api/v1/inworld/voices" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Full Inworld voice library (cached 24h on backend; pass ?refresh=true to bypass)
curl "$VERSELY_API_URL/api/v1/inworld/voice-library" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# List your cloned Inworld voices
curl "$VERSELY_API_URL/api/v1/inworld/my-cloned-voices" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

**Voice cloning** (multipart form, up to 5 audio sample files; field name MUST be `files`):

```bash
curl -X POST "$VERSELY_API_URL/api/v1/inworld/voices/clone" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -F "files=@sample1.wav" \
  -F "files=@sample2.wav" \
  -F "displayName=My Inworld Clone" \
  -F "langCode=en-US" \
  -F "description=Soft conversational tone" \
  -F "tags=conversational,warm" \
  -F "removeBackgroundNoise=true"
```

`displayName` and `langCode` are required. After cloning, the new `voiceId` is usable in `/inworld/tts`.

### Voice Preview Caching

```bash
# Cache an external voice preview URL into your R2 bucket
curl -X POST "$VERSELY_API_URL/api/v1/audio/cache-voice-preview" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "preview_url": "https://external.example/preview.mp3" }'

# Generate a fresh preview sample for a voice (MiniMax / Inworld / Gemini providers)
curl -X POST "$VERSELY_API_URL/api/v1/audio/generate-voice-sample" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "provider": "minimax", "voice_id": "Wise_Woman", "language": "en" }'
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

## AI Model Catalog — `/api/v1/ai-models/*`

The full model registry. Public, **rate-limited per IP** (`publicRateLimiter`, 100 req/15min) — no auth or scope needed for the read endpoints. Richer metadata than `/generate/models`: categories, providers, virality stats, credit costs, ranking data.

Use this when you want filtering/sorting beyond what `/generate/models` exposes (e.g., "give me featured image models from FAL sorted by rank").

### Browse

```bash
# All models with filters + pagination
curl "$VERSELY_API_URL/api/v1/ai-models?content_type=image&provider=fal&is_featured=true&page=1&page_size=20"

# Filter params: content_type, provider, category, requires_image, is_active,
# is_premium, is_featured, min_credits, max_credits, search, page, page_size

# Per-content-type shortcuts
curl "$VERSELY_API_URL/api/v1/ai-models/images?provider=runpod"
curl "$VERSELY_API_URL/api/v1/ai-models/videos?is_featured=true"
curl "$VERSELY_API_URL/api/v1/ai-models/lipsync"
curl "$VERSELY_API_URL/api/v1/ai-models/audio"        # TTS / audio models
curl "$VERSELY_API_URL/api/v1/ai-models/featured?content_type=video&limit=10"

# Models that require an input image (edit / I2V / reference flows)
curl "$VERSELY_API_URL/api/v1/ai-models/requires-images?content_type=image"

# Browse by category (e.g., text-to-image, image-to-video, first-last-frame)
curl "$VERSELY_API_URL/api/v1/ai-models/category/text-to-image"

# Browse by provider
curl "$VERSELY_API_URL/api/v1/ai-models/provider/fal?content_type=image"

# Provider stats (counts, etc.)
curl "$VERSELY_API_URL/api/v1/ai-models/providers"
curl "$VERSELY_API_URL/api/v1/ai-models/providers/stats?content_type=video"

# Single model by slug
curl "$VERSELY_API_URL/api/v1/ai-models/flux-pro-ultra"
```

### Pricing helpers

```bash
# Credits for a single model
curl "$VERSELY_API_URL/api/v1/ai-models/credits?model=Flux+Pro+Ultra&contentType=image&usage=1"

# Total for a list of models (compare options)
curl -X POST "$VERSELY_API_URL/api/v1/ai-models/calculate-credits" \
  -H "Content-Type: application/json" \
  -d '{
    "models": ["Flux Pro Ultra", "Imagen 4", "Recraft V3"],
    "contentType": "image",
    "usage": 4
  }'
```

### Rankings

```bash
# Get rankings (model performance leaderboard)
curl "$VERSELY_API_URL/api/v1/ai-models/rankings?content_type=image&category=text-to-image&ranking_type=quality&is_latest=true&limit=20"

# Submit a ranking (auth required)
curl -X POST "$VERSELY_API_URL/api/v1/ai-models/rankings" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model_id": "<model uuid>",
    "content_type": "image",
    "rank": 1,
    "score": 0.93,
    "ranking_type": "quality",
    "is_latest": true
  }'
```

The ranking-sync trigger (`POST /ai-models/rankings/sync`) is gated by an admin key and not relevant for normal API consumers.

### Discovery vs `/generate/models`

| Want | Use |
|---|---|
| Quick string list of supported names | `/generate/models` |
| Filter by `is_featured`, `is_premium`, provider stats, credits | `/ai-models` |
| Pricing math for a multi-model selection | `/ai-models/calculate-credits` |
| Sort by community/quality ranking | `/ai-models/rankings` |
| Provider routing decision for a specific model | `/generate/provider-check` |

## LTX Batch Jobs — `/api/v1/ltx-batch/*`

Cheap, asynchronous-batched LTX video generation. Jobs queue → backend autoscales pods (RunPod LTX) → batch-processes when threshold is hit. Lower cost per second than realtime endpoints; latency depends on queue depth.

**Scope:** `generate`. Auth required.

### Submit a job

```bash
curl -X POST "$VERSELY_API_URL/api/v1/ltx-batch/jobs" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A serene mountain lake at sunrise, cinematic, slow camera push-in",
    "negative_prompt": "blurry, low quality",
    "workflow_type": "t2v",
    "audio_enabled": true,
    "width": 768,
    "height": 512,
    "length": 121,
    "fps": 24,
    "seed": 42,
    "priority": 0
  }'
```

**Body fields:**
- `prompt` (required, ≥3 chars)
- `negative_prompt` (optional)
- `workflow_type` (default `t2v`): `t2v` | `i2v` | `flf2v` | `audio_driven_i2v` | `audio_driven_t2v`
- `audio_enabled` (boolean, default `true`)
- `width`, `height`: 64-2048, **must be divisible by 32** (e.g., 768/512/1024)
- `length` (frames): one of 1, 9, 17, 25, ..., 257 (formula: `(length - 1) % 8 === 0`)
- `fps`: 8-60
- `seed` (optional, integer for reproducible generation)
- `input_image_url` (required for `i2v` and `audio_driven_i2v`)
- `last_image_url` (required for `flf2v`)
- `audio_url` (required for `audio_driven_*`)
- `priority` (default 0; higher = sooner)

**Response:**
```json
{
  "success": true,
  "job": { "id": "<job uuid>", "status": "queued", "credits_charged": 5, "queued_at": "..." }
}
```

### List your jobs

```bash
curl "$VERSELY_API_URL/api/v1/ltx-batch/jobs?limit=50&offset=0&status=queued" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

`status` filter (optional): `queued` | `processing` | `completed` | `failed` | `cancelled`. Returns `{ success, jobs: [...], total, limit, offset }`. Newest first.

### Poll a single job

```bash
curl "$VERSELY_API_URL/api/v1/ltx-batch/jobs/$JOB_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Returns the full job row including `output_url` once status flips to `completed`.

### Cancel a queued job

```bash
curl -X DELETE "$VERSELY_API_URL/api/v1/ltx-batch/jobs/$JOB_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

**Only `queued` jobs are cancellable** — once status is `processing`, it's too late. Cancel auto-refunds credits and removes the mirrored row from your media library.

`409 Conflict` is returned if the job has moved past `queued`.

### Queue depth + your active jobs

```bash
curl "$VERSELY_API_URL/api/v1/ltx-batch/queue/stats" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Returns:
```json
{
  "success": true,
  "queue": { "depth": 12, "remainingForStart": 3 },
  "config": { "minBatchSize": 15, "maxJobsPerPod": 50 },
  "activePods": { "provisioning": 1, "ready": 2, "draining": 0, "totalJobsProcessed": 87 },
  "myJobs": [
    { "id": "...", "status": "queued", "workflow_type": "t2v", "queued_at": "...", "output_url": null }
  ]
}
```

`remainingForStart` is how many more queued jobs are needed before the next pod boots (a batch starts when queue depth ≥ `minBatchSize`). Use this to set user expectations: if `remainingForStart > 0`, the next batch hasn't been triggered yet.

## Polling for Results

All generation is async. After submitting a request, poll the status endpoint.

**Response shape varies by upstream provider** — extract whichever ID is present:
- **FAL** providers (Flux Pro Ultra, Imagen 4, Recraft, Topaz Upscale, etc.) → `data.successful[0].data.requestId`
- **RunPod** providers (Nano Banana Edit, Sora 2 I2V, Wan, etc.) → `data.successful[0].data.job_id`
- **Suno** → top-level `data.taskId` (not nested under `successful`)

Both `requestId` and `job_id` work against the same `/api/v1/status/:id` endpoint, so the polling loop is identical — only the extraction differs.

```bash
# 1. Submit generation and extract the request ID — fall back across naming
RESPONSE=$(curl -s -X POST "$VERSELY_API_URL/api/v1/generate/image" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "Flux Pro Ultra", "prompt": "..."}')

# Try requestId (FAL), then job_id (RunPod) — whichever the provider returned
REQUEST_ID=$(echo $RESPONSE | jq -r '.data.successful[0].data.requestId // .data.successful[0].data.job_id // .data.taskId')

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
- **403 Forbidden** — Multiple causes: API key lacks the required scope (tell user which scope is needed, e.g., `generate`); OR account balance is ≤ 0 at request entry (`userCreditsMiddleware` blocks the request before it runs); OR `user_id` in the body doesn't match the authenticated user.
- **402 Payment Required** — Per-call credit deduction failed (balance was non-zero at request entry but dropped below the required cost before deduction). Refund any partially-charged credits and tell the user the balance and estimated cost.
- **429 Too Many Requests** — Rate limited. Check `X-RateLimit-Reset` header, wait, retry once.
- **500 Internal Server Error** — Server error. Retry once after 10 seconds.
- **Generation timeout** (5+ min with no completion) — Report as failed, suggest retrying with a different model.
- **Network error** — Verify `$VERSELY_API_URL` is correct. Retry once.

## Rate Limits

- Default: 60 requests/minute per API key (configurable per key)
- Generation endpoints (`/generate`, `/suno`, `/audio`, `/runpod`, `/replicate`): 30 requests/minute, IP-based (cost-sensitive rate limiter)
- Status polling: recommended max 1 request every 5 seconds per request_id
- Response headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

For complete API schemas with all fields, see [api-reference.md](api-reference.md).
For real workflow examples, see [examples.md](examples.md).
