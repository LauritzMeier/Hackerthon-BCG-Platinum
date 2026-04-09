# ADR-0002: Patient-Facing MVP Scope

- Status: Accepted
- Date: 2026-04-09

## Context

The challenge brief could support multiple interfaces, including internal clinician tooling, analytics dashboards, and patient engagement products.

Trying to cover all of them at once would dilute the MVP and make product decisions less coherent.

## Decision

Focus the first MVP on a patient-facing journey only.

The system should prioritize:

- personalized coaching
- risk and opportunity flags
- relevant preventive offers
- simple API payloads for a patient app

Internal operational or clinician-facing experiences are explicitly out of scope for the first version.

## Consequences

- Product decisions can stay tightly aligned with one user.
- Data payloads can optimize for app consumption rather than internal reporting.
- Clinician workflows, care team escalation, and back-office tooling are deferred.

## Alternatives Considered

- dual patient and clinician MVP
- clinician-first workflow
- analytics-first proof of concept

