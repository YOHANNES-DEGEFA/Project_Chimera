# ADR-001: Hybrid Database Architecture

**Status**: Accepted  
**Date**: 2026-02-07  
**Deciders**: Architecture Team  
**Tags**: database, scalability, data-architecture

## Context

Project Chimera requires storing and querying multiple data types with distinct access patterns:
- **High-velocity video metadata**: 15,000+ writes/sec during viral events
- **Transactional campaign/wallet data**: ACID compliance required for financial operations
- **Semantic agent memories**: Vector search for persona consistency
- **Task queue coordination**: Sub-millisecond latency for swarm orchestration

A single database technology cannot efficiently handle all these workloads.

## Decision

Adopt a **hybrid database architecture**:
- **Apache Cassandra**: Video metadata (time-series, schema-less, linear scalability)
- **PostgreSQL**: Transactional data (campaigns, wallets, HITL reviews, ACID compliance)
- **Weaviate**: Semantic memory (vector embeddings, hybrid keyword+semantic search)
- **Redis**: Task queue and ephemeral cache (sub-millisecond latency, atomic operations)

## Rationale

### Why Not Single Database?

**PostgreSQL alone**: Cannot handle 15,000 writes/sec for video metadata without sharding complexity. Time-series queries are inefficient.

**Cassandra alone**: Lacks ACID transactions required for wallet operations. No native vector search.

**MongoDB alone**: Similar limitations—no native vector search, ACID transactions limited to single documents.

### Why This Hybrid?

1. **Cassandra for Video Metadata**:
   - TimeWindowCompactionStrategy automatically ages out frame-level tags
   - Composite partition key (agent_id, date_bucket) prevents hot partitions
   - Linear scalability: add nodes to increase write throughput

2. **PostgreSQL for Transactions**:
   - Row-Level Security (RLS) enforces multi-tenancy at database level
   - Budget governance triggers prevent overspending
   - ACID guarantees for wallet transactions

3. **Weaviate for Semantic Memory**:
   - Native vector search with hybrid keyword+semantic retrieval
   - Enables "vibe search" for persona consistency
   - Automatic embedding generation via text2vec-openai

4. **Redis for Coordination**:
   - Atomic operations for OCC state_version validation
   - Pub/Sub for event-driven swarm coordination
   - Sub-millisecond latency for task queue

## Alternatives Considered

### Alternative 1: PostgreSQL + TimescaleDB Extension
- **Pros**: Single database, familiar SQL interface
- **Cons**: Write throughput limited (~5,000 writes/sec), no native vector search
- **Rejected**: Cannot meet 15,000 writes/sec requirement for video metadata

### Alternative 2: MongoDB + Atlas Vector Search
- **Pros**: Document model fits evolving metadata, Atlas provides vector search
- **Cons**: No ACID transactions across documents, write throughput similar to PostgreSQL
- **Rejected**: Financial transactions require ACID guarantees

### Alternative 3: Single Vector Database (Pinecone/Weaviate) for Everything
- **Pros**: Unified query interface
- **Cons**: No ACID transactions, expensive for high-velocity writes, no time-series optimization
- **Rejected**: Cannot handle transactional and high-velocity workloads efficiently

## Consequences

### Positive
- Each database optimized for its workload (write throughput, query patterns, consistency requirements)
- Linear scalability for video metadata (Cassandra)
- Strong consistency for financial operations (PostgreSQL)
- Semantic search enables persona consistency (Weaviate)

### Negative
- **Operational Complexity**: Four databases to manage, monitor, and backup
- **Data Synchronization**: Cross-database queries require application-level joins
- **Cost**: Multiple database licenses/infrastructure costs
- **Migration Complexity**: Data lifecycle requires coordination across databases

### Mitigation
- Use Apache Flink for stream processing and cross-database enrichment
- Implement materialized views in PostgreSQL for common query patterns
- Use Redis as cache layer to reduce cross-database queries
- Document data flow diagrams in specs/technical.md §2.6

## Compliance

- **SRS Reference**: Addresses SRS §3.2 (Data Architecture)
- **Technical Spec**: Documented in specs/technical.md §2 (Database Architecture)
- **Migration Strategy**: Defined in specs/technical.md §2.6
