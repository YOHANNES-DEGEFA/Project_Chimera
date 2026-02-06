# Skill: Transcribe Audio
*Converts audio/video speech to text with multi-language and dialect support*

## Purpose
Extracts spoken content from audio/video files for script analysis, trend detection, and cultural context extraction. Supports Ethiopian languages (Amharic, Oromo, Tigrinya) with slang/dialect recognition for authentic content generation.

## Input Contract
```json
{
  "skill_id": "skill_transcribe_audio",
  "version": "1.0.0",
  "input_schema": {
    "type": "object",
    "required": ["audio_source", "target_language", "agent_did"],
    "properties": {
      "audio_source": {
        "type": "string",
        "format": "uri",
        "description": "Path to audio/video file (local filesystem URI: file:///tmp/chimera/{agent_id}/...) or YouTube URL"
      },
      "target_language": {
        "type": "string",
        "enum": ["amharic", "oromo", "tigrinya", "english", "amharic_slang", "auto_detect"],
        "description": "Target language for transcription (auto_detect uses language identification model)"
      },
      "agent_did": {
        "type": "string",
        "format": "uri",
        "description": "Decentralized identifier of the requesting agent"
      },
      "include_timestamps": {
        "type": "boolean",
        "default": true,
        "description": "Whether to include word-level timestamps for video editing alignment"
      },
      "speaker_diarization": {
        "type": "boolean",
        "default": false,
        "description": "Whether to identify and separate multiple speakers (useful for interview content)"
      },
      "confidence_threshold": {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "default": 0.7,
        "description": "Minimum confidence score for word inclusion (lower = more words but potentially less accurate)"
      },
      "extract_sentiment": {
        "type": "boolean",
        "default": false,
        "description": "Whether to perform sentiment analysis on transcribed text"
      },
      "extract_keywords": {
        "type": "boolean",
        "default": true,
        "description": "Whether to extract trending keywords and cultural references"
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
    "required": ["transcription_status", "transcript_text", "confidence", "language_detected"],
    "properties": {
      "transcription_status": {
        "type": "string",
        "enum": ["success", "partial", "failed"],
        "description": "Transcription completion status"
      },
      "transcript_text": {
        "type": "string",
        "description": "Full transcribed text (UTF-8 encoded, supports Amharic script)"
      },
      "confidence": {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Overall confidence score for transcription accuracy"
      },
      "language_detected": {
        "type": "string",
        "description": "Detected language (if auto_detect was used)"
      },
      "word_timestamps": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["word", "start_time", "end_time", "confidence"],
          "properties": {
            "word": {"type": "string"},
            "start_time": {"type": "number", "description": "Start time in seconds"},
            "end_time": {"type": "number", "description": "End time in seconds"},
            "confidence": {"type": "number", "minimum": 0.0, "maximum": 1.0}
          }
        },
        "description": "Word-level timestamps (only if include_timestamps=true)"
      },
      "speakers": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "speaker_id": {"type": "string"},
            "segments": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "text": {"type": "string"},
                  "start_time": {"type": "number"},
                  "end_time": {"type": "number"}
                }
              }
            }
          }
        },
        "description": "Speaker-separated segments (only if speaker_diarization=true)"
      },
      "sentiment": {
        "type": "object",
        "properties": {
          "overall": {
            "type": "string",
            "enum": ["positive", "neutral", "negative"]
          },
          "score": {
            "type": "number",
            "minimum": -1.0,
            "maximum": 1.0
          }
        },
        "description": "Sentiment analysis result (only if extract_sentiment=true)"
      },
      "keywords": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "keyword": {"type": "string"},
            "relevance_score": {"type": "number", "minimum": 0.0, "maximum": 1.0},
            "category": {
              "type": "string",
              "enum": ["trending", "cultural_reference", "slang", "location", "other"]
            }
          }
        },
        "description": "Extracted keywords with relevance scores (only if extract_keywords=true)"
      },
      "processing_time_seconds": {
        "type": "number",
        "description": "Time taken to process audio file"
      },
      "state_version": {
        "type": "string",
        "description": "GlobalState version at execution time (for OCC validation)"
      }
    }
  },
  "errors": [
    {
      "code": "FILE_NOT_FOUND",
      "message": "Audio source file not found at specified path"
    },
    {
      "code": "UNSUPPORTED_FORMAT",
      "message": "Audio format not supported (supported: mp3, wav, mp4, webm)"
    },
    {
      "code": "LANGUAGE_NOT_SUPPORTED",
      "message": "Target language not supported by transcription model"
    },
    {
      "code": "AUDIO_TOO_LONG",
      "message": "Audio duration exceeds processing limit (max 300 seconds)"
    },
    {
      "code": "LOW_AUDIO_QUALITY",
      "message": "Audio quality too low for accurate transcription (confidence < 0.5)"
    },
    {
      "code": "MCP_TOOL_ERROR",
      "message": "MCP transcription service unavailable or rate-limited"
    }
  ]
}
```

## MCP Integration
This skill MUST be invoked via MCP Tool `transcribe_audio` (not direct API calls). The MCP server handles:
- Whisper/OpenAI API authentication (via secrets manager)
- Multi-language model selection (Whisper-large-v3 for Amharic, custom fine-tuned for slang)
- Rate limiting (50 requests/minute per agent DID due to compute-intensive nature)
- Automatic cleanup of temporary audio files after processing

## Usage Example
```json
{
  "audio_source": "file:///tmp/chimera/agent-9b4d/video_abc123.mp4",
  "target_language": "amharic_slang",
  "agent_did": "did:chimera:agent:worker-tiktok-9b4d",
  "include_timestamps": true,
  "speaker_diarization": false,
  "confidence_threshold": 0.7,
  "extract_keywords": true
}
```

## SRS References
- **FR-W1**: Atomic task execution via MCP (no direct API calls)
- **FR-P2**: Dynamic re-planning using transcribed trend keywords
- **NFR 1.1**: Cultural authenticity via dialect recognition (Amharic slang support)
- **Security §4.5**: Filesystem access limited to `/tmp/chimera/{agent_id}/`
