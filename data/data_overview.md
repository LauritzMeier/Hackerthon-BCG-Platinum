# Longevity Data Overview & Insights Strategy

This document provides a strategic overview of the raw data available in `data/raw`, how it maps to the **Longevity Compass** (the core product experience), what insights we can generate, and what critical missing data the app needs to collect directly from the user to drive the 12-month CEO mandate.

## Available Datasets

We have three primary data sources linking on `patient_id`:

1. **`ehr_records.csv`** (Clinical Baseline)
   - *Key Fields*: Age, BMI, vitals (systolic/diastolic BP), lipid panel (cholesterol, HDL, LDL, triglycerides), metabolic markers (HbA1c, fasting glucose), inflammation (CRP), kidney function (eGFR), chronic conditions, and medications.
2. **`lifestyle_survey.csv`** (Subjective Baseline)
   - *Key Fields*: Smoking/alcohol status, diet quality score, fruit/veg intake, hydration, exercise frequency, sedentary hours, perceived stress, WHO-5 mental wellbeing, and self-rated health.
3. **`wearable_telemetry_1.csv`** (Continuous Telemetry - 90 Days)
   - *Key Fields*: Resting heart rate (RHR), Heart Rate Variability (HRV), daily steps, active minutes, sleep duration, sleep quality, deep sleep percentage, and SpO2.

---

## Mapping Data to the Six Pillars

By triangulating clinical, subjective, and continuous data, we can generate a robust score and trend for each of the six longevity pillars without requiring the user to do heavy manual logging.

### 1. Sleep and Recovery
- **Data Used**: `wearable` (sleep duration, sleep quality score, deep sleep %) + `survey` (sleep satisfaction).
- **Insights**: We can compare objective wearable data against subjective satisfaction. A drop in deep sleep combined with a drop in HRV is a strong leading indicator of under-recovery or impending illness.

### 2. Cardiovascular Health
- **Data Used**: `ehr` (blood pressure, age) + `wearable` (Resting HR, HRV, SpO2).
- **Insights**: HRV is our primary metric for autonomic nervous system balance. We can flag downward trending HRV or climbing RHR over a rolling 7-day window vs. a 30-day baseline to trigger early warnings before clinical BP rises.

### 3. Metabolic Health
- **Data Used**: `ehr` (HbA1c, fasting glucose, lipids, BMI).
- **Insights**: This is currently mostly static. We can project long-term metabolic risk (e.g., pre-diabetic drift) based on body composition and blood panels, and use this to justify targeted nutrition or movement interventions.

### 4. Movement and Fitness
- **Data Used**: `wearable` (steps, active minutes) + `survey` (exercise sessions, sedentary hours).
- **Insights**: We can distinguish between "active" (high heart rate minutes) and "moving" (just steps). If a user has 10,000 steps but 0 active minutes, we can nudge towards moderate-to-vigorous physical activity (MVPA) for cardiovascular longevity.

### 5. Nutrition Quality
- **Data Used**: `survey` (diet quality, fruit/veg servings, water glasses, alcohol) + `ehr` (alcohol history).
- **Insights**: Currently heavily reliant on a one-time survey. We can identify high systemic inflammation (from `ehr` CRP levels) and tie it back to reported low diet quality or high alcohol intake to drive nutritional coaching.

### 6. Mental Resilience
- **Data Used**: `survey` (stress level, WHO-5, self-rated health).
- **Insights**: We can map high baseline stress to acute wearable metrics (suppressed HRV, poor sleep). This creates a powerful feedback loop showing the user the physical toll of psychological stress.

---

## Monetization & Actionable Opportunities

The goal is to translate these insights into the hybrid commercial model (recurring engagement + episodic revenue).

- **Diagnostics Upsell**: If a user's wearable HRV and active minutes are improving over 3 months, but their last EHR lipid panel was poor, the coach can suggest a **follow-up metabolic blood test** (episodic revenue) to "validate their hard work."
- **Targeted Packages**: If sleep and mental resilience are both drifting downward concurrently, the app can offer a **stress-management digital therapeutic or premium telehealth coaching session**.

---

## What the App Needs to Query the User For

To make the app "always-on" and engaging daily (our North Star Metric), relying solely on 90-day wearable telemetry and static EHRs won't cut it. The application **must** initiate micro-interactions to fill data gaps and provide context.

We should query the user for:

### 1. Daily Contextual Tags (The "Why")
When wearable data detects an anomaly (e.g., a sudden drop in HRV or a bad night of sleep), the app should ask *why*.
- *Example App Prompt*: "Your recovery took a hit last night. Did you have a late heavy meal, alcohol, or a stressful day?"
- *Value*: Humans love explaining mysteries about themselves. This contextualizes the data and trains the AI coach.

### 2. Frictionless Nutrition & Hydration Tracking
The `lifestyle_survey.csv` is static. Nutrition is the weakest continuous pillar right now. 
- *Recommendation*: The app should occasionally ask simple binary or image-based questions: "Did you hit your 5 servings of veg today?" or offer a photo-log for meals.

### 3. Acute Emotional State
Continuous stress monitoring is difficult with just HRV. 
- *Recommendation*: Occasional prompt: "How are you feeling right now on a scale of 1-5?" Mapped against their HRV, this helps the app learn if they are physically stressed (overtraining) or psychologically stressed.

### 4. Goal Commitment (The North Star Driver)
The app must propose micro-goals based on the weakest pillar. 
- *Example*: If Metabolic Health is the primary focus, the coach asks: "Will you commit to a 10-minute walk after dinner for the next 3 days?"
- *Value*: Tracking the acceptance and completion of these goals directly feeds our North Star Metric (*weekly guided engagement rate*).
