# ADR 001: Agent Orchestration Pattern Selection

## Status
Accepted 2026-02-07

## Context
Chimera requires an agent orchestration pattern that satisfies:
- Sub-60-second end-to-end latency for viral content windows (NFR 3.0)
- Fault tolerance at 1,000+ concurrent agents (SRS §2.4)
- Emergent specialization without centralized assignment (SRS §1.2)
- ASN interoperability for dynamic agent recruitment (OpenClaw integration)

## Decision
**Hierarchical Swarm pattern** (FastRender architecture) selected over Sequential Chain.

### Pattern Comparison

| Criterion | Sequential Chain | Hierarchical Swarm (Selected) | Rationale |
|-----------|------------------|-------------------------------|-----------|
| **Parallel Execution** | Linear dependencies create bottlenecks | Moderation checks execute concurrently (toxicity + copyright + brand safety) | Meets <60s SLA requirement (NFR 3.0) |
| **Fault Tolerance** | Single point of failure halts pipeline | Self-healing: failed Workers auto-replaced without workflow interruption | Supports 1,000+ agents where failures are inevitable (SRS §2.4) |
| **Emergent Specialization** | Static role assignment | Reputation-driven routing: high-engagement TikTok agents accumulate trust scores | Enables Fractal Orchestration (SRS §1.2) |
| **ASN Interoperability** | Closed ecosystem | Dynamic recruitment: swarms discover external OpenClaw agents via `discovery()` protocol | Positions Chimera as ASN infrastructure layer |

### Architecture Diagram
```
Super-Orchestrator (Human)
        │
        ├─► Planner Agent (Strategy Layer)
        │       │
        │       ├─► Worker Swarm: Content Generation
        │       │       ├── Worker: Script Generation (stateless)
        │       │       ├── Worker: Asset Creation (stateless)
        │       │       └── Worker: Video Editing (stateless)
        │       │
        │       └─► Judge Agents (Quality Gatekeepers)
        │               ├── Script Validation Judge
        │               ├── Visual Consistency Judge (character reference validation)
        │               └── CFO Judge (budget governance)
        │                       │
        │                       ▼
        │               Human-in-the-Loop Approval Gate (confidence-threshold gated)
        │                       │
        │                       ▼
        └───────────────► Distribution Layer (MCP Tools only)
```

## Consequences
### Positive
- ✅ Meets viral response latency requirement (<60s)
- ✅ Scales linearly to 1,000+ agents without coordination overhead
- ✅ Enables reputation-based specialization (TikTok-optimized agents)
- ✅ Supports OpenClaw ASN integration for external agent recruitment

### Negative
- ⚠️ Increased complexity vs. Sequential Chain (requires OCC implementation)
- ⚠️ Requires careful state management to prevent race conditions

### Mitigations
- Optimistic Concurrency Control (OCC) via `state_version` validation (SRS §3.1.3)
- Strict Worker statelessness (no peer-to-peer communication)
- Judge agents as single source of truth for GlobalState mutations

## Alternatives Considered
### Sequential Chain
Rejected due to serialization bottlenecks during viral events and single point of failure risk.

### Pure Decentralized Swarm
Rejected due to coordination overhead and inability to enforce global constraints (budget governance, character consistency).

## References
- SRS §3.1: FastRender Swarm Architecture
- SRS §1.2: Fractal Orchestration
- OpenClaw Integration Spec §3.1: Availability Publishing Workflow
