# Project Chimera: Technical Specification
*API Contracts, Data Architecture & Security Boundaries | Version 1.0*

## 1. MCP Primitive Contracts

### 1.1 MCP Tools Schema (`mcp_schema.json`)
```json
{
  "tools": {
    "generate_script": {
      "description": "Generate culturally authentic script for short-form video",
      "parameters": {
        "type": "object",
        "required": ["topic", "platform", "language"],
        "properties": {
          "topic": {"type": "string", "description": "Content theme (e.g., 'Addis Ababa street fashion')"},
          "platform": {"type": "string", "enum": ["tiktok", "instagram_reels", "youtube_shorts"]},
          "language": {"type": "string", "description": "Target language with dialect (e.g., 'amharic_slang')"},
          "character_reference_id": {"type": "string", "format": "uri", "description": "Optional character consistency anchor"}
        }
      },
      "returns": {
        "type": "object",
        "required": ["script_text", "confidence", "state_version"],
        "properties": {
          "script_text": {"type": "string"},
          "confidence": {"type": "number", "minimum": 0.0, "maximum": 1.0},
          "state_version": {"type": "string", "description": "GlobalState version at generation time"}
        }
      },
      "errors": [
        {"code": "MISSING_REQUIRED_PARAM", "message": "Missing required parameter: {param_name}"},
        {"code": "MISSING_CHARACTER_REFERENCE", "message": "character_reference_id required for image generation per FR 3.1"}
      ]
    },
    "generate_image": {
      "description": "Generate culturally authentic visual asset with character consistency",
      "parameters": {
        "type": "object",
        "required": ["prompt", "character_reference_id"],
        "properties": {
          "prompt": {"type": "string", "description": "Visual description in target language"},
          "character_reference_id": {"type": "string", "format": "uri", "pattern": "^chimera://characters/[a-z0-9_]+/[a-z0-9_]+$"},
          "style_reference_id": {"type": "string", "format": "uri", "optional": true}
        }
      },
      "returns": {
        "type": "object",
        "required": ["image_url", "confidence", "state_version"],
        "properties": {
          "image_url": {"type": "string", "format": "uri"},
          "confidence": {"type": "number", "minimum": 0.0, "maximum": 1.0},
          "character_consistency_score": {"type": "number", "minimum": 0.0, "maximum": 1.0},
          "state_version": {"type": "string"}
        }
      },
      "errors": [
        {"code": "MISSING_CHARACTER_REFERENCE", "message": "character_reference_id is REQUIRED per FR 3.1"},
        {"code": "CHARACTER_DRIFT_DETECTED", "message": "Generated image deviates from reference (score: {actual_score} < threshold 0.85)"}
      ]
    },
    "post_content": {
      "description": "Publish content to social platform with mandatory disclosure",
      "parameters": {
        "type": "object",
        "required": ["platform", "content_hash", "disclosure_level", "approval_token"],
        "properties": {
          "platform": {"type": "string", "enum": ["tiktok", "instagram_reels", "youtube_shorts"]},
          "content_hash": {"type": "string", "description": "SHA-256 of final video asset"},
          "disclosure_level": {"type": "string", "enum": ["platform_native", "caption_watermark"], "description": "EU AI Act compliance mode"},
          "approval_token": {"type": "string", "description": "Cryptographic token from HITL service (expires in 300s)"}
        }
      },
      "security": {
        "requires_approval_token": true,
        "token_expiry_seconds": 300,
        "rate_limit": "100 requests per minute per agent DID"
      },
      "errors": [
        {"code": "MISSING_APPROVAL_TOKEN", "message": "HITL approval token required for content distribution"},
        {"code": "TOKEN_EXPIRED", "message": "Approval token expired (valid 300s)"},
        {"code": "SENSITIVE_TOPIC_DETECTED", "message": "Content contains politics/health/finance—requires human review per NFR 1.2"}
      ]
    }
  },
  "resources": {
    "trends_ethiopia": {
      "uri": "mcp://twitter/trends/ethiopia",
      "description": "Real-time trending topics in Ethiopia",
      "update_frequency": "300 seconds",
      "schema": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["term", "volume", "relevance_score"],
          "properties": {
            "term": {"type": "string"},
            "volume": {"type": "integer"},
            "relevance_score": {"type": "number", "minimum": 0.0, "maximum": 1.0}
          }
        }
      }
    }
  }
}

## 2. Database Architecture

### 2.1 Hybrid Schema Design Philosophy
Chimera employs a purpose-built hybrid architecture optimized for distinct workload patterns. **No single database technology suffices** for high-velocity metadata, transactional integrity, semantic search, and swarm coordination.

| Data Domain | Technology | Rationale | Write Throughput Target |
|-------------|------------|-----------|-------------------------|
| **Video Metadata** | Apache Cassandra | Schema-less design for evolving metadata; time-series partitioning; linear scalability during viral events | 15,000 writes/sec |
| **Transactional Data** | PostgreSQL | ACID compliance for wallet transactions; row-level security for multi-tenancy | 5,000 writes/sec |
| **Semantic Memory** | Weaviate | Vector search for persona consistency; hybrid keyword+semantic retrieval | 1,000 writes/sec |
| **Task Queue** | Redis | Sub-millisecond latency for swarm coordination; atomic OCC validation | 50,000 ops/sec |

### 2.2 Cassandra Schema (Video Metadata) - Executable DDL
```sql
CREATE KEYSPACE IF NOT EXISTS chimera 
WITH replication = {'class': 'NetworkTopologyStrategy', 'datacenter1': 3};

CREATE TABLE chimera.video_metadata (
    agent_id UUID,
    date_bucket TEXT,          -- Format: '2026-02-07' (partition key component)
    timestamp TIMESTAMP,       -- Clustering column
    content_hash TEXT,
    platform TEXT,             -- 'tiktok' | 'instagram_reels' | 'youtube_shorts'
    engagement_rate DECIMAL,   -- 0.0 to 1.0
    frame_tags MAP<TEXT, TEXT>,-- {'scene_001': 'street_fashion_addis', ...}
    agent_annotations MAP<TEXT, TEXT>,
    PRIMARY KEY ((agent_id, date_bucket), timestamp)
) WITH CLUSTERING ORDER BY (timestamp DESC)
  AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': '1',
    'compaction_window_unit': 'DAYS'
  }
  AND gc_grace_seconds = 86400;

Critical Design Notes:
TimeWindowCompactionStrategy: Automatically ages out frame-level tags after 30 days while preserving daily aggregates for analytics
Partition Key (agent_id, date_bucket): Prevents hot partitions during viral events (max 86.4M writes/day/partition at 1k writes/sec)
Schema-less Flexibility: frame_tags accommodates VR spatial audio tags without migration

### 2.3 PostgreSQL Schema (Transactional) - Executable DDL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    super_orchestrator_id UUID NOT NULL,
    goal TEXT NOT NULL CHECK (length(goal) > 10),  -- Prevent vague goals per SRS §2.1
    budget_usd DECIMAL(10,2) NOT NULL CHECK (budget_usd > 0),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE agent_wallets (
    agent_id UUID PRIMARY KEY,
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    address TEXT NOT NULL UNIQUE CHECK (address ~ '^0x[a-fA-F0-9]{40}$'),  -- Base L2 address
    daily_spend_limit_usd DECIMAL(10,2) NOT NULL CHECK (daily_spend_limit_usd > 0),
    daily_spend_usd DECIMAL(10,2) DEFAULT 0.00 CHECK (daily_spend_usd >= 0),
    last_reset_date DATE DEFAULT CURRENT_DATE
);

-- Row-Level Security for Multi-Tenancy (Critical for PaaS Model)
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
CREATE POLICY campaign_isolation ON campaigns
  USING (super_orchestrator_id = current_setting('app.current_user_id')::UUID);

-- Budget Governance Trigger (Enforces FR 5.2)
CREATE OR REPLACE FUNCTION check_budget_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.daily_spend_usd > (SELECT daily_spend_limit_usd FROM agent_wallets WHERE agent_id = NEW.agent_id) THEN
    RAISE EXCEPTION 'Budget exceeded: daily_spend_usd (%) > daily_spend_limit_usd (%)',
      NEW.daily_spend_usd,
      (SELECT daily_spend_limit_usd FROM agent_wallets WHERE agent_id = NEW.agent_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_budget_limit
BEFORE UPDATE ON agent_wallets
FOR EACH ROW EXECUTE FUNCTION check_budget_limit();

CREATE TABLE task_dag_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    planner_agent_did TEXT NOT NULL,
    dag_json JSONB NOT NULL,
    state_version TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'executing', 'completed', 'failed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE hitl_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_hash TEXT NOT NULL,
    agent_id UUID NOT NULL,
    confidence_score DECIMAL(3,2) NOT NULL CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0),
    sensitive_topic_detected BOOLEAN DEFAULT FALSE,
    review_status TEXT NOT NULL CHECK (review_status IN ('pending', 'approved', 'rejected', 'escalated')),
    approval_token TEXT,
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_hitl_pending ON hitl_reviews(review_status, created_at) WHERE review_status = 'pending';
CREATE INDEX idx_task_dag_campaign ON task_dag_executions(campaign_id, created_at);

### 2.4 Weaviate Schema (Semantic Memory) - Executable Schema
```json
{
  "class": "AgentMemory",
  "description": "Long-term persona consistency and engagement embeddings",
  "vectorizer": "text2vec-openai",
  "moduleConfig": {
    "text2vec-openai": {
      "model": "text-embedding-3-large",
      "modelVersion": "latest"
    }
  },
  "properties": [
    {
      "name": "agent_id",
      "dataType": ["text"],
      "description": "UUID of the agent that generated this memory"
    },
    {
      "name": "memory_type",
      "dataType": ["text"],
      "description": "Type: 'persona_trait', 'engagement_pattern', 'cultural_context'"
    },
    {
      "name": "content",
      "dataType": ["text"],
      "description": "The semantic content to be embedded"
    },
    {
      "name": "video_content_hash",
      "dataType": ["text"],
      "description": "SHA-256 hash linking to video_metadata table"
    },
    {
      "name": "timestamp",
      "dataType": ["date"],
      "description": "When this memory was created"
    },
    {
      "name": "relevance_score",
      "dataType": ["number"],
      "description": "Agent-computed relevance (0.0-1.0)"
    }
  ]
}
```

### 2.5 Entity Relationship Diagram (ERD)
```
┌─────────────────┐
│  campaigns      │
├─────────────────┤
│ id (PK)         │
│ super_orch_id   │──┐
│ goal            │  │
│ budget_usd      │  │
│ created_at      │  │
└─────────────────┘  │
                     │
┌─────────────────┐  │     ┌──────────────────┐
│ agent_wallets   │  │     │ task_dag_        │
├─────────────────┤  │     │ executions       │
│ agent_id (PK)   │  │     ├──────────────────┤
│ campaign_id (FK)├──┼─────┤ campaign_id (FK)  │
│ address         │  │     │ planner_agent_did│
│ daily_spend_*   │  │     │ dag_json         │
│ last_reset_date │  │     │ state_version    │
└─────────────────┘  │     │ status           │
                     │     └──────────────────┘
┌─────────────────┐  │
│ hitl_reviews    │  │
├─────────────────┤  │
│ id (PK)         │  │
│ content_hash    │──┼──┐
│ agent_id        │  │  │
│ confidence_score│  │  │
│ review_status   │  │  │
│ approval_token  │  │  │
└─────────────────┘  │  │
                     │  │
┌─────────────────┐  │  │
│ video_metadata  │  │  │
│ (Cassandra)     │  │  │
├─────────────────┤  │  │
│ agent_id        │──┼──┘
│ date_bucket     │  │
│ timestamp       │  │
│ content_hash    │──┘
│ platform        │
│ engagement_rate │
│ frame_tags      │
└─────────────────┘

┌─────────────────┐
│ AgentMemory     │
│ (Weaviate)      │
├─────────────────┤
│ agent_id        │──┐
│ memory_type     │  │
│ content         │  │ (vectorized)
│ video_content_  │  │
│   hash          │──┼──┐
│ timestamp       │  │  │
│ relevance_score │  │  │
└─────────────────┘  │  │
                     │  │
                     └──┴── (Referential integrity via content_hash)
```

**Relationship Summary:**
- `campaigns` → `agent_wallets` (1:N): One campaign can have multiple agent wallets
- `campaigns` → `task_dag_executions` (1:N): One campaign generates multiple DAG execution plans
- `agent_wallets` → `video_metadata` (1:N via agent_id): One agent produces multiple videos
- `video_metadata` → `hitl_reviews` (1:1 via content_hash): Each video has one review record
- `video_metadata` → `AgentMemory` (1:N via content_hash): One video can generate multiple semantic memories

### 2.6 Data Lifecycle & Migration Strategy

**INGESTION (Real-time)**
```
Video metadata → Cassandra (write-optimized path)
Wallet transactions → PostgreSQL (ACID path)
Agent memories → Weaviate (vector embedding path)
```

**TRANSFORMATION (Near-real-time)**
```
Stream processor (Apache Flink) enriches metadata:
  - Adds character_consistency_score from vision model
  - Computes engagement_rate_rolling_avg
  - Flags sensitive topics via classifier
  - Generates semantic embeddings for Weaviate
```

**STORAGE (Optimized for query patterns)**
- **Hot data (<7 days)**: All databases (Cassandra, PostgreSQL, Weaviate, Redis)
- **Warm data (7–30 days)**: Cassandra tiered storage; PostgreSQL archived partitions; Weaviate retention policy
- **Cold data (>30 days)**: Cassandra time-window compaction → S3 Glacier; PostgreSQL → S3 parquet; Weaviate → archived vectors

**RETRIEVAL (Query-optimized)**
- Real-time dashboards: Redis cache + Cassandra time-series queries
- Analytics: Materialized views in PostgreSQL + Cassandra aggregates
- Agent memory recall: Weaviate hybrid search (keyword + vector)

**Migration Strategy:**
- **Day 1**: Co-deploy Cassandra + PostgreSQL; dual-write metadata during pilot
- **Day 14**: Cut over reads to Cassandra for metadata; PostgreSQL remains source of truth for transactions
- **Day 30**: Backfill historical metadata via Apache Spark job (1TB/day throughput)
- **Day 60**: Decommission legacy storage; enable Cassandra time-window compaction
**Partition Key Design to Avoid Hotspots**
- **Problem**: Viral agent could create hot partition (e.g., all writes to agent_id=X)
- **Solution**: Composite partition key (agent_id, date_bucket) where date_bucket = floor(timestamp / 86400)
- **Result**: Even during viral events (10k writes/sec), max writes/partition = 864k/day → well within Cassandra limits

**Failure Mode Handling**

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Cassandra node down | Gossip protocol detects failure in <10s | QUORUM consistency ensures writes succeed to remaining nodes; hinted handoff replays writes when node recovers |
| Network partition | Phi accrual failure detector | Stale node marked down; writes continue to healthy nodes; manual repair required post-partition |
| Disk full | Prometheus alert at 85% capacity | Auto-scale EBS volume + trigger compaction to reclaim space |
| PostgreSQL connection pool exhaustion | PgBouncer metrics >90% utilization | Auto-scale read replicas; circuit breaker rejects new connections with 503 |
| Weaviate vector index corruption | Checksum validation on backup restore | Restore from S3 snapshot; rebuild index from PostgreSQL content_hash references |

## 3. State Management Contracts

### 3.1 GlobalState Structure (TypeScript Interface)
```typescript
interface GlobalState {
  version: string;          // OCC token (e.g., "v42")
  campaign_goals: Array<{
    id: string;
    description: string;
    budget_remaining_usd: number;
    sensitive_topic_filter: boolean;  // Enforced per NFR 1.2
  }>;
  agent_swarm_status: Map<AgentID, {
    role: 'planner' | 'worker' | 'judge' | 'cfo';
    reputation: number;     // 0.0 to 1.0 (portable across ASN)
    current_task_id?: string;
    last_heartbeat: Timestamp;
    containment_boundary: {
      max_filesystem_access: '/tmp',
      max_network_endpoints: ['mcp://*'],
      max_mcp_calls_per_minute: 100
    };
  }>;
  content_registry: Map<ContentHash, {
    platform: Platform;
    engagement_rate: number;
    agent_provenance: Array<{
      agent_did: string;      // DID-signed contribution
      contribution_type: 'script' | 'visual' | 'edit';
      character_reference_id?: string;
    }>;
    disclosure_applied: boolean;  // EU AI Act compliance flag
    sensitive_topic_detected: boolean;
  }>;
}
```

### 3.2 Optimistic Concurrency Control (OCC) Protocol
```
1. Worker reads GlobalState → receives version="v42"
2. Worker executes task → generates result with state_version="v42"
3. Judge receives result → checks current GlobalState.version
   ├─ IF current.version == "v42" → COMMIT result; increment version to "v43"
   └─ IF current.version != "v42" → REJECT("State drift detected—replan required per SRS §3.1.3")
4. On COMMIT: GlobalState.version increments atomically via Redis INCR
```

## 4. Security Boundary Definitions (Pro-Tier Detail)

### 4.1 AuthN/AuthZ Strategy
| Component | Strategy | Justification |
|-----------|----------|---------------|
| **Super-Orchestrator Access** | OAuth 2.0 PKCE with Google Workspace | Enterprise-grade identity; no password management |
| **Agent-to-Agent Communication** | DID-based authentication + Ed25519 signatures | Portable trust across ASN platforms per OpenClaw spec |
| **MCP Server Access** | Per-agent API keys rotated hourly via HashiCorp Vault | Prevents credential theft from compromised agents |
| **Database Access** | PostgreSQL Row-Level Security + Cassandra role-based auth | Multi-tenant isolation without application-layer checks |

### 4.2 Secrets Management Protocol
```
SECRET LIFECYCLE:
1. Creation: AWS Secrets Manager generates 256-bit key
2. Rotation: Automatic every 90 days; old keys retained 30 days for decryption
3. Access: 
   - Runtime: Agent requests via MCP Resource `mcp://secrets/wallet_key/{agent_id}`
   - MCP Server validates agent DID + rate limits requests (max 1/min)
   - NEVER exposed to agent logic—only to Coinbase AgentKit SDK
4. Leakage Response:
   - Automated alert to SOC team
   - Immediate key rotation via AWS API
   - Forensic audit of agent logs for 24h prior to leak
```

### 4.3 Content Safety Guardrails (Three-Layer Moderation)
| Layer | Technology | Threshold | Action |
|-------|------------|-----------|--------|
| **Layer 1: Toxicity** | Google Perspective API | Toxicity score >0.7 | Auto-reject + retry with sanitized prompt |
| **Layer 2: Copyright** | YouTube Content ID fingerprinting | Match confidence >0.85 | Auto-reject + flag for human review |
| **Layer 3: Brand Safety** | Custom rules engine (SOUL.md alignment) | Brand misalignment score >0.6 | Escalate to HITL regardless of confidence |

### 4.4 Agent Containment Boundaries (Non-Negotiable)
| Boundary | Enforcement Mechanism | Violation Example |
|----------|------------------------|-------------------|
| **Filesystem** | Linux namespaces + seccomp filters | Worker attempts `open("/etc/passwd")` → syscall blocked |
| **Network** | eBPF firewall rules | Worker attempts direct `curl https://api.tiktok.com` → connection reset |
| **Compute** | cgroups CPU/memory limits | Worker exceeds 512MB RAM → OOM killer terminates process |
| **MCP Calls** | Rate limiting at MCP Server | Worker exceeds 100 calls/min → 429 Too Many Requests |
| **Wallet Access** | `@budget_check` decorator on all transaction functions | Worker attempts spend without CFO Judge approval → exception raised |

## 5. High-Velocity Metadata Handling (Pro-Tier Detail)

### 5.1 Write Path Optimization
```
Client Request → API Gateway (rate limiting) → 
  ↓
Kafka Topic "metadata_ingest" (partitioned by agent_id) → 
  ↓
Flink Stream Processor (enriches with character_consistency_score) → 
  ↓
Cassandra Async Batch Writer (token-aware routing) → 
  ↓
Acknowledgment to client (<50ms p99)
```

### 5.2 Partition Key Design to Avoid Hotspots
- **Problem**: Viral agent could create hot partition (e.g., all writes to `agent_id=X`)
- **Solution**: Composite partition key `(agent_id, date_bucket)` where `date_bucket = floor(timestamp / 86400)`
- **Result**: Even during viral events (10k writes/sec), max writes/partition = 864k/day → well within Cassandra limits

### 5.3 Failure Mode Handling
| Failure | Detection | Recovery |
|---------|-----------|----------|
| **Cassandra node down** | Gossip protocol detects failure in <10s | QUORUM consistency ensures writes succeed to remaining nodes; hinted handoff replays writes when node recovers |
| **Network partition** | Phi accrual failure detector | Stale node marked down; writes continue to healthy nodes; manual repair required post-partition |
| **Disk full** | Prometheus alert at 85% capacity | Auto-scale EBS volume + trigger compaction to reclaim space |

### 3.1 Agent Framework: FastRender Swarm Orchestration

**Framework Selection**: Custom orchestration layer built on LangGraph (state machine) + MCP primitives

**Rationale**: 
- LangGraph provides explicit state transitions and cycle detection (prevents infinite loops)
- MCP abstraction enables platform-agnostic tooling
- Custom swarm coordination layer handles OCC validation and budget governance

### 3.2 REST API Contracts (Super-Orchestrator Interface)

#### 3.2.1 POST /api/v1/campaigns
**Purpose**: Create a new campaign goal for agent swarm execution

**Request Schema:**
```json
{
  "goal": "string (min 10 chars, max 500 chars)",
  "budget_usd": "decimal(10,2) > 0",
  "target_platforms": ["tiktok", "instagram_reels", "youtube_shorts"],
  "character_reference_id": "uri (optional, format: chimera://characters/{namespace}/{id})"
}
```

**Response Schema (201 Created):**
```json
{
  "campaign_id": "uuid",
  "status": "pending",
  "estimated_completion_minutes": "integer",
  "created_at": "iso8601_timestamp"
}
```

**Error Responses:**
- `400 Bad Request`: Goal too vague (length < 10) or invalid budget
- `401 Unauthorized`: Missing or invalid JWT token
- `403 Forbidden`: Budget exceeds super_orchestrator limit

#### 3.2.2 GET /api/v1/campaigns/{campaign_id}/status
**Purpose**: Query campaign execution status and DAG progress

**Response Schema (200 OK):**
```json
{
  "campaign_id": "uuid",
  "status": "pending|executing|completed|failed",
  "dag_execution_id": "uuid",
  "tasks_completed": "integer",
  "tasks_total": "integer",
  "current_phase": "planning|generation|review|distribution",
  "budget_consumed_usd": "decimal(10,2)",
  "hitl_pending_count": "integer"
}
```

#### 3.2.3 POST /api/v1/hitl/reviews/{review_id}/approve
**Purpose**: Human approval for content requiring review (confidence 0.7-0.9 or sensitive topic)

**Request Schema:**
```json
{
  "approval_token": "string (128 chars, cryptographic)",
  "notes": "string (optional, max 500 chars)"
}
```

**Response Schema (200 OK):**
```json
{
  "review_id": "uuid",
  "status": "approved",
  "approval_token": "string (for MCP post_content tool)",
  "token_expires_at": "iso8601_timestamp"
}
```

### 3.3 Agent Workflow Specifications

#### 3.3.1 Planner Agent Workflow
```
1. Receive campaign goal via MCP Resource: campaigns/{id}
2. Decompose goal into task DAG:
   - Task types: [script_generation, image_generation, video_assembly, distribution]
   - Dependencies: script → image → video → distribution
   - Parallelization: Multiple script/image tasks can run concurrently
3. Validate DAG against budget constraints (sum of task costs < budget_usd)
4. Commit DAG to PostgreSQL task_dag_executions with state_version
5. Publish tasks to Redis queue with priority ordering
```

**DAG Output Schema:**
```json
{
  "dag_id": "uuid",
  "campaign_id": "uuid",
  "tasks": [
    {
      "task_id": "uuid",
      "type": "script_generation|image_generation|video_assembly|distribution",
      "required_mcp_tools": ["generate_script", "generate_image", ...],
      "estimated_cost_usd": "decimal(10,2)",
      "dependencies": ["task_id_1", "task_id_2"],
      "priority": "HIGH|MEDIUM|LOW"
    }
  ],
  "state_version": "string (monotonic counter)"
}
```

#### 3.3.2 Worker Agent Workflow
```
1. Poll Redis queue for available task (atomic pop with OCC check)
2. Load task context from PostgreSQL
3. Validate state_version matches current GlobalState
4. Execute task using MCP Tools:
   - Call MCP tool with required parameters
   - Receive result with confidence_score
5. Submit result to Judge Agent via MCP Resource: judge/submit
```

**Worker Output Schema:**
```json
{
  "task_id": "uuid",
  "worker_agent_did": "uri",
  "result": {
    "artifact_type": "script|image|video",
    "artifact_hash": "sha256",
    "confidence_score": "decimal(3,2) 0.0-1.0",
    "mcp_tool_calls": [
      {
        "tool_name": "generate_script",
        "parameters": {...},
        "result": {...}
      }
    ]
  },
  "state_version": "string (from GlobalState at execution start)"
}
```

#### 3.3.3 Judge Agent Workflow
```
1. Receive Worker result via MCP Resource: judge/submit
2. Validate state_version (OCC check):
   - If state_version mismatch → REJECT("Stale state, task must be retried")
   - If match → proceed
3. Apply safety filters:
   - Confidence threshold: <0.7 → REJECT + trigger Planner re-plan
   - Sensitive topic detection: politics/health/finance/legal → HITL_REQUIRED
   - Character consistency: If image, validate against character_reference_id (score >0.85)
4. Budget check: Verify task cost doesn't exceed campaign budget
5. Route decision:
   - confidence >= 0.9 AND no sensitive topic → AUTO_APPROVE → Commit to GlobalState
   - confidence 0.7-0.9 OR sensitive topic → HITL_REQUIRED → Create hitl_reviews record
   - confidence < 0.7 → REJECT → Notify Planner for re-plan
```

**Judge Decision Schema:**
```json
{
  "task_id": "uuid",
  "decision": "AUTO_APPROVE|HITL_REQUIRED|REJECT",
  "reason": "string",
  "hitl_review_id": "uuid (if HITL_REQUIRED)",
  "approval_token": "string (if AUTO_APPROVE, for immediate distribution)",
  "state_version": "string (incremented on commit)"
}
```

### 3.4 OpenClaw Integration Protocol

**Purpose**: Publish Chimera agent availability and status to Agent Social Network

**MCP Resource**: `mcp://openclaw/agent_status`

**Status Publication Schema:**
```json
{
  "agent_did": "did:key:...",
  "agent_type": "planner|worker|judge",
  "availability": "available|busy|maintenance",
  "current_campaign_id": "uuid (if busy)",
  "capabilities": {
    "mcp_tools": ["generate_script", "generate_image", "post_content"],
    "max_parallel_tasks": "integer",
    "budget_remaining_usd": "decimal(10,2)"
  },
  "reputation_score": "decimal(3,2) 0.0-1.0",
  "last_heartbeat": "iso8601_timestamp"
}
```

**MoltBook Integration**: Chimera agents publish content metadata to MoltBook feed via MCP Tool `moltbook_publish_post`:
```json
{
  "content_hash": "sha256",
  "platform": "tiktok|instagram_reels|youtube_shorts",
  "engagement_metrics": {
    "views": "integer",
    "likes": "integer",
    "shares": "integer"
  },
  "agent_provenance": [{"agent_did": "...", "contribution_type": "..."}]
}
```

### 3.5 Inter-System Communication Patterns

**Pattern 1: Event-Driven via Redis Pub/Sub**
- Planner publishes DAG → Workers subscribe to task queue
- Judge publishes approval → Distribution Worker subscribes

**Pattern 2: Request-Response via MCP**
- Worker → MCP Server → External API (TikTok, Ideogram, etc.)
- All external calls MUST route through MCP (no direct HTTP)

**Pattern 3: State Synchronization via PostgreSQL OCC**
- All state mutations include state_version
- Optimistic locking prevents race conditions in swarm

## 4. Security Architecture

### 4.1 Authentication & Authorization Strategy

**AuthN Method**: OAuth 2.0 PKCE (Proof Key for Code Exchange) with Google Workspace
- **Rationale**: Enterprise-grade identity provider; supports SSO for Super-Orchestrators
- **Token Format**: JWT (JSON Web Token) with 15-minute expiry, refresh token rotation

**AuthZ Model**: Role-Based Access Control (RBAC) with campaign-scoped permissions
- **Super-Orchestrator Role**: Full access to own campaigns; cannot access other orchestrators' campaigns (enforced via PostgreSQL RLS)
- **Agent DID**: Decentralized identifiers for agent authentication; signed requests via Ed25519

**JWT Claims Schema:**
```json
{
  "sub": "super_orchestrator_id (uuid)",
  "email": "user@example.com",
  "roles": ["super_orchestrator"],
  "campaign_ids": ["uuid1", "uuid2"],
  "exp": "unix_timestamp",
  "iat": "unix_timestamp"
}
```

**API Endpoint Security:**
- `/api/v1/campaigns/*`: Requires JWT with `super_orchestrator` role
- `/api/v1/hitl/reviews/*`: Requires JWT + campaign_id ownership validation
- MCP endpoints: Authenticated via agent DID signature validation

### 4.2 Secrets Management

**Strategy**: Enterprise secrets manager (AWS Secrets Manager or HashiCorp Vault)

**Stored Secrets:**
- Private keys for agent wallets (encrypted at rest, never in code)
- MCP server API keys (TikTok, Instagram, YouTube, Ideogram, OpenAI)
- Database connection strings (PostgreSQL, Cassandra, Weaviate)
- JWT signing keys (HS256 secret or RS256 private key)

**Access Pattern:**
```python
# Pseudo-code pattern (implementation must use actual secrets manager SDK)
wallet_private_key = secrets_manager.get_secret(
    secret_id="chimera/agent_wallets/{agent_id}",
    version_stage="AWSCURRENT"
)
```

**Forbidden Patterns** ❌:
- Hardcoded API keys in source code
- Environment variables in Docker images (use secrets injection at runtime)
- Private keys in Git repository (even if encrypted)

### 4.3 Rate Limiting

**Per-Endpoint Limits:**
- `/api/v1/campaigns` (POST): 10 requests/minute per super_orchestrator_id
- `/api/v1/hitl/reviews/*` (POST): 100 requests/minute per super_orchestrator_id
- MCP Tool calls: 100 calls/minute per agent DID (enforced at MCP Server layer)

**Implementation**: Redis-based token bucket algorithm
- Key format: `rate_limit:{resource}:{identifier}`
- Burst allowance: 2x base rate for 10-second windows

### 4.4 Content Safety Guardrails

**Sensitive Topic Detection**: Multi-classifier pipeline
- **Categories**: `politics`, `health`, `finance`, `legal`
- **Model**: Fine-tuned BERT classifier (confidence threshold: 0.7)
- **Action**: ANY detected sensitive topic → HITL_REQUIRED (bypasses confidence auto-approve)

**Content Moderation Pipeline:**
```
1. Worker generates content → confidence_score computed
2. Sensitive topic classifier runs in parallel
3. Judge receives both scores:
   - If sensitive_topic_detected = true → HITL_REQUIRED (regardless of confidence)
   - If confidence < 0.7 → REJECT
   - If confidence 0.7-0.9 → HITL_REQUIRED
   - If confidence >= 0.9 AND no sensitive topic → AUTO_APPROVE
```

**EU AI Act Compliance**: All distributed content MUST include disclosure flags
- Platform-native: `is_generated=true` metadata (TikTok/Instagram/YouTube APIs)
- Caption watermark: "#AIGenerated" appended to captions if platform doesn't support native flags

### 4.5 Agent Containment Boundaries

**Resource Limits (Per Agent DID):**
- **Filesystem**: Read/write limited to `/tmp/chimera/{agent_id}/` (Docker volume mount)
- **Network**: Only MCP endpoint access; no direct internet (enforced via network policy)
- **Memory**: 2GB RAM limit per agent process (Docker memory constraint)
- **CPU**: 1 vCPU limit per agent (Docker CPU constraint)
- **Execution Time**: 300-second timeout per task (Kubernetes job timeout)

**Forbidden Actions (Enforced at Runtime):**
- ❌ Direct API calls to social platforms (must use MCP Tools)
- ❌ File system access outside `/tmp/chimera/{agent_id}/`
- ❌ Network connections to non-MCP endpoints
- ❌ Modification of GlobalState without state_version validation
- ❌ Wallet transactions exceeding daily_spend_limit_usd

**Escalation Triggers:**
- Agent attempts forbidden action → Logged + Task REJECTED + Alert to Super-Orchestrator
- Agent exceeds resource limits → Process terminated + Task requeued with lower priority
- Agent generates content with confidence <0.5 → Auto-escalate to human review + flag agent for retraining

### 4.6 Data Protection & Privacy

**PII Handling**: 
- Ethiopian user data stored in Africa-region data centers only (GDPR compliance)
- Data retention: Video metadata retained for 90 days, then archived to S3 Glacier
- Right to deletion: Super-Orchestrator can request campaign deletion → cascading delete in all databases

**Encryption:**
- **At Rest**: All databases encrypted with AES-256 (AWS KMS)
- **In Transit**: TLS 1.3 for all API and MCP communications
- **Agent Wallet Private Keys**: Encrypted with envelope encryption (KMS CMK + data key)

### 4.7 Security Monitoring & Alerting

**Logging Requirements:**
- All MCP Tool calls logged with agent_did, timestamp, parameters (sanitized), result status
- All state_version validations logged (OCC conflicts detected)
- All HITL decisions logged with reviewer_id, timestamp, decision rationale

**Alert Conditions:**
- Budget exceeded attempt → Immediate alert to Super-Orchestrator
- OCC conflict rate >5% in 1 hour → Alert to operations team
- Agent containment violation → Immediate alert + agent suspension
- Sensitive topic detected in auto-approved content → Post-hoc audit alert
