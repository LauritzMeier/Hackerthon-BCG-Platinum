# ADR-0006: Google-First MVP Architecture

- Status: Accepted
- Date: 2026-04-09

## Context

The hackathon sponsor context makes Google tooling a natural fit for hosting and AI capabilities.

The problem statement also emphasizes that the client is losing the patient interface to stronger digital players while operating with fragmented data and under a 12-month launch mandate.

The solution also needs:

- a credible deployment story
- consumer-grade mobile and web delivery
- fast iteration
- managed services where possible
- support for an AI coach and regular user engagement

The repo currently uses a local DuckDB setup for fast prototyping, which is still useful during the early product phase.

## Decision

Use a Google-first target architecture for the MVP:

- Flutter as the primary client stack
- Firebase as the core app platform layer
- Firebase Hosting for the Flutter web app
- Firebase Authentication for sign-in
- Cloud Firestore for app state
- Firebase Cloud Messaging for re-engagement
- Firebase Analytics, Remote Config, and Crashlytics for measurement and app operations
- Cloud Run for backend services
- BigQuery for cloud analytics tables
- Vertex AI for the AI coach or chatbot
- Cloud Storage for raw files and evidence assets
- Secret Manager, Cloud Logging, and Cloud Monitoring for operations

Lovable is allowed as a rapid prototyping accelerator for selected web or concept surfaces, but it is not the core application architecture.

Keep DuckDB locally as the fastest development environment until the product flow stabilizes.

## Consequences

- The architecture is easier to present in a sponsor-aligned story.
- The stack supports mobile and web hosting needs plus engagement and AI needs without heavy infrastructure work.
- The path from prototype to cloud-hosted MVP becomes clearer.
- Flutter now becomes the default delivery path for the primary user experience.
- The project now has a dual-track architecture:
  local for rapid iteration, Google-native for deployment.

## Alternatives Considered

- staying entirely local and deferring cloud decisions
- non-Google hosting despite sponsor context
- moving fully to cloud analytics immediately and losing iteration speed
