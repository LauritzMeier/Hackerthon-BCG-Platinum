# ADK Agent (Firestore-Connected)

This folder contains a Google Cloud ADK agent configured to use Firestore project:

- `longevity-compass-firestore` (Firestore Native, region `eur3`)

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
