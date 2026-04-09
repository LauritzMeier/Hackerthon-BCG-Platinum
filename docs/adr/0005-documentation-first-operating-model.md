# ADR-0005: Documentation-First Operating Model

- Status: Accepted
- Date: 2026-04-09

## Context

The project is still at an early stage and risks drifting into implementation before the goals, journeys, and business logic are stable.

Without explicit discipline, the team can easily create:

- stale docs
- duplicated assumptions
- premature feature work
- weak handoffs between contributors and agents

## Decision

Adopt a documentation-first operating model.

Before every substantial task, contributors should:

- clean or reconcile relevant documentation
- confirm the source of truth
- verify that the task fits the documented goals

Feature implementation should not meaningfully advance ahead of:

- documented goals
- documented user journeys
- documented monetization path
- documented architecture tradeoffs

## Consequences

- The repo stays easier to understand.
- Product work becomes more coherent.
- There is more upfront discipline before coding.
- Some tasks will feel slower at first, but rework risk is reduced.

## Alternatives Considered

- implementation-first workflow
- documentation only at milestone boundaries
- leaving documentation cleanup as optional

