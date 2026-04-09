# ADR-0007: Longevity Compass As The Core Product Experience

- Status: Accepted
- Date: 2026-04-09

## Context

The product still needs a single, coherent concept that ties together personalization, regular engagement, chatbot usage, and monetization.

A generic dashboard is too passive.
A generic chatbot is too vague.
A generic prevention app is too broad.

## Decision

Anchor the MVP around a Longevity Compass concept.

The compass answers four questions for the user:

- where am I now
- where am I heading
- what should I do next
- what support is relevant now

The compass is organized around six pillars:

- sleep and recovery
- cardiovascular health
- metabolic health
- movement and fitness
- nutrition quality
- mental resilience

The chatbot becomes the conversational interface to this compass rather than a standalone feature.

All major user-facing outputs should derive from the compass:

- weekly plans
- nudges
- risk alerts
- coach prompts
- diagnostics recommendations
- premium or subscription offers

## Consequences

- The product gets a stronger story for both user value and demo clarity.
- Journeys, screens, and monetization can all orbit one concept.
- Future scenario modeling becomes easier to add later.
- Product and data work now need to support current state, trajectory, and next-best action logic.

## Alternatives Considered

- dashboard-first experience
- chatbot-first experience
- generic coaching app without a unifying concept
