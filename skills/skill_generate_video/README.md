# Skill: Generate Video
*Assembles script, images, and audio into final short-form video asset*

## Purpose
Orchestrates the video assembly pipeline: combines generated script, visual assets (images), and audio (text-to-speech) into a complete short-form video ready for distribution. This skill coordinates multiple MCP Tools and validates character consistency across all assets.

## Input Contract
```json
{
  "skill_id": "skill_generate_video",
  "version": "1.0.0",
  "input_schema": {
    "type": "object",
    "required": ["script_id", "image_ids", "platform", "character_reference_id"],
    "properties": {
      "script_id": {
        "type": "string",
        "format": "uuid",
        "description": "UUID of generated script (from skill_generate_script or MCP generate_script tool)"
      },
      "image_ids": {
        "type": "array",
        "items": {
          "type": "string",
          "format": "uuid"
        },
        "minItems": 1,
        "maxItems": 10,
        "description": "Array of image UUIDs to include in video (ordered sequence)"
      },
      "platform": {
        "type": "string",
        "enum": ["tiktok", "instagram_reels", "youtube_shorts"],
        "description": "Target platform (determines video dimensions and duration limits)"
      },
      "character_reference_id": {
        "type": "string",
        "format": "uri",
        "pattern": "^chimera://characters/[a-z0-9_]+/[a-z0-9_]+$",
        "description": "Character reference for consistency validation (REQUIRED per FR 3.1)"
      },
      "language": {
        "type": "string",
        "optional": true,
        "description": "Language code for text-to-speech (e.g., 'am' for Amharic). If omitted, inferred from script metadata."
      },
      "duration_seconds": {
        "type": "integer",
        "minimum": 5,
        "maximum": 60,
        "default": 30,
        "description": "Target video duration in seconds (platform-specific limits apply)"
      },
      "background_music": {
        "type": "boolean",
        "default": true,
        "description": "Whether to add background music (royalty-free, culturally appropriate)"
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
    "required": ["video_artifact", "metadata", "confidence_score", "state_version"],
    "properties": {
      "video_artifact": {
        "type": "object",
        "required": ["video_url", "content_hash", "duration_seconds", "file_size_bytes"],
        "properties": {
          "video_url": {
            "type": "string",
            "format": "uri",
            "description": "Signed S3 URL for video file (expires in 24 hours)"
          },
          "content_hash": {
            "type": "string",
            "pattern": "^[a-f0-9]{64}$",
            "description": "SHA-256 hash of video file (for integrity verification and deduplication)"
          },
          "duration_seconds": {
            "type": "integer",
            "description": "Actual video duration"
          },
          "file_size_bytes": {
            "type": "integer",
            "description": "Video file size in bytes"
          },
          "thumbnail_url": {
            "type": "string",
            "format": "uri",
            "optional": true,
            "description": "Generated thumbnail for preview"
          }
        }
      },
      "metadata": {
        "type": "object",
        "required": ["platform", "character_reference_id", "assembly_timestamp", "mcp_tool_calls"],
        "properties": {
          "platform": {
            "type": "string",
            "enum": ["tiktok", "instagram_reels", "youtube_shorts"]
          },
          "character_reference_id": {
            "type": "string",
            "format": "uri"
          },
          "assembly_timestamp": {
            "type": "string",
            "format": "iso8601"
          },
          "mcp_tool_calls": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "tool_name": {"type": "string"},
                "parameters": {"type": "object"},
                "result_status": {"type": "string", "enum": ["success", "failed"]}
              }
            },
            "description": "Audit trail of all MCP Tool calls made during assembly"
          }
        }
      },
      "confidence_score": {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Overall confidence score for video quality (composite of script, image, audio confidence)"
      },
      "character_consistency_score": {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Validated character consistency across all images (must be >= 0.85 per FR 3.1)"
      },
      "state_version": {
        "type": "string",
        "description": "GlobalState version at generation time"
      }
    }
  }
}
```

## Error Cases
```json
{
  "error_codes": [
    {
      "code": "MISSING_CHARACTER_REFERENCE",
      "message": "character_reference_id is REQUIRED per FR 3.1. Cannot generate video without character consistency anchor.",
      "recovery": "Provide valid character_reference_id in format: chimera://characters/{namespace}/{id}"
    },
    {
      "code": "CHARACTER_DRIFT_DETECTED",
      "message": "Character consistency validation failed: score {actual_score} < threshold 0.85. Images deviate from character_reference_id.",
      "recovery": "Regenerate images with correct character_reference_id, then retry video assembly"
    },
    {
      "code": "SCRIPT_NOT_FOUND",
      "message": "Script with script_id {script_id} not found in database or cache",
      "recovery": "Verify script_id exists and is accessible to current agent"
    },
    {
      "code": "IMAGE_NOT_FOUND",
      "message": "One or more image_ids {image_ids} not found in database",
      "recovery": "Verify all image_ids exist and are accessible"
    },
    {
      "code": "PLATFORM_DURATION_EXCEEDED",
      "message": "Requested duration_seconds {duration} exceeds platform limit: TikTok=60s, Instagram=90s, YouTube=60s",
      "recovery": "Reduce duration_seconds to within platform limits"
    },
    {
      "code": "MCP_TOOL_FAILED",
      "message": "MCP Tool {tool_name} failed during video assembly: {error_message}",
      "recovery": "Check MCP Server logs, verify API keys, retry with exponential backoff"
    },
    {
      "code": "VIDEO_ASSEMBLY_TIMEOUT",
      "message": "Video assembly exceeded timeout (300 seconds)",
      "recovery": "Retry with fewer images or shorter duration, or escalate to human review"
    }
  ]
}
```

## Dependencies
- **MCP Tools**:
  - `generate_script` (if script not provided, generates on-the-fly)
  - `generate_image` (validates character consistency)
  - `text_to_speech` (converts script to audio)
  - `assemble_video` (combines assets into final video)
- **External Services**: 
  - S3 bucket for video storage (via MCP Tool)
  - Video processing service (FFmpeg-based, via MCP Tool)
- **Database**: 
  - PostgreSQL: Read script and image metadata
  - Cassandra: Write video_metadata record after assembly

## Usage Example
```python
# Pseudo-code usage pattern
result = skill_generate_video.execute({
    "script_id": "uuid-script-123",
    "image_ids": ["uuid-image-001", "uuid-image-002"],
    "platform": "tiktok",
    "character_reference_id": "chimera://characters/fashion_influencer/main",
    "duration_seconds": 30,
    "language": "am"
})

# Result contains:
# - video_artifact: S3 URL, content_hash, metadata
# - confidence_score: Composite quality score
# - character_consistency_score: Validated >= 0.85
# - state_version: For OCC validation
```

## Implementation Notes
- **Character Consistency Validation**: Before assembly, this skill validates that all images have `character_consistency_score >= 0.85`. If any image fails, the skill rejects with `CHARACTER_DRIFT_DETECTED` error.
- **MCP Integrity**: ALL video assembly operations (text-to-speech, asset combination, upload) MUST route through MCP Tools. No direct API calls to video processing services.
- **Platform-Specific Constraints**:
  - TikTok: Max 60s, 1080x1920 (9:16), MP4 format
  - Instagram Reels: Max 90s, 1080x1920 (9:16), MP4 format
  - YouTube Shorts: Max 60s, 1080x1920 (9:16), MP4 format
- **Confidence Score Calculation**: Composite of:
  - Script confidence (from MCP generate_script): 40% weight
  - Image confidence (from MCP generate_image): 30% weight
  - Character consistency score: 20% weight
  - Audio quality (TTS confidence): 10% weight
- **State Management**: Skill reads `state_version` at start, validates it matches GlobalState before committing video_metadata to Cassandra.

## Traceability
- **SRS Reference**: Addresses SRS §3.1 (Worker Agent task execution)
- **Functional Spec**: Implements FR-W1 (Atomic Task Execution) and FR-W2 (Character Consistency Enforcement)
- **Technical Spec**: Uses MCP Tools per specs/technical.md §1.1, validates character consistency per FR 3.1
