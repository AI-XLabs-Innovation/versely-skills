# Versely Agent Skills

Eight AI agent skills that turn Claude Code, Cursor, Codex, and 50+ other coding agents into a complete Versely-powered content studio — image and video generation, music, slideshows, UGC videos, social publishing, and analytics.

## Quick start

The full Versely flow — skills + MCP server + API key — is one command:

```bash
npx @versely/cli setup
```

That runs three things for you:

1. Installs these skills via [vercel-labs/skills](https://github.com/vercel-labs/skills) into every detected agent.
2. Prompts for your Versely API key and stores it at `~/.versely/config.json`.
3. Connects the [Versely MCP server](https://mcp.versely.studio/mcp) to every detected agent so the skills can call it.

Restart your agent and the skills + `mcp__versely__*` tools are live.

### Skills only (no MCP)

If you already have the Versely MCP connected and only want the skill instructions:

```bash
npx skills add AI-XLabs-Innovation/versely-skills
```

This uses Vercel Labs' [open skills CLI](https://github.com/vercel-labs/skills) and installs to whichever agents you have on disk.

## The skills

| Skill | What it does |
|---|---|
| [versely-generate](versely-generate/) | Generate AI images, videos, music, and sound effects. 100+ image models (Flux 2, Imagen 4, Nano Banana 2, Midjourney V7, GPT Image 2, Recraft 4), 60+ video models (Sora 2, VEO 3.1, Kling 2.5, Hailuo 2.3, Seedance 2.0, LTX 2.3, Wan 2.7, Pixverse V6), Suno music V3.5–V5.5. |
| [versely-slideshow](versely-slideshow/) | Create AI-generated slideshows and convert them to videos. Generate multiple images from a prompt, add text overlays, upload custom media, export as video with transitions and audio. |
| [versely-movie](versely-movie/) | Build multi-scene AI movies with the dedicated `/movie/*` project API. Manage scenes, chain them via previous-frame I2V, generate, poll per-scene status, combine into a final video. |
| [versely-ugc](versely-ugc/) | UGC-style videos: video overlays, text captions, auto-timed captions from speech, background removal, voiceover generation. Overlay a talking head onto product footage. |
| [versely-music](versely-music/) | Full Suno music API — generate, extend, mashup, replace sections, boost style, separate vocals, generate covers/personas/MIDI, create sound effects, music videos from a track + image set. |
| [versely-social](versely-social/) | Post and schedule content to Instagram, TikTok, YouTube, Twitter, Facebook, LinkedIn, Pinterest, Bluesky, and Threads via Versely's Post for Me integration. |
| [versely-analytics](versely-analytics/) | Read-only analytics for Versely-published posts plus external trend research. Per-post engagement with history, account-level overview, AI trend analysis, public trending feed across TikTok / Instagram / YouTube / Twitter. |
| [versely-content-pipeline](versely-content-pipeline/) | End-to-end content creation workflows that orchestrate everything above — image/video → overlays → captions → publish or schedule. Use when you want a full content calendar or multi-step creative pipeline. |

## How they work

Each skill is a folder with a [`SKILL.md`](https://github.com/vercel-labs/skills#skill-file-format) describing when to use it, plus reference docs (API endpoints, model lists, examples). Agents that support the Anthropic skills format load these automatically and surface them when the user's request matches the skill's description.

All skills call the public Versely API through the [Versely MCP server](https://mcp.versely.studio/mcp). You need an API key from [versely.studio](https://versely.studio/settings/api-keys) and the MCP server connected to your agent — `npx @versely/cli setup` handles both.

## Supported agents

Anywhere [vercel-labs/skills](https://github.com/vercel-labs/skills) installs to — currently 54 agents including:

Claude Code · Cursor · Codex · Gemini CLI · GitHub Copilot · Continue · Cline · Goose · Windsurf · OpenCode · Roo · Kilo · Augment · Aider · Crush · Warp · Zencoder · Tabnine · Trae · Devin · Replit · Junie · Qoder · Forgecode · …

`@versely/cli`'s automatic MCP connection currently handles Claude Code and Cursor. For other agents, install skills with `npx skills add` and connect the MCP server manually (see your agent's docs).

## Get an API key

Sign in at [versely.studio](https://versely.studio/) and create a key under **Settings → API Keys**. API usage is billed at 2× the in-app credit rate.

## Links

- npm: [@versely/cli](https://www.npmjs.com/package/@versely/cli)
- MCP endpoint: `https://mcp.versely.studio/mcp`
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Website: [versely.studio](https://versely.studio)

## License

MIT
