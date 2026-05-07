# Changelog

All notable changes to the Versely Agent Skills will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.0] - 2026-05-08

### Added

#### versely-analytics (new)

- Read-only analytics for posts published via Versely: per-post engagement metrics with history, account-level overview, and AI trend analysis.
- Public trending feed across TikTok, Instagram, YouTube, and Twitter for external trend research.

#### versely-music (new)

- Full Suno music API surface — covers all ~24 Suno endpoints.
- Generate, extend, mashup, replace sections, and boost style on existing tracks.
- Vocal separation, cover / persona / MIDI generation, and sound-effect creation.
- Music-video creation from a track plus image set.

#### versely-content-pipeline

- Significantly expanded workflow library and pipeline templates (covering analytics + music on top of existing image / video / slideshow / UGC / social pipelines).

### Changed

#### versely-movie

- Reworked around the dedicated `/api/v1/movie/*` project API: explicit movie + scene records, per-scene non-blind polling, and a unified `/:movieId/status` endpoint replacing per-request-id polling.
- Scene chaining via previous-frame I2V is first-class (cleaner than the prior storyboard-only flow).

#### versely-generate

- Substantially expanded SKILL.md with deeper model coverage and workflow guidance.

### Tooling

- Added `sync-skills.ps1` — PowerShell helper that wipes and re-copies every skill folder into `~/.claude/skills/` so deleted / renamed source files don't linger after an update.
- Updated the `sync-models.yml` GitHub Actions workflow.

## [1.0.1] - 2026-02-16

### Changed

- All skill docs updated to reflect the new API-key pricing model: API requests cost **half** the credits of in-app usage (formula changed from `ceil(USD × 20)` to `ceil(USD × 10)`). Affects credit estimates throughout `versely-generate`, `versely-movie`, `versely-slideshow`, `versely-social`, `versely-ugc`, and `versely-content-pipeline`.

## [1.0.0] - 2026-02-15

### Added

#### versely-generate
- Image generation with 50+ models (Flux Pro Ultra, Imagen 4, GPT Image, Midjourney V7)
- Video generation with 30+ models (Sora 2, VEO 3.1, Kling, Hailuo)
- Music generation (Suno V3.5-V5)
- Sound effects generation
- Image editing (Nano Banana Edit, GPT Image 1 Edit, Flux Kontext)
- Image upscaling (Topaz, SeedVR, Clarity Crystal)
- Background removal
- Scene expansion for cinematic prompts
- Models reference with progressive disclosure (quick table + full details)
- Real workflow examples (product photos, video ads, music)

#### versely-social
- Post to 9 platforms: Instagram, TikTok, YouTube, Twitter/X, Facebook, LinkedIn, Pinterest, Bluesky, Threads
- Schedule posts with ISO 8601 datetime
- Instagram carousel support (up to 20 images)
- Account management (list, sync, disconnect)
- Per-platform best practices guide

#### versely-slideshow
- Create slideshows with AI-generated images
- Text overlays with positioning, fonts, backgrounds
- Convert to video with transitions (none, fade, crossfade)
- Upload custom media and audio
- Reorder images
- Full pipeline: create → overlay → video → post

#### versely-movie
- Multi-scene storyboard generation (Sora 2 Pro Storyboard)
- Scene expansion with camera direction
- Kling 2.5 Turbo and VEO 3.1 First Last Frame support
- Scene merging via Segmind API

#### versely-ugc
- Video overlay (talking-head on product footage)
- Static text captions with styling
- Auto-timed captions from speech (STT)
- Caption preview and manual editing
- TTS voiceover with auto-synced captions
- Black background removal

#### versely-content-pipeline
- Generate & Post pipeline
- Social Media Reel pipeline (slideshow → video → post)
- Product Carousel pipeline
- Content Calendar pipeline (7-day scheduling)
- UGC Product Review pipeline
- Music Video pipeline
- TTS Voiceover Reel template
- Multi-Platform Batch template
- Error recovery guidelines
- Credit budget calculator
