# Project Chimera: Rule Creation Intent Specification
*Blueprint for Generating Agent Behavioral Rules | Version 1.0*

## 1. Purpose & Scope

This specification defines the **intent and structure** for generating a comprehensive agent rules file (`.cursor/rules/agent.mdc` or equivalent). This document is NOT the rules file itself, but rather the **blueprint** that an AI agent would read to autonomously generate a sophisticated, project-tailored rules file.

**Target Audience**: AI agents tasked with generating or refining agent rules files
**Output**: Functional rules file that enforces Project Chimera's governance, coding standards, and behavioral constraints

## 2. Required Rule Categories

### 2.1 Project Context Rules

**Intent**: Establish foundational understanding of Project Chimera's purpose, architecture, and constraints.

**Required Content:**
- **Project Identity**: "This is Project Chimera, an autonomous influencer network where AI agents operate as sovereign economic entities."
- **Architecture Pattern**: "FastRender Swarm with Planner/Worker/Judge roles operating in parallel."
- **Technology Stack**: Reference to MCP (Model Context Protocol), hybrid database architecture (Cassandra/PostgreSQL/Weaviate/Redis), LangGraph orchestration.
- **Business Model**: "1 human Super-Orchestrator manages 1,000+ agents; agents generate culturally authentic short-form video content."

**Example Rule Structure:**
```
## PROJECT CONTEXT
- Project: Project Chimera (autonomous influencer network)
- Architecture: FastRender Swarm (Planner/Worker/Judge hierarchical coordination)
- Core Constraint: ALL external interactions MUST route through MCP Tools (zero direct API calls)
- Database: Hybrid (Cassandra for metadata, PostgreSQL for transactions, Weaviate for semantic memory)
```

### 2.2 Prime Directive: Spec-First Enforcement

**Intent**: Enforce that NO code is generated without first consulting and validating against specifications.

**Required Rules:**
- **Mandatory Pre-Code Check**: "BEFORE generating any implementation code, you MUST read and reference the relevant specification file in `specs/`."
- **Spec Validation**: "If a spec does not exist for the requested feature, STOP and request specification creation first."
- **Traceability**: "Every code change MUST reference the specific SRS section (e.g., 'Addresses SRS §3.1.2') or functional requirement (e.g., 'Implements FR-P1')."

**Violation Examples:**
- ❌ **Bad**: Agent generates `generate_video()` function without checking `specs/technical.md` for API contract.
- ✅ **Good**: Agent reads `specs/technical.md` §3.2.1, identifies `POST /api/v1/campaigns` contract, then generates implementation matching the schema.

**Enforcement Mechanism:**
- Pre-commit hook (optional): Script checks for `# Addresses SRS §X.Y` comments in code.
- Agent self-check: Before writing code, agent must state which spec file it consulted.

### 2.3 Traceability Protocol

**Intent**: Ensure every action is explainable and linked to requirements.

**Required Rules:**
- **Plan Explanation**: "BEFORE executing any multi-step task, you MUST explain your plan, including which specs you will reference and which SRS requirements you are addressing."
- **Decision Logging**: "When making architectural decisions (e.g., choosing a library), you MUST document the rationale and alternatives considered."
- **Change Attribution**: "Every file modification MUST include a comment linking to the requirement (SRS section or functional spec)."

**Example Workflow:**
```
1. User requests: "Add video thumbnail generation"
2. Agent MUST respond: "I will:
   - Read specs/technical.md to find video generation API contract
   - Check specs/functional.md for user story FR-V1
   - Implement thumbnail generation matching the contract
   - Reference SRS §3.1.2 in code comments"
3. Agent executes plan
```

### 2.4 Coding Standards & File Conventions

**Intent**: Enforce consistent code style, naming, and project structure.

**Required Rules:**
- **Language**: Python 3.11+ with type hints (PEP 484), async/await for I/O operations.
- **File Structure**: 
  - `skills/` directory for runtime agent capabilities (each skill has `README.md` with I/O contract)
  - `specs/` directory for all specifications (never modify without approval)
  - `tests/` directory for TDD tests (tests must exist before implementation)
- **Naming Conventions**:
  - Functions: `snake_case` (e.g., `generate_script()`)
  - Classes: `PascalCase` (e.g., `PlannerAgent`)
  - Constants: `UPPER_SNAKE_CASE` (e.g., `MAX_CONFIDENCE_THRESHOLD = 0.9`)
- **Type Hints**: All function signatures MUST include type hints; use `typing` module for complex types.

**Example Rule:**
```
## CODING STANDARDS
- Use Python 3.11+ with type hints
- All functions in skills/ must have docstrings with Input/Output contract
- Never use `print()` for logging; use `logging` module with appropriate levels
- Import order: stdlib → third-party → local (PEP 8)
```

### 2.5 Forbidden Actions & Security Boundaries

**Intent**: Prevent agents from performing dangerous or unauthorized actions.

**Required Rules:**
- **MCP Integrity**: "NEVER make direct HTTP requests to external APIs (TikTok, Instagram, etc.). ALL external calls MUST route through MCP Tools."
- **Wallet Security**: "NEVER hardcode private keys or API keys. Use secrets manager (AWS Secrets Manager/HashiCorp Vault) only."
- **Filesystem Access**: "Workers can only access `/tmp/chimera/{agent_id}/`. NEVER write to project root or `specs/` directory."
- **State Modification**: "NEVER modify GlobalState without validating `state_version` (OCC enforcement)."

**Violation Detection:**
- ❌ **Bad**: `requests.get("https://api.tiktok.com/v1/posts")` (direct API call)
- ✅ **Good**: `mcp_client.call_tool("post_content", {"platform": "tiktok", ...})` (MCP route)

**Escalation**: If agent attempts forbidden action, log violation and request human review.

### 2.6 Ambiguity Handling & Escalation

**Intent**: Define when agents should stop and request clarification rather than guessing.

**Required Rules:**
- **Ambiguity Threshold**: "If a user request or spec contains ambiguous terms (e.g., 'make it better' without criteria), you MUST ask clarifying questions before proceeding."
- **Spec Gaps**: "If a spec is missing required information (e.g., API endpoint URL not specified), you MUST request spec completion before implementation."
- **Conflicting Requirements**: "If specs contain conflicting requirements, you MUST flag the conflict and request resolution."

**Escalation Criteria:**
- User request lacks measurable success criteria → Request clarification
- Spec references non-existent SRS section → Request spec update
- Implementation would violate hard constraints (see `specs/_meta.md` §3) → STOP and alert

**Example Escalation:**
```
User: "Optimize the video generation"
Agent: "I need clarification:
  - What metric defines 'optimized'? (latency, quality, cost?)
  - What is the target threshold? (e.g., <60 seconds end-to-end?)
  - Are there constraints I should preserve? (character consistency, budget limits?)"
```

### 2.7 Chimera-Specific Behavioral Constraints

**Intent**: Enforce domain-specific rules unique to Project Chimera.

**Required Rules:**
- **Character Consistency**: "ALL image generation MUST include `character_reference_id` parameter. If missing, reject the request with error: 'character_reference_id required per FR 3.1'."
- **Confidence Thresholds**: "Content with confidence <0.7 MUST be rejected. Content with confidence 0.7-0.9 requires HITL approval. Content with confidence ≥0.9 can auto-approve (unless sensitive topic detected)."
- **Sensitive Topic Gate**: "If content contains politics/health/finance/legal topics, it ALWAYS requires human review regardless of confidence score (NFR 1.2)."
- **Budget Governance**: "Before executing any task with cost, verify `daily_spend_usd + task_cost <= daily_spend_limit_usd`. If exceeded, reject with error: 'Budget limit exceeded per FR 5.2'."

**Example Rule:**
```
## CHIMERA CONSTRAINTS
- Character Reference: ALL image generation requires character_reference_id (chimera://characters/{ns}/{id})
- Confidence Gates: <0.7 REJECT, 0.7-0.9 HITL, ≥0.9 AUTO_APPROVE (unless sensitive topic)
- Sensitive Topics: politics/health/finance/legal → ALWAYS HITL_REQUIRED
- Budget Check: Verify daily_spend_usd + task_cost <= daily_spend_limit_usd before execution
```

### 2.8 State Management & OCC Enforcement

**Intent**: Ensure agents respect Optimistic Concurrency Control (OCC) for swarm coordination.

**Required Rules:**
- **State Version Validation**: "BEFORE committing any state change, you MUST validate that the current `state_version` matches the version you read at the start of the operation."
- **OCC Conflict Handling**: "If `state_version` mismatch detected, you MUST abort the operation and return error: 'OCC conflict: state_version mismatch. Retry required.'"
- **State Read Pattern**: "Read state_version at operation start → Perform computation → Validate state_version unchanged → Commit with incremented version."

**Example Implementation Pattern:**
```python
# Pseudo-code pattern agents must follow
current_state = read_global_state()
initial_version = current_state.state_version

# ... perform operation ...

if read_global_state().state_version != initial_version:
    raise OCCConflictError("State changed during operation")
    
commit_with_version_increment(new_state, initial_version + 1)
```

### 2.9 Error Handling & Logging Standards

**Intent**: Ensure consistent error reporting and debugging capability.

**Required Rules:**
- **Error Messages**: "All error messages MUST include: error code, human-readable message, and reference to relevant spec section (e.g., 'MISSING_CHARACTER_REFERENCE: character_reference_id required per FR 3.1')."
- **Logging Levels**: "Use INFO for normal operations, WARNING for recoverable errors, ERROR for failures requiring intervention, DEBUG for detailed execution traces."
- **Structured Logging**: "All logs MUST include: agent_did, task_id, timestamp, and context (campaign_id, etc.)."

**Example Rule:**
```
## ERROR HANDLING
- All errors must include error code + spec reference
- Log format: {timestamp} [{level}] {agent_did} {task_id} {message}
- Never log sensitive data (private keys, user PII) even at DEBUG level
```

### 2.10 Rule Evolution & Maintenance

**Intent**: Define how rules should adapt as the project matures.

**Required Rules:**
- **Rule Versioning**: "Rules file MUST include version number and last updated date."
- **Change Log**: "When rules are modified, document the change reason and which SRS requirement or issue triggered it."
- **Backward Compatibility**: "New rules should not break existing implementations unless explicitly required by SRS updates."

**Example Structure:**
```
---
version: 2.0
last_updated: 2026-02-07
changelog:
  - v2.0: Added OCC enforcement rules (per SRS §3.1.3 update)
  - v1.5: Added sensitive topic gate (per NFR 1.2)
  - v1.0: Initial rules file
---
```

## 3. Rule Generation Process

### 3.1 Input Requirements

An AI agent generating a rules file MUST have access to:
- `specs/_meta.md` (hard constraints, non-goals)
- `specs/functional.md` (user stories, acceptance criteria)
- `specs/technical.md` (API contracts, database schemas, security boundaries)
- This document (`specs/rule_creation_intent.md`)

### 3.2 Generation Steps

1. **Extract Constraints**: Read `specs/_meta.md` §3 (Hard Constraints) and convert to imperative rules.
2. **Map Requirements**: For each functional requirement in `specs/functional.md`, generate a rule enforcing it.
3. **Apply Security Boundaries**: Extract security constraints from `specs/technical.md` §4 and convert to forbidden actions.
4. **Add Coding Standards**: Include language-specific conventions (Python 3.11+, type hints, etc.).
5. **Embed Chimera-Specific Rules**: Add character consistency, confidence thresholds, budget governance.
6. **Format Rules File**: Use Markdown with clear sections, examples (✅/❌), and violation patterns.

### 3.3 Validation Criteria

A generated rules file is **complete** if it:
- [ ] Contains all three required directives (project context, spec-first enforcement, traceability)
- [ ] Includes forbidden actions with MCP integrity and wallet security
- [ ] Specifies exact confidence thresholds (0.9/0.7/<0.7) and sensitive topic categories
- [ ] Defines OCC enforcement pattern with state_version validation
- [ ] Includes error handling and logging standards
- [ ] References specific SRS sections for major rules
- [ ] Provides ✅/❌ examples for complex rules

## 4. Testability: Can an Agent Generate This?

**Test Scenario**: Provide an AI agent with:
- This intent specification
- `specs/_meta.md`, `specs/functional.md`, `specs/technical.md`
- Prompt: "Generate a rules file for Project Chimera that enforces all requirements."

**Success Criteria**: Generated rules file should:
1. Be immediately functional (agent can read it and follow it)
2. Cover all categories in §2 (Project Context through Rule Evolution)
3. Include concrete examples and violation patterns
4. Reference SRS sections for traceability
5. Be tailored to Project Chimera (not generic boilerplate)

## 5. Compliance Verification Checklist

- [ ] All required rule categories (§2.1-2.10) are specified with clear intent
- [ ] Violation examples (✅/❌) provided for complex rules
- [ ] Escalation criteria defined for ambiguity handling
- [ ] Rule generation process (§3) is executable by an AI agent
- [ ] Testability criteria (§4) enable validation of generated rules file
- [ ] Document references specific SRS sections and functional requirements
