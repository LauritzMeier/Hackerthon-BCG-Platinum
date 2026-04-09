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

## Quick Start

Create a virtual environment and install the project:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
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
uvicorn longevity_mvp.api:app --reload --app-dir src
```

## API Surface

- `GET /health`
- `GET /patients?limit=25`
- `GET /patients/{patient_id}`
- `GET /patients/{patient_id}/timeline?days=30`
- `GET /patients/{patient_id}/flags`
- `GET /patients/{patient_id}/offers`

## Notes

- The scaffold was validated locally with a `.venv` created in the repo root.
- The documentation index lives in [docs/README.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/README.md).
- The product brief lives in [docs/product/brief.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/brief.md).
- The persona portfolio lives in [docs/product/personas.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/personas.md).
- The recurring user journeys live in [docs/product/journeys.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/journeys.md).
- The Longevity Compass concept lives in [docs/product/longevity-compass.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/longevity-compass.md).
- The Google-first target architecture lives in [docs/architecture/google-first-mvp.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/architecture/google-first-mvp.md).
- The chosen MVP stack is Flutter + Firebase + Cloud Run + Vertex AI, with Lovable available as an optional prototyping accelerator.
- The contributor operating guide lives in [AGENT.MD](/Users/lauritz/git/Hackerthon-BCG-Platinum/AGENT.MD).
- Architectural decisions live in [docs/adr/README.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/adr/README.md).
