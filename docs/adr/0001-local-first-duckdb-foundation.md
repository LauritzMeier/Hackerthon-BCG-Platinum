# ADR-0001: DuckDB As Local Prototyping Foundation

- Status: Accepted
- Date: 2026-04-09

## Context

The project needs very fast local iteration on three CSV datasets while product direction is still moving.

At the same time, the deployment direction is now Google-first, so DuckDB is no longer the primary architecture story for production.

The project still needs:

- fast local querying
- easy reproducibility
- minimal operational setup
- clean integration with Python and a thin API

## Decision

Use DuckDB as the local prototyping and development warehouse with:

- raw CSV files in `data/raw/`
- DuckDB as the warehouse in `data/warehouse/longevity.duckdb`
- curated SQL models in `sql/marts.sql`
- Python scripts and a thin FastAPI layer for app consumption

## Consequences

- Local setup is simple and fast.
- Analytics and product payloads share one prototyping source of truth.
- Cloud deployment architecture is handled separately in ADR-0006.
- Multi-user production concerns remain intentionally deferred in the local stack.

## Alternatives Considered

- Postgres from day one
- notebook-only exploration without a warehouse
- full cloud data platform during hackathon phase
