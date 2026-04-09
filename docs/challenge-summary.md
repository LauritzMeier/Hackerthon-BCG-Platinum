# Challenge Summary

## Brief Summary

The challenge is to help a large European healthcare group launch a patient-facing longevity product within 12 months.

The business problem is not just data storage. It is the translation of fragmented health data into:

- personalized longevity coaching
- early risk and opportunity flagging
- relevant commercial touchpoints such as diagnostics or nutrition offers

## Must-Haves From The Brief

- Define a clear patient persona
- Map a longevity journey from awareness to daily engagement
- Ground the MVP in at least 3 user stories
- Pick one north star metric for year-one patient success
- Include an AI coach with evidence-grounded recommendations
- Surface risk and opportunity flags with actionable interventions
- Show in-app commercial touchpoints without breaking the care experience

## Data We Have

- `ehr_records.csv`: 1,000 patients, one row per patient
- `lifestyle_survey.csv`: 1,000 patients, latest self-reported lifestyle snapshot
- `wearable_telemetry_1.csv`: 90 daily rows per patient, 90,000 rows total

All three datasets join cleanly on `patient_id`.

## Selected Infrastructure Decisions

- Slightly cleaner local foundation instead of a one-off hackathon script
- Patient-facing journey only for the first MVP
- Raw challenge files copied into `data/raw/`
- DuckDB as the local analytics and serving warehouse
- FastAPI as the thin app-facing layer

Related docs:

- Persona library: [docs/personas.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/personas.md)
- Agent guide: [AGENT.MD](/Users/lauritz/git/Hackerthon-BCG-Platinum/AGENT.MD)
- ADR index: [docs/adr/README.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/adr/README.md)

## What The Curated Layer Should Enable

- Fast lookup of any patient profile
- Fast retrieval of daily wearable history
- One place for starter longevity scores and heuristics
- Rule-based risk flags we can later enrich with model logic
- Rule-based upsell or engagement opportunities for the app
- A compact context object the AI coach can consume

## Remaining Product Questions

- Which patient persona should we optimize first?
  Example: cardio-risk middle-aged professional, stressed parent, or health-conscious high-performer
- What should the north star metric be for the MVP?
  Example: weekly active users, coaching adherence, completed diagnostics, or risk reduction proxy
- Which commercial touchpoints are in scope first?
  Example: preventive check-up, blood panel, sleep package, nutrition consult
- How cautious should the first coach be?
  Example: insight and nudges only, or more directive recommendation language
