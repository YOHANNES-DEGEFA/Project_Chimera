# Skill: Download YouTube
*Fetches video assets from YouTube for content remixing and trend analysis*

## Purpose
Downloads video content from YouTube URLs for trend analysis, remixing, and cultural reference extraction. This skill enables the Chimera agent to ingest existing content for inspiration while maintaining attribution and copyright compliance.

## Input Contract
```json
{
  "skill_id": "skill_download_youtube",
  "version": "1.0.0",
  "input_schema": {
    "type": "object",
    "required": ["youtube_url", "output_format", "agent_did"],
    "properties": {
      "youtube_url": {
        "type": "string",
        "format": "uri",
        "pattern": "^(https?://)?(www\\.)?(youtube\\.com|youtu\\.be)/.*",
        "description": "Full YouTube URL (supports youtu.be and youtube.com formats)"
      },
      "output_format": {
        "type": "string",
        "enum": ["mp4", "webm", "audio_only"],
        "description": "Desired output format for downloaded content"
      },
      "agent_did": {
        "type": "string",
        "format": "uri",
        "description": "Decentralized identifier of the requesting agent (for attribution tracking)"
      },
      "max_duration_seconds": {
        "type": "integer",
        "minimum": 1,
        "maximum": 300,
        "default": 60,
        "description": "Maximum video duration to download (enforced for short-form content focus)"
      },
      "quality": {
        "type": "string",
        "enum": ["low", "medium", "high"],
        "default": "medium",
        "description": "Video quality preference (affects download size and processing time)"
      },
      "extract_metadata": {
        "type": "boolean",
        "default": true,
        "description": "Whether to extract title, description, tags, and engagement metrics"
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
    "required": ["download_status", "file_path", "content_hash", "metadata"],
    "properties": {
      "download_status": {
        "type": "string",
        "enum": ["success", "partial", "failed"],
        "description": "Download completion status"
      },
      "file_path": {
        "type": "string",
        "format": "uri",
        "description": "Local filesystem path to downloaded file (within /tmp/chimera/{agent_id}/)"
      },
      "content_hash": {
        "type": "string",
        "pattern": "^[a-f0-9]{64}$",
        "description": "SHA-256 hash of downloaded content for deduplication"
      },
      "metadata": {
        "type": "object",
        "properties": {
          "title": {"type": "string"},
          "description": {"type": "string"},
          "duration_seconds": {"type": "integer"},
          "view_count": {"type": "integer"},
          "like_count": {"type": "integer"},
          "upload_date": {"type": "string", "format": "date"},
          "channel_id": {"type": "string"},
          "tags": {
            "type": "array",
            "items": {"type": "string"}
          }
        }
      },
      "attribution": {
        "type": "object",
        "required": ["source_url", "channel_name", "license_type"],
        "properties": {
          "source_url": {"type": "string", "format": "uri"},
          "channel_name": {"type": "string"},
          "license_type": {
            "type": "string",
            "enum": ["standard_youtube", "creative_commons", "unknown"]
          }
        }
      },
      "confidence": {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Confidence in successful download and metadata extraction"
      },
      "state_version": {
        "type": "string",
        "description": "GlobalState version at execution time (for OCC validation)"
      }
    }
  },
  "errors": [
    {
      "code": "INVALID_URL",
      "message": "YouTube URL format invalid or unsupported"
    },
    {
      "code": "DOWNLOAD_FAILED",
      "message": "Network error or video unavailable (private/deleted/region-locked)"
    },
    {
      "code": "DURATION_EXCEEDED",
      "message": "Video duration exceeds max_duration_seconds limit"
    },
    {
      "code": "COPYRIGHT_RESTRICTED",
      "message": "Video has download restrictions (copyright protection)"
    },
    {
      "code": "STORAGE_QUOTA_EXCEEDED",
      "message": "Agent storage quota exceeded (filesystem limit enforced)"
    }
  ]
}
```

## MCP Integration
This skill MUST be invoked via MCP Tool `download_youtube` (not direct API calls). The MCP server handles:
- YouTube API authentication (via secrets manager)
- Rate limiting (100 requests/minute per agent DID)
- Temporary file management in `/tmp/chimera/{agent_id}/`
- Automatic cleanup after 24 hours

## Usage Example
```json
{
  "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "output_format": "mp4",
  "agent_did": "did:chimera:agent:worker-tiktok-9b4d",
  "max_duration_seconds": 60,
  "quality": "medium",
  "extract_metadata": true
}
```

## SRS References
- **FR-W1**: Atomic task execution via MCP (no direct API calls)
- **NFR 2.0**: Attribution tracking for copyright compliance
- **Security §4.5**: Filesystem access limited to `/tmp/chimera/{agent_id}/`
