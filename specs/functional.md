# Project Chimera: Functional Specification
*Agent-Centric User Stories with Gherkin Acceptance Criteria | Version 1.0*

## 1. Planner Agent Stories

### FR-P1: Campaign Goal Decomposition
**As a** Planner Agent  
**I need to** decompose high-level campaign goals into executable task DAGs  
**So that** Workers can execute atomic tasks in parallel  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Decompose fashion campaign into multi-platform DAG
  Given campaign goal "Promote summer fashion line targeting Gen-Z in Ethiopia"
  And budget_usd = 500
  When Planner executes decomposition
  Then output DAG contains ≥3 task types (script, asset, distribution)
  And all tasks include required_mcp_tools array
  And TikTok distribution task has priority = HIGH
  And DAG state_version is set to current GlobalState version

Scenario: Reject ambiguous campaign goal
  Given campaign goal "Make people happy"
  When Planner attempts decomposition
  Then output = REJECT("Goal lacks measurable success criteria per SRS §2.1")
  And error code = "VAGUE_GOAL"
  And error references SRS section "§2.1"

Scenario: Budget validation in DAG generation
  Given campaign goal "Create 10 videos for product launch"
  And budget_usd = 50
  And estimated cost per video = 10 USD
  When Planner executes decomposition
  Then DAG total estimated cost = 100 USD
  And output = REJECT("Budget insufficient: 50 USD < 100 USD required")
  And error code = "BUDGET_INSUFFICIENT"

Scenario: DAG includes character reference validation
  Given campaign goal "Generate influencer content for brand X"
  And character_reference_id = "chimera://characters/brand_x/influencer_001"
  When Planner executes decomposition
  Then all image_generation tasks include character_reference_id parameter
  And character_reference_id matches input value
```

### FR-P2: Real-Time Re-Planning
**As a** Planner Agent  
**I need to** re-plan when world-state changes (trend shifts, budget exhausted)  
**So that** campaigns adapt to dynamic conditions  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Re-plan on trend shift detection
  Given active campaign with DAG status = "executing"
  And MCP Resource trends_ethiopia reports new trending topic "Ethiopian coffee culture"
  When Planner detects trend shift via MCP Resource poll
  Then Planner generates new DAG with updated topic
  And new DAG state_version = previous_version + 1
  And previous DAG tasks are marked "cancelled" if not yet started

Scenario: Re-plan on budget exhaustion
  Given active campaign with budget_remaining_usd = 5.00
  And next task estimated_cost_usd = 10.00
  When Planner evaluates task feasibility
  Then Planner generates REJECT decision
  And notification sent to Super-Orchestrator via HITL dashboard
  And error message = "Budget exhausted: 5.00 USD remaining < 10.00 USD required"
```

## 2. Worker Agent Stories

### FR-W1: Atomic Task Execution
**As a** Worker Agent  
**I need to** execute atomic tasks using MCP Tools  
**So that** content generation is parallelizable and fault-tolerant  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Execute script generation task
  Given task from DAG with type = "script_generation"
  And task parameters = {"topic": "Addis Ababa street fashion", "platform": "tiktok", "language": "amharic_slang"}
  When Worker executes task
  Then Worker calls MCP Tool "generate_script" with parameters
  And MCP Tool returns script_text and confidence_score
  And Worker submits result to Judge with state_version from GlobalState
  And result includes agent_did for provenance

Scenario: Handle MCP Tool failure gracefully
  Given task requiring MCP Tool "generate_image"
  And MCP Server returns error code "RATE_LIMIT_EXCEEDED"
  When Worker receives error
  Then Worker marks task status = "failed"
  And Worker logs error with task_id and agent_did
  And Worker does NOT retry (Planner will re-plan)
  And error details submitted to Judge for HITL escalation

Scenario: OCC validation before task execution
  Given task with state_version = "v42"
  And GlobalState current state_version = "v43"
  When Worker reads GlobalState before execution
  Then Worker detects state_version mismatch
  And Worker aborts task execution
  And Worker returns error "OCC_CONFLICT: state_version mismatch (expected v42, got v43)"
  And task is requeued for Planner re-evaluation

Scenario: Worker filesystem isolation
  Given Worker assigned task_id = "task_123"
  When Worker needs to write temporary files
  Then Worker only writes to /tmp/chimera/{agent_id}/task_123/
  And Worker cannot access /tmp/chimera/{other_agent_id}/
  And Worker cannot access project root or specs/ directory
```

### FR-W2: Character Consistency Enforcement
**As a** Worker Agent  
**I need to** include character_reference_id in all image generation  
**So that** visual consistency is maintained across content  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Image generation with character reference
  Given task type = "image_generation"
  And character_reference_id = "chimera://characters/fashion_influencer/main"
  When Worker calls MCP Tool "generate_image"
  Then Worker includes character_reference_id in parameters
  And MCP Tool validates character_reference_id format (URI pattern)
  And generated image includes character_consistency_score in response
  And character_consistency_score >= 0.85 (threshold per FR 3.1)

Scenario: Reject image generation without character reference
  Given task type = "image_generation"
  And character_reference_id = null
  When Worker attempts to call MCP Tool "generate_image"
  Then Worker rejects task before MCP call
  And Worker returns error "MISSING_CHARACTER_REFERENCE: character_reference_id required per FR 3.1"
  And error code = "MISSING_CHARACTER_REFERENCE"
```

## 3. Judge Agent Stories

### FR-J1: Confidence-Based Routing
**As a** Judge Agent  
**I need to** route content based on confidence scores and safety filters  
**So that** high-quality content auto-publishes while risky content gets human review  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Auto-approve high confidence content
  Given Worker result with confidence_score = 0.95
  And sensitive_topic_detected = false
  And state_version matches current GlobalState
  When Judge evaluates result
  Then Judge decision = "AUTO_APPROVE"
  And Judge generates approval_token (128-char cryptographic token)
  And approval_token expires in 300 seconds
  And Judge commits result to GlobalState with incremented state_version
  And content is immediately distributed via MCP post_content tool

Scenario: Route to HITL for medium confidence
  Given Worker result with confidence_score = 0.80
  And sensitive_topic_detected = false
  When Judge evaluates result
  Then Judge decision = "HITL_REQUIRED"
  And Judge creates hitl_reviews record with status = "pending"
  And Super-Orchestrator receives notification via dashboard
  And content is NOT distributed until human approval

Scenario: Reject low confidence content
  Given Worker result with confidence_score = 0.60
  When Judge evaluates result
  Then Judge decision = "REJECT"
  And Judge logs rejection reason = "Confidence score 0.60 < threshold 0.70"
  And Judge notifies Planner to re-plan task
  And content is NOT distributed

Scenario: Sensitive topic always requires HITL
  Given Worker result with confidence_score = 0.95
  And sensitive_topic_detected = true
  And sensitive_topic_category = "politics"
  When Judge evaluates result
  Then Judge decision = "HITL_REQUIRED" (regardless of high confidence)
  And Judge logs reason = "Sensitive topic detected: politics (per NFR 1.2)"
  And hitl_reviews record includes sensitive_topic_category = "politics"
```

### FR-J2: OCC State Version Validation
**As a** Judge Agent  
**I need to** validate state_version before committing state changes  
**So that** swarm coordination prevents race conditions  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Accept valid state version
  Given Worker result with state_version = "v42"
  And GlobalState current state_version = "v42"
  When Judge validates state_version
  Then Judge accepts result
  And Judge commits with state_version = "v43" (incremented)
  And commit succeeds

Scenario: Reject stale state version (OCC conflict)
  Given Worker result with state_version = "v41"
  And GlobalState current state_version = "v43"
  When Judge validates state_version
  Then Judge detects OCC conflict
  And Judge decision = "REJECT"
  And Judge returns error "OCC_CONFLICT: state_version mismatch (expected v41, got v43). Task must be retried."
  And Judge does NOT commit result to GlobalState
  And task is requeued for Worker re-execution with updated state_version
```

### FR-J3: Budget Governance Enforcement
**As a** Judge Agent  
**I need to** validate budget limits before approving costly operations  
**So that** campaigns do not exceed allocated budgets  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Approve task within budget
  Given task with estimated_cost_usd = 10.00
  And campaign daily_spend_usd = 40.00
  And campaign daily_spend_limit_usd = 50.00
  When Judge evaluates budget constraint
  Then Judge calculates: 40.00 + 10.00 = 50.00 <= 50.00
  And Judge approves task
  And Judge updates daily_spend_usd = 50.00

Scenario: Reject task exceeding budget
  Given task with estimated_cost_usd = 15.00
  And campaign daily_spend_usd = 40.00
  And campaign daily_spend_limit_usd = 50.00
  When Judge evaluates budget constraint
  Then Judge calculates: 40.00 + 15.00 = 55.00 > 50.00
  And Judge decision = "REJECT"
  And Judge returns error "BUDGET_EXCEEDED: daily_spend_usd (55.00) > daily_spend_limit_usd (50.00) per FR 5.2"
  And Judge sends alert to Super-Orchestrator
  And task is NOT executed
```

## 4. Super-Orchestrator Stories

### FR-SO1: Campaign Creation
**As a** Super-Orchestrator  
**I need to** create campaigns with goals and budgets  
**So that** agent swarms can execute content generation at scale  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Create valid campaign
  Given authenticated Super-Orchestrator with JWT token
  And campaign data: goal = "Promote Ethiopian coffee culture", budget_usd = 500, target_platforms = ["tiktok", "instagram_reels"]
  When Super-Orchestrator POSTs to /api/v1/campaigns
  Then API validates goal length >= 10 characters
  And API validates budget_usd > 0
  And API creates campaign record in PostgreSQL
  And API returns campaign_id (UUID)
  And API returns status = "pending"
  And campaign is assigned to Planner Agent for DAG generation

Scenario: Reject vague campaign goal
  Given campaign data: goal = "Make videos"
  When Super-Orchestrator POSTs to /api/v1/campaigns
  Then API returns 400 Bad Request
  And error message = "Goal too vague: length 9 < minimum 10 characters per SRS §2.1"
  And error code = "VAGUE_GOAL"
  And campaign is NOT created

Scenario: Reject invalid budget
  Given campaign data: goal = "Valid campaign goal with sufficient length", budget_usd = -100
  When Super-Orchestrator POSTs to /api/v1/campaigns
  Then API returns 400 Bad Request
  And error message = "Budget must be positive: -100.00 <= 0"
  And error code = "INVALID_BUDGET"
  And campaign is NOT created
```

### FR-SO2: HITL Content Review
**As a** Super-Orchestrator  
**I need to** review and approve content requiring human judgment  
**So that** risky or medium-confidence content is validated before distribution  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Approve HITL review
  Given HITL review with review_id = "review_123"
  And review status = "pending"
  And content_hash = "abc123def456..."
  When Super-Orchestrator POSTs to /api/v1/hitl/reviews/review_123/approve
  Then API validates Super-Orchestrator owns campaign (via JWT + campaign_id lookup)
  And API updates hitl_reviews record: status = "approved", reviewed_at = NOW()
  And API generates approval_token (128-char cryptographic token)
  And API returns approval_token with expires_at = NOW() + 300 seconds
  And content is immediately distributed via MCP post_content tool with approval_token

Scenario: Reject HITL review
  Given HITL review with review_id = "review_123"
  When Super-Orchestrator POSTs to /api/v1/hitl/reviews/review_123/reject
  And request includes notes = "Content does not match brand guidelines"
  Then API updates hitl_reviews record: status = "rejected", reviewed_at = NOW(), notes = "..."
  And API notifies Planner Agent to re-plan task
  And content is NOT distributed
  And rejection reason is logged for analytics

Scenario: Approval token expiry handling
  Given approval_token generated at T=0
  And approval_token expires_at = T=300 seconds
  When Worker attempts to use approval_token at T=301 seconds
  Then MCP post_content tool rejects request
  And error code = "TOKEN_EXPIRED"
  And error message = "Approval token expired (valid 300s). New approval required."
  And content is NOT distributed
```

## 5. Performance & Non-Functional Acceptance Criteria

### NFR-1: End-to-End Latency
**Requirement**: Campaign goal → published video in <60 seconds (p95)

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Measure end-to-end latency
  Given campaign created at T=0
  And campaign goal = "Generate TikTok video about Ethiopian coffee"
  When campaign execution completes (video published)
  Then elapsed_time = T_completion - T=0
  And elapsed_time <= 60 seconds (p95 percentile)
  And latency breakdown logged: planning_time, generation_time, review_time, distribution_time
```

### NFR-2: HITL Review Rate
**Requirement**: <15% of content requires human review

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Calculate HITL review rate
  Given campaign generates 100 content items
  When campaign execution completes
  Then hitl_reviews count = items with confidence 0.7-0.9 OR sensitive_topic_detected = true
  And hitl_review_rate = hitl_reviews_count / 100
  And hitl_review_rate < 0.15 (15%)
```

### NFR-3: Character Consistency
**Requirement**: Zero character drift incidents (character_consistency_score < 0.85)

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Validate character consistency
  Given image generation task with character_reference_id
  When Judge validates character_consistency_score
  Then character_consistency_score >= 0.85
  And if score < 0.85, Judge decision = "REJECT"
  And error code = "CHARACTER_DRIFT_DETECTED"
  And incident logged for analytics
```

## 6. Edge Cases & Failure Modes

### EC-1: MCP Server Unavailable
```gherkin
Scenario: Handle MCP Server downtime
  Given Worker task requiring MCP Tool "generate_script"
  And MCP Server returns 503 Service Unavailable
  When Worker receives error
  Then Worker marks task status = "failed"
  And Worker logs error with retry_after timestamp
  And Planner Agent is notified to re-plan after retry_after
  And task is NOT lost (persisted in PostgreSQL for recovery)
```

### EC-2: Database Connection Failure
```gherkin
Scenario: Handle PostgreSQL connection failure
  Given Judge attempting to commit result to GlobalState
  And PostgreSQL connection pool exhausted
  When Judge receives connection error
  Then Judge retries with exponential backoff (max 3 retries)
  And if all retries fail, Judge logs error and notifies operations team
  And result is persisted to Redis queue for later commit
  And Super-Orchestrator sees "System Degraded" banner in dashboard
```

## 7. Compliance Verification Checklist

- [ ] All functional requirements (FR-P1 through FR-SO2) have formal Gherkin acceptance criteria
- [ ] All non-functional requirements (NFR-1 through NFR-3) have measurable acceptance criteria
- [ ] Edge cases (EC-1, EC-2) include failure mode handling
- [ ] All scenarios are traceable to SRS sections (e.g., "per SRS §2.1")
- [ ] Error codes and messages are specified for all failure paths
- [ ] Performance thresholds are quantitative (e.g., "<60 seconds p95", "<15% review rate")
```

*Validation:* All tasks include `required_mcp_tools` array  
*SRS Reference:* §3.1.1

### FR-P2: Dynamic Re-Planning on Context Shift
**As a** Planner Agent  
**I need to** detect context shifts (breaking news, trending topics) via MCP Resources  
**So that** I can prune irrelevant tasks and inject new high-opportunity tasks without human intervention  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Inject trending topic task during viral event
  Given current DAG with 10 tasks
  And MCP Resource mcp://twitter/trends/ethiopia returns trend "Addis Ababa street fashion" with relevance_score = 0.92
  When Planner detects context shift
  Then new task injected with priority = CRITICAL
  And ≥80% of original DAG preserved
  And new task assigned to Worker with specialization "amharic_scripting"
```

*SRS Reference:* §3.1.1

## 2. Worker Agent Stories

### FR-W1: Atomic Task Execution via MCP
**As a** Worker Agent  
**I need to** execute single atomic tasks using ONLY MCP Tools  
**So that** platform API changes don't break agent logic  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Execute generate_script with valid parameters
  Given task_id = "t-7a3f"
  And mcp_tool = "generate_script"
  And params = {"topic": "Addis Ababa street fashion", "platform": "tiktok", "language": "amharic_slang"}
  When Worker executes task
  Then output contains script_text, confidence ≥0.7, state_version matching input
  And NO direct API calls detected in execution trace

Scenario: Reject task with missing required parameter
  Given task_id = "t-8b4e"
  And mcp_tool = "generate_script"
  And params = {"topic": "street fashion"}  # missing platform/language
  When Worker attempts execution
  Then output = REJECT("Missing required parameters: platform, language per MCP schema")
```

*SRS Reference:* §3.2

### FR-W2: Character Consistency Enforcement
**As a** Worker Agent generating visuals  
**I need to** include `character_reference_id` in ALL image generation requests  
**So that** Judge can validate output against canonical reference  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Generate image with valid character reference
  Given mcp_tool = "generate_image"
  And params = {"prompt": "Ethiopian model in summer dress", "character_reference_id": "chimera://characters/fashion_summer_2026/aida"}
  When Worker executes
  Then MCP Tool call includes character_reference_id parameter
  And output confidence ≥0.85

Scenario: Auto-reject task missing character_reference_id
  Given mcp_tool = "generate_image"
  And params = {"prompt": "Ethiopian model in summer dress"}  # missing reference
  When Worker attempts execution
  Then output = REJECT("MISSING_CHARACTER_REFERENCE per FR 3.1")
  And confidence = 0.0
```

*SRS Reference:* FR 3.1

## 3. Judge Agent Stories

### FR-J1: Multi-Criteria Validation Gate
**As a** Judge Agent  
**I need to** validate Worker outputs against 4 criteria before commit:  
1. Persona constraints (SOUL.md alignment)  
2. Safety guidelines (toxicity/copyright/brand)  
3. Acceptance criteria (engagement thresholds)  
4. Optimistic Concurrency Control (state_version match)  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Approve content passing all validation gates
  Given Worker result with confidence = 0.92
  And current_global_state.version = "v42"
  And result.state_version = "v42"
  And toxicity_score < 0.1
  And copyright_match = false
  When Judge validates
  Then output = APPROVE
  And GlobalState.version increments to "v43"

Scenario: Reject on state drift (OCC failure)
  Given Worker result with confidence = 0.95
  And current_global_state.version = "v43"  # changed since Worker read state
  And result.state_version = "v42"
  When Judge validates
  Then output = REJECT("State drift detected—replan required per SRS §3.1.3")
```

*SRS Reference:* §3.1.3

### FR-J2: Confidence Scoring Engine
**As a** Judge Agent  
**I need to** compute confidence scores (0.0–1.0) using multi-factor model  
**So that** HITL routing decisions are data-driven  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Compute confidence for high-quality output
  Given LLM_probability = 0.95
  And historical_success_rate = 0.92
  And semantic_classifier_score = 0.88
  And persona_alignment_score = 0.90
  When Judge computes confidence
  Then confidence = 0.917  # (0.4*0.95 + 0.3*0.92 + 0.2*0.88 + 0.1*0.90)
  And routing = AUTO_APPROVE (confidence > 0.90)

Scenario: Escalate sensitive topic regardless of confidence
  Given confidence = 0.96
  And content contains political_claim = true
  When Judge evaluates
  Then routing = ESCALATE_TO_HITL("Sensitive topic: politics per NFR 1.2")
```

*Thresholds:* >0.90 auto-approve, 0.70–0.90 async review, <0.70 reject  
*SRS Reference:* §5.1

## 4. Human-in-the-Loop Stories

### FR-H1: Context-Aware Review Dashboard
**As a** Human Reviewer  
**I need to** see agent provenance + risk context for each content item  
**So that** I can approve behavioral patterns (not pixels) in <15 seconds  

#### Acceptance Criteria (Gherkin)
```gherkin
Scenario: Display review card for medium-confidence content
  Given content item with confidence = 0.82
  And agent_did = "did:chimera:agent:worker-tiktok-9b4d"
  And agent_reputation = 0.94
  And risk_flags = ["new_platform_feature"]
  When dashboard renders review card
  Then displays agent reputation score prominently
  And shows content provenance chain (DID-signed edit history)
  And highlights risk flags in yellow border
  And average review time ≤15 seconds per item
```

*SRS Reference:* §5.1