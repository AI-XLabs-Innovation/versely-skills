---
name: versely-social
version: 1.0.0
description: >
  Post and schedule content to Instagram, TikTok, YouTube, Twitter, Facebook,
  LinkedIn, Pinterest, Bluesky, and Threads via Versely's Post for Me integration.
  Use when the user wants to publish, share, schedule, or post content to social media.
allowed-tools: Bash, Read
metadata:
  agentskills.io:
    category: social-media
    homepage: https://versely.studio
    tags: ["social-media", "posting", "scheduling", "instagram", "tiktok"]
---

# Versely Social — Social Media Posting & Scheduling

Post and schedule content to 9 social media platforms through Versely's Post for Me integration.

**Supported platforms:** Instagram, TikTok, YouTube, Twitter/X, Facebook, LinkedIn, Pinterest, Bluesky, Threads.

The backend doesn't hard-code a platform list — it uses whatever Post for Me returns. In addition to the 9 above, TikTok accounts can come back as `"tiktok"` or `"tiktok_business"`. Filter by both when targeting TikTok specifically:

```bash
jq '[.accounts[] | select(.platform == "tiktok" or .platform == "tiktok_business") | .id]'
```

## Authentication

All requests use a scoped API key (`vsk_` prefix).

```bash
VERSELY_API_KEY="vsk_..."
VERSELY_API_URL="https://api.versely.studio"
```

Every request includes:
```bash
-H "Authorization: Bearer $VERSELY_API_KEY"
-H "Content-Type: application/json"
```

**Important:** Do NOT send `user_id` in requests. The API key resolves the user server-side.

## Required API Key Scopes

This skill spans **two scopes** — they're separate so you can grant account-management independently from posting.

| Scope | Endpoints |
|---|---|
| `post` | `POST /social/posts`, `GET /social/posts`, `GET /social/posts/:id`, `DELETE /social/posts/:id`, `POST /social/preview` |
| `manage_accounts` | `GET /social/auth-url`, `GET /social/accounts`, `POST /social/accounts/refresh`, `DELETE /social/accounts/:id` |

A key that runs every example in this skill needs both: `{"scopes": ["post", "manage_accounts"]}`. Live scope catalog: `GET /api/v1/auth/api-keys/scopes`.

## Before Posting — Pre-checks

### 1. Check Credits

Each post costs **1 credit per platform** via API (2 credits in-app). Posting to 3 platforms = 3 credits.

```bash
curl -s "$VERSELY_API_URL/api/v1/user/me" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq '.user.credits'
```

### 2. List Connected Accounts

Always verify which accounts are available before posting:

```bash
curl -s "$VERSELY_API_URL/api/v1/social/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq '.accounts[] | {id, platform, username}'
```

**Response:**
```json
{
  "success": true,
  "accounts": [
    {
      "id": "uuid-1234",
      "external_account_id": "12345",
      "platform": "instagram",
      "username": "johndoe",
      "profile_image_url": "https://...",
      "is_active": true
    }
  ]
}
```

If no accounts are connected, tell the user to connect accounts at Settings > Social Accounts.

## Preview Before Posting (Optional)

**Endpoint:** `POST /api/v1/social/preview`

Render mock platform previews of how a post will look on each connected account, without spending credits or actually publishing. Use this when the user wants to "see what it'll look like first."

```bash
curl -X POST "$VERSELY_API_URL/api/v1/social/preview" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "Check out this amazing sunset!",
    "media_urls": ["https://example.com/sunset.jpg"],
    "account_ids": ["uuid-1234", "uuid-5678"]
  }'
```

**Body:**
- `account_ids` (required): Same DB UUIDs from `/social/accounts` — used to determine platform per preview.
- `caption` OR `media_urls` (at least one required): If only media is given, caption can be empty.

**Response:**
```json
{
  "success": true,
  "previews": [
    { "platform": "instagram", "username": "...", "preview_html": "...", "image_url": "..." },
    { "platform": "tiktok",    "username": "...", "preview_html": "...", "image_url": "..." }
  ]
}
```

**Errors:**
- `400` — neither caption nor media supplied, or `account_ids` empty
- `403` — none of the supplied account IDs belong to the authenticated user

This endpoint is rate-limited by the `socialPostRateLimiter` (same bucket as create-post) but does NOT charge credits.

## Create a Post (Immediate)

**Endpoint:** `POST /api/v1/social/posts`

```bash
curl -X POST "$VERSELY_API_URL/api/v1/social/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "Check out this amazing sunset!",
    "media_urls": ["https://example.com/sunset.jpg"],
    "account_ids": ["uuid-1234", "uuid-5678"]
  }'
```

**Required fields:**
- `caption` (string): Post text content
- `account_ids` (string[]): Array of social account UUIDs from the accounts endpoint

**Optional fields:**
- `media_urls` (string[]): Array of media URLs (images or videos)
- `scheduled_at` (string): ISO 8601 datetime for scheduling (omit for immediate)
- `is_draft` (boolean): Save as draft without posting
- `tiktok_draft` (boolean): Save TikTok-specific drafts (TikTok in-app drafts) — separate from `is_draft`

**Response:**
```json
{
  "success": true,
  "post": {
    "id": "uuid-post-1",
    "caption": "Check out this amazing sunset!",
    "status": "processing",
    "platforms": ["instagram", "tiktok"],
    "scheduled_at": null,
    "is_draft": false,
    "tiktok_draft": false
  },
  "credits_charged": 4
}
```

Immediate posts initially return `status: "processing"`. The status moves to `"posted"` (or `"failed"`) after the Post for Me webhook fires. Poll `GET /api/v1/social/posts/:postId` to track the final status.

## Schedule a Post

Same endpoint, but include `scheduled_at`:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/social/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "Morning motivation! Rise and grind.",
    "media_urls": ["https://example.com/motivation.jpg"],
    "account_ids": ["uuid-1234"],
    "scheduled_at": "2026-03-01T09:00:00Z"
  }'
```

**Response** will show `"status": "scheduled"`.

## Instagram Carousel Posts

Pass multiple image URLs (up to 20) for Instagram carousels:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/social/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "Our latest product collection",
    "media_urls": [
      "https://example.com/product1.jpg",
      "https://example.com/product2.jpg",
      "https://example.com/product3.jpg"
    ],
    "account_ids": ["uuid-instagram-account"]
  }'
```

## Post to All Connected Accounts

Workflow: fetch all accounts, then post with all account IDs:

```bash
# 1. Get all account IDs
ACCOUNTS=$(curl -s "$VERSELY_API_URL/api/v1/social/accounts" \
  -H "Authorization: Bearer $VERSELY_API_KEY")
ACCOUNT_IDS=$(echo $ACCOUNTS | jq '[.accounts[].id]')

# 2. Post to all
curl -X POST "$VERSELY_API_URL/api/v1/social/posts" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"caption\": \"Posted everywhere!\",
    \"media_urls\": [\"https://example.com/image.jpg\"],
    \"account_ids\": $ACCOUNT_IDS
  }"
```

**Warning:** This charges 2 credits per account. Always calculate total cost and confirm with the user first.

## View Post History

```bash
# List recent posts (default: 20)
curl -s "$VERSELY_API_URL/api/v1/social/posts?limit=10&offset=0" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq '.posts'
```

## Get Post Details & Results

```bash
curl -s "$VERSELY_API_URL/api/v1/social/posts/POST_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

**Response includes platform-specific results:**
```json
{
  "success": true,
  "post": { "..." },
  "results": [
    {
      "success": true,
      "social_account_id": 123,
      "platform_data": {
        "id": "instagram-post-id",
        "url": "https://instagram.com/p/...",
        "username": "johndoe"
      }
    }
  ]
}
```

## Delete a Post

```bash
curl -X DELETE "$VERSELY_API_URL/api/v1/social/posts/POST_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

## Refresh New Accounts

After a user connects new social accounts via the OAuth flow, refresh them:

```bash
curl -X POST "$VERSELY_API_URL/api/v1/social/accounts/refresh" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

**Response:**
```json
{
  "success": true,
  "new_accounts": 2,
  "total": 5
}
```

## Disconnect an Account

```bash
curl -X DELETE "$VERSELY_API_URL/api/v1/social/accounts/ACCOUNT_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

## Credit Costs

- **1 credit per platform** per post via API (2 credits in-app)
- Posting to 3 platforms = 3 credits
- Scheduling costs the same as immediate posting (charged at schedule time)
- Credits are refunded automatically if the Post for Me API call fails

## Platform-Specific Tips

- **Instagram**: Supports carousels (up to 20 images). Best aspect ratios: 1:1, 4:5, 9:16.
- **TikTok**: Automatically adds trending music to slideshow/carousel posts. Use 9:16 vertical video.
- **YouTube**: Supports longer captions. Include a title in the first line.
- **Twitter/X**: 280 character limit. Images auto-attached.
- **LinkedIn**: Professional tone recommended. Supports up to 20 images.
- **Pinterest**: Include descriptive text for SEO. Link back to source.
- **Bluesky**: 300 character limit. Growing platform.
- **Threads**: Similar to Instagram. Short-form text + media.

For detailed per-platform best practices, see [platform-guide.md](platform-guide.md).

## Error Handling

- **401 Unauthorized** — API key invalid or expired. Check Settings > API Keys.
- **403 Forbidden** — Multiple causes: API key lacks `post` scope (use a key with the `post` scope, or `manage_accounts` for `/accounts/*`); insufficient credits at request entry (no balance); or `"No valid accounts found for this user"` (the supplied `account_ids` don't belong to this user or are disconnected).
- **402 Payment Required** — Insufficient credits at deduction time. Cost = 2 credits × number of platforms (flat — same for API and in-app).
- **404 Not Found** — Post not found (only for `GET /posts/:postId` and `DELETE /posts/:postId`).
- **429 Too Many Requests** — Rate limited. Wait and retry. Check `X-RateLimit-Reset` header.
- **502 Bad Gateway** — `"Post for Me error: ..."` — platform-specific failure (e.g., Instagram aspect ratio rejection). Credits are auto-refunded.
- **500 Internal Server Error** — Server error. Retry once after 10 seconds.
- **"Caption is required"** — The `caption` field is missing or empty.
- **"At least one account_id is required"** — No `account_ids` provided.

## Rate Limits

- Social posting: 10 requests/minute per user
- Account sync: 5 requests/minute per user
- Default API: 60 requests/minute per API key
- Response headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

For complete API schemas, see [api-reference.md](api-reference.md).
