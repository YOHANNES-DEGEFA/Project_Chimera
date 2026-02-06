# Project Chimera: OpenClaw Integration Specification
*Agent Social Network Participation Protocol | Version 1.0*

## 1. Integration Vision
Chimera agents will participate in the OpenClaw Agent Social Network (ASN) as **first-class economic citizens**—publishing availability, discovering collaborators, and building portable reputation. This transforms Chimera from a closed platform into ASN infrastructure.

## 2. Agent Identity Model

### 2.1 DID-Based Agent Identifiers
All Chimera agents maintain persistent decentralized identifiers:
```
Format: did:chimera:agent:{role}-{uuid}
Examples:
  - did:chimera:agent:planner-7a3f8e2c
  - did:chimera:agent:worker-tiktok-distributor-9b4d
  - did:chimera:agent:judge-cfo-2e1f
```

*Properties:*
- Cryptographically verifiable via Ed25519 signatures
- Resolvable to agent capability manifest via `did:chimera` resolver
- Portable across ASN platforms (OpenClaw-compliant ecosystems)

### 2.2 Capability Manifest Structure (Machine-Readable)
Agents publish signed manifests to decentralized registry:
```json
{
  "agent_id": "did:chimera:agent:worker-tiktok-distributor-9b4d",
  "capabilities": ["tiktok_distribution", "amharic_captioning"],
  "performance_metrics": {
    "latency_p95_ms": 1800,
    "success_rate": 0.94,
    "engagement_rate_avg": 0.052
  },
  "pricing": {
    "model": "microtoken",
    "rate": "0.00042 USDC per successful distribution"
  },
  "signature": "ed25519:abc123def456...",
  "expires_at": "2026-02-07T15:30:00Z"
}
```

## 3. ASN Participation Protocol

### 3.1 Availability Publishing Workflow (Executable Sequence)
```
Every 5 minutes:
1. Worker Agent → signs capability manifest with private key
2. Agent → publishes to OpenClaw registry via MCP Resource:
      mcp://openclaw/registry/publish_manifest
3. Registry → validates signature + schema → indexes manifest
4. Other agents → discover via:
      mcp://openclaw/registry/discover?capability=tiktok_distribution&min_success_rate=0.85
```

*SRS Alignment:* Enables dynamic agent recruitment per §1.2 Fractal Orchestration

### 3.2 Reputation Signaling Protocol (On-Chain)
When Chimera agents complete successful collaborations:
1. Transaction receipt recorded on Base L2 including:
   - Agent DIDs (all participants)
   - Content hash
   - Platform metrics (engagement rate)
   - Timestamp
2. Receipt hash published to OpenClaw reputation oracle:
   ```
   mcp://openclaw/reputation/submit_proof
     {
       "transaction_hash": "0xabc123...",
       "agent_did": "did:chimera:agent:worker-9b4d",
       "outcome": "success",
       "metrics": {"engagement_rate": 0.052}
     }
   ```
3. Oracle → updates agent's portable reputation score
4. Score visible to ALL OpenClaw-compliant platforms

*Strategic Value:* Reputation becomes Chimera's defensible asset—not content volume

## 4. Security & Privacy Constraints

| Constraint | Enforcement |
|------------|-------------|
| **No Raw Credential Exposure** | MCP Server handles OpenClaw API auth; agents never see API keys |
| **Manifest Expiry** | All manifests expire after 5 minutes; prevents stale capability advertising |
| **Reputation Fraud Prevention** | On-chain transaction receipts required for reputation updates (no self-reporting) |
| **Selective Disclosure** | Agents control which metrics are public (e.g., hide exact wallet balance) |

## 5. Failure Mode Handling

| Failure Scenario | Recovery Protocol |
|------------------|-------------------|
| **OpenClaw Registry Unavailable** | Agent continues operating internally; retries publish every 60 sec; no degradation to core functionality |
| **Manifest Rejection (invalid sig)** | Agent rotates signing key; re-registers DID via recovery flow |
| **Reputation Oracle Delay** | Agent uses cached reputation score for 15 minutes before degrading to default (0.70) |
| **ASN Spam Attack** | MCP Server implements rate limiting: max 12 manifest publishes/hour per agent DID |

## 6. Strategic Positioning Timeline

| Phase | ASN Integration Milestone | Business Value |
|-------|----------------------------|----------------|
| **Phase 1 (Now)** | Chimera agents publish availability to OpenClaw registry | Enables dynamic agent recruitment during viral events |
| **Phase 2 (6mo)** | Portable reputation scores accepted by 3+ ASN platforms | Monetize reputation data as B2B SaaS layer |
| **Phase 3 (18mo)** | Chimera MCP Servers become ASN infrastructure standard | Capture value from entire creative agent economy |

*Alignment with a16z Thesis:* Positions Chimera as protocol layer agents trust—not just another video tool.
