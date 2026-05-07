# API Reference — Versely Movie

Base URL: `$VERSELY_API_URL` (default: `https://api.versely.studio`)

All endpoints require `Authorization: Bearer $VERSELY_API_KEY`. The `enforceUserId` middleware injects `user_id` from the API key — do not pass it.

**Required scope:** `generate` (covers `/movie/*` and `/generate/*`).

---

# Part 1 — `/movie/*` (recommended)

The dedicated movie API. Stateful project + scenes + per-scene polling + auto-combine.

## GET /api/v1/movie/models

Returns models grouped by generation type.

```json
{
  "success": true,
  "data": {
    "text_to_video":    ["Sora 2", "VEO 3.1", "Kling 2.5 Turbo", ...],
    "image_to_video":   ["Sora 2 I2V", "Kling 2.5 Turbo I2V", ...],
    "first_last_frame": ["VEO First Last Frame", "Kling First Last Frame", ...]
  }
}
```

## POST /api/v1/movie/create

Create a movie project + scenes.

### Request

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `title` | string | No | `"Untitled Movie"` | |
| `description` | string | No | | |
| `aspect_ratio` | string | No | `"16:9"` | |
| `transition_type` | enum | No | `concat` | `concat` \| `fade` \| `dissolve` \| `wipe` |
| `transition_duration` | number | No | `0.5` | Seconds between scenes when combined |
| `scenes` | object[] | **Yes** | | Array of scene definitions, min 1 |

### Scene fields

| Field | Type | Required for | Description |
|-------|------|--------------|-------------|
| `generation_type` | enum | All | `text_to_video` \| `image_to_video` \| `first_last_frame` \| `previous_scene_image_to_video` \| `previous_scene_first_last_frame` |
| `model` | string | All | Must match the generation_type (use `/movie/models`) |
| `prompt` | string | text_to_video, image_to_video, all `previous_scene_*` | |
| `image_url` | string | image_to_video | Reference image |
| `first_frame_url` | string | first_last_frame | |
| `last_frame_url` | string | first_last_frame, previous_scene_first_last_frame | |
| `duration` | number | No | Seconds, default `5` |

`previous_scene_*` types cannot be used at scene_order 1.

### Response (`201`)

```json
{
  "success": true,
  "message": "Movie project created",
  "data": {
    "movie": { "id": "mov_...", "user_id": "...", "title": "...", "status": "draft", ... },
    "scenes": [{ "id": "scn_...", "scene_order": 1, "status": "pending", ... }, ...],
    "estimated_credits": 90
  }
}
```

## GET /api/v1/movie/list?page=1&limit=20

```json
{
  "success": true,
  "data": [{...movie}, ...],
  "pagination": { "page": 1, "limit": 20, "total": 5, "totalPages": 1 }
}
```

## GET /api/v1/movie/:movieId

```json
{
  "success": true,
  "data": {
    "movie": {...},
    "scenes": [{...}, ...]
  }
}
```

## PUT /api/v1/movie/:movieId

Update metadata. Body: any of `title`, `description`, `aspect_ratio`, `transition_type`, `transition_duration`, `metadata`.

## DELETE /api/v1/movie/:movieId

Deletes movie + all scenes.

## GET /api/v1/movie/:movieId/status

**Canonical poll endpoint for movies.**

```json
{
  "success": true,
  "data": {
    "movie_id": "mov_...",
    "status": "draft | generating | combining | completed | failed",
    "title": "...",
    "final_video_url": "https://..." | null,
    "scenes_total": 3,
    "scenes_pending": 0,
    "scenes_generating": 1,
    "scenes_completed": 2,
    "scenes_failed": 0,
    "scenes": [
      {
        "id": "scn_...",
        "order": 1,
        "status": "pending | generating | completed | failed",
        "generation_type": "...",
        "model": "...",
        "video_url": "https://..." | null,
        "error": "..." | null,
        "duration": 5
      },
      ...
    ]
  }
}
```

## POST /api/v1/movie/:movieId/scene

Add a scene to an existing movie. Body: same shape as a scene in `/movie/create`.

Response: `{ "success": true, "data": {...scene} }` (status `201`).

## PUT /api/v1/movie/scene/:sceneId

Update a single scene. Body: any of `prompt`, `model`, `generation_type`, `image_url`, `first_frame_url`, `last_frame_url`, `duration`.

## DELETE /api/v1/movie/scene/:sceneId

## PUT /api/v1/movie/:movieId/reorder

```json
{ "scene_ids": ["scn_2", "scn_1", "scn_3"] }
```

## POST /api/v1/movie/:movieId/generate

Start generation. Independent scenes dispatch in parallel; dependents queue.

### Response

```json
{
  "success": true,
  "message": "Movie generation started",
  "data": {
    "movie_id": "mov_...",
    "credits_deducted": 60,
    "credits_refunded": 0,
    "scenes_dispatched": 1,
    "scenes_failed": 0,
    "scenes_queued": 2,
    "details": [
      { "sceneId": "scn_1", "requestId": "req_...", "credits": 30 },
      { "sceneId": "scn_2", "requestId": "queued_awaiting_scene_scn_1", "credits": 30 }
    ]
  }
}
```

### Errors

| Status | Body |
|--------|------|
| 404 | Movie not found |
| 403 | Movie owned by another user |
| 409 | Movie already generating or combining |
| 400 | No pending/failed scenes to generate |
| 500 | All dispatches failed (credits refunded) |

## POST /api/v1/movie/:movieId/generate-scene/:sceneId

Retry a single scene.

```json
{
  "success": true,
  "message": "Scene generation started",
  "data": { "scene_id": "scn_...", "request_id": "req_...", "credits_deducted": 30 }
}
```

For dependent scenes, the previous scene must already be `completed`.

## POST /api/v1/movie/:movieId/combine

Manually combine completed scenes. Auto-combine usually fires automatically when the last scene's webhook arrives.

Returns the full movie object once combine succeeds.

### Errors

| Status | Reason |
|--------|--------|
| 400 | Not all scenes completed (returns `incomplete_scenes[]`) |
| 400 | No scene videos available |

## POST /api/v1/movie/webhook/scene

Provider callback (do not call directly).

---

# Part 2 — `/generate/story` (one-shot alternative)

Use when you don't need scene-level retries or chained frames.

## POST /api/v1/generate/story

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `model` | string | Yes | `"Sora 2 Pro Storyboard"` \| `"Kling 2.5 Turbo"` \| `"VEO 3.1 First Last Frame"` |
| `scenes` | array | Yes (Sora) | `[{ description: "...", duration: "5" }]` — min 2 |
| `image_urls` | string[] | No | Reference images |
| `aspect_ratio` | string | No | `"16:9"` (default) \| `"9:16"` |
| `total_duration` | string | No | `"10"` \| `"15"` \| `"25"` |
| `audio_url` | string | No | Background audio |
| `prompt` | string | VEO models | Overall prompt |
| `first_frame_url` | string | VEO First Last Frame | |
| `last_frame_url` | string | VEO First Last Frame | |
| `duration` | string | Kling models | |

### Response

Same shape as `POST /generate/video`:

```json
{
  "success": true,
  "data": {
    "successful": [{ "data": { "requestId": "abc123", "model": "...", "isVideoModel": true } }]
  }
}
```

Poll via `GET /api/v1/status/:requestId`.

## POST /api/v1/generate/expand-scene

Expand a brief idea into a cinematic prompt.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `description` | string | Yes | Brief idea |
| `context` | string | No | Genre/context |
| `style` | string | No | Visual style |
| `camera` | string | No | `static` \| `pan_left` \| `pan_right` \| `zoom_in` \| `zoom_out` \| `tilt_up` \| `tilt_down` \| `dolly_in` \| `orbit` \| `tracking` |
| `characters` | string | No | |

```json
{ "success": true, "expanded": "A wide establishing shot of..." }
```

## GET /api/v1/generate/story-models

```json
{ "success": true, "models": ["Sora 2 Pro Storyboard", "Kling 2.5 Turbo", "VEO 3.1 First Last Frame"] }
```

## GET /api/v1/status/:requestId

Generic poll endpoint (use only with `/generate/story`; for `/movie/*` use `/movie/:id/status`).

```json
{
  "success": true,
  "status": "generating | completed | failed",
  "type": "videos",
  "model": "...",
  "result_url": "https://...",
  "result_urls": ["https://..."]
}
```

---

## Credit Costs

| Operation | Billing | ~Credits (API) |
|-----------|---------|----------------|
| Sora 2 (text-to-video, 5s) | $0.50 | ~25 |
| Sora 2 Pro Storyboard | $0.30/second | 15/5s |
| VEO 3.1 (5s) | ~$0.05 | ~2 |
| Kling 2.5 Turbo (5s) | ~$0.10 | ~5 |
| VEO First Last Frame | flat $0.10-$0.15 | 1-2 |

API keys bill at half the in-app rate (CREDITS_PER_USD_API=10 vs APP=20).

## Rate Limits

| Scope | Limit |
|-------|-------|
| Default (`/movie/*`) | 60 req/min per API key |
| `/generate/story`, `/generate/expand-scene` | 30 req/min, IP-based |
| Concurrent video generation | 2 recommended |

## Error Codes

| Status | Meaning |
|--------|---------|
| 400 | Validation error (missing scenes, invalid generation_type, etc.) |
| 401 | Invalid / expired API key |
| 402 | Per-call credit deduction failed |
| 403 | Missing `generate` scope, balance ≤ 0, or unauthorized movie |
| 404 | Movie or scene not found |
| 409 | Movie already `generating` or `combining` |
| 429 | Rate limited |
| 500 | Provider failure or unexpected error |
