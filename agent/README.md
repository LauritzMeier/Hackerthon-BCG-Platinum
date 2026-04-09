# ADK Agent Service

This folder contains the Google Cloud ADK-backed coaching service.
It reads `FIREBASE_PROJECT_ID` from `.env.local` or the surrounding environment,
and it can target a named Firestore database through `FIRESTORE_DATABASE_ID`.

## Capabilities

The agent exposes tools for:

- writing a startup and manual test message to Firestore
- analyzing all six longevity pillars for a given patient id
- explaining one specific pillar in plain language with key signals
- generating a tailored coaching explanation package with:
  - evidence-backed claims
  - trade-offs
  - next-best actions
  - required safety guardrails and uncertainty language
- reading patient-tailored support offers from Firestore
- matching support offers to chat requests using `patient_experiences` and `offer_catalog`
- remembering the last proposed offer so a later "book it" can be resolved
- creating `support_bookings` records with the same shape the Flutter UI reads

The six pillars are:

- `sleep_recovery`
- `cardiovascular_health`
- `metabolic_health`
- `movement_fitness`
- `nutrition_quality`
- `mental_resilience`

Analysis combines:

- curated warehouse fields aligned to [sql/schema_reference.sql](/home/tengen/Code/Hackerthon-BCG-Platinum/sql/schema_reference.sql)
- especially `curated.patient_profile`, `curated.patient_metrics`, and `curated.coach_context`
- Firestore patient documents (if present) from the overview-driven agent collections
- support offer data from Firestore collections:
  - `patient_experiences`
  - `offer_catalog`
  - `coach_conversations`
  - `support_bookings`

## Lazy-seed Firestore for the agent

From repo root (requires local warehouse built and Firebase credentials):

```bash
python3 scripts/seed_agent_firestore.py --project YOUR_PROJECT_ID --patient-id PT0001
```

- Writes one document per collection (`patients`, `longevity_data_overview`, `pillar_mappings`, `actionable_opportunities`, `engagement_queries`) with **document id = patient id**.
- The Firestore shape mirrors [data/data_overview.md](/home/tengen/Code/Hackerthon-BCG-Platinum/data/data_overview.md) and uses the naming from [sql/schema_reference.sql](/home/tengen/Code/Hackerthon-BCG-Platinum/sql/schema_reference.sql) for warehouse-backed fields.
- **Lazy default:** skips any document that already exists; use `--force` to overwrite.
- `--dry-run` prints planned writes without touching Firestore.
- Omit `--patient-id` to seed the first `--limit` patients from the warehouse (default 25).

## What happens first

When `main.py` loads, it immediately writes a startup test document to:

- collection: `agent_test_messages`

This verifies connectivity before the agent handles prompts.

## Setup

1. Install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r agent/requirements.txt
```

2. Copy the local env template if you have not done it yet:

```bash
cp .env.example .env.local
```

3. Authenticate for Firestore write access (one of):
   - `gcloud auth application-default login`
   - or set `GOOGLE_APPLICATION_CREDENTIALS` to a service account JSON key path.

4. Confirm the Firebase project and Firestore database in `.env.local`:

```bash
FIREBASE_PROJECT_ID=your-firebase-project-id
FIRESTORE_DATABASE_ID=longevity-compass-firestore
```

## Run

```bash
python3 -m agent.main
```

If credentials are valid, a test document is created in Firestore collection
`agent_test_messages`.

## Run streaming API

```bash
uvicorn agent.server:app --host 0.0.0.0 --port 8080
```

## Container

Build from the repo root. The repo now uses a single Dockerfile:

```bash
docker build -t longevity-compass .
docker run --rm -p 8080:8080 longevity-compass
```

### Endpoints (single central chat)

- `POST /chat` returns a full response payload (batch)
- `POST /chat/stream` streams SSE deltas for real-time feedback

The UI should use only one chat surface. The backend routes internally:

- general chat questions -> coach response
- pillar-related questions -> automatic pillar analysis/explanation with evidence

Example stream call:

```bash
curl -N -X POST http://127.0.0.1:8080/chat/stream \
  -H "Content-Type: application/json" \
  -d '{"patient_id":"PT0001","message":"How is my sleep pillar doing?"}'
```

## Infrastructure as Code for deployment

Use the repo scripts so IAM and runtime config are reproducible and not manual.

1) Bootstrap service account + cross-project Firestore IAM:

```bash
./scripts/bootstrap_agent_infra.sh \
  ai-hack26ham-435 \
  ai-hack26ham-435 \
  europe-west1 \
  longevity-agent-sa
```

2) Deploy the agent with fixed runtime identity + env vars:

```bash
./scripts/deploy_agent.sh \
  ai-hack26ham-435 \
  ai-hack26ham-435 \
  europe-west1 \
  longevity-agent \
  longevity-agent-sa \
  "longevity-compass-firestore"
```

3) Verify health, batch chat, and stream chat:

```bash
./scripts/verify_agent.sh \
  https://longevity-agent-102290354167.europe-west1.run.app \
  PT0001
```

## Debug flags and diagnostics

Enable verbose runtime diagnostics in Cloud Run:

```bash
--set-env-vars AGENT_DEBUG=true
```

Additional targeted flags:

```bash
--set-env-vars AGENT_DEBUG_FIRESTORE=true,AGENT_DEBUG_CHAT=true
```

With debug enabled:

- logs include resolved Firestore project/database during client initialization
- Firestore lookups capture `lookup_status`, `failure_stage`, per-collection read attempts, and exception details
- `/chat` and `/chat/stream` can return top-level debug payloads when `include_debug=true` or `AGENT_DEBUG_CHAT=true`
- `GET /debug/runtime` returns non-secret env wiring diagnostics
- `GET /debug/firebase/{patient_id}` returns patient-scoped Firestore lookup diagnostics

For the verification script, enable debug output with:

```bash
AGENT_VERIFY_DEBUG=1 ./scripts/verify_agent.sh https://your-service-url PT0001
```
