# Hackerthon-BCG-Platinum

Google-first longevity MVP direction with a fast local data prototyping foundation.

## What We Optimized For

- A slightly cleaner foundation that we can keep building after the hackathon
- Google-first target deployment with lightweight local iteration
- Flutter + Firebase + Cloud Run + Vertex AI as the chosen MVP stack
- A patient-facing journey only
- Fast access to the challenge CSVs through one local warehouse and one thin API layer

## Repo Shape

```text
data/
  raw/            # source CSVs copied into the repo
  warehouse/      # local DuckDB database
  exports/        # optional demo exports
docs/
  README.md
  product/
  architecture/
  adr/
apps/
  longevity_compass/
scripts/
  build_warehouse.py
  query_patient.py
sql/
  marts.sql
src/
  longevity_mvp/
    api.py
    config.py
    pipeline.py
    repository.py
agent/
  main.py         # ADK-backed coaching tools and startup wiring
  server.py       # FastAPI/SSE chat wrapper around the agent
```

## Recommended Architecture

1. Keep raw files immutable in `data/raw/`.
2. Build a local DuckDB warehouse into `data/warehouse/longevity.duckdb`.
3. Expose patient-facing curated tables:
   - `curated.patient_profile`
   - `curated.wearable_daily`
   - `curated.patient_metrics`
   - `curated.risk_flags`
   - `curated.offer_opportunities`
   - `curated.coach_context`
4. Use the warehouse directly for local analysis and payload design.
5. Treat Google Cloud as the target deployment architecture for mobile, web, and chatbot delivery.
6. Build the patient-facing app around one six-pillar Longevity Compass experience:
   - current state
   - future direction
   - weekly plan
   - coach chat
   - relevant offer

## Quick Start

Create a virtual environment and install the project:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Optional: store your local mobile defaults once so the run scripts can reuse them:

```bash
cp .env.example .env.local
```

Build the warehouse:

```bash
python3 scripts/build_warehouse.py
```

Inspect a patient bundle:

```bash
python3 scripts/query_patient.py PT0001
```

Run the API:

```bash
./scripts/run_api.sh
```

Set up Firebase for the Flutter app:

```bash
./scripts/setup_firebase.sh --project your-firebase-project-id
```

Publish the generated patient data into Firestore:

```bash
./scripts/sync_firestore.sh --project your-firebase-project-id
```

That script will also remember the Firebase project in `.env.local` unless you pass `--no-save`.
If `.env.local` contains `FIREBASE_PROJECT_ID`, the iOS and Android launch scripts will configure Firebase automatically on first launch when native config is still missing.

Run the app:

```bash
./scripts/run_ios.sh
./scripts/run_android.sh
./scripts/run_web.sh
```

Build and deploy the API prototype to Cloud Run with Cloud Build:

```bash
gcloud builds submit --config cloudbuild.yaml
```

## API Surface

- `GET /health`
- `GET /patients?limit=25`
- `GET /patients/{patient_id}`
- `GET /patients/{patient_id}/experience`
- `GET /patients/{patient_id}/timeline?days=30`
- `GET /patients/{patient_id}/flags`
- `GET /patients/{patient_id}/offers`
- `GET /patients/{patient_id}/compass`
- `GET /patients/{patient_id}/plan`
- `GET /patients/{patient_id}/coach`
- `POST /patients/{patient_id}/coach/reply`

## Notes

- The scaffold was validated locally with a `.venv` created in the repo root.
- The Flutter app lives in `apps/longevity_compass/` and now includes generated `ios/`, `android/`, and `web/` project shells.
- Flutter, Firebase CLI, FlutterFire CLI, and Google Cloud CLI are installed locally. Restart your terminal if `flutterfire` is not immediately available on your PATH.
- Android Studio, the Android SDK, platform tools, emulator tooling, and a default Android AVD are installed locally.
- `adb` and `emulator` are available in a fresh terminal session.
- Scripted entrypoints now live in `scripts/run_api.sh`, `scripts/setup_firebase.sh`, `scripts/sync_firestore.sh`, `scripts/run_android.sh`, `scripts/run_ios.sh`, and `scripts/run_web.sh`.
- The run/setup scripts auto-load `.env.local` when it exists, so you do not need to keep retyping your Firebase project or local API defaults.
- The documentation index lives in [docs/README.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/README.md).
- The product brief lives in [docs/product/brief.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/brief.md).
- The persona portfolio lives in [docs/product/personas.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/personas.md).
- The recurring user journeys live in [docs/product/journeys.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/journeys.md).
- The Longevity Compass concept lives in [docs/product/longevity-compass.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/longevity-compass.md).
- The Google-first target architecture lives in [docs/architecture/google-first-mvp.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/architecture/google-first-mvp.md).
- The chosen MVP stack is Flutter + Firebase + Cloud Run + Vertex AI, with Lovable available as an optional prototyping accelerator.
- Container builds now use the single root [Dockerfile](/Users/lauritz/git/Hackerthon-BCG-Platinum/Dockerfile).
- The contributor operating guide lives in [AGENT.MD](/Users/lauritz/git/Hackerthon-BCG-Platinum/AGENT.MD).
- Architectural decisions live in [docs/adr/README.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/adr/README.md).
