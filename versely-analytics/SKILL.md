---
name: versely-analytics
version: 1.0.0
description: >
  Read-only analytics for Versely-published posts and external trend research:
  per-post engagement metrics with history, account-level overview, AI trend
  analysis, and a public trending feed (TikTok / Instagram / YouTube / Twitter).
  Use when the user wants to measure post performance, research trends, or
  pull metadata from social URLs.
allowed-tools: Bash, Read
metadata:
  agentskills.io:
    category: analytics
    homepage: https://versely.studio
    tags: ["analytics", "metrics", "trends", "social-research"]
---

# Versely Analytics — Post Metrics & Trend Research

Three concerns, one skill:

1. **Post metrics** — engagement on posts you published through Versely (`/social-analytics/*`).
2. **Trend analysis** — AI-driven analysis of a topic / niche / competitor (`/trend-analysis/*`).
3. **Trending feed** — public per-platform discovery + URL metadata extraction (`/trending-feed/*`).

## Authentication

```bash
VERSELY_API_KEY="vsk_..."
VERSELY_API_URL="${VERSELY_API_URL:-https://api.versely.studio}"
```

Send `Authorization: Bearer $VERSELY_API_KEY`. Do not send `user_id` — middleware injects it.

The `/trending-feed/*` endpoints are **public** (no auth required) but rate-limited per IP. You can still pass the bearer token; it's ignored.

## Required API Key Scope

**Scope:** `analytics`. Covers `/social-analytics/*`, `/trend-analysis/*`, `/trending-feed/*`.

Create a key with `{"scopes": ["analytics"]}` via `POST /api/v1/auth/api-keys`. Live scope catalog: `GET /api/v1/auth/api-keys/scopes`.

`/trending-feed/*` doesn't actually check scopes (public route), but tagging your key with `analytics` keeps usage clean and signals intent.

---

# 1. Post Metrics — `/api/v1/social-analytics/*`

Backed by ScrapCreators. Pulls live metrics from the platform, snapshots them into the `post_metrics` table, and serves them back. Limited to posts you published through Versely (`/social/posts`).

## Account-Level Overview

```bash
curl "$VERSELY_API_URL/api/v1/social-analytics/overview" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Returns aggregate engagement across all your posts plus per-platform breakdowns. Cached server-side (~5 min).

**Response shape:**
```json
{
  "success": true,
  "totals": {
    "posts": 42,
    "views": 125000,
    "likes": 8900,
    "comments": 320,
    "shares": 540,
    "saves": 210,
    "engagement_rate": 0.078
  },
  "by_platform": [
    { "platform": "instagram", "posts": 15, "views": 50000, ... },
    { "platform": "tiktok",    "posts": 20, "views": 70000, ... }
  ],
  "top_posts": [{ "post_id": "...", "platform": "...", "views": 30000, ... }]
}
```

## Per-Post Live Analytics

```bash
curl "$VERSELY_API_URL/api/v1/social-analytics/$POST_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Where `$POST_ID` is the Versely post ID (from `POST /social/posts`'s response `.post.id`, NOT the platform's external ID).

Behavior:
- Cache hit → returns cached payload immediately.
- Cache miss → fetches live from ScrapCreators, snapshots into `post_metrics`, returns the fresh payload.
- Verifies ownership (returns 404 if the post isn't yours).

**Response shape:**
```json
{
  "success": true,
  "postId": "uuid",
  "external_post_id": "...",
  "platforms": ["instagram", "tiktok"],
  "metrics": {
    "instagram": { "views": 12000, "likes": 850, "comments": 24, "shares": 30, "saves": 18, "engagement_rate": 0.077 },
    "tiktok":    { "views": 45000, "likes": 3200, "comments": 95, "shares": 220, "saves": 110, "engagement_rate": 0.081 }
  },
  "fetched_at": "2026-05-07T12:34:56Z"
}
```

**Errors:**
- `400` — `postId is required`
- `404` — post not found OR not owned by you
- `500` — ScrapCreators API key not configured (server-side)

## Force-Collect a Fresh Snapshot

```bash
curl -X POST "$VERSELY_API_URL/api/v1/social-analytics/$POST_ID/collect" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Bypasses cache, fetches live, writes a new row to `post_metrics`. Use when you want a measurement at a specific point in time (e.g., for a daily-snapshot cron, or after a viral spike).

## Metrics History

```bash
curl "$VERSELY_API_URL/api/v1/social-analytics/$POST_ID/history?limit=50" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

Returns ordered `post_metrics` snapshots (newest first, default limit 50). Use to plot a metric over time:

```json
{
  "success": true,
  "postId": "uuid",
  "metrics": [
    { "platform": "tiktok", "views": 45000, "likes": 3200, "fetched_at": "2026-05-07T12:00:00Z" },
    { "platform": "tiktok", "views": 32000, "likes": 2400, "fetched_at": "2026-05-06T12:00:00Z" },
    ...
  ]
}
```

---

# 2. Trend Analysis — `/api/v1/trend-analysis/*`

Cost-sensitive (rate-limited at 30 req/min per IP) — generates an AI trend report on a topic.

## Run an Analysis

```bash
curl -X POST "$VERSELY_API_URL/api/v1/trend-analysis/analyze" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "AI tools for solo founders",
    "platforms": ["tiktok", "youtube", "instagram"],
    "depth": "deep"
  }'
```

**Body:**
- `topic` (required): the niche / keyword / handle to analyze
- `platforms` (optional): subset of `tiktok`, `instagram`, `youtube`, `twitter`
- `depth` (optional): `"quick"` | `"standard"` | `"deep"`

**Response:** stores into `trend_analyses`, returns the saved row with `id`, `summary`, `key_topics[]`, `viral_hooks[]`, `recommendations[]`. Charges credits proportional to depth.

## History & Detail

```bash
# List your analyses
curl "$VERSELY_API_URL/api/v1/trend-analysis/history" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Get one by ID
curl "$VERSELY_API_URL/api/v1/trend-analysis/$ANALYSIS_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"

# Delete
curl -X DELETE "$VERSELY_API_URL/api/v1/trend-analysis/$ANALYSIS_ID" \
  -H "Authorization: Bearer $VERSELY_API_KEY"
```

---

# 3. Trending Feed — `/api/v1/trending-feed/*`

Public discovery & metadata extraction. **No auth required**, but per-IP rate-limited (`publicRateLimiter`, 100 req/15 min).

## Per-Platform Endpoints

```bash
# TikTok video detail (by URL or ID)
curl "$VERSELY_API_URL/api/v1/trending-feed/tiktok/video?url=https://www.tiktok.com/@user/video/12345"

# Instagram user reels
curl "$VERSELY_API_URL/api/v1/trending-feed/instagram/reels?username=jane.doe"

# YouTube video detail
curl "$VERSELY_API_URL/api/v1/trending-feed/youtube/video?url=https://youtu.be/abc123"

# Twitter/X tweet detail
curl "$VERSELY_API_URL/api/v1/trending-feed/twitter/tweet?url=https://x.com/user/status/12345"
```

Each returns the platform-specific metadata (caption, view/like/share counts, media URLs, posted_at, author handle, etc.).

## Generic Search & URL Resolver

```bash
# Cross-platform keyword search (uses ScrapCreators)
curl "$VERSELY_API_URL/api/v1/trending-feed/search?query=morning+routine&platform=tiktok&cursor="

# Resolve any social URL to its post metadata (auto-detects platform)
curl "$VERSELY_API_URL/api/v1/trending-feed/post-info?url=https://www.tiktok.com/@user/video/12345"
```

`post-info` is the universal resolver — pass it any TikTok / Instagram / YouTube / Twitter URL and it returns the appropriate platform's metadata. Useful when chaining "user pastes a link → analyze it".

---

## Common Pipelines

### Daily Engagement Snapshot

```bash
# Cron: pull all your posts, snapshot metrics for each
POSTS=$(curl -s "$VERSELY_API_URL/api/v1/social/posts?limit=100" \
  -H "Authorization: Bearer $VERSELY_API_KEY" | jq -r '.posts[].id')

for POST_ID in $POSTS; do
  curl -s -X POST "$VERSELY_API_URL/api/v1/social-analytics/$POST_ID/collect" \
    -H "Authorization: Bearer $VERSELY_API_KEY" > /dev/null
done
```

### Trend → Generate → Post

```bash
# 1. Research the trend
ANALYSIS=$(curl -s -X POST "$VERSELY_API_URL/api/v1/trend-analysis/analyze" \
  -H "Authorization: Bearer $VERSELY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"topic": "AI productivity hacks", "depth": "deep"}')

HOOK=$(echo "$ANALYSIS" | jq -r '.viral_hooks[0]')

# 2. Generate content using the hook (requires `generate` scope on a separate key, or merged scopes on one key)
# 3. Post via /social/posts (requires `post` scope)
# See versely-content-pipeline for the full chain.
```

## Error Handling

- **401** — invalid / expired API key (only on `/social-analytics` and `/trend-analysis`).
- **403** — wrong scope (need `analytics`).
- **404** — post / analysis not found, or not owned by you.
- **429** — rate limited:
  - `/trend-analysis/analyze`: 30/min per IP (cost-sensitive)
  - `/trending-feed/*`: 100 / 15 min per IP (public)
  - default: 60/min per API key
- **500** — server-side: usually `SCRAPECREATORS_API_KEY` not configured.

## Rate Limits

| Endpoint group | Limit | Bucket |
|---|---|---|
| `/social-analytics/*` | 60/min | per API key |
| `/trend-analysis/analyze` | 30/min | per IP (cost-sensitive) |
| `/trend-analysis` (history/get/delete) | 60/min | per API key |
| `/trending-feed/*` | 100 / 15 min | per IP (public) |

Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.
