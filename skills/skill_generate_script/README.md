# Skill: Generate Script
*Generates culturally authentic short-form video scripts with platform-specific optimization*

## Purpose
Produces platform-native scripts for TikTok/Reels/Shorts with cultural authenticity for Ethiopian audiences, including Amharic slang and local references.

## Input Contract
```json
{
  "skill_id": "skill_generate_script",
  "version": "1.2.0",
  "input_schema": {
    "type": "object",
    "required": ["topic", "platform", "language", "campaign_id"],
    "properties": {
      "topic": {
        "type": "string",
        "description": "Content theme (e.g., 'Addis Ababa street fashion')",
        "minLength": 5,
        "maxLength": 200
      },
      "platform": {
        "type": "string",
        "enum": ["tiktok", "instagram_reels", "youtube_shorts"],
        "description": "Target platform for script optimization"
      },
      "language": {
        "type": "string",
        "description": "Target language with dialect specification",
        "examples": ["amharic_slang", "english_ethiopian_accent"]
      },
      "campaign_id": {
        "type": "string",
        "pattern": "^[a-z0-9_]+$",
        "description": "Campaign identifier for persona consistency"
      },
      "character_reference_id": {
        "type": "string",
        "format": "uri",
        "optional": true,
        "description": "Optional character anchor for persona alignment"
      },
      "trending_topic": {
        "type": "string",
        "optional": true,
        "description": "Current trending topic to incorporate (from MCP Resource)"
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
    "required": ["script_text", "confidence", "platform_optimization", "cultural_authenticity_score"],
    "properties": {
      "script_text": {
        "type": "string",
        "minLength": 50,
        "maxLength": 500,
        "description": "Final script text ready for voiceover"
      },
      "confidence": {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Confidence score for script quality"
      },
      "platform_optimization": {
        "type": "object",
        "properties": {
          "hook_quality": {"type": "number", "minimum": 0.0, "maximum": 1.0},
          "pacing": {"type": "string", "enum": ["fast", "medium", "slow"]},
          "caption_length": {"type": "integer", "minimum": 10, "maximum": 100}
        }
      },
      "cultural_authenticity_score": {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Score for Ethiopian cultural relevance (validated against SOUL.md)"
      },
      "state_version": {
        "type": "string",
        "description": "GlobalState version at generation time (for OCC)"
      }
    }
  }
}
```

## Error Cases
| Error Code | Condition | Recovery Action |
|------------|-----------|-----------------|
| `MISSING_REQUIRED_PARAM` | Any required field absent | Return error; do not attempt generation |
| `LOW_CULTURAL_AUTHENTICITY` | cultural_authenticity_score < 0.7 | Auto-reject; trigger Planner retry with refined cultural context |
| `PLATFORM_MISMATCH` | Script violates platform TOS (e.g., TikTok >60s) | Auto-reject; trigger Planner retry with platform constraints |

## Dependencies
- MCP Resource: `mcp://twitter/trends/ethiopia` (for trending_topic injection)
- MCP Tool: `validate_cultural_authenticity` (external validation service)
- Memory: Weaviate persona vector for campaign_id
