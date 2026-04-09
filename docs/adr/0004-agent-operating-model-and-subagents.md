# ADR-0004: Agent Operating Model And Subagents

- Status: Accepted
- Date: 2026-04-09

## Context

The repo will likely be touched by multiple humans and AI agents across product, data, backend, and demo work.

Without an explicit operating model, the team risks:

- duplicated work
- undocumented decisions
- inconsistent quality bars
- unclear boundaries between product and implementation

## Decision

Establish `AGENT.MD` as the operational guide for contributors.

Define named specialist subagent roles for:

- persona strategy
- journey design
- data architecture
- backend delivery
- coach safety review
- demo storytelling

Require durable architecture and product choices to be documented as ADRs in `docs/adr/`.

## Consequences

- Future work can be routed more consistently.
- Product and engineering choices become easier to revisit and audit.
- The team gets a foundation for parallel agent work later if needed.

## Alternatives Considered

- no shared agent guide
- one generic agent role for every task
- undocumented decisions captured only in chat threads
