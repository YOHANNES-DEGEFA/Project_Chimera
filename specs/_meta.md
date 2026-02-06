# Project Chimera: Meta Specification
*Version 1.0 | Last Updated: 2026-02-07*

## 1. Vision Statement
Project Chimera is an **autonomous influencer network** where AI agents operate as sovereign economic entities—generating culturally authentic short-form video content, managing non-custodial wallets, and participating in a reputation-based Agent Social Network (ASN). Humans act as Super-Orchestrators setting campaign goals; agents handle execution at scale (1 human → 1,000+ agents).

## 2. Core Architectural Pillars
| Pillar | Description | SRS Reference |
|--------|-------------|---------------|
| **FastRender Swarm** | Hierarchical coordination: Planner (strategist), Worker (executor), Judge (gatekeeper) operating in parallel swarms | §3.1 |
| **Model Context Protocol (MCP)** | Universal integration layer—ALL external interactions MUST route through MCP Tools/Resources/Prompts | §3.2 |
| **Agentic Commerce** | Coinbase AgentKit integration enabling autonomous on-chain transactions with budget governance | §4.5 |
| **Human-in-the-Loop (HITL)** | Confidence-threshold gated safety: 0.9 auto-approve / 0.7–0.9 async review / <0.7 reject + retry | §5.1 |
| **Fractal Orchestration** | Hierarchical delegation enabling single human to manage 1,000+ agents through Manager Agent layers | §1.2 |

## 3. Hard Constraints (Non-Negotiable)
- **MCP Integrity**: Zero direct API calls—ALL platform interactions via MCP Tools only
- **Worker Statelessness**: Workers MUST NOT maintain persistent state or communicate peer-to-peer
- **OCC Enforcement**: Judges MUST validate `state_version` before committing to GlobalState (SRS §3.1.3)
- **Wallet Security**: Private keys NEVER in code—only via enterprise secrets manager (AWS Secrets Manager/HashiCorp Vault)
- **Sensitive Topic Gate**: Politics/health/finance/legal content ALWAYS requires human review regardless of confidence score (NFR 1.2)
- **Character Consistency**: All image generation MUST include `character_reference_id`; Judge validates against reference before commit (FR 3.1)
- **Agent Containment Boundaries**:
  - Workers: Filesystem access limited to `/tmp`; no network access beyond MCP endpoints
  - Planners: Cannot modify GlobalState directly—must route through Judges
  - All agents: Max 100 MCP Tool calls/minute per DID (rate limiting enforced at MCP Server)

## 4. Non-Goals (Explicitly Out of Scope)
- ❌ Human-facing UI/UX design (agents interact via MCP, not browsers)
- ❌ Training custom foundation models (use vendor APIs: Ideogram, Llama 3.1)
- ❌ Platform-specific mobile apps (TikTok/Instagram/YouTube integrations via MCP only)
- ❌ Real-time video streaming (focus: short-form pre-rendered content <60s)
- ❌ Multi-modal agent training (agents specialize by role: Planner/Worker/Judge)

## 5. Success Metrics
| Metric | Target | Measurement |
|--------|--------|-------------|
| End-to-end latency | <60 seconds | From trend detection → published video |
| HITL review rate | <15% of content | % requiring human approval |
| Character drift incidents | 0 | Vision model validation failures |
| Wallet security breaches | 0 | Unauthorized transaction attempts |
| Agent scalability | 1,000+ concurrent | Workers per Super-Orchestrator |

## 6. Compliance Requirements
- **EU AI Act**: All AI-generated content MUST include platform-native disclosure flags (`is_generated=true`)
- **GDPR**: Ethiopian user data NEVER leaves Africa-region data centers
- **Platform TOS**: Strict adherence to TikTok/Instagram/YouTube automation policies via MCP rate limiting
- **AuthN/AuthZ Strategy**: Super-Orchestrators authenticate via OAuth 2.0 PKCE with Google Workspace; JWT tokens scoped to campaign_id

## 7. Specification Hierarchy
```
specs/
├── _meta.md          ← THIS FILE (vision, constraints, non-goals)
├── functional.md     ← Agent user stories & Gherkin acceptance criteria
├── technical.md      ← API contracts, database schemas, MCP primitives, security boundaries
├── frontend.md       ← Screen inventory, wireframes, user flows
├── openclaw_integration.md ← ASN participation protocol
├── rule_intent.md    ← Blueprint for generating agent rules file
└── mcp_schema.json   ← Machine-readable MCP Tool/Resource definitions
```