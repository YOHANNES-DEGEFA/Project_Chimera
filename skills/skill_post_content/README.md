
# Skill: Post Content
*Publishes AI-generated content to social platforms with mandatory disclosure and HITL enforcement*

## Purpose
Executes final distribution of approved content to TikTok/Instagram/YouTube with EU AI Act-compliant disclosure flags and cryptographic approval validation.

## Input Contract
```json
{
  "skill_id": "skill_post_content",
  "version": "1.3.0",
  "input_schema": {
    "type": "object",
    "required": ["platform", "content_hash", "disclosure_level", "approval_token", "agent_provenance"],
    "properties": {
      "platform": {
        "type": "string",
        "enum": ["tiktok", "instagram_reels", "youtube_shorts"],
        "description": "Target platform for distribution"
      },
      "content_hash": {
        "type": "string",
        "pattern": "^[a-f0-9]{64}$",
        "description": "SHA-256 hash of final video asset"
      },
      "disclosure_level": {
        "type": "string",
        "enum": ["platform_native", "caption_watermark"],
        "description": "EU AI Act compliance mode per NFR 2.0"
      },
      "approval_token": {
        "type": "string",
        "pattern": "^[a-zA-Z0-9_-]{128}$",
        "description": "Cryptographic token from HITL service (expires in 300s)"
      },
      "agent_provenance": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["agent_did", "contribution_type"],
          "properties": {
            "agent_did": {"type": "string", "format": "uri"},
            "contribution_type": {"type": "string", "enum": ["script", "visual", "edit"]}
          }
        },
        "minItems": 1,
        "description": "DID-signed contribution chain for attribution"
      },
      "sensitive_topic_detected": {
        "type": "boolean",
        "description": "Flag indicating politics/health/finance content per NFR 1.2"
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
    "required": ["platform_url", "disclosure_applied", "transaction_hash"],
    "properties": {
      "platform_url": {
        "type": "string",
        "format": "uri",
        "description": "Public URL to published content"
      },
      "disclosure_applied": {
        "type": "boolean",
        "description": "Confirmation that AI disclosure flag was applied"
      },
      "transaction_hash": {
        "type": "string",
        "description": "On-chain transaction hash for reputation recording"
      },
      "engagement_metrics": {
        "type": "object",
        "optional": true,
        "properties": {
          "initial_views": {"type": "integer"},
          "shares": {"type": "integer"}
        }
      }
    }
  }
}
```

## Error Cases (Security-Critical)
| Error Code | Condition | Recovery Action |
|------------|-----------|-----------------|
| `MISSING_APPROVAL_TOKEN` | approval_token absent | **BLOCK EXECUTION**; log security incident; alert Super-Orchestrator |
| `TOKEN_EXPIRED` | approval_token >300s old | **BLOCK EXECUTION**; return 401 to agent |
| `SENSITIVE_TOPIC_NO_REVIEW` | sensitive_topic_detected=true AND no HITL approval | **BLOCK EXECUTION**; escalate to HITL queue |
| `DISCLOSURE_NOT_APPLIED` | platform rejected content due to missing disclosure | **ROLLBACK**; retry with higher disclosure_level |

## Dependencies
- MCP Tool: `validate_approval_token` (cryptographic validation)
- MCP Resource: `mcp://wallet/balance/{agent_id}` (for transaction fees)
- Coinbase AgentKit: Executes on-chain reputation recording
- Platform SDKs: TikTok/Instagram/YouTube official APIs via MCP Servers