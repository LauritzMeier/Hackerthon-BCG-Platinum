# Product Brief

## Challenge Context

This hackathon asks us to behave like a BCG Platinion consulting team designing a patient-facing longevity product for a large European healthcare group.

The deliverable is not only a prototype. It is also a consulting-quality recommendation that explains:

- why this product matters now
- which patient we should serve first
- how the experience drives regular usage
- how it creates revenue without undermining trust
- why the proposed architecture can credibly launch within 12 months

## Problem Statement

The brief describes a leading European healthcare group with clinics, diagnostics centers, and home care services across multiple countries. The client has scale, patient trust, and rich health data, but the system landscape is fragmented.

The key problem is not missing data. It is that health data is not translated into:

- personalized patient engagement
- scalable preventive journeys
- recurring digital revenue

The brief highlights three structural barriers:

1. Fragmented data with no unified patient profile across clinical and lifestyle sources
2. Capability gap between clinical delivery and consumer-grade digital product building
3. Competitive pressure from digital health and retail players that own the interface and monetize prevention demand

## Why Now

The brief frames this as urgent because:

- healthcare is shifting from episodic treatment to continuous prevention
- patients increasingly expect personalized, digital-first, always-on experiences
- external platforms are already capturing preventive health demand and high-margin revenue

This means the client risks losing the patient relationship even while still owning core care delivery.

## CEO Mandate

The explicit mandate from the brief is to launch a patient-facing longevity product within 12 months.

That makes the winning concept one that is:

- understandable
- commercially credible
- architecturally plausible
- capable of showing user value quickly

## What The Hackathon Must Show

The brief explicitly asks for:

- one clear patient persona
- a mapped longevity journey from first awareness to daily engagement
- at least 3 user stories
- one north star metric for patient success in year one
- an AI coach with evidence-grounded recommendations
- risk and opportunity flagging with actionable interventions
- relevant in-app touchpoints for diagnostics, packages, or nutrition

The brief also notes that the provided datasets and longevity dimensions are inspirational inputs, not a requirement to use every field exhaustively.

## Product Goals

The MVP should prove these points:

- fragmented data can become one coherent patient experience
- the app can personalize meaningfully
- the user has a reason to return regularly
- the chatbot or coach makes the app feel tailored and useful
- monetization is relevant and timely rather than intrusive
- the architecture looks viable for a real enterprise rollout

## Business Goals

The app should support three business outcomes:

1. Increase patient engagement frequency
2. Create recurring and episodic preventive revenue
3. Protect the client’s ownership of the patient interface

## Scope Decisions

Current scope:

- patient-facing only
- mobile app on iOS and Android as the primary engagement surface
- web app as a companion and deeper review surface
- Flutter as the primary client stack across mobile and, if useful, web
- Firebase as the app platform layer for the MVP
- Google-first target deployment architecture
- chatbot included only if it clearly improves understanding, retention, or conversion

Out of scope for the first MVP:

- full clinician workflow
- complex medical diagnostics
- broad care-team coordination tools
- exhaustive data science sophistication

## Data Available

- `ehr_records.csv`: 1,000 patients, one row per patient
- `lifestyle_survey.csv`: 1,000 patients, latest lifestyle snapshot
- `wearable_telemetry_1.csv`: 90 days of wearable telemetry per patient

All three datasets join cleanly on `patient_id`.

## Strategic Direction

The emerging product concept is a **Longevity Compass**:

- where the user is now
- where their current trajectory is taking them
- what to do next
- which offer or check-up is most relevant now

This concept is a better anchor than a generic dashboard because it combines:

- personalization
- future orientation
- recurring utility
- monetization logic

## Compass Operating Model

The compass should become the primary product model for the app.

Everything else should derive from it:

- weekly coaching
- chatbot explanations
- nudges
- risk flags
- diagnostics recommendations
- premium or subscription offers

### Six Pillars Of The Compass

Working product assumption for the MVP:

1. Sleep and Recovery
2. Cardiovascular Health
3. Metabolic Health
4. Movement and Fitness
5. Nutrition Quality
6. Mental Resilience

The compass should always answer two questions at the pillar level:

- what is the user’s current state in each pillar?
- which pillar is improving, stable, or drifting?

From there, the app can derive:

- one primary focus area
- one weekly plan
- one recommended conversation with the coach
- one relevant offer when extra support is justified

## Questions Still Open

- Which primary persona should anchor the live demo?
- Which monetization path should lead the story: diagnostics, subscription, or hybrid?
- What should the north star metric be for year one?
- How directive should the chatbot be versus how explanatory?
