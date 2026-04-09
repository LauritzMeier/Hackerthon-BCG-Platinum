# User Journeys

## Purpose

These journeys define how the longevity MVP creates recurring user value and monetizes without breaking trust.

They are written before detailed feature implementation so the product does not turn into disconnected screens.

## Journey Principles

- Every journey must create patient value first.
- Every journey should have a retention reason, not just an onboarding reason.
- Every journey should have an optional but relevant monetization moment.
- The chatbot should act as a helpful guide across journeys, not as a novelty layer.
- Personalization should adapt tone, cadence, and recommendations by persona and risk context.
- The Longevity Compass should be the common thread across journeys.
- Every meaningful user-facing output should be traceable back to one or more compass pillars.

## Core Journey System

The MVP should operate as four connected journeys:

1. Compass onboarding and first value
2. Weekly compass check-in and coaching loop
3. Risk drift to action journey
4. Relevant offer conversion and follow-through

## Journey 1: Compass Onboarding And First Value

### Goal

Show the user that fragmented data can become one clear and personal starting point.

### Trigger

- first sign-in
- invitation acceptance
- reactivation after inactivity

### User Flow

1. User signs in with low-friction authentication.
2. App explains what data it uses and how the compass works.
3. User chooses goals and coaching preferences.
4. App assembles the initial Longevity Compass:
   - six pillar states
   - six pillar trajectories
   - primary focus area
   - first 7-day action plan
5. User can ask the coach why they are seeing each recommendation.

### Chatbot Role

- explain the current compass state
- explain which pillars are strongest and weakest
- explain why one focus area matters most
- convert the baseline into a conversational first-week plan

### Monetization Role

Usually none at first unless there is a very strong, signal-driven reason.

### Success Signal

- onboarding completion
- first plan acceptance
- first coach interaction

## Journey 2: Weekly Compass Check-In And Coaching Loop

### Goal

Create a strong weekly reason to return and reinforce that the app is actively tailored to the user.

### Trigger

- weekly review cadence
- meaningful data change
- user-initiated check-in

### User Flow

1. App shows updated compass direction:
   - improving
   - stable
   - drifting
2. User sees which pillar is driving the change.
3. User receives 2-3 realistic actions for the coming week.
4. Chatbot adapts the plan to schedule, stress, travel, budget, or motivation.
5. App tracks adherence and visible progress.

### Chatbot Role

- explain the weekly change
- tailor the plan to real-life constraints
- keep the product feeling personal between major reviews

### Monetization Role

Soft and supportive:

- premium coaching tier
- recovery or nutrition program
- deeper monthly progress review

### Success Signal

- weekly active users
- action plan completion rate
- chatbot conversations per active user

## Journey 3: Risk Drift To Action Journey

### Goal

Turn a negative change in trajectory or a risk signal into understandable action before the user delays care.

### Trigger

- worsened pillar trend
- sudden deterioration in a high-priority pillar
- multi-pillar drift that suggests broader risk

### User Flow

1. App shows that the compass is drifting in a specific pillar.
2. User sees what changed and why it matters.
3. App proposes a short action plan.
4. Chatbot answers questions and reduces anxiety.
5. If relevant, app recommends a diagnostics package or program.

### Chatbot Role

- explain the drift in plain language
- separate general wellness advice from clinical escalation
- help the user choose between self-management and booking follow-up

### Monetization Role

This is the cleanest high-intent conversion path because the recommendation is tied to a drifting or high-risk pillar:

- cardiometabolic diagnostics
- sleep assessment
- nutrition coaching
- movement program

### Success Signal

- flag acknowledgment
- action plan acceptance
- diagnostics or package conversion

## Journey 4: Offer Conversion And Follow-Through

### Goal

Make monetization feel like relevant support and then feed the result back into the user journey.

### Trigger

- accepted recommendation
- milestone review with stalled progress
- chatbot-guided escalation

### User Flow

1. App presents one relevant offer with context.
2. User sees why it is recommended now.
3. User books, buys, or saves it.
4. App follows through:
   - reminders
   - completion tracking
   - result integration
   - updated next-best actions
5. User returns to the weekly compass loop with new context.

### Chatbot Role

- explain the value of the offer
- answer relevance and cost questions
- keep the conversion tied to user benefit

### Monetization Role

Primary revenue capture:

- diagnostics packages
- subscription coaching
- premium annual plans
- targeted lifestyle programs

### Success Signal

- conversion rate
- completion after conversion
- continued engagement after purchase

## Persona Fit

| Persona | Best journey anchor |
| --- | --- |
| Markus | Risk drift to action |
| Sofia | Weekly coaching loop |
| Claire | Onboarding plus follow-through |
| Johanna | Risk drift to action |
| Luca | Weekly coaching loop |
| Anika | Onboarding plus weekly loop |
| Tomasz | Risk drift to action |
| Ingrid | Weekly coaching loop |
| Elise | Onboarding plus follow-through |

## Recommendation

- Choose Markus if we want the cleanest diagnostics-led monetization story
- Choose Sofia if we want the clearest retention-led story

## Compass Rule

The product should follow one simple rule:

- if something appears in the app, we should be able to explain which pillar or trajectory change caused it

That includes:

- chatbot prompts
- weekly plans
- nudges
- risk alerts
- diagnostics recommendations
- premium offers
