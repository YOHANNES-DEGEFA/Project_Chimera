# Skill: Download Trends
*Fetches real-time trending topics from social platforms via MCP Resources*

## Purpose
Retrieves trending topics and cultural signals from external data sources (Twitter/X, TikTok, Instagram) to inform campaign planning and content generation. This skill enables Planner Agents to adapt campaigns to real-time cultural shifts.

## Input Contract
```json
{
  "skill_id": "skill_download_trends",
  "version": "1.0.0",
  "input_schema": {
    "type": "object",
    "required": ["platform", "region", "max_results"],
    "properties": {
      "platform": {
        "type": "string",
        "enum": ["twitter", "tiktok", "instagram"],
        "description": "Source platform for trending data"
      },
      "region": {
        "type": "string",
        "pattern": "^[A-Z]{2}$",
        "description": "ISO 3166-1 alpha-2 country code (e.g., 'ET' for Ethiopia)"
      },
      "max_results": {
        "type": "integer",
        "minimum": 1,
        "maximum": 50,
        "default": 10,
        "description": "Maximum number of trending topics to return"
      },
      "language": {
        "type": "string",
        "optional": true,
        "description": "Filter by language code (e.g., 'am' for Amharic). If omitted, returns all languages for region."
      },
      "category": {
        "type": "string",
        "enum": ["entertainment", "fashion", "food", "technology", "all"],
        "default": "all",
        "description": "Category filter for trending topics"
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
    "required": ["trends", "metadata", "state_version"],
    "properties": {
      "trends": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["term", "volume", "relevance_score", "platform", "timestamp"],
          "properties": {
            "term": {
              "type": "string",
              "description": "Trending topic or hashtag"
            },
            "volume": {
              "type": "integer",
              "description": "Number of mentions/engagements in last 24 hours"
            },
            "relevance_score": {
              "type": "number",
              "minimum": 0.0,
              "maximum": 1.0,
              "description": "Computed relevance to target audience (0.0 = irrelevant, 1.0 = highly relevant)"
            },
            "platform": {
              "type": "string",
              "enum": ["twitter", "tiktok", "instagram"]
            },
            "timestamp": {
              "type": "string",
              "format": "iso8601",
              "description": "When this trend was captured"
            },
            "category": {
              "type": "string",
              "optional": true,
              "description": "Detected category (entertainment, fashion, etc.)"
            }
          }
        }
      },
      "metadata": {
        "type": "object",
        "required": ["source_mcp_resource", "fetch_timestamp", "region"],
        "properties": {
          "source_mcp_resource": {
            "type": "string",
            "format": "uri",
            "description": "MCP Resource URI used (e.g., 'mcp://twitter/trends/ethiopia')"
          },
          "fetch_timestamp": {
            "type": "string",
            "format": "iso8601"
          },
          "region": {
            "type": "string"
          },
          "total_results": {
            "type": "integer",
            "description": "Total trends available (may exceed max_results)"
          }
        }
      },
      "state_version": {
        "type": "string",
        "description": "GlobalState version at fetch time (for OCC validation)"
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
      "code": "MCP_RESOURCE_UNAVAILABLE",
      "message": "MCP Resource {resource_uri} is unavailable or rate-limited",
      "recovery": "Retry with exponential backoff (max 3 attempts)"
    },
    {
      "code": "INVALID_REGION",
      "message": "Region code {region} is not supported or invalid ISO 3166-1 alpha-2 format",
      "recovery": "Validate region code against supported list"
    },
    {
      "code": "PLATFORM_NOT_SUPPORTED",
      "message": "Platform {platform} does not have MCP Resource configured",
      "recovery": "Check .mcp/config.json for available platforms"
    },
    {
      "code": "RATE_LIMIT_EXCEEDED",
      "message": "MCP Server rate limit exceeded (100 requests/minute per agent DID)",
      "recovery": "Wait for rate limit window to reset, then retry"
    }
  ]
}
```

## Dependencies
- **MCP Resources**: 
  - `mcp://twitter/trends/{region}` (if platform=twitter)
  - `mcp://tiktok/trends/{region}` (if platform=tiktok)
  - `mcp://instagram/trends/{region}` (if platform=instagram)
- **External Services**: None (all data via MCP Resources)
- **Database**: None (stateless skill, results passed to caller)

## Usage Example
```python
# Pseudo-code usage pattern
result = skill_download_trends.execute({
    "platform": "twitter",
    "region": "ET",
    "max_results": 20,
    "category": "fashion"
})

# Result contains:
# - trends: Array of trending topics with relevance scores
# - metadata: Source information and fetch timestamp
# - state_version: For OCC validation in downstream processing
```

## Implementation Notes
- **Stateless**: This skill does not maintain persistent state. All data is fetched fresh on each invocation.
- **MCP Integrity**: ALL trend data MUST be fetched via MCP Resources. Never make direct API calls to Twitter/TikTok/Instagram APIs.
- **Relevance Scoring**: The `relevance_score` is computed by a lightweight ML model (fine-tuned BERT) that considers:
  - Cultural context (Ethiopian-specific terms get higher scores)
  - Historical engagement patterns
  - Category alignment with campaign goals
- **Caching**: Results may be cached in Redis for 5 minutes to reduce MCP Resource load, but cache key must include region+platform+category to ensure freshness.

## Traceability
- **SRS Reference**: Addresses SRS §3.1 (Planner Agent real-time adaptation)
- **Functional Spec**: Implements FR-P2 (Real-Time Re-Planning)
- **Technical Spec**: Uses MCP Resources per specs/technical.md §1.1
