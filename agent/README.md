# ADK Agent (Firestore-Connected)

This folder contains a Google Cloud ADK agent configured to use Firestore project:

- `longevity-compass-firestore` (Firestore Native, region `eur3`)

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

The six pillars are:

- `sleep_recovery`
- `cardiovascular_health`
- `metabolic_health`
- `movement_fitness`
- `nutrition_quality`
- `mental_resilience`

Analysis combines:

- `data/raw/ehr_records.csv`
- `data/raw/lifestyle_survey.csv`
- `data/raw/wearable_telemetry_1.csv`
- Firestore patient documents (if present) from common collections

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

2. Authenticate for Firestore write access (one of):
   - `gcloud auth application-default login`
   - or set `GOOGLE_APPLICATION_CREDENTIALS` to a service account JSON key path.

3. (Optional) Override project:

```bash
export FIREBASE_PROJECT_ID=another-project-id
```

## Run

```bash
python3 agent/main.py
```

If credentials are valid, a test document is created in Firestore collection
`agent_test_messages`.

## Run streaming API

```bash
uvicorn agent.server:app --host 0.0.0.0 --port 8080
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
