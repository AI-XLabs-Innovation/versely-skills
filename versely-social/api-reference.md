# API Reference — Versely Social

Base URL: `$VERSELY_API_URL` (default: `https://api.versely.studio`)

All endpoints require `Authorization: Bearer $VERSELY_API_KEY` header. API key must have the `post` scope.

---

## GET /api/v1/postbridge/connect-url

Get the PostBridge URL for connecting new social accounts.

### Query Parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `redirect_url` | string | No | URL to redirect after connecting |

### Response

```json
{
  "success": true,
  "connect_url": "https://app.post-bridge.com/connect?api_key=...&redirect_url=..."
}
```

### curl Example

```bash
curl -s "$VERSELY_API_URL/api/v1/postbridge/connect-url" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## GET /api/v1/postbridge/accounts

List the authenticated user's connected social media accounts.

### Response

```json
{
  "success": true,
  "accounts": [
    {
      "id": "uuid-1234-5678",
      "postbridge_account_id": "12345",
      "platform": "instagram",
      "username": "johndoe",
      "profile_image_url": "https://...",
      "connected_at": "2026-01-15T10:00:00Z",
      "is_active": true
    }
  ]
}
```

### curl Example

```bash
curl -s "$VERSELY_API_URL/api/v1/postbridge/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## POST /api/v1/postbridge/accounts/sync

Sync accounts from PostBridge after a user connects new social accounts.

**Rate limit:** 5 requests/minute per user

### Response

```json
{
  "success": true,
  "new_accounts": 2,
  "total": 5
}
```

### curl Example

```bash
curl -X POST "$VERSELY_API_URL/api/v1/postbridge/accounts/sync" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## DELETE /api/v1/postbridge/accounts/:accountId

Disconnect (soft-delete) a social account.

### Path Parameters

| Param | Type | Description |
|-------|------|-------------|
| `accountId` | string | UUID of the social account |

### Response

```json
{
  "success": true
}
```

### curl Example

```bash
curl -X DELETE "$VERSELY_API_URL/api/v1/postbridge/accounts/uuid-1234" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## POST /api/v1/postbridge/posts

Create a social media post (immediate or scheduled).

**Rate limit:** 10 requests/minute per user
**Credit cost:** 2 credits per platform

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `caption` | string | Yes | Post text content |
| `account_ids` | string[] | Yes | Social account UUIDs to post to |
| `media_urls` | string[] | No | Media URLs (images or videos) |
| `scheduled_at` | string | No | ISO 8601 datetime for scheduling |
| `is_draft` | boolean | No | Save as draft. Default: `false` |

### Response — Immediate Post

```json
{
  "success": true,
  "post": {
    "id": "postbridge-post-id",
    "caption": "Check out this sunset!",
    "status": "posted",
    "platforms": ["instagram", "tiktok"],
    "scheduled_at": null
  },
  "credits_charged": 4
}
```

### Response — Scheduled Post

```json
{
  "success": true,
  "post": {
    "id": "postbridge-post-id",
    "caption": "Morning motivation!",
    "status": "scheduled",
    "platforms": ["instagram"],
    "scheduled_at": "2026-03-01T09:00:00Z"
  },
  "credits_charged": 2
}
```

### Error Responses

```json
{"success": false, "error": "Caption is required"}
{"success": false, "error": "At least one account_id is required"}
{"success": false, "error": "No valid accounts found for this user"}
{"success": false, "error": "Failed to deduct credits"}
{"success": false, "error": "PostBridge error: ..."}
```

**Credit refund:** If PostBridge API fails after credits are deducted, credits are automatically refunded.

### curl Example — Immediate Post

```bash
curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "New collection dropping soon! Stay tuned.",
    "media_urls": ["https://cdn.versely.studio/image123.jpg"],
    "account_ids": ["uuid-instagram", "uuid-tiktok"]
  }'
```

### curl Example — Scheduled Post

```bash
curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "Happy Monday! Start the week strong.",
    "media_urls": ["https://cdn.versely.studio/image456.jpg"],
    "account_ids": ["uuid-instagram"],
    "scheduled_at": "2026-03-03T08:00:00Z"
  }'
```

### curl Example — Instagram Carousel

```bash
curl -X POST "$VERSELY_API_URL/api/v1/postbridge/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "Swipe through our top picks!",
    "media_urls": [
      "https://cdn.versely.studio/img1.jpg",
      "https://cdn.versely.studio/img2.jpg",
      "https://cdn.versely.studio/img3.jpg",
      "https://cdn.versely.studio/img4.jpg"
    ],
    "account_ids": ["uuid-instagram"]
  }'
```

---

## GET /api/v1/postbridge/posts

List the authenticated user's social posts.

### Query Parameters

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | number | 20 | Results per page |
| `offset` | number | 0 | Pagination offset |

### Response

```json
{
  "success": true,
  "posts": [
    {
      "id": "uuid-post-1",
      "postbridge_post_id": "pb-123",
      "text": "Check out this sunset!",
      "media_urls": ["https://..."],
      "platforms": ["instagram", "tiktok"],
      "scheduled_at": null,
      "status": "posted",
      "credits_charged": 4,
      "created_at": "2026-02-15T10:00:00Z"
    }
  ]
}
```

### curl Example

```bash
curl -s "$VERSELY_API_URL/api/v1/postbridge/posts?limit=10" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## GET /api/v1/postbridge/posts/:postId

Get a single post with platform-specific results.

### Response

```json
{
  "success": true,
  "post": {
    "id": "uuid-post-1",
    "postbridge_post_id": "pb-123",
    "text": "Check out this sunset!",
    "media_urls": ["https://..."],
    "platforms": ["instagram"],
    "status": "posted",
    "credits_charged": 2,
    "created_at": "2026-02-15T10:00:00Z"
  },
  "results": [
    {
      "id": "result-1",
      "post_id": "pb-123",
      "success": true,
      "social_account_id": 12345,
      "error": null,
      "platform_data": {
        "id": "ig-post-abc123",
        "url": "https://instagram.com/p/abc123",
        "username": "johndoe"
      }
    }
  ]
}
```

### curl Example

```bash
curl -s "$VERSELY_API_URL/api/v1/postbridge/posts/uuid-post-1" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## DELETE /api/v1/postbridge/posts/:postId

Delete a post from PostBridge and the database.

### Response

```json
{
  "success": true
}
```

### curl Example

```bash
curl -X DELETE "$VERSELY_API_URL/api/v1/postbridge/posts/uuid-post-1" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| Social posting | 10 req/min per user |
| Account sync | 5 req/min per user |
| Default (per API key) | 60 req/min |

Response headers:
- `X-RateLimit-Limit` — Maximum requests allowed
- `X-RateLimit-Remaining` — Requests remaining in window
- `X-RateLimit-Reset` — Unix timestamp when window resets

---

## Error Codes

| Status | Meaning |
|--------|---------|
| 400 | Bad request — missing caption or account_ids |
| 401 | Unauthorized — invalid/expired API key |
| 402 | Insufficient credits — cost = 2 x platforms |
| 403 | API key lacks `post` scope |
| 404 | Post or account not found |
| 429 | Rate limited — check `X-RateLimit-Reset` |
| 500 | Server error — retry once |
