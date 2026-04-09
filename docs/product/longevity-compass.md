# Longevity Compass

## Product Thesis

The core product should be a **Longevity Compass**.

This is the simplest way to answer the user’s central questions:

- Where am I now?
- Where am I heading?
- What should I do next?
- What support or offer is relevant now?

The compass should not feel like a generic wellness score. It should feel like a personalized navigation system built from clinical, lifestyle, and wearable signals.

## Compass Goal

The goal of the compass is to give the user one consistent operating system for their longevity journey.

It should unify:

- current health understanding
- future trajectory
- weekly action
- coach interaction
- monetization moments

Everything else in the app should come from the compass.

That means the compass is not one feature among many. It is the source system for the product experience.

## Why This Is The Right Core Experience

The challenge brief is about translating fragmented data into personalized engagement and digital revenue.

The Longevity Compass works because it combines:

- current state
- future trajectory
- explanation
- action
- monetization timing

That makes it stronger than a dashboard, a report, or a chatbot alone.

## Six Pillars

Working product assumption for the MVP:

1. Sleep and Recovery
2. Cardiovascular Health
3. Metabolic Health
4. Movement and Fitness
5. Nutrition Quality
6. Mental Resilience

These six pillars should be visible in the compass model and should drive:

- status
- trend
- focus area
- recommendations
- coaching prompts
- monetization timing

The center of the compass is the overall longevity trajectory, while the six pillars explain what is driving that trajectory.

## Core Functional Pillars

### 1. Pillar State

Show the user where they stand right now across the six pillars.

The six pillars are:

- sleep and recovery
- cardiovascular health
- metabolic health
- movement and fitness
- nutrition quality
- mental resilience

Each pillar should have a simple state signal such as:

- strong
- watch
- needs focus

### 2. Pillar Trajectory

Show the user where each pillar is moving:

- improving
- stable
- drifting

This creates the bridge between current status and future direction.

### 3. Overall Longevity Direction

Roll the six pillars into one overall compass view:

- on track
- mixed
- drifting

This is the highest-level answer to “where am I heading?”

### 4. Primary Focus Area

Always tell the user which pillar matters most now.

This should usually be:

- the weakest pillar
- the fastest-worsening pillar
- or the most commercially and clinically relevant pillar

### 5. Weekly Action Plan

Translate the compass into 2-3 realistic actions the user can do this week.

These actions should explicitly map back to one or two pillars.

### 6. Coach Chat

The chatbot should be the conversational interface to the compass.

It should help the user:

- understand their pillar state
- understand their trajectory
- ask follow-up questions
- adapt the plan
- decide whether to book further support

### 7. Relevant Next Best Offer

If the user needs more than self-guided action, the app should surface the most relevant next step.

That recommendation should come from the pillar model, for example:

- drifting metabolic health -> cardiometabolic diagnostics or nutrition coaching
- drifting sleep and recovery -> sleep support or sleep diagnostics
- drifting movement and fitness -> guided movement program
- drifting mental resilience -> recovery content or coaching support

## Product Rule

Everything else should come from the compass.

That includes:

- weekly summaries
- chatbot prompts
- push notifications
- action plans
- alerts
- diagnostics recommendations
- upsell or premium moments

If a feature cannot be explained as a consequence of the compass, it probably should not be in the MVP.

## Cross-Platform Product Model

The product should exist as:

- mobile app on iOS and Android for habitual use
- web app for richer review, onboarding, and transactional flows

## Mobile App Role

The mobile app should be the primary engagement surface.

Best mobile use cases:

- daily or weekly check-ins
- coach chat
- nudges
- progress updates
- simple action plans
- fast explanation of changes

Mobile should optimize for:

- quick comprehension
- frequent return
- low friction

Firebase implications:

- Firebase Cloud Messaging can deliver timely pillar-driven nudges
- Firebase Analytics can track return behavior and coaching engagement
- Firebase Crashlytics can keep the core experience reliable

## Web App Role

The web app should be the deeper companion experience.

Best web use cases:

- richer onboarding
- deep review of the longevity compass
- historical trend exploration
- booking diagnostics or programs
- reviewing longer summaries or reports

Web should optimize for:

- depth
- clarity
- comparison
- transaction confidence

Firebase implications:

- Firebase App Hosting or Hosting supports the web delivery layer
- Firebase Authentication keeps identity consistent across mobile and web

## Core Screens

### Mobile

1. Home Compass
2. Ask The Coach
3. Weekly Plan
4. Pillar Detail
5. Alerts And Opportunities
6. Progress

### Web

1. Detailed Compass Review
2. Six Pillar Trend Explorer
3. Personalized Recommendations
4. Offer And Booking Flow
5. Account And Preferences

## Monetization Model

The compass creates two monetization modes.

### Recurring Revenue

- premium coaching subscription
- advanced progress reviews
- targeted support programs

### Episodic Revenue

- preventive diagnostics
- sleep assessments
- nutrition consults
- annual preventive bundles

The compass makes monetization feel earned because the recommendation is grounded in a visible state and direction.

It should also make monetization explainable:

- which pillar triggered this
- why this offer matters now
- what outcome it could improve

## MVP Success Criteria

The concept is working if users can quickly answer:

- what is my current status?
- which pillar is driving my status?
- why did this change?
- what should I do this week?
- when should I consider more support?

## Recommended MVP Slice

For the first MVP, the most coherent slice is:

- one primary persona
- one main compass home screen
- one weekly update loop
- one risk-drift flow
- one chatbot entry point
- one clear offer path

That is enough to demonstrate both retention and monetization logic without overbuilding.
