# Project Chimera Constitution
*The foundational principles and governance rules for the Autonomous Influencer Factory*

## Core Principles

### I. Spec-Driven Development (SDD) - NON-NEGOTIABLE
**Intent is the source of truth.** Implementation code MUST NOT be written until the Specification is ratified and documented in the `specs/` directory using the GitHub Spec Kit framework.

**Enforcement:**
- ✅ All features must have corresponding entries in `specs/functional.md` (user stories) and `specs/technical.md` (API contracts, schemas)
- ✅ AI agents MUST check `specs/` directory before generating any code
- ❌ NO "vibe coding" or prototyping without spec ratification
- ❌ NO implementation in `skills/` without documented Input/Output contracts

**Rationale:** Ambiguity is the enemy of AI. Vague specs lead to hallucination and fragile codebases. The spec serves as the contract between human architects and AI agents.

### II. Traceability via MCP (Model Context Protocol)
**All agent activity must be observable.** The Tenx MCP Sense server MUST remain connected to the IDE at all times, serving as the "Black Box" flight recorder for agent decision-making.

**Enforcement:**
- ✅ MCP Sense connection verified before any development session
- ✅ All external interactions MUST route through MCP Tools/Resources/Prompts (zero direct API calls)
- ✅ Agent "thinking" and tool calls logged via MCP telemetry
- ❌ NO direct platform API calls (Twitter, TikTok, YouTube) outside MCP layer
- ❌ NO development without active MCP Sense connection

**Rationale:** Traceability enables debugging, compliance auditing, and prevents "black box" agent behavior. MCP provides standardized integration boundaries.

### III. Test-Driven Development (TDD) - Red-Green-Refactor
**Tests define the empty slots that agents must fill.** Tests are written FIRST, approved by humans, and MUST fail before implementation begins.

**Enforcement:**
- ✅ All `tests/` files must exist and fail before corresponding implementation
- ✅ Test structure defines expected Input/Output contracts (e.g., `test_trend_fetcher.py`, `test_skills_interface.py`)
- ✅ CI/CD pipeline runs tests in Docker on every push
- ❌ NO implementation code without failing tests
- ❌ NO merging PRs with failing tests (except when tests are intentionally failing to define contracts)

**Rationale:** TDD creates executable specifications. Failing tests are success—they define the "goal posts" that AI agents must reach.

### IV. Skills vs. Tools Distinction
**Clear separation between runtime capabilities and development infrastructure.**

**Definitions:**
- **Skills** (Runtime): Reusable functions/scripts that agents call during execution (e.g., `skill_download_youtube`, `skill_transcribe_audio`). Live in `skills/` directory with documented I/O contracts.
- **Tools** (Development): MCP servers that assist development workflow (e.g., `git-mcp`, `filesystem-mcp`). Documented in `research/tooling_strategy.md`.

**Enforcement:**
- ✅ Skills must have README.md defining Input/Output contracts before implementation
- ✅ Developer MCP tools documented separately from runtime skills
- ✅ Skills directory structure ready before agent implementation phase
- ❌ NO mixing of development tooling with agent runtime capabilities

**Rationale:** Clear boundaries prevent architectural confusion and enable proper dependency management.

### V. Git Hygiene & Commit Discipline
**Commit history tells the story of evolving complexity.** Frequent, meaningful commits enable rollback and audit trails.

**Enforcement:**
- ✅ Minimum 2 commits per day during active development
- ✅ Commit messages must reference spec sections or task numbers
- ✅ Commit history should demonstrate progression: Research → Spec → Test → Implementation
- ❌ NO large monolithic commits (max 200 lines per commit)
- ❌ NO commits without clear, descriptive messages

**Rationale:** Git history serves as documentation and enables collaboration with AI agents who can understand project evolution.

## Architectural Constraints

### FastRender Swarm Pattern
Project Chimera uses a **Hierarchical FastRender Swarm** architecture (not Sequential Chain) to prevent cumulative hallucination.

**Role Boundaries:**
- **Planner**: Generates task DAGs, reactive to world-state changes. Cannot modify GlobalState directly.
- **Worker**: Stateless, ephemeral, high-parallelism executors. Filesystem limited to `/tmp`, no peer-to-peer communication.
- **Judge**: Validates Worker output against SOUL.md, budget limits, safety filters. Implements OCC (Optimistic Concurrency Control).

**Enforcement:**
- ✅ Workers MUST validate `state_version` before committing to GlobalState
- ✅ All agents rate-limited to 100 MCP Tool calls/minute per DID
- ❌ NO persistent state in Workers
- ❌ NO direct Planner-to-GlobalState writes (must route through Judge)

### MCP Integrity Requirement
**Zero direct API calls.** ALL platform interactions (Twitter, TikTok, YouTube, Coinbase AgentKit, Weaviate) MUST route through MCP Tools only.

**Enforcement:**
- ✅ All external services accessed via MCP Server endpoints
- ✅ MCP Tool definitions documented in `specs/mcp_schema.json`
- ❌ NO `requests.post()` or direct HTTP calls to platform APIs
- ❌ NO hardcoded API keys (use enterprise secrets manager only)

### Human-in-the-Loop (HITL) Safety Gates
**Confidence-based escalation ensures human oversight for sensitive decisions.**

**Thresholds:**
- **Green Tier (>0.90)**: Fully autonomous execution
- **Amber Tier (0.70-0.90)**: Asynchronous human review required
- **Red Tier (<0.70)**: Auto-rejection, correction loop triggered

**Sensitive Topics** (always require review regardless of confidence):
- Politics, Health, Finance, Legal content

**Enforcement:**
- ✅ Judge Agent MUST apply confidence thresholds before commit
- ✅ Sensitive topic detection mandatory before content generation
- ❌ NO auto-approval for sensitive topics, even with high confidence

## Development Workflow & Quality Gates

### Repository Structure Requirements
The repository MUST contain the following structure before Day 3 completion:

```
specs/              # GitHub Spec Kit structure
tests/              # Failing tests defining contracts
skills/             # Agent runtime capabilities (with README.md per skill)
Dockerfile          # Containerized environment
Makefile            # Standardized commands (setup, test, spec-check)
.github/workflows/  # CI/CD automation
.cursor/rules       # IDE agent context (Prime Directive, traceability)
```

### CI/CD Pipeline Requirements
**Automated governance prevents spec drift and security vulnerabilities.**

**Required Actions:**
- ✅ Run `make test` in Docker on every push
- ✅ Linting and security vulnerability scanning
- ✅ Spec alignment verification (optional but recommended via `make spec-check`)
- ✅ AI Review Policy configured (CodeRabbit or equivalent checking for Spec Alignment)

**Enforcement:**
- ✅ All PRs must pass CI/CD gates before merge
- ❌ NO bypassing CI/CD checks (even for administrators)

### Containerization & Environment Standardization
**"It works on my machine" is unacceptable.** All development and testing MUST occur in containerized environments.

**Enforcement:**
- ✅ `Dockerfile` encapsulates complete environment (Python, dependencies, MCP servers)
- ✅ `make setup` installs dependencies consistently
- ✅ `make test` runs tests in Docker container
- ❌ NO local-only testing without Docker verification
- ❌ NO environment-specific configurations in code (use environment variables)

## Governance

### Constitution Supremacy
This Constitution supersedes all other practices, conventions, and ad-hoc decisions. All development decisions must align with these principles.

### Amendment Process
Constitution amendments require:
1. Documentation of rationale and tradeoffs considered
2. Approval from Lead Architect
3. Migration plan for existing code/specs
4. Version bump and ratification date update

### Compliance Verification
**All PRs and code reviews MUST verify:**
- [ ] Spec alignment: Does code match `specs/technical.md` contracts?
- [ ] MCP Integrity: Are all external calls routed through MCP?
- [ ] Test Coverage: Do failing tests exist before implementation?
- [ ] Git Hygiene: Are commits frequent and meaningful?
- [ ] Security: Are secrets managed via enterprise secrets manager?
- [ ] HITL Gates: Are confidence thresholds and sensitive topic filters implemented?

### AI Agent Context Requirements
The `.cursor/rules` (or `CLAUDE.md`) file MUST explicitly contain:
- Project Context: "This is Project Chimera, an autonomous influencer system."
- Prime Directive: "NEVER generate code without checking `specs/` first."
- Traceability: "Explain your plan before writing code."
- MCP Requirement: "All external interactions via MCP Tools only."

**Version**: 1.0.0 | **Ratified**: 2025-02-04 | **Last Amended**: 2025-02-04
