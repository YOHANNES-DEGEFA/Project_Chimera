# ADR-002: MCP Integrity Constraint (Zero Direct API Calls)

**Status**: Accepted  
**Date**: 2026-02-07  
**Deciders**: Architecture Team  
**Tags**: architecture, mcp, security, constraints

## Context

Project Chimera agents need to interact with external platforms (TikTok, Instagram, YouTube, Ideogram, OpenAI) for content generation and distribution. Two approaches are possible:
1. **Direct API calls**: Agents call platform APIs directly (e.g., `requests.get("https://api.tiktok.com/...")`)
2. **MCP abstraction**: All external calls route through Model Context Protocol (MCP) Tools/Resources

Direct API calls create several problems:
- **Security**: API keys exposed to agent code, difficult to rotate
- **Rate Limiting**: No centralized enforcement, agents can exceed platform limits
- **Observability**: No unified logging/monitoring of external interactions
- **Testing**: Hard to mock external APIs in tests
- **Vendor Lock-in**: Tight coupling to platform-specific API formats

## Decision

Enforce **MCP Integrity Constraint**: **ZERO direct API calls**. ALL external interactions MUST route through MCP Tools/Resources.

This is a **hard constraint** (non-negotiable) per specs/_meta.md §3.

## Rationale

### Why MCP Abstraction?

1. **Security**: API keys stored in MCP Server configuration (secrets manager), never in agent code
2. **Rate Limiting**: Centralized enforcement at MCP Server layer (100 calls/minute per agent DID)
3. **Observability**: All external calls logged via MCP telemetry (Tenx Sense)
4. **Testing**: MCP Servers can be mocked for unit tests
5. **Vendor Flexibility**: Swap TikTok API for alternative without changing agent code
6. **Agent Containment**: Enforces security boundaries (agents cannot make arbitrary HTTP requests)

### Why Not Direct API Calls?

- **Security Risk**: API keys in code → exposed in Git, difficult to rotate
- **Rate Limit Violations**: Agents could exceed platform limits, causing account suspension
- **No Observability**: Cannot track which agents call which APIs
- **Tight Coupling**: Platform API changes break agent code

## Alternatives Considered

### Alternative 1: Direct API Calls with SDK Wrapper
- **Pros**: Simpler initial implementation, no MCP Server setup
- **Cons**: Security risks, no centralized rate limiting, tight coupling
- **Rejected**: Violates security and observability requirements

### Alternative 2: Hybrid (MCP for some, direct for others)
- **Pros**: Flexibility for "trusted" platforms
- **Cons**: Inconsistent patterns, security boundary violations
- **Rejected**: Creates ambiguity—which platforms use MCP? Violates principle of least privilege

## Consequences

### Positive
- **Security**: API keys never in agent code, centralized secrets management
- **Observability**: All external calls logged via MCP telemetry
- **Rate Limiting**: Centralized enforcement prevents platform account suspension
- **Testability**: MCP Servers can be mocked for unit tests
- **Vendor Flexibility**: Swap platforms without changing agent code

### Negative
- **Operational Overhead**: Must deploy and maintain MCP Servers for each platform
- **Latency**: Additional hop through MCP Server (minimal, ~10ms overhead)
- **Complexity**: Agents must learn MCP Tool calling patterns

### Mitigation
- Document MCP Tool schemas in .mcp/config.json (self-documenting)
- Provide MCP Server templates for common platforms
- Cache MCP Tool results in Redis to reduce latency

## Enforcement

### Code-Level
- **Linting Rule**: Static analysis detects direct HTTP calls (`requests.get`, `httpx.post`, etc.)
- **Runtime Check**: Agents run in sandboxed environment with network policy blocking non-MCP endpoints

### Specification-Level
- **Hard Constraint**: Documented in specs/_meta.md §3 (Hard Constraints)
- **Agent Rules**: .cursor/rules/agent.mdc enforces "NEVER make direct API calls"

### Testing
- **TDD Tests**: test_skills_interface.py validates skills use MCP Tools, not direct calls
- **Integration Tests**: Verify MCP Servers handle all platform interactions

## Compliance

- **SRS Reference**: Addresses SRS §3.2 (MCP Integration Layer)
- **Technical Spec**: Documented in specs/technical.md §1.1 (MCP Primitive Contracts)
- **Security Spec**: Enforced in specs/technical.md §4.5 (Agent Containment Boundaries)
