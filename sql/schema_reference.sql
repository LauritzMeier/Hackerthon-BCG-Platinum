-- DuckDB-compatible reference schema for the current project data model.
-- Generated from:
--   1. CSV-backed raw inputs in data/raw/
--   2. Curated mart definitions in sql/marts.sql
--
-- Notes:
-- - The active build pipeline still creates raw tables with read_csv_auto()
--   and curated tables with CTAS statements from sql/marts.sql.
-- - Column types are inferred from the current CSV inputs and mart SQL.
-- - This file exists as a separate, human-readable schema reference.

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS curated;

-- raw.ehr_records
CREATE TABLE IF NOT EXISTS raw.ehr_records (
    patient_id VARCHAR,
    age BIGINT,
    sex VARCHAR,
    country VARCHAR,
    height_cm DOUBLE,
    weight_kg DOUBLE,
    bmi DOUBLE,
    smoking_status VARCHAR,
    alcohol_units_weekly BIGINT,
    chronic_conditions VARCHAR,
    icd_codes VARCHAR,
    n_chronic_conditions BIGINT,
    medications VARCHAR,
    n_visits_2yr BIGINT,
    visit_history VARCHAR,
    sbp_mmhg BIGINT,
    dbp_mmhg BIGINT,
    total_cholesterol_mmol DOUBLE,
    ldl_mmol DOUBLE,
    hdl_mmol DOUBLE,
    triglycerides_mmol DOUBLE,
    hba1c_pct DOUBLE,
    fasting_glucose_mmol DOUBLE,
    crp_mg_l DOUBLE,
    egfr_ml_min BIGINT
);

-- raw.lifestyle_survey
CREATE TABLE IF NOT EXISTS raw.lifestyle_survey (
    patient_id VARCHAR,
    survey_date DATE,
    smoking_status VARCHAR,
    alcohol_units_weekly BIGINT,
    diet_quality_score BIGINT,
    fruit_veg_servings_daily DOUBLE,
    meal_frequency_daily BIGINT,
    exercise_sessions_weekly BIGINT,
    sedentary_hrs_day DOUBLE,
    stress_level BIGINT,
    sleep_satisfaction BIGINT,
    mental_wellbeing_who5 BIGINT,
    self_rated_health BIGINT,
    water_glasses_daily BIGINT
);

-- raw.wearable_telemetry
CREATE TABLE IF NOT EXISTS raw.wearable_telemetry (
    patient_id VARCHAR,
    date DATE,
    resting_hr_bpm BIGINT,
    hrv_rmssd_ms DOUBLE,
    steps BIGINT,
    active_minutes BIGINT,
    sleep_duration_hrs DOUBLE,
    sleep_quality_score BIGINT,
    deep_sleep_pct DOUBLE,
    spo2_avg_pct DOUBLE,
    calories_burned_kcal BIGINT
);

-- curated.patient_profile
CREATE TABLE IF NOT EXISTS curated.patient_profile (
    patient_id VARCHAR,
    age BIGINT,
    sex VARCHAR,
    country VARCHAR,
    height_cm DOUBLE,
    weight_kg DOUBLE,
    bmi DOUBLE,
    ehr_smoking_status VARCHAR,
    survey_smoking_status VARCHAR,
    current_smoking_status VARCHAR,
    ehr_alcohol_units_weekly BIGINT,
    survey_alcohol_units_weekly BIGINT,
    current_alcohol_units_weekly BIGINT,
    chronic_conditions VARCHAR,
    icd_codes VARCHAR,
    n_chronic_conditions BIGINT,
    medications VARCHAR,
    n_visits_2yr BIGINT,
    visit_history VARCHAR,
    sbp_mmhg BIGINT,
    dbp_mmhg BIGINT,
    total_cholesterol_mmol DOUBLE,
    ldl_mmol DOUBLE,
    hdl_mmol DOUBLE,
    triglycerides_mmol DOUBLE,
    hba1c_pct DOUBLE,
    fasting_glucose_mmol DOUBLE,
    crp_mg_l DOUBLE,
    egfr_ml_min BIGINT,
    latest_survey_date DATE,
    diet_quality_score BIGINT,
    fruit_veg_servings_daily DOUBLE,
    meal_frequency_daily BIGINT,
    exercise_sessions_weekly BIGINT,
    sedentary_hrs_day DOUBLE,
    stress_level BIGINT,
    sleep_satisfaction BIGINT,
    mental_wellbeing_who5 BIGINT,
    self_rated_health BIGINT,
    water_glasses_daily BIGINT
);

-- curated.wearable_daily
CREATE TABLE IF NOT EXISTS curated.wearable_daily (
    patient_id VARCHAR,
    reading_date DATE,
    resting_hr_bpm BIGINT,
    hrv_rmssd_ms DOUBLE,
    steps BIGINT,
    active_minutes BIGINT,
    sleep_duration_hrs DOUBLE,
    sleep_quality_score BIGINT,
    deep_sleep_pct DOUBLE,
    spo2_avg_pct DOUBLE,
    calories_burned_kcal BIGINT
);

-- curated.patient_metrics
CREATE TABLE IF NOT EXISTS curated.patient_metrics (
    patient_id VARCHAR,
    latest_wearable_date DATE,
    steps_7d_avg DOUBLE,
    active_minutes_7d_avg DOUBLE,
    sleep_duration_7d_avg DOUBLE,
    sleep_quality_7d_avg DOUBLE,
    resting_hr_7d_avg DOUBLE,
    hrv_7d_avg DOUBLE,
    spo2_7d_avg DOUBLE,
    steps_30d_avg DOUBLE,
    active_minutes_30d_avg DOUBLE,
    sleep_duration_30d_avg DOUBLE,
    sleep_quality_30d_avg DOUBLE,
    deep_sleep_30d_avg DOUBLE,
    resting_hr_30d_avg DOUBLE,
    hrv_30d_avg DOUBLE,
    spo2_30d_avg DOUBLE,
    sleep_recovery_score DOUBLE,
    cardiovascular_fitness_score DOUBLE,
    lifestyle_behavior_score DOUBLE,
    metabolic_health_score DOUBLE,
    estimated_biological_age DOUBLE
);

-- curated.risk_flags
CREATE TABLE IF NOT EXISTS curated.risk_flags (
    patient_id VARCHAR,
    flag_code VARCHAR,
    severity VARCHAR,
    title VARCHAR,
    rationale VARCHAR,
    recommended_action VARCHAR
);

-- curated.offer_opportunities
CREATE TABLE IF NOT EXISTS curated.offer_opportunities (
    patient_id VARCHAR,
    priority BIGINT,
    offer_code VARCHAR,
    offer_label VARCHAR,
    rationale VARCHAR
);

-- curated.coach_context
CREATE TABLE IF NOT EXISTS curated.coach_context (
    patient_id VARCHAR,
    age BIGINT,
    sex VARCHAR,
    country VARCHAR,
    latest_wearable_date DATE,
    estimated_biological_age DOUBLE,
    sleep_recovery_score DOUBLE,
    cardiovascular_fitness_score DOUBLE,
    lifestyle_behavior_score DOUBLE,
    metabolic_health_score DOUBLE,
    primary_focus_area VARCHAR,
    active_flags VARCHAR,
    suggested_offers VARCHAR
);
