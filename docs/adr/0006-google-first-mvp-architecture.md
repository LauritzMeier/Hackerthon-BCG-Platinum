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
- a realistic path to a chat-first experience without building heavy custom middleware first

The repo currently uses a local DuckDB setup for fast prototyping, which is still useful during the early product phase.

An architect review on April 9, 2026 also refined the desired runtime split:

- the app can talk directly to Firebase plus Firestore for lightweight MVP state
- the agent runtime should still sit behind a backend container
- relational context should not be forced into Firestore
- Google-managed agent and retrieval primitives should be preferred over custom glue code

## Decision

Use a Google-first target architecture for the MVP:

- Flutter as the primary client stack
- Firebase as the core app platform layer
- Firebase Hosting for the Flutter web app
- Firebase Authentication for sign-in
- Cloud Firestore for app state, chat state, goals, and timeline state
- Firebase Cloud Messaging for re-engagement
- Firebase Analytics, Remote Config, and Crashlytics for measurement and app operations
- direct Firebase SDK plus Firestore access from the app is acceptable for lightweight MVP state
- Cloud Run for backend services and the ADK-hosted agent runtime
- Python as the default agent implementation language because ADK support is strongest there
- ADK runner or REST wrapper as the standard agent-facing interface
- BigQuery for cloud analytics tables and relational context used by the agent
- optional AI Applications datastore or equivalent managed retrieval layer over BigQuery-derived content
- Vertex AI for the AI coach or chatbot and as the default model endpoint behind the agent
- Gemini Flash as the default model choice unless a better fit is recorded
- Cloud Storage for raw files and evidence assets
- Secret Manager, Cloud Logging, and Cloud Monitoring for operations

Use this responsibility split by default:

- app to Firestore for lightweight product state
- app to Cloud Run over REST for agent access and protected logic
- Cloud Run agent service to Firestore for stateful updates
- Cloud Run agent service to BigQuery for relational and analytical reads

Lovable is allowed as a rapid prototyping accelerator for selected web or concept surfaces, but it is not the core application architecture.

Keep DuckDB locally as the fastest development environment until the product flow stabilizes.

## Consequences

- The architecture is easier to present in a sponsor-aligned story.
- The stack supports mobile and web hosting needs plus engagement and AI needs without heavy infrastructure work.
- The path from prototype to cloud-hosted MVP becomes clearer.
- Flutter now becomes the default delivery path for the primary user experience.
- The project now has a dual-track architecture:
  local for rapid iteration, Google-native for deployment.
- The MVP gets a faster path because basic app state can skip a full backend-for-frontend layer.
- The architecture becomes explicitly chat-first, not just API-first.
- Firestore stays a product-state store, while BigQuery becomes the place for relational and analytical context.
- The MVP accepts weaker validation on direct client writes unless rules and backend boundaries are tightened later.

## Alternatives Considered

- staying entirely local and deferring cloud decisions
- non-Google hosting despite sponsor context
- moving fully to cloud analytics immediately and losing iteration speed
- forcing every app action through backend APIs from day one
