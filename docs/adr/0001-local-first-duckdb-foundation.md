# ADR-0001: Local-First DuckDB Foundation

- Status: Accepted
- Date: 2026-04-09

## Context

The challenge requires quick iteration on three local CSV datasets while still leaving behind a foundation that can survive beyond the hackathon.

The project needs:

- fast local querying
- easy reproducibility
- minimal operational setup
- clean integration with Python and a thin API

## Decision

Use a local-first stack with:

- raw CSV files in `data/raw/`
- DuckDB as the warehouse in `data/warehouse/longevity.duckdb`
- curated SQL models in `sql/marts.sql`
- Python scripts and a thin FastAPI layer for app consumption

## Consequences

- Local setup is simple and fast.
- Analytics and product payloads share one source of truth.
- The architecture is easy to refactor later into a cloud warehouse if needed.
- Multi-user production concerns are intentionally deferred.

## Alternatives Considered

- Postgres from day one
- notebook-only exploration without a warehouse
- full cloud data platform during hackathon phase

