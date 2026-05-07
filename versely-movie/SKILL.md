---
name: versely-movie
version: 2.0.0
description: >
  Create multi-scene AI movies with the dedicated /movie/* project API. Manage
  scenes, chain them via previous-frame I2V, generate, poll per-scene status,
  and combine into a final video. Use when the user wants a multi-scene short
  film, storyboard, or chained-frame video with non-blind polling.
allowed-tools: Bash, Read
metadata:
  agentskills.io:
    category: content-creation
    homepage: https://versely.studio
    tags: ["movie", "storyboard", "video", "scenes", "chained"]
---

# Versely Movie — Multi-Scene AI Movies

The `/movie/*` namespace is the **first-class movie API**: project + scene CRUD, chained frames between scenes, per-scene status polling, automatic combine. Use this instead of the lower-level `/generate/story` whenever you need to track progress, retry individual scenes, or chain frames between scenes.

**Typical workflow:** Plan scenes → Create movie → Generate → Poll `/movie/:id/status` → Combine

## Authentication

```bash
VERSELY_API_KEY="vsk_..."
VERSELY_API_URL="${VERSELY_API_URL:-https://api.versely.studio}"
```

Send `Authorization: Bearer $VERSELY_API_KEY`. Do NOT send `user_id` — middleware injects it.

## Required API Key Scope

**Scope:** `generate`. Covers `/movie/*` (project + scene CRUD, generate, combine, status, models) and underlying `/generate/*` endpoints used in fallback flows.

Create a key with `{"scopes": ["generate"]}` via `POST /api/v1/auth/api-keys`. Live scope catalog: `GET /api/v1/auth/api-keys/scopes`.

## Two Movie APIs — Pick One

| API | Use when |
|---|---|
| **`/movie/*`** (this skill) | Want per-scene visibility, retries, chained frames, transitions |
| `/generate/story` | One-shot Sora 2 Pro Storyboard call, no project state needed |

The rest of this skill documents `/movie/*`. For `/generate/story`, see [api-reference.md](api-reference.md).

## Step 1: Discover Models

```bash
curl -s "$VERSELY_API_URL/api/v1/movie/models" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq
```

**Response shape:**
```json
{
  "success": true,
  "data": {
    "text_to_video":     ["Sora 2", "VEO 3.1", "Kling 2.5 Turbo", ...],
    "image_to_video":    ["Sora 2 I2V", "Kling 2.5 Turbo I2V", "Wan 2.5 I2V", ...],
    "first_last_frame":  ["VEO First Last Frame", "Kling First Last Frame", ...]
  }
}
```

Pick a model that matches each scene's `generation_type` (see Step 2).

## Step 2: Create Movie Project

**Endpoint:** `POST /api/v1/movie/create`

Creates a movie + its scenes in one call. Each scene specifies how its video is generated.

### Generation types

| `generation_type` | Required fields | Use case |
|---|---|---|
| `text_to_video` | `prompt`, `model` | Generate from prompt only |
| `image_to_video` | `prompt`, `image_url`, `model` | Generate from a reference image |
| `first_last_frame` | `prompt`, `first_frame_url`, `last_frame_url`, `model` | Transition between two given frames |
| `previous_scene_image_to_video` | `prompt`, `model` | Use the **previous scene's last frame** as the input image (chained scenes) |
| `previous_scene_first_last_frame` | `prompt`, `last_frame_url`, `model` | Previous scene's last frame becomes this scene's first frame; you supply the new last frame |

Scene 1 cannot use a `previous_scene_*` type (no previous scene to chain from).

### Example — 3-scene chained movie

```bash
curl -s -X POST "$VERSELY_API_URL/api/v1/movie/create" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Forest Journey",
    "description": "A traveler crosses an enchanted forest",
    "aspect_ratio": "16:9",
    "transition_type": "fade",
    "transition_duration": 0.5,
    "scenes": [
      {
        "generation_type": "image_to_video",
        "model": "Kling 2.5 Turbo",
        "prompt": "A cloaked traveler steps onto a misty forest path at dawn",
        "image_url": "https://example.com/character.jpg",
        "duration": 5
      },
      {
        "generation_type": "previous_scene_image_to_video",
        "model": "Kling 2.5 Turbo",
        "prompt": "The traveler discovers an ancient stone bridge over a river",
        "duration": 5
      },
      {
        "generation_type": "previous_scene_first_last_frame",
        "model": "VEO First Last Frame",
        "prompt": "Crossing the bridge, a castle rises in the distance",
        "last_frame_url": "https://example.com/castle.jpg",
        "duration": 5
      }
    ]
  }'
```

**Response (`201`):**
```json
{
  "success": true,
  "message": "Movie project created",
  "data": {
    "movie": { "id": "mov_abc", "title": "...", "status": "draft", "user_id": "...", "aspect_ratio": "16:9", ... },
    "scenes": [{ "id": "scn_1", "scene_order": 1, "status": "pending", ... }, ...],
    "estimated_credits": 90
  }
}
```

Save `data.movie.id` — you'll need it for every subsequent call.

**Top-level fields:** `title` (default `"Untitled Movie"`), `description`, `aspect_ratio` (default `"16:9"`), `transition_type` (`concat` | `fade` | `dissolve` | `wipe`, default `concat`), `transition_duration` (seconds, default `0.5`), `scenes` (array, required).

## Step 3: Generate All Pending Scenes

**Endpoint:** `POST /api/v1/movie/:movieId/generate`

Kicks off generation for all `pending` and `failed` scenes. Independent scenes start in parallel; dependent (`previous_scene_*`) scenes are queued and auto-triggered when their prerequisite completes.

```bash
MOVIE_ID="mov_abc"

curl -s -X POST "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID/generate" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

**Response (`200`):**
```json
{
  "success": true,
  "message": "Movie generation started",
  "data": {
    "movie_id": "mov_abc",
    "credits_deducted": 60,
    "credits_refunded": 0,
    "scenes_dispatched": 1,
    "scenes_failed": 0,
    "scenes_queued": 2,
    "details": [
      { "sceneId": "scn_1", "requestId": "req_123", "credits": 30 },
      { "sceneId": "scn_2", "requestId": "queued_awaiting_scene_scn_1", "credits": 30 },
      { "sceneId": "scn_3", "requestId": "queued_awaiting_scene_scn_2", "credits": 30 }
    ]
  }
}
```

**Errors:**
- `409` — movie already `generating` or `combining`. Don't retry; poll status instead.
- `400` — no pending scenes (movie already complete or all already generating).
- `500` with `details: []` — every scene failed at dispatch; credits are refunded.

## Step 4: Poll Per-Scene Status

**Endpoint:** `GET /api/v1/movie/:movieId/status` — **the canonical poll endpoint for movies. Do NOT poll `/status/:requestId` per scene.**

```bash
for i in $(seq 1 90); do
  STATUS=$(curl -s "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID/status" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo "$STATUS" | jq -r '.data.status')
  COMPLETED=$(echo "$STATUS" | jq -r '.data.scenes_completed')
  TOTAL=$(echo "$STATUS" | jq -r '.data.scenes_total')
  echo "[$i] movie=$STATE scenes=$COMPLETED/$TOTAL"
  if [ "$STATE" = "completed" ] || [ "$STATE" = "failed" ]; then break; fi
  sleep 10
done
```

**Response shape:**
```json
{
  "success": true,
  "data": {
    "movie_id": "mov_abc",
    "status": "generating",
    "title": "Forest Journey",
    "final_video_url": null,
    "scenes_total": 3,
    "scenes_pending": 0,
    "scenes_generating": 1,
    "scenes_completed": 1,
    "scenes_failed": 0,
    "scenes": [
      { "id": "scn_1", "order": 1, "status": "completed", "video_url": "https://...", "model": "...", "duration": 5, "error": null },
      { "id": "scn_2", "order": 2, "status": "generating", "video_url": null, ... },
      { "id": "scn_3", "order": 3, "status": "pending", "video_url": null, ... }
    ]
  }
}
```

**Movie statuses:** `draft` → `generating` → `combining` → `completed` (or `failed` at any point).

**Auto-combine:** when the last scene finishes successfully, the backend automatically calls combine — `status` will move through `combining` → `completed` and `final_video_url` will populate. You don't always need to call `/combine` yourself; only call it manually if you skipped a scene's webhook or auto-combine failed.

## Step 5: Combine (only if needed)

**Endpoint:** `POST /api/v1/movie/:movieId/combine`

```bash
curl -s -X POST "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID/combine" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Merges all completed scene videos using the configured `transition_type` and `transition_duration`. Returns the final movie object with `final_video_url`. Returns `400` if any scene is still incomplete.

## Retry a Failed Scene

**Endpoint:** `POST /api/v1/movie/:movieId/generate-scene/:sceneId`

```bash
curl -s -X POST "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID/generate-scene/scn_2" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Use this to retry a `failed` scene without re-running the entire movie. Charges credits for that single scene only. For dependent scenes, the previous scene must already be `completed`.

**Response:**
```json
{
  "success": true,
  "message": "Scene generation started",
  "data": { "scene_id": "scn_2", "request_id": "req_456", "credits_deducted": 30 }
}
```

## Scene Editing Before Generation

You can mutate the scene list while the movie is in `draft` status:

```bash
# Add a scene to an existing movie
curl -X POST "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID/scene" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "generation_type": "text_to_video",
    "model": "VEO 3.1",
    "prompt": "Final shot: zooming out from the castle",
    "duration": 5
  }'

# Update a scene
curl -X PUT "$VERSELY_API_URL/api/v1/movie/scene/scn_2" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "prompt": "Updated description", "duration": 7 }'

# Delete a scene
curl -X DELETE "$VERSELY_API_URL/api/v1/movie/scene/scn_2" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Reorder scenes (full ordered list of IDs)
curl -X PUT "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID/reorder" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "scene_ids": ["scn_1", "scn_3", "scn_2"] }'
```

## Movie CRUD

```bash
# List your movies
curl "$VERSELY_API_URL/api/v1/movie/list?page=1&limit=20" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Get a movie with all scenes
curl "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Update metadata
curl -X PUT "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "title": "Renamed", "transition_type": "dissolve" }'

# Delete movie + all scenes
curl -X DELETE "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

## Full Pipeline Example

```bash
# 1. Check budget — chained 3-scene at 5s each ≈ 15s of video
CREDITS=$(curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.user.credits')
echo "Have $CREDITS credits"

# 2. Create the movie project
MOVIE_ID=$(curl -s -X POST "$VERSELY_API_URL/api/v1/movie/create" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Quick Demo",
    "scenes": [
      { "generation_type": "text_to_video", "model": "VEO 3.1",
        "prompt": "Sunrise over mountains", "duration": 5 },
      { "generation_type": "previous_scene_image_to_video", "model": "Kling 2.5 Turbo I2V",
        "prompt": "Camera pans down to a river", "duration": 5 }
    ]
  }' | jq -r '.data.movie.id')

# 3. Kick off generation
curl -s -X POST "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID/generate" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# 4. Poll movie status (auto-combines when done)
for i in $(seq 1 90); do
  RESP=$(curl -s "$VERSELY_API_URL/api/v1/movie/$MOVIE_ID/status" \
    -H "Authorization: Bearer $VERSELY_API_KEY")
  STATE=$(echo "$RESP" | jq -r '.data.status')
  if [ "$STATE" = "completed" ]; then
    URL=$(echo "$RESP" | jq -r '.data.final_video_url')
    echo "Final: $URL"; break
  elif [ "$STATE" = "failed" ]; then
    echo "Failed"; echo "$RESP" | jq '.data.scenes' ; break
  fi
  sleep 10
done
```

## Common Gotchas

- **Don't poll `/status/:requestId` per scene.** Use `/movie/:id/status` — it aggregates per-scene state into one response.
- **Dependent scenes can't be the first scene.** If you put `previous_scene_*` at order 1 you'll get a 400 at create time.
- **Scene 1 in chained movies needs an explicit input.** Use `text_to_video` (with `prompt`), `image_to_video` (with `image_url`), or `first_last_frame` — Scene 2+ then chain with `previous_scene_*`.
- **`previous_scene_image_to_video` retries require the previous scene to be `completed`.** The backend extracts the parent's last frame on retry; if the parent is `failed`, retry it first.
- **Auto-combine** runs when the final scene's webhook arrives; you usually don't need to call `/combine` explicitly.
- **Credits are refunded** for dispatch failures (independent scenes that failed to start) and cascade failures (dependents whose parent failed). Successful dispatches that later fail provider-side are NOT refunded automatically.

## Error Handling

- `401` — invalid / expired API key.
- `403` — wrong scope, OR balance ≤ 0 at request entry, OR movie owned by another user.
- `402` — credit deduction failed mid-flight.
- `404` — movie or scene not found.
- `409` — movie already `generating` or `combining`. Poll instead.
- `429` — rate limited. Default 60 req/min per key; cost-sensitive endpoints (story, expand-scene) are 30 req/min.
- `500` — provider failure. Read `details` array; specific scenes' errors are in `scenes[].error`.

## Rate Limits

- Default: 60 requests/minute per API key.
- `/movie/*` shares the default bucket; per-scene generation goes through provider-specific concurrency caps (≈ 2 concurrent video jobs per key recommended).
- Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

## Lower-Level Alternative — `/generate/story`

If you don't need project state, scene retries, or chained frames, use the one-shot `/generate/story` endpoint with Sora 2 Pro Storyboard. See [api-reference.md](api-reference.md) for details.

For complete API schemas (movie + story), see [api-reference.md](api-reference.md).
