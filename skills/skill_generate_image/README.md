# Skill: Generate Image
*Generates culturally authentic visual assets with strict character consistency enforcement*

## Purpose
Produces platform-native visual assets for short-form video with guaranteed character consistency against reference ID—critical for brand safety and persona integrity per FR 3.1.

## Input Contract
```json
{
  "skill_id": "skill_generate_image",
  "version": "2.1.0",
  "input_schema": {
    "type": "object",
    "required": ["prompt", "character_reference_id", "campaign_id", "platform"],
    "properties": {
      "prompt": {
        "type": "string",
        "description": "Visual description in target language",
        "minLength": 10,
        "maxLength": 500
      },
      "character_reference_id": {
        "type": "string",
        "format": "uri",
        "pattern": "^chimera://characters/[a-z0-9_]+/[a-z0-9_]+$",
        "description": "MANDATORY character consistency anchor per FR 3.1",
        "examples": ["chimera://characters/fashion_summer_2026/aida_ethiopian_model"]
      },
      "campaign_id": {
        "type": "string",
        "pattern": "^[a-z0-9_]+$"
      },
      "platform": {
        "type": "string",
        "enum": ["tiktok", "instagram_reels", "youtube_shorts"]
      },
      "style_reference_id": {
        "type": "string",
        "format": "uri",
        "optional": true,
        "description": "Optional style LoRA identifier"
      },
      "negative_prompt": {
        "type": "string",
        "optional": true,
        "description": "Elements to exclude from generation"
      }
    }
  }
}
```

## Output Contract
```json
{
  "output_schema": {
    "type": "object",
    "required": ["image_url", "confidence", "character_consistency_score", "state_version"],
    "properties": {
      "image_url": {
        "type": "string",
        "format": "uri",
        "description": "HTTPS URL to generated image asset"
      },
      "confidence": {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0
      },
      "character_consistency_score": {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Vision model validation score against reference ID"
      },
      "style_consistency_score": {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "optional": true
      },
      "state_version": {
        "type": "string"
      }
    }
  }
}
```

## Error Cases (Strict Enforcement)
| Error Code | Condition | Recovery Action |
|------------|-----------|-----------------|
| `MISSING_CHARACTER_REFERENCE` | character_reference_id absent | **AUTO-REJECT** with confidence=0.0; log security incident |
| `CHARACTER_DRIFT_DETECTED` | character_consistency_score < 0.85 | **AUTO-REJECT**; trigger Planner retry with refined prompt |
| `PLATFORM_VIOLATION` | Image violates platform policies (e.g., TikTok nudity filters) | **AUTO-REJECT**; escalate to HITL for policy clarification |

## Dependencies
- Vision model service: Validates character_consistency_score against reference ID
- Ideogram API: Primary image generation backend
- Weaviate: Retrieves character reference embeddings
- MCP Tool: `validate_platform_compliance` (pre-submission check)
