# Project Chimera: Rule Creation Intent Specification
*Blueprint for Generating Agent Rules File | Version 1.0*

## 1. Purpose
This document specifies the **intent and structure** for an AI agent to generate a sophisticated `.cursor/rules` file. It is NOT the rules file itself—it is the specification an agent would read to produce that file without ambiguity.

## 2. Rule Categories Taxonomy
The generated rules file MUST contain these 8 categories in order:

| Category | Required Elements | Forbidden Patterns | Example (✅ Good) | Example (❌ Bad) |
|----------|-------------------|--------------------|-------------------|------------------|
| **Project Context** | Exact string: "This is Project Chimera: an autonomous influencer network..." + 4 architectural pillars | Vague statements like "AI project" | ✅ "This is Project Chimera: an autonomous influencer network where AI agents operate as sovereign economic entities..." | ❌ "This is an AI project for social media" |
| **Prime Directive** | Exact string: "NEVER generate code without first checking the `specs/` directory" + enforcement mechanism | Soft language like "should check specs" | ✅ "NEVER generate code without first checking the `specs/` directory for SRS requirements" | ❌ "Try to check specs before coding" |
| **Traceability Protocol** | Mandatory 4-part plan format BEFORE code generation:<br>1. Alignment (SRS section)<br>2. Architecture (pattern rationale)<br>3. Validation (Judge criteria)<br>4. Confidence score (0.0–1.0) | Skipping plan or partial plans | ✅ "PLAN:\n- Alignment: Implements SRS §4.0...\n- Architecture: Using Worker role because...\n- Validation: Judge verifies...\n- Confidence: 0.95\n✅ Proceed?" | ❌ "I'll implement TikTok posting now" |
| **Safety Constraints** | 5 non-negotiable boundaries:<br>1. MCP integrity (no direct API calls)<br>2. Wallet security (secrets manager only)<br>3. HITL thresholds (0.9/0.7/<0.7)<br>4. Character consistency (reference ID required)<br>5. Worker statelessness | Permissive language like "avoid direct API calls" | ✅ "NEVER bypass MCP for external interactions. Violation examples:\n❌ `import tweepy...`\n✅ `mcp_client.call_tool('post_content', ...)`" | ❌ "Prefer using MCP over direct APIs" |
| **Scope Control** | Explicit DO NOT list (6 items) + requirement to ask before architectural decisions | Ambiguous boundaries like "don't add unnecessary deps" | ✅ "DO NOT:\n- Add dependencies not in pyproject.toml\n- Modify .env structure\n- Bypass MCP layer\n- Create stateful Workers\n- Modify GlobalState without Judge\n- Generate docs unprompted" | ❌ "Be careful with dependencies" |
| **Error Handling** | Required actions for errors:<br>1. Fix with minimal changes<br>2. Explain root cause<br>3. Never hide failures | "Work around errors silently" | ✅ "If error discovered:\n- Fix with minimal changes\n- Explain root cause clearly\n- Do not hide or work around errors silently" | ❌ "Try to make it work somehow" |
| **Edge Case Handling** | 7 Chimera-specific edge cases with required handling (see Section 3) | Generic statements like "handle edge cases" | ✅ "Viral event burst: Auto-scale Worker pool; NEVER degrade Orchestrator performance (NFR 3.0)" | ❌ "Handle high traffic gracefully" |
| **Evolution Strategy** | Phase-based rule refinement:<br>Phase 1: Spec enforcement<br>Phase 2: Wallet security<br>Phase 3: Character consistency | Static rules that never evolve | ✅ "Phase 1 (Now): Basic spec enforcement\nPhase 2 (6mo): Add wallet security constraints\nPhase 3 (18mo): Add cross-platform reputation validation" | ❌ "These rules are final" |

## 3. Chimera-Specific Edge Cases (MUST be included)
The generated rules file MUST contain explicit handling for these 7 edge cases:

| Edge Case | Required Handling Statement | SRS Reference |
|-----------|-----------------------------|---------------|
| **Viral event burst** | "Auto-scale Worker pool; NEVER degrade Orchestrator performance" | NFR 3.0 |
| **API rate limit hit** | "Self-healing: Worker retries with exponential backoff; Planner re-routes to alternate platform" | §2.4 Assumption 3 |
| **Wallet balance depletion** | "CFO Judge blocks ALL transactions; triggers alert to Super-Orchestrator" | FR 5.2 |
| **Character drift in images** | "Judge uses vision model to validate against reference ID BEFORE commit" | FR 3.1 |
| **MCP Server outage** | "Fallback to cached Resources; Planner pauses non-critical tasks" | §3.2.1 |
| **Confidence score manipulation** | "Cross-validate with semantic classifier; reject if discrepancy >0.2" | NFR 1.1 |
| **Platform API change** | "MCP Server absorbs change; agent logic UNMODIFIED" | §2.4 Assumption 3 |

## 4. Testability Criteria
The generated rules file is valid ONLY if it passes these checks:

| Check | Validation Method | Pass Condition |
|-------|-------------------|----------------|
| **Prime Directive Presence** | String search | Contains exact substring: "NEVER generate code without first checking the `specs/` directory" |
| **Traceability Format** | Regex match | Contains pattern: `PLAN:\n- Alignment:.*\n- Architecture:.*\n- Validation:.*\n- Confidence: [0-9.]+\n✅ Proceed\?` |
| **MCP Integrity Enforcement** | Keyword scan | Contains "NEVER bypass MCP" + at least 2 violation examples (✅/❌) |
| **Wallet Security** | Keyword scan | Contains "secrets manager" + "NEVER hardcoded keys" |
| **Confidence Thresholds** | Numeric validation | Contains exact values: "0.9 auto-approve", "0.7–0.9 async review", "<0.7 reject" |

## 5. Evolution Protocol
The rules file MUST include a versioning strategy:

```
## VERSION HISTORY
v1.0 (2026-02-07): Initial spec enforcement + MCP integrity
v1.1 (2026-03-01): Add wallet security constraints per FR 5.2
v1.2 (2026-04-15): Add character consistency lock per FR 3.1
→ Next evolution triggered by: First production wallet transaction
```

## 6. Generation Instructions for AI Agent
To generate the rules file:
1. Start with YAML frontmatter: `---\nalwaysApply: true\n---`
2. Follow category order in Section 2 EXACTLY
3. For each category, include ALL required elements from "Required Elements" column
4. Include ALL 7 edge cases from Section 3 under "Safety Constraints"
5. End with "VERSION HISTORY" block from Section 5
6. Validate against testability criteria in Section 4 before delivery
