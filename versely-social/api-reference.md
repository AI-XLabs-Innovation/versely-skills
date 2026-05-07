# API Reference — Versely Social

Base URL: `$VERSELY_API_URL` (default: `https://api.versely.studio`)

All endpoints require `Authorization: Bearer $VERSELY_API_KEY` header.

**Scopes:** This skill spans two scopes:
- `post` — `/posts`, `/posts/:id`, `/preview`
- `manage_accounts` — `/auth-url`, `/accounts`, `/accounts/refresh`, `/accounts/:id`

A key that uses every endpoint in this reference needs both. Live scope catalog: `GET /api/v1/auth/api-keys/scopes`.

---

## GET /api/v1/social/auth-url

Get a per-platform OAuth URL for users to connect their social account.

### Query Parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `platform` | string | Yes | Platform to connect: `instagram`, `tiktok`, `youtube`, `twitter`, `facebook`, `linkedin`, `pinterest`, `bluesky`, `threads` |
| `connection_type` | string | No | Instagram only: `facebook` (Login with Facebook) or `instagram` (Login with Instagram) |
| `redirect_url` | string | No | URL to redirect after connecting |

### Response

```json
{
  "success": true,
  "url": "https://app.post-bridge.com/connect?..."
}
```

### curl Example

```bash
curl -s "$VERSELY_API_URL/api/v1/social/auth-url?platform=instagram" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## GET /api/v1/social/accounts

List the authenticated user's connected social media accounts.

### Response

```json
{
  "success": true,
  "accounts": [
    {
      "id": "uuid-1234-5678",
      "external_account_id": "12345",
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
curl -s "$VERSELY_API_URL/api/v1/social/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## POST /api/v1/social/accounts/refresh

Refresh accounts from Post for Me after a user connects new social accounts.

**Rate limit:** 5 requests/minute per user

### Response

```json
{
  "success": true,
  "new_accounts": 2,
  "reactivated_accounts": 1,
  "total": 5
}
```

`reactivated_accounts` counts previously-disconnected mappings that were re-activated when the same external account reconnected.

### curl Example

```bash
curl -X POST "$VERSELY_API_URL/api/v1/social/accounts/refresh" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## DELETE /api/v1/social/accounts/:accountId

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
curl -X DELETE "$VERSELY_API_URL/api/v1/social/accounts/uuid-1234" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## POST /api/v1/social/posts

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
| `tiktok_draft` | boolean | No | Save TikTok-specific in-app drafts (independent of `is_draft`). Default: `false` |

### Response — Immediate Post

```json
{
  "success": true,
  "post": {
    "id": "uuid-post-1",
    "caption": "Check out this sunset!",
    "status": "processing",
    "platforms": ["instagram", "tiktok"],
    "scheduled_at": null,
    "is_draft": false,
    "tiktok_draft": false
  },
  "credits_charged": 4
}
```

Immediate posts initially return `status: "processing"`. They transition to `"posted"` (or `"failed"`) after the Post for Me webhook fires. Poll `GET /api/v1/social/posts/:postId` to track the final state.

### Response — Scheduled Post

```json
{
  "success": true,
  "post": {
    "id": "uuid-post-1",
    "caption": "Morning motivation!",
    "status": "scheduled",
    "platforms": ["instagram"],
    "scheduled_at": "2026-03-01T09:00:00Z",
    "is_draft": false,
    "tiktok_draft": false
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
{"success": false, "error": "Post for Me error: ..."}
```

**Credit refund:** If Post for Me API fails after credits are deducted, credits are automatically refunded.

### curl Example — Immediate Post

```bash
curl -X POST "$VERSELY_API_URL/api/v1/social/posts" \
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
curl -X POST "$VERSELY_API_URL/api/v1/social/posts" \
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
curl -X POST "$VERSELY_API_URL/api/v1/social/posts" \
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

## GET /api/v1/social/posts

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
      "external_post_id": "pb-123",
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
curl -s "$VERSELY_API_URL/api/v1/social/posts?limit=10" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## GET /api/v1/social/posts/:postId

Get a single post with platform-specific results.

### Response

```json
{
  "success": true,
  "post": {
    "id": "uuid-post-1",
    "external_post_id": "pb-123",
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
curl -s "$VERSELY_API_URL/api/v1/social/posts/uuid-post-1" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

## DELETE /api/v1/social/posts/:postId

Delete a post from Post for Me and the database.

### Response

```json
{
  "success": true
}
```

### curl Example

```bash
curl -X DELETE "$VERSELY_API_URL/api/v1/social/posts/uuid-post-1" \
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
| 400 | Bad request — missing caption or `account_ids` |
| 401 | Unauthorized — invalid/expired API key |
| 402 | Insufficient credits at deduction time — cost = 2 × number of platforms (flat) |
| 403 | API key lacks the required scope (`post`, or `manage_accounts` for `/accounts/*`); insufficient credits at request entry; or "No valid accounts found for this user" (the `account_ids` don't belong to this user or are disconnected) |
| 404 | Post not found (only for `GET /posts/:postId` and `DELETE /posts/:postId`) |
| 429 | Rate limited — check `X-RateLimit-Reset` |
| 502 | "Post for Me error: …" — upstream/platform failure. Credits are auto-refunded. |
| 500 | Server error — retry once |
