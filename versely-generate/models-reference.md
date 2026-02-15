# Models Reference — Versely Generate

## Quick Reference (always read this)

Credits formula: `ceil(USD_price × 20)`. Costs may vary by resolution/duration.

### Top Image Models

| Model | Speed | Quality | ~Credits | Input |
|-------|-------|---------|----------|-------|
| Flux Pro Ultra | Fast | Best | 2 | Text |
| Imagen 4 Ultra | Fast | Excellent | 2 | Text |
| Imagen 4 | Fast | Great | 1 | Text |
| Imagen 4 Fast | Fastest | Good | 1 | Text |
| GPT Image 1 | Fast | Great | 1 | Text |
| Midjourney V7 | Medium | Best | 2 | Text |
| Seedream 4.0 | Fast | Great | 1 | Text |
| Recraft V3 | Fast | Great | 1 | Text |
| Ideogram V3 | Medium | Excellent | 1-2 | Text |
| NANO Banana | Fast | Good | 1 | Text |
| Nano Banana Edit | Fast | Good | 1 | Text + Image |
| GPT Image 1 Edit | Fast | Great | 1 | Text + Image |
| Reve Edit | Fast | Good | 1 | Text + Image |
| Flux Kontext | Fast | Great | 1 | Text + Image |
| Seedream Edit | Fast | Good | 1 | Text + Image |
| Qwen Image Edit | Fast | Good | 1 | Text + Image |

### Top Video Models

| Model | Speed | Quality | ~Credits (5s) | Input |
|-------|-------|---------|---------------|-------|
| Sora 2 Text to Video Pro | Slow | Best | 15-25 | Text |
| Sora 2 Text to Video | Medium | Great | 10 | Text |
| VEO 3.1 | Medium | Excellent | 4-8 | Text |
| VEO 3.1 Fast | Fast | Good | 2-3 | Text |
| Kling 2.5 Turbo | Medium | Great | 5 | Text |
| Hailuo 02 | Medium | Good | 5 | Text |
| Wan Video 2.5 T2V | Medium | Good | 5-15 | Text |
| Pixverse V4 | Fast | Good | 3-8 | Text |
| Sora 2 Image to Video | Slow | Best | 6 | Image |
| Wan Video 2.5 I2V | Medium | Good | 5-15 | Image |
| VEO First Last Frame | Medium | Excellent | 4-8 | 2 Images |

### Music & Audio Models

| Model | Speed | Quality | ~Credits | Notes |
|-------|-------|---------|----------|-------|
| Suno V5 | Medium | Best | ~10 | Latest, best quality |
| Suno V4_5PLUS | Medium | Excellent | ~8 | Great for instrumentals |
| Suno V4_5 | Medium | Great | ~6 | Good all-around |
| Suno V4 | Fast | Good | ~4 | Reliable |
| Chatterbox TTS | Fast | Good | ~1/s | Text-to-speech |
| Eleven Labs Speech Turbo | Fast | Best | ~2/s | Premium TTS |
| Minimax Speech | Fast | Good | ~1/s | Budget TTS |

### Utility Models

| Model | Type | ~Credits | Input |
|-------|------|----------|-------|
| Topaz Upscale Image | Upscale | 1 | Image |
| SeedVR Upscale | Upscale | 1 | Image |
| Crystal Upscale | Upscale | 1 | Image |
| BRIO Video Background Removal | BG Remove | ~2/s | Video |

---

## Full Model Details (read only when user asks about a specific model)

### Image Models — Text-to-Image

| Model | Billing | Price (USD) | ~Credits |
|-------|---------|-------------|----------|
| Flux Pro Ultra | flat | $0.06 | 2 |
| Imagen 4 Ultra | flat | $0.06 | 2 |
| Imagen 4 | flat | $0.02 | 1 |
| Imagen 4 Fast | flat | $0.02 | 1 |
| GPT Image 1 (GPT IMAG 1) | flat | $0.02 | 1 |
| GPT Image 1.5 | flat | $0.02 | 1 |
| Midjourney V7 | flat | $0.10 | 2 |
| Midjourney Niji 7 | flat | $0.10 | 2 |
| Recraft V3 Image | flat | $0.04 | 1 |
| Reve Text to Image | flat | $0.04 | 1 |
| Seedream 4.0 | flat | $0.03 | 1 |
| Seedream 4.5 | flat | $0.03 | 1 |
| NANO Banana | flat | $0.04 | 1 |
| Nano Banana Pro | flat | $0.04 | 1 |
| Ideogram V3 Turbo | flat | $0.03 | 1 |
| Ideogram V3 Quality | flat | $0.09 | 2 |
| Flux Schnell | per_megapixel | $0.003 | 1 |
| Flux 1.1 Pro | per_megapixel | $0.04 | 1 |
| Flux Pro | flat | $0.04 | 1 |
| Flux Kontext Max | flat | $0.08 | 2 |
| Flux 2 Flash | per_megapixel | $0.01 | 1 |
| HiggsField | flat | $0.23 | 5 |
| Bria Fibo | flat | $0.04 | 1 |
| Luma Photon Flash | per_megapixel | $0.005 | 1 |
| Leonardo Lucid Origin | flat | $0.04 | 1 |
| Qwen Image | per_megapixel | $0.02 | 1 |
| Qwen Image Max | per_megapixel | $0.03 | 1 |
| Grok Imagine | flat | $0.04 | 1 |
| Imagine Heart 1.5 | flat | $0.04 | 1 |
| WAN V2.6 Text to Image | flat | $0.04 | 1 |

### Image Models — Edit / Image-to-Image

| Model | Billing | Price (USD) | ~Credits | Requires |
|-------|---------|-------------|----------|----------|
| Nano Banana Edit | flat | $0.04 | 1 | image_url |
| NANO Banana Edit (2) | flat | $0.04 | 1 | image_url |
| Nano Banana Pro Edit | flat | $0.04 | 1 | image_url |
| GPT Image 1 Edit | flat | $0.02 | 1 | image_url |
| Midjourney V7 Image Edit | flat | $0.12 | 3 | image_url |
| Reve Edit | flat | $0.04 | 1 | image_url |
| Flux Kontext | flat | $0.04 | 1 | image_url |
| Seedream Edit | per_image | $0.03 | 1 | image_url |
| Seedream 4.5 Edit | flat | $0.03 | 1 | image_url |
| Qwen Image Edit | per_megapixel | $0.03 | 1 | image_url |
| Qwen Image Edit Plus Lora | per_megapixel | $0.035 | 1 | image_url |
| Qwen Image (I2I) | per_megapixel | $0.03 | 1 | image_url |
| Lucy Restyle | flat | $0.04 | 1 | image_url |
| LightX Recamera | flat | $0.04 | 1 | image_url |
| LightX Relight | flat | $0.04 | 1 | image_url |
| WAN V2.6 Image to Image | flat | $0.04 | 1 | image_url |
| WAN Vision Enhancer | flat | $0.04 | 1 | image_url |

### Video Models — Text-to-Video

| Model | Billing | Price | ~Credits (5s) |
|-------|---------|-------|---------------|
| Sora 2 Text to Video | per_second | $0.10/s | 10 |
| Sora 2 Text to Video Pro | res_per_second | $0.30-0.50/s | 15-25 |
| Sora 2 Pro Storyboard | per_second | $0.30/s | 30 |
| VEO 3.1 | audio_based | $0.20-0.40 | 4-8 |
| VEO 3.1 Fast | audio_based | $0.10-0.15 | 2-3 |
| Kling 2.5 Turbo | base+per_second | $0.21 base | 5 |
| Kling V2.6 Pro T2V | base+per_second | $0.40 base | 8 |
| Kling V3 Pro T2V | base+per_second | $0.50 base | 10 |
| Hailuo 02 | per_second | $0.045/s | 5 |
| Hailuo 2.3 Pro | flat | $0.49 | 10 |
| Wan Video 2.5 T2V | res_per_second | $0.05-0.15/s | 5-15 |
| Pixverse V4 | resolution_flat | $0.15-0.40 | 3-8 |
| LTXV2 | resolution | $0.04-0.16 | 1-4 |
| Seed Dance T2V | flat | $0.18 | 4 |
| Luma Ray 2 720p | flat | $0.50 | 10 |

### Video Models — Image-to-Video

| Model | Billing | Price | ~Credits (5s) | Requires |
|-------|---------|-------|---------------|----------|
| Sora 2 Image to Video | per_second | $0.12/s | 12 | image_url |
| Sora 2 I2V Pro | res_per_second | $0.30-0.50/s | 15-25 | image_url |
| Wan Video 2.5 I2V | res_per_second | $0.05-0.15/s | 5-15 | image_url |
| Kling 2.5 Turbo (I2V) | base+per_second | $0.35 base | 7 | image_url |
| Kling V3 Pro I2V | base+per_second | $0.55 base | 11 | image_url |
| Hailuo 02 (I2V) | per_second | $0.08/s | 8 | image_url |
| Pixverse Image to Video | flat | $0.20 | 4 | image_url |
| Seed Dance I2V | flat | $0.24 | 5 | image_url |
| Seedance v1.5 Pro I2V | flat | $0.60 | 12 | image_url |
| VEO First Last Frame | audio_based | $0.20-0.40 | 4-8 | 2 images |
| VEO First Last Frame Fast | audio_based | $0.10-0.15 | 2-3 | 2 images |
| Dreamactor V2 | flat | $0.30 | 6 | image + video |

### Lipsync Models

| Model | Billing | Price | ~Credits | Requires |
|-------|---------|-------|----------|----------|
| Veo 3 | per_second | $0.30/s | 6/s | image + audio |
| Veo 3.1 Fast | per_second | $0.20/s | 4/s | image + audio |
| Infini Talk | per_second | $0.30/s | 6/s | image + audio |
| VEED Fabric 1.0 | res_per_second | $0.08-0.15/s | 2-3/s | image + audio |
| Wan 2.2 Speech Turbo | res_per_second | $0.10-0.20/s | 2-4/s | image + audio |
| Veed Avatars | per_minute | $0.30/min | 6/min | image + audio |
| Kling Avatar Standard | per_second | $0.056/s | 2/s | avatar_id + audio |
| Kling Avatar Pro | per_second | $0.115/s | 3/s | avatar_id + audio |
| Kling Lipsync | per_second | $0.25/s | 5/s | audio only |

### Audio / TTS Models

| Model | Billing | Price | ~Credits |
|-------|---------|-------|----------|
| Chatterbox TTS | per_second | $0.025/s | 1/s |
| Chatterbox TTS Turbo | per_second | $0.08/s | 2/s |
| Chatterbox STS | per_second | $0.04/s | 1/s |
| Eleven Labs Speech Turbo | per_second | $0.08/s | 2/s |
| Eleven Labs Multilingual | per_second | $0.06/s | 2/s |
| Eleven Labs Voice Change | per_second | $0.05/s | 1/s |
| Minimax Speech | per_second | $0.02/s | 1/s |
| Qwen 3 TTS 1.7B | per_second | $0.025/s | 1/s |
| Qwen 3 TTS 0.6B | per_second | $0.02/s | 1/s |
| Whisper V3 Pruna | flat | $0.01 | 1 |

### Upscale Models

| Model | Billing | Price | ~Credits |
|-------|---------|-------|----------|
| Topaz Upscale Image | flat | $0.05 | 1 |
| SeedVR Upscale | flat | $0.04 | 1 |
| Clarity Crystal Upscaler | flat | $0.04 | 1 |
| Crystal Upscale | flat | $0.03 | 1 |
| Bytedance Upscaler Video | per_second | $0.10/s | 2/s |

### Background Removal Models

| Model | Billing | Price | ~Credits |
|-------|---------|-------|----------|
| BRIO Video Background Removal | per_second | $0.08/s | 2/s |
| Veed Video Background Removal | per_second | $0.10/s | 2/s |
| Veed Video Background Removal Fast | per_second | $0.12/s | 3/s |
| Veed Video BG Removal Green Screen | per_second | $0.10/s | 2/s |
