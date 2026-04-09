# Google-First MVP Architecture

## Purpose

This document defines the Google-first target architecture for the hackathon MVP and near-term evolution.

The architect review on April 9, 2026 refined that direction into a more specific split:

- the mobile app can talk directly to Firebase for lightweight MVP state
- the agent runtime should still live behind a backend container on Cloud Run
- relational and analytical context should stay outside Firestore and be read via backend tools
- the primary user journey should be chat-first rather than screen-first

Local DuckDB remains useful for rapid prototyping, but the primary deployment direction is Google-native because:

- Google is sponsoring the hackathon
- the product needs a credible hosted story
- the app includes a chatbot and regular user engagement flows
- managed services reduce infrastructure overhead

Within that Google-first approach, Firebase should be the primary application platform for the MVP.

## Architecture Principles

- Google-first for target deployment
- Firebase-first for the app experience layer
- Flutter-first for the primary client application layer
- chat-first for the primary interaction model
- split direct app state from backend agent orchestration
- mobile and web friendly from day one
- chatbot-safe by design
- support recurring engagement, not only a static demo
- preserve a clean path from hackathon MVP to real rollout
- prefer Google-managed connectors and runtimes before custom integration code

## Chosen MVP Stack

The current chosen MVP stack is:

- Flutter
- Firebase
- Cloud Run
- ADK on Cloud Run
- BigQuery
- Vertex AI

This should be treated as the default implementation direction unless we explicitly record a new ADR.

## Recommended Stack

### Firebase Platform Layer

Firebase should be the default platform layer for the MVP:

- Firebase Hosting for the Flutter web companion experience
- Firebase Authentication for sign-in
- Cloud Firestore for app state, chat state, goals, and lightweight coach session state
- Firebase Cloud Messaging for notifications and re-engagement
- Firebase Analytics for product measurement
- Firebase Remote Config for controlled tuning of prompts, nudges, and experiments
- Firebase Crashlytics for mobile reliability

This gives us one coherent app platform across iOS, Android, and web.

### Frontend

- Flutter is the chosen client stack for iOS, Android, and the companion web experience
- Firebase Hosting is the default delivery path for Flutter Web
- Firebase App Hosting should only be considered later if we introduce a separate framework-based web surface

### Mobile

- Flutter is the chosen client stack for the MVP
- Flutter gives us one codebase for iOS and Android and may also support selected web reuse
- native mobile apps remain possible later, but are not the recommended MVP path

### Authentication

- Firebase Authentication

Recommended sign-in order:

1. Email-based sign-in for broad accessibility
2. Google sign-in as optional convenience

### Backend

- Cloud Run for APIs and agent orchestration

Use Cloud Run for:

- agent runtime and ADK runner host
- REST interface for agent execution
- patient data APIs
- six-pillar score and trajectory calculation services
- chatbot orchestration
- offer recommendation logic
- writes or mutations that should not come directly from the client

### Agent Runtime

The architect discussion points to a Python-first ADK runtime on Cloud Run:

- define the main coach agent in Python
- expose the agent through the ADK runner or REST wrapper
- treat the agent as a backend service, not a client-side SDK concern
- use Vertex AI as the model endpoint behind the agent

Preferred tool shapes:

- Python functions for Firestore updates and product actions
- OpenAPI-backed tools when an existing API already exists
- MCP-backed tools when connector reuse is faster than writing custom wrappers

Default model choice:

- Gemini on Vertex AI, with Gemini Flash as the default MVP starting point

### Data Layer

- BigQuery for cloud analytical tables, wearable and clinical context, pillar state tables, and trajectory features
- Firestore for app state, chat threads, goals, plans, and lightweight realtime product state
- Cloud Storage for raw files, exports, and supporting assets

Optional managed retrieval layer:

- Google Cloud AI Applications data stores or equivalent managed datastore-backed retrieval over BigQuery exports when we want low-custom-code RAG

### Engagement And Measurement

- Firebase Cloud Messaging for cross-platform notifications and re-engagement
- Firebase Analytics for funnel and retention measurement
- Firebase Remote Config for tuning copy, nudges, and journey variations without a full redeploy
- Firebase Crashlytics for stability monitoring on mobile

### AI Layer

- Vertex AI for the coach or chatbot

Use Vertex AI for:

- explaining compass changes and six-pillar interactions
- generating tailored weekly plans
- answering user questions
- converting flags into understandable action
- serving the model used by the ADK-hosted agent

Use Firestore and BigQuery through tools rather than feeding raw tables straight into prompts:

1. Firestore-backed product state and conversation state
2. BigQuery-backed analytical and relational context
3. optional managed datastore or RAG endpoint over BigQuery-derived content
4. internal product or evidence content
5. optional public grounding only for non-patient-specific wellness explanations

### Interaction Pattern

The architect recommendation is a split interaction model:

1. Flutter app talks directly to Firestore through the Firebase SDK for lightweight MVP state
2. Flutter app talks to Cloud Run over REST for agent execution and protected business logic
3. Cloud Run agent service reads Firestore for current state and BigQuery for relational context
4. Cloud Run agent service calls Vertex AI for reasoning
5. Agent tools write back to Firestore when goals, timeline items, or chat state need to change

This is intentionally not a pure backend-for-frontend design.
The app should not wait on Cloud Run for every simple state read when Firestore can handle it directly.

### Operations

- Secret Manager
- Cloud Logging
- Cloud Monitoring
- Cloud Scheduler and Cloud Run Jobs

## Lovable Positioning

Lovable can be used as a rapid product-design and web-prototyping accelerator.

Recommended use:

- quick concept exploration
- UI idea generation
- landing-page or web-flow prototyping
- fast experimentation for non-core surfaces

Not recommended as the core system architecture for this MVP because our chosen implementation stack is Flutter plus Firebase plus Cloud Run plus Vertex AI.

In short:

- use Lovable to accelerate exploration
- keep Flutter and Firebase as the real product foundation

## Topology

```mermaid
flowchart LR
    M["Flutter Mobile App"] --> FS["Firestore via Firebase SDK"]
    W["Flutter Web Companion"] --> FS
    M --> API["Cloud Run Agent / API Container"]
    W --> API
    API --> FS
    API --> BQ["BigQuery"]
    BQ --> RAG["AI Applications Datastore / RAG (optional)"]
    API --> RAG
    API --> VAI["Vertex AI / Gemini"]
    API --> GCS["Cloud Storage"]
    JOBS["Cloud Scheduler / Cloud Run Jobs"] --> API
    API --> OBS["Cloud Logging / Cloud Monitoring"]
```

## Why This Fits The Problem Statement

The brief describes a client that is losing the patient interface to more engaging digital players while sitting on fragmented data.

This architecture fits that problem because it supports:

- a consumer-grade mobile and web experience
- a chat-first interaction model for the core journey
- a Firebase-centered app platform that is strong for mobile and web delivery
- a Flutter-first mobile delivery model for regular usage
- a six-pillar compass as the central product object
- fast iteration on personalized journeys
- hosted chatbot functionality
- managed services instead of heavy infrastructure operations
- a believable 12-month launch path

## Local Versus Cloud

Keep both of these ideas true:

- local DuckDB remains the fastest place to prototype data logic
- Firebase is the primary app platform for hosted MVP delivery
- Google Cloud is the primary target for hosted MVP deployment

That means DuckDB is now a development convenience, while Firebase plus Google Cloud form the real MVP architecture story.

## Current Implementation Slice

The current repo should support this path:

1. Local DuckDB for rapid data and payload iteration
2. FastAPI for current app-facing APIs and transition-friendly backend logic
3. Flutter app source checked into `apps/longevity_compass/`
4. Firebase for authentication, analytics, notifications, crash monitoring, and direct Firestore-backed app state
5. Cloud Run as the deployment target for the Python API and future ADK runner service
6. BigQuery as the target hosted store for relational and analytical context used by the agent
7. Vertex AI as the target model endpoint behind the agent

The Flutter app can be scaffolded in source form before generated platform folders are added. Once the Flutter toolchain is available, run `flutter create . --platforms=ios,android,web` inside the app directory to generate the platform shell around the checked-in app code.

## Recommended Build Sequence

1. Finalize primary persona, journey, and monetization model
2. Finalize the Longevity Compass product slice
3. Use local data and APIs to validate payloads and logic
4. Define the Firestore chat, goal, and timeline data model
5. Finalize six-pillar compass payloads and trajectory logic
6. Build the core Flutter app for iOS and Android
7. Let the app read and write lightweight MVP state through Firebase SDK plus Firestore
8. Move hosted APIs and the ADK runtime to Cloud Run
9. Move cloud analytical tables to BigQuery
10. Add Vertex AI coach orchestration and ADK tools
11. Add optional managed RAG over BigQuery-derived content if retrieval quality becomes important
12. Use Lovable only if it helps accelerate selected web or concept flows

## MVP Tradeoffs

This architecture intentionally accepts some MVP shortcuts:

- direct app-to-Firestore access is faster to ship than routing every action through backend validation
- Firestore is not the analytical source of truth for wearable or clinical data
- agent writes should still be routed through backend tools, not granted as arbitrary client privileges

Before any production hardening pass, we should tighten:

- Firestore security rules and validation boundaries
- which writes are allowed directly from the client
- auditability of agent actions
- separation between user-facing product state and analytical or medical source data

## Official Google References

- [Firebase for Flutter](https://firebase.google.com/docs/flutter)
- [Firebase App Hosting](https://firebase.google.com/docs/app-hosting)
- [Firebase Authentication](https://firebase.google.com/docs/auth/)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Google Analytics for Firebase](https://firebase.google.com/docs/analytics)
- [Firebase Remote Config](https://firebase.google.com/docs/remote-config)
- [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)
- [Cloud Run](https://cloud.google.com/run)
- [BigQuery](https://cloud.google.com/bigquery?hl=com)
- [Cloud Storage](https://cloud.google.com/storage/docs/objects)
- [Vertex AI Overview](https://docs.cloud.google.com/vertex-ai/docs/start/introduction-unified-platform)
- [Cloud Monitoring](https://docs.cloud.google.com/monitoring/docs)

## Optional Prototyping Reference

- [Lovable Documentation](https://docs.lovable.dev/)
