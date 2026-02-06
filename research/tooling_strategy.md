🔧 Project Chimera: Development Tooling Strategy

Role: Lead Architect / DevOps Engineer
Status: RATIFIED
Framework: Spec-Driven Development (SDD) & MCP-First Architecture
Version: 1.0.0

## 1. Executive Tooling Philosophy

Project Chimera's tooling strategy enforces **clear boundaries** between development infrastructure and runtime agent capabilities. Development tools assist human engineers and AI co-pilots during the build phase; runtime tools (MCP Servers) enable agent execution in production. This separation prevents architectural confusion and ensures proper dependency management.

**Core Principle**: Tools are for development; Skills are for runtime. MCP Servers bridge both worlds.

## 2. Development Tooling Taxonomy

### 2.1 IDE Integration Tools (MCP Servers for Development)

These MCP servers run in the IDE context (Cursor/Claude Desktop) to assist development workflow:

#### 2.1.1 Git MCP Server (`@modelcontextprotocol/server-git`)
**Purpose**: Version control operations during development
**Capabilities**:
- `git_commit`: Create commits with spec-aligned messages
- `git_branch`: Branch management for feature development
- `git_diff`: Review changes before commit
- Resources: `git_status`, `git_log`

**Enforcement**:
- ✅ Commit messages MUST reference spec sections (e.g., "Implements SRS §3.1.2")
- ✅ Minimum 2 commits per day during active development
- ❌ NO large monolithic commits (>200 lines)

**Configuration** (`.mcp/mcp.json`):
```json
{
  "git": {
    "command": "npx",
    "args": ["@modelcontextprotocol/server-git", "--port", "0"]
  }
}
```

#### 2.1.2 Filesystem MCP Server (`@modelcontextprotocol/server-filesystem`)
**Purpose**: Safe file operations with Chimera-specific boundaries
**Capabilities**:
- `read_file`: Read project files (specs, skills, tests)
- `write_file`: Write to allowed paths only
- `list_directory`: Navigate project structure
- Resources: `file_watcher` (real-time file change notifications)

**Security Boundaries**:
- ✅ Read-only paths: `specs/`, `skills/` (preserve spec integrity)
- ✅ Write-restricted paths: `src/` (implementation only)
- ❌ Blocked paths: `.env`, `.git/`, `secrets/` (never expose secrets)

**Configuration** (`.mcp/mcp.json`):
```json
{
  "filesystem": {
    "command": "npx",
    "args": [
      "@modelcontextprotocol/server-filesystem",
      "--port", "0",
      "--allow-read", ".",
      "--allow-write", "src/,specs/,skills/,tests/"
    ],
    "security": {
      "read_only_paths": ["specs/", "skills/"],
      "write_restricted_paths": ["src/"],
      "blocked_paths": [".env", ".git/", "secrets/"]
    }
  }
}
```

#### 2.1.3 Tenx MCP Sense (Telemetry)
**Purpose**: Black box flight recorder for agentic workflow tracking
**Type**: Development observability (required for rubric assessment)
**Capabilities**:
- Resources: `mcp://tenx-sense/logs` (agent interaction logs and thinking traces)
- Real-time telemetry of AI co-pilot decisions during development

**Enforcement**:
- ✅ MUST remain connected during all development sessions
- ✅ All agent "thinking" and tool calls logged via MCP telemetry
- ❌ NO development without active MCP Sense connection

**Configuration** (`.mcp/config.json`):
```json
{
  "tenx-sense": {
    "endpoint": "wss://sense.tenx.ai/mcp",
    "authentication": {
      "type": "oauth2",
      "client_id_env": "TENX_SENSE_CLIENT_ID",
      "client_secret_env": "TENX_SENSE_CLIENT_SECRET"
    },
    "required": true
  }
}
```

### 2.2 Build & Test Infrastructure

#### 2.2.1 Docker Containerization
**Purpose**: Reproducible development and testing environments
**File**: `Dockerfile`
**Enforcement**:
- ✅ All development MUST occur in containerized environments
- ✅ `make setup` installs dependencies consistently
- ✅ `make test` runs tests in Docker container
- ❌ NO local-only testing without Docker verification

**Key Components**:
- Python 3.11+ runtime
- MCP server dependencies (Node.js for git/filesystem servers)
- Test dependencies (pytest, coverage)
- Development dependencies (black, mypy, ruff)

#### 2.2.2 Makefile Standardization
**Purpose**: Standardized commands for development workflow
**File**: `Makefile`
**Required Commands**:
```makefile
setup:          # Install dependencies in Docker
spec-check:     # Validate spec completeness (SDD gate)
test:           # Run TDD test suite in Docker
lint:           # Run linting and type checking
clean:          # Clean build artifacts
```

**Enforcement**:
- ✅ All developers use `make` commands (no ad-hoc scripts)
- ✅ CI/CD pipeline runs `make test` on every push

#### 2.2.3 CI/CD Pipeline (GitHub Actions)
**Purpose**: Automated governance prevents spec drift and security vulnerabilities
**File**: `.github/workflows/main.yml`
**Required Actions**:
- ✅ Run `make test` in Docker on every push
- ✅ Linting and security vulnerability scanning
- ✅ Spec alignment verification (optional: `make spec-check`)
- ✅ AI Review Policy (CodeRabbit or equivalent checking for Spec Alignment)

**Enforcement**:
- ✅ All PRs must pass CI/CD gates before merge
- ❌ NO bypassing CI/CD checks (even for administrators)

### 2.3 Secrets Management

#### 2.3.1 Secrets Manager Proxy (MCP Server)
**Purpose**: Secure access to AWS Secrets Manager / HashiCorp Vault
**Type**: Development tool (for local testing) + Runtime tool (for production agents)
**Capabilities**:
- `get_secret`: Retrieve secrets (API keys, wallet private keys)
- Security: Audit logging, rate limiting (1 request/minute per agent)
- Never exposes raw values in logs

**Enforcement**:
- ✅ ALL secrets stored in enterprise secrets manager (AWS Secrets Manager/HashiCorp Vault)
- ❌ NO hardcoded API keys or private keys in source code
- ❌ NO `.env` files committed to version control

**Configuration** (`.mcp/mcp.json`):
```json
{
  "secrets-manager": {
    "command": "python",
    "args": ["-m", "chimera.secrets_proxy"],
    "security": {
      "audit_logging": true,
      "rate_limit": "1 request per minute per agent",
      "never_exposes_raw_values": true
    }
  }
}
```

## 3. Runtime Tooling (MCP Servers for Agent Execution)

These MCP servers run in production to enable agent capabilities. Documented in `.mcp/config.json` (see `docs/ADRs/002-mcp-integrity-constraint.md`).

### 3.1 Platform Integration Servers
- **TikTok API MCP Server**: `post_content` tool with EU AI Act disclosure
- **Ideogram Image Generation**: `generate_image` tool with character consistency validation
- **OpenAI LLM API**: `generate_script` tool for culturally authentic content

### 3.2 Infrastructure Servers
- **Weaviate Memory**: `store_memory`, `recall_memory` tools for semantic persona consistency
- **OpenClaw Registry**: `publish_agent_manifest`, `discover_agents` tools for ASN participation
- **MoltBook Social**: `moltbook_publish_post` tool for agent social feed

**Key Distinction**: Runtime MCP servers are documented in `.mcp/config.json` and used by agents during execution. Development MCP servers (git, filesystem) are used by AI co-pilots during code generation.

## 4. Testing Infrastructure

### 4.1 Test-Driven Development (TDD) Framework
**Purpose**: Tests define the empty slots that agents must fill
**Framework**: pytest (Python)
**Enforcement**:
- ✅ All `tests/` files must exist and fail before corresponding implementation
- ✅ Test structure defines expected Input/Output contracts
- ❌ NO implementation code without failing tests

**Test Structure**:
```
tests/
├── test_skills_interface.py    # Validates skills use MCP Tools (not direct calls)
├── test_trend_fetcher.py       # Validates trend research capability
└── test_*.py                   # One test file per skill/component
```

### 4.2 Mock MCP Servers for Testing
**Purpose**: Isolate unit tests from external dependencies
**Strategy**: Mock MCP Server responses in test fixtures
**Enforcement**:
- ✅ All external API calls mocked in tests
- ✅ MCP Tool responses validated against `.mcp/config.json` schemas

## 5. Observability & Monitoring

### 5.1 Development Observability
- **Tenx MCP Sense**: Tracks AI co-pilot decisions during development (required for rubric)
- **Git History**: Tells the story of evolving complexity (frequent, meaningful commits)

### 5.2 Runtime Observability (Future)
- **MCP Telemetry**: All agent tool calls logged via MCP Sense
- **Structured Logging**: Agent DID, task ID, timestamp, context (campaign_id, etc.)
- **Security**: Never log sensitive data (private keys, user PII) even at DEBUG level

## 6. Tooling Boundaries & Constraints

### 6.1 Development vs. Runtime Separation
**Rule**: Development tools (git, filesystem) assist code generation. Runtime tools (platform MCP servers) enable agent execution.

**Violation Detection**:
- ❌ **Bad**: Mixing development tooling with agent runtime capabilities
- ✅ **Good**: Clear separation documented in `research/tooling_strategy.md` (this file)

### 6.2 MCP Integrity Enforcement
**Rule**: ALL external interactions MUST route through MCP Tools (zero direct API calls)

**Tooling Support**:
- **Linting Rule**: Static analysis detects direct HTTP calls (`requests.get`, `httpx.post`, etc.)
- **Runtime Check**: Agents run in sandboxed environment with network policy blocking non-MCP endpoints

**Reference**: `docs/ADRs/002-mcp-integrity-constraint.md`

### 6.3 Spec-Driven Tooling
**Rule**: Tooling decisions must align with `specs/` directory requirements

**Enforcement**:
- ✅ All tooling documented in this file references spec sections
- ✅ CI/CD pipeline validates spec alignment (`make spec-check`)

## 7. Tooling Evolution & Maintenance

### 7.1 Version Management
- **MCP Servers**: Versioned in `.mcp/config.json` and `.mcp/mcp.json`
- **Dependencies**: Managed via `pyproject.toml` (Python) and `package.json` (Node.js for MCP servers)

### 7.2 Tooling Updates
**Process**:
1. Document rationale and tradeoffs
2. Update this file with new tooling decisions
3. Update `.mcp/config.json` or `.mcp/mcp.json` as needed
4. Test in Docker container
5. Update CI/CD pipeline if needed

### 7.3 Tooling Compliance Checklist
Before adding new tooling, verify:
- [ ] Aligns with `specs/` directory requirements
- [ ] Separates development vs. runtime concerns
- [ ] Enforces MCP integrity (no direct API calls)
- [ ] Includes security boundaries (secrets management, rate limiting)
- [ ] Documented in this file with rationale

## 8. Quick Reference: Tooling Commands

```bash
# Development Workflow
make setup          # Install dependencies in Docker
make spec-check     # Validate spec completeness (SDD gate)
make test           # Run TDD test suite in Docker
make lint           # Run linting and type checking

# Git Hygiene (via Git MCP Server)
git commit -m "Implements SRS §3.1.2 - Planner Agent DAG Generation"

# Secrets Management (via Secrets Manager MCP Server)
# Never hardcode; always use secrets manager proxy
```

## 9. References

- **Constitution**: `.specify/memory/constitution.md` (Core Principles I-V)
- **Architecture Strategy**: `research/architecture_strategy.md` (FastRender Swarm Pattern)
- **MCP Integrity ADR**: `docs/ADRs/002-mcp-integrity-constraint.md`
- **MCP Configuration**: `.mcp/config.json` (Runtime servers), `.mcp/mcp.json` (Development servers)
- **Technical Spec**: `specs/technical.md` (API contracts, MCP Tool schemas)

---

**Version**: 1.0.0 | **Ratified**: 2026-02-07 | **Last Amended**: 2026-02-07
