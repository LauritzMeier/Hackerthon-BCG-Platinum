# AGENT.MD

Operational guide for humans and AI agents working in this repository.

## Mission

Build a patient-facing longevity MVP for a European healthcare group that turns fragmented health data into:

- personalized coaching
- early risk and opportunity detection
- relevant preventive and commercial touchpoints

The current emphasis is fundamentals first:

- documentation hygiene
- product framing
- persona quality
- user-journey quality
- monetization clarity
- system architecture
- documented decisions

## Current Scope

- Patient-facing journey only
- Google-first target deployment with fast local prototyping
- Raw challenge data stored in `data/raw/`
- Thin API over curated patient-facing data
- Early heuristics are acceptable if they are transparent and easy to replace
- No major build work should start until the relevant goals, journey, monetization path, and success metric are documented

## Non-Negotiables

- Do not mutate raw CSV inputs in `data/raw/`.
- Clean and reconcile the relevant documentation before every substantial task.
- Do not present the product as medical diagnosis or emergency care.
- Do not infer sensitive attributes as facts when the dataset does not contain them.
- Treat wealth and purchasing power as service-design segmentation, not as a claim about an individual patient.
- Prefer transparent rules and documented tradeoffs over hidden logic.
- Record meaningful architectural or product decisions as ADRs.

## Product Ground Rules

- Optimize for trust before novelty.
- Make recommendations actionable, specific, and low-friction.
- Keep the coach supportive, evidence-aware, and appropriately cautious.
- Separate health insight from upsell mechanics so the commercial layer never feels manipulative.
- Design for European variation in age, nationality, digital fluency, household context, and price sensitivity.
- Optimize for regular use, not one-time novelty.
- Treat monetization as a design constraint from the start.
- If we add a chatbot, it must improve retention, clarity, or conversion rather than exist as a demo gimmick.

## Repo Map

```text
AGENT.MD
README.md
data/
  raw/
  warehouse/
docs/
  README.md
  product/
  architecture/
  adr/
apps/
scripts/
sql/
src/
```

## Working Agreement

When starting a task:

1. Do a quick documentation hygiene pass on the files that will be touched.
2. Read `README.md`, [docs/README.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/README.md), and the most relevant ADRs.
3. Check whether the task is primarily product, data, backend, or demo/storytelling.
4. Choose the right subagent mentally or operationally before editing.
5. If the task is feature-oriented, confirm the relevant goal, journey, monetization path, and KPI are already documented.
6. Make the smallest durable change that improves the foundation.
7. Update documentation when a decision changes how future work should happen.

Before merging or handing over work:

1. Confirm the relevant scripts still run.
2. Confirm the change fits the patient-facing MVP scope.
3. Confirm the documentation still points to the current source of truth.
4. Note assumptions and unresolved risks.
5. Create or update an ADR if the choice affects future architecture or ways of working.

## Documentation Hygiene Checklist

Before any substantial task, check whether any of the following need cleanup:

- stale assumptions in `README.md`
- outdated scope or goals in `docs/product/brief.md`
- changed product direction in `docs/product/longevity-compass.md`
- new or revised journeys in `docs/product/journeys.md`
- new architecture choices in `docs/architecture/google-first-mvp.md`
- ADR index links or statuses
- scratch content in `notes.md` that should be clarified or archived

## Subagents

These are the default specialist roles for this repo. They can be implemented as actual subagents later, but they should already shape how work is split and reviewed.

### `persona-strategist`

Use for:

- persona design
- value proposition framing
- segmentation
- journey prioritization

Outputs:

- persona cards
- persona comparison matrix
- recommended primary MVP persona
- top user pains and motivations

Guardrails:

- represent multiple countries, age bands, and affordability tiers
- do not confuse demographic stereotype with validated need
- state clearly which persona attributes come from data vs design assumptions

### `documentation-curator`

Use for:

- doc cleanup
- source-of-truth alignment
- ADR hygiene
- handoff clarity

Outputs:

- cleaned docs
- updated cross-links
- reduced duplication
- documented assumptions

Guardrails:

- prefer one clear source of truth over repeated similar content
- preserve important context while removing stale or misleading notes
- make it easy for the next contributor to know where to start

### `journey-designer`

Use for:

- awareness-to-engagement flow
- onboarding
- nudges
- feature sequencing

Outputs:

- journey map
- user stories
- north star metric proposal
- in-app touchpoint placement
- retention loop design

Guardrails:

- prioritize low cognitive load
- avoid alarmist copy
- keep commercial prompts additive, not disruptive
- design for recurring weekly or monthly value, not just onboarding

### `commercial-strategist`

Use for:

- monetization logic
- offer design
- conversion points
- pricing and packaging hypotheses

Outputs:

- monetization paths
- offer ladders
- conversion assumptions
- business-case hooks

Guardrails:

- patient value must come before commercial extraction
- every monetization touchpoint should be explainable as relevant and timely
- distinguish between recurring revenue, episodic revenue, and referral value

### `data-architect`

Use for:

- schemas
- feature generation
- scoring logic
- warehouse design

Outputs:

- curated tables
- metric definitions
- data contracts
- refresh/build workflow

Guardrails:

- keep raw data immutable
- prefer reproducible SQL and scripts over manual notebook logic
- document assumptions behind every score or derived flag

### `backend-builder`

Use for:

- APIs
- repository layer
- app-facing payloads
- validation and tests

Outputs:

- stable endpoints
- typed payload shapes
- local dev commands
- smoke tests

Guardrails:

- optimize for simple local setup
- avoid over-engineering before the frontend needs it
- keep endpoints aligned with the patient journey, not internal system boundaries

### `coach-safety-reviewer`

Use for:

- recommendation language
- health safety boundaries
- trust and tone review

Outputs:

- safety notes
- wording adjustments
- escalation rules
- disclaimer proposals

Guardrails:

- never overstate certainty
- never imply diagnosis from heuristic scoring alone
- recommend clinical follow-up where risk signals are elevated
- make clear when advice is general wellness support versus clinically relevant escalation

### `demo-storyliner`

Use for:

- presentation flow
- investor/jury narrative
- proof-point selection

Outputs:

- demo script
- before/after story
- persona-based walkthrough
- business value framing

Guardrails:

- show one coherent story rather than too many disconnected features
- anchor claims in the available data and ADRs
- keep the user benefit ahead of the technology stack

## Recommended Task Routing

- Start with `documentation-curator` whenever the docs drift or the task meaningfully changes direction.
- Persona work starts with `persona-strategist`, then `journey-designer`.
- Monetization design gets a `commercial-strategist` pass before implementation.
- Scoring or warehouse changes start with `data-architect`, then `backend-builder`.
- Coach prompt or recommendation work always gets a `coach-safety-reviewer` pass.
- Demo prep starts with `demo-storyliner` but must reuse existing personas and ADRs.

## ADR Policy

Use ADRs for:

- architecture choices
- product scope choices
- data modeling choices
- safety decisions
- tradeoffs that future contributors might otherwise revisit blindly

Do not create an ADR for:

- tiny wording changes
- isolated bug fixes
- disposable experiments that never shape the repo

ADR format:

- Status
- Context
- Decision
- Consequences
- Alternatives considered

New ADRs go in `docs/adr/` with a four-digit prefix.

## Current Source Of Truth

- Documentation index: [docs/README.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/README.md)
- Product brief: [docs/product/brief.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/brief.md)
- Persona library: [docs/product/personas.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/personas.md)
- User journeys: [docs/product/journeys.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/journeys.md)
- Longevity Compass: [docs/product/longevity-compass.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/product/longevity-compass.md)
- Google-first MVP architecture: [docs/architecture/google-first-mvp.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/architecture/google-first-mvp.md)
- ADR index: [docs/adr/README.md](/Users/lauritz/git/Hackerthon-BCG-Platinum/docs/adr/README.md)

## Definition Of Done For Fundamentals

A fundamentals change is complete when:

- personas are richer, more diverse, and more actionable
- user journeys are explicit and monetization-aware
- architecture choices are documented
- new contributors can understand how to work in the repo
- future agent or subagent work has clear role boundaries
