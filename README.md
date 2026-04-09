# Hackerthon-BCG-Platinum

Local-first data foundation for the BCG Platinion longevity MVP challenge.

## What We Optimized For

- A slightly cleaner foundation that we can keep building after the hackathon
- A patient-facing journey only
- Fast access to the challenge CSVs through one local warehouse and one thin API layer

## Repo Shape

```text
data/
  raw/            # source CSVs copied into the repo
  warehouse/      # local DuckDB database
  exports/        # optional demo exports
docs/
  challenge-summary.md
  personas.md
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
4. Use the warehouse directly for analysis and a thin FastAPI app for the MVP frontend.

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
- The challenge brief summary and remaining product questions live in [docs/challenge-summary.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/challenge-summary.md).
- The persona portfolio lives in [docs/personas.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/personas.md).
- The contributor operating guide lives in [AGENT.MD](/Users/lauritz/git/Hackerthon-BCG-Platinum/AGENT.MD).
- Architectural decisions live in [docs/adr/README.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/adr/README.md).
