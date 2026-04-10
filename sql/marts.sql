CREATE SCHEMA IF NOT EXISTS curated;

CREATE OR REPLACE TABLE curated.patient_profile AS
WITH latest_survey_ranked AS (
    SELECT
        patient_id,
        CAST(survey_date AS DATE) AS survey_date,
        smoking_status AS survey_smoking_status,
        alcohol_units_weekly AS survey_alcohol_units_weekly,
        diet_quality_score,
        fruit_veg_servings_daily,
        meal_frequency_daily,
        exercise_sessions_weekly,
        sedentary_hrs_day,
        stress_level,
        sleep_satisfaction,
        mental_wellbeing_who5,
        self_rated_health,
        water_glasses_daily,
        ROW_NUMBER() OVER (
            PARTITION BY patient_id
            ORDER BY CAST(survey_date AS DATE) DESC
        ) AS row_num
    FROM raw.lifestyle_survey
),
latest_survey AS (
    SELECT * EXCLUDE (row_num)
    FROM latest_survey_ranked
    WHERE row_num = 1
)
SELECT
    ehr.patient_id,
    ehr.age,
    ehr.sex,
    ehr.country,
    ehr.height_cm,
    ehr.weight_kg,
    ROUND(ehr.bmi, 1) AS bmi,
    ehr.smoking_status AS ehr_smoking_status,
    survey.survey_smoking_status,
    COALESCE(survey.survey_smoking_status, ehr.smoking_status) AS current_smoking_status,
    ehr.alcohol_units_weekly AS ehr_alcohol_units_weekly,
    survey.survey_alcohol_units_weekly,
    COALESCE(survey.survey_alcohol_units_weekly, ehr.alcohol_units_weekly) AS current_alcohol_units_weekly,
    ehr.chronic_conditions,
    ehr.icd_codes,
    ehr.n_chronic_conditions,
    ehr.medications,
    ehr.n_visits_2yr,
    ehr.visit_history,
    ehr.sbp_mmhg,
    ehr.dbp_mmhg,
    ehr.total_cholesterol_mmol,
    ehr.ldl_mmol,
    ehr.hdl_mmol,
    ehr.triglycerides_mmol,
    ehr.hba1c_pct,
    ehr.fasting_glucose_mmol,
    ehr.crp_mg_l,
    ehr.egfr_ml_min,
    survey.survey_date AS latest_survey_date,
    survey.diet_quality_score,
    survey.fruit_veg_servings_daily,
    survey.meal_frequency_daily,
    survey.exercise_sessions_weekly,
    survey.sedentary_hrs_day,
    survey.stress_level,
    survey.sleep_satisfaction,
    survey.mental_wellbeing_who5,
    survey.self_rated_health,
    survey.water_glasses_daily
FROM raw.ehr_records AS ehr
LEFT JOIN latest_survey AS survey
    USING (patient_id);

CREATE OR REPLACE TABLE curated.wearable_daily AS
SELECT
    patient_id,
    CAST(date AS DATE) AS reading_date,
    resting_hr_bpm,
    hrv_rmssd_ms,
    steps,
    active_minutes,
    sleep_duration_hrs,
    sleep_quality_score,
    deep_sleep_pct,
    spo2_avg_pct,
    calories_burned_kcal
FROM raw.wearable_telemetry;

CREATE OR REPLACE TABLE curated.patient_metrics AS
WITH wearable_rollups AS (
    SELECT
        patient_id,
        reading_date,
        resting_hr_bpm,
        hrv_rmssd_ms,
        steps,
        active_minutes,
        sleep_duration_hrs,
        sleep_quality_score,
        deep_sleep_pct,
        spo2_avg_pct,
        calories_burned_kcal,
        AVG(steps) OVER rolling_7d AS steps_7d_avg,
        AVG(active_minutes) OVER rolling_7d AS active_minutes_7d_avg,
        AVG(sleep_duration_hrs) OVER rolling_7d AS sleep_duration_7d_avg,
        AVG(sleep_quality_score) OVER rolling_7d AS sleep_quality_7d_avg,
        AVG(resting_hr_bpm) OVER rolling_7d AS resting_hr_7d_avg,
        AVG(hrv_rmssd_ms) OVER rolling_7d AS hrv_7d_avg,
        AVG(spo2_avg_pct) OVER rolling_7d AS spo2_7d_avg,
        AVG(steps) OVER rolling_30d AS steps_30d_avg,
        AVG(active_minutes) OVER rolling_30d AS active_minutes_30d_avg,
        AVG(sleep_duration_hrs) OVER rolling_30d AS sleep_duration_30d_avg,
        AVG(sleep_quality_score) OVER rolling_30d AS sleep_quality_30d_avg,
        AVG(deep_sleep_pct) OVER rolling_30d AS deep_sleep_30d_avg,
        AVG(resting_hr_bpm) OVER rolling_30d AS resting_hr_30d_avg,
        AVG(hrv_rmssd_ms) OVER rolling_30d AS hrv_30d_avg,
        AVG(spo2_avg_pct) OVER rolling_30d AS spo2_30d_avg
    FROM curated.wearable_daily
    WINDOW
        rolling_7d AS (
            PARTITION BY patient_id
            ORDER BY reading_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        rolling_30d AS (
            PARTITION BY patient_id
            ORDER BY reading_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        )
),
latest_wearable_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY patient_id
            ORDER BY reading_date DESC
        ) AS row_num
    FROM wearable_rollups
),
latest_wearable AS (
    SELECT * EXCLUDE (row_num)
    FROM latest_wearable_ranked
    WHERE row_num = 1
)
SELECT
    profile.patient_id,
    latest_wearable.reading_date AS latest_wearable_date,
    ROUND(latest_wearable.steps_7d_avg, 1) AS steps_7d_avg,
    ROUND(latest_wearable.active_minutes_7d_avg, 1) AS active_minutes_7d_avg,
    ROUND(latest_wearable.sleep_duration_7d_avg, 2) AS sleep_duration_7d_avg,
    ROUND(latest_wearable.sleep_quality_7d_avg, 1) AS sleep_quality_7d_avg,
    ROUND(latest_wearable.resting_hr_7d_avg, 1) AS resting_hr_7d_avg,
    ROUND(latest_wearable.hrv_7d_avg, 1) AS hrv_7d_avg,
    ROUND(latest_wearable.spo2_7d_avg, 1) AS spo2_7d_avg,
    ROUND(latest_wearable.steps_30d_avg, 1) AS steps_30d_avg,
    ROUND(latest_wearable.active_minutes_30d_avg, 1) AS active_minutes_30d_avg,
    ROUND(latest_wearable.sleep_duration_30d_avg, 2) AS sleep_duration_30d_avg,
    ROUND(latest_wearable.sleep_quality_30d_avg, 1) AS sleep_quality_30d_avg,
    ROUND(latest_wearable.deep_sleep_30d_avg, 1) AS deep_sleep_30d_avg,
    ROUND(latest_wearable.resting_hr_30d_avg, 1) AS resting_hr_30d_avg,
    ROUND(latest_wearable.hrv_30d_avg, 1) AS hrv_30d_avg,
    ROUND(latest_wearable.spo2_30d_avg, 1) AS spo2_30d_avg,
    ROUND(
        GREATEST(
            0,
            LEAST(
                100,
                100
                - ABS(latest_wearable.sleep_duration_30d_avg - 8.0) * 18
                - GREATEST(0, 70 - latest_wearable.sleep_quality_30d_avg) * 0.9
                - GREATEST(0, 20 - latest_wearable.deep_sleep_30d_avg) * 1.1
            )
        ),
        1
    ) AS sleep_recovery_score,
    ROUND(
        GREATEST(
            0,
            LEAST(
                100,
                100
                - GREATEST(0, profile.sbp_mmhg - 120) * 0.6
                - GREATEST(0, profile.dbp_mmhg - 80) * 0.8
                - GREATEST(0, profile.ldl_mmol - 3.0) * 10
                - GREATEST(0, latest_wearable.resting_hr_30d_avg - 65) * 1.7
                + GREATEST(0, latest_wearable.hrv_30d_avg - 35) * 0.4
                + CASE
                    WHEN latest_wearable.steps_30d_avg >= 9000 THEN 8
                    WHEN latest_wearable.steps_30d_avg >= 7000 THEN 4
                    ELSE 0
                  END
            )
        ),
        1
    ) AS cardiovascular_fitness_score,
    ROUND(
        GREATEST(
            0,
            LEAST(
                100,
                100
                - CASE
                    WHEN profile.current_smoking_status = 'current' THEN 30
                    WHEN profile.current_smoking_status = 'ex' THEN 8
                    ELSE 0
                  END
                - GREATEST(0, profile.current_alcohol_units_weekly - 10) * 1.5
                - GREATEST(0, 5 - profile.diet_quality_score) * 8
                - GREATEST(0, profile.sedentary_hrs_day - 8) * 4
                - GREATEST(0, profile.stress_level - 4) * 5
                + LEAST(profile.exercise_sessions_weekly, 7) * 3
            )
        ),
        1
    ) AS lifestyle_behavior_score,
    ROUND(
        GREATEST(
            0,
            LEAST(
                100,
                100
                - GREATEST(0, profile.bmi - 25) * 4
                - GREATEST(0, profile.total_cholesterol_mmol - 5.2) * 8
                - GREATEST(0, profile.ldl_mmol - 3.0) * 10
                - GREATEST(0, profile.triglycerides_mmol - 1.7) * 10
                - GREATEST(0, profile.fasting_glucose_mmol - 5.5) * 12
                - GREATEST(0, profile.hba1c_pct - 5.6) * 10
                - GREATEST(0, profile.crp_mg_l - 3.0) * 3
            )
        ),
        1
    ) AS metabolic_health_score,
    ROUND(
        profile.age
        + CASE
            WHEN profile.bmi BETWEEN 18.5 AND 24.9 THEN 0
            WHEN profile.bmi < 18.5 THEN 1
            ELSE 3
          END
        + CASE
            WHEN profile.sbp_mmhg < 120 AND profile.dbp_mmhg < 80 THEN 0
            WHEN profile.sbp_mmhg < 140 AND profile.dbp_mmhg < 90 THEN 1.5
            ELSE 4
          END
        + CASE
            WHEN profile.hba1c_pct < 5.7 THEN 0
            WHEN profile.hba1c_pct < 6.5 THEN 2
            ELSE 4
          END
        + CASE
            WHEN latest_wearable.steps_30d_avg >= 9000 THEN -1
            WHEN latest_wearable.steps_30d_avg >= 7000 THEN 0
            ELSE 2
          END
        + CASE
            WHEN latest_wearable.sleep_duration_30d_avg BETWEEN 7 AND 8.5 THEN 0
            ELSE 1
          END
        + CASE
            WHEN latest_wearable.resting_hr_30d_avg <= 65 THEN -1
            WHEN latest_wearable.resting_hr_30d_avg <= 75 THEN 0
            ELSE 2
          END,
        1
    ) AS estimated_biological_age
FROM curated.patient_profile AS profile
LEFT JOIN latest_wearable
    USING (patient_id);

CREATE OR REPLACE TABLE curated.risk_flags AS
WITH base AS (
    SELECT *
    FROM curated.patient_profile AS profile
    LEFT JOIN curated.patient_metrics AS metrics
        USING (patient_id)
)
SELECT *
FROM (
    SELECT
        patient_id,
        'blood_pressure' AS flag_code,
        CASE
            WHEN sbp_mmhg >= 160 OR dbp_mmhg >= 100 THEN 'high'
            ELSE 'medium'
        END AS severity,
        'Elevated blood pressure' AS title,
        'Latest blood pressure is above the healthy range.' AS rationale,
        'Offer a cardiovascular follow-up package and coaching on activity, stress, and sodium intake.' AS recommended_action
    FROM base
    WHERE sbp_mmhg >= 140 OR dbp_mmhg >= 90

    UNION ALL

    SELECT
        patient_id,
        'glycemic_control' AS flag_code,
        CASE
            WHEN hba1c_pct >= 6.5 THEN 'high'
            ELSE 'medium'
        END AS severity,
        'Poor glycemic control' AS title,
        'Blood sugar markers suggest elevated metabolic risk.' AS rationale,
        'Offer a metabolic blood panel and nutrition coaching journey.' AS recommended_action
    FROM base
    WHERE hba1c_pct >= 5.7 OR fasting_glucose_mmol >= 5.6

    UNION ALL

    SELECT
        patient_id,
        'sleep_debt' AS flag_code,
        CASE
            WHEN sleep_duration_30d_avg < 6.0 OR sleep_recovery_score < 45 THEN 'high'
            ELSE 'medium'
        END AS severity,
        'Poor sleep recovery' AS title,
        'Recent wearable patterns show insufficient or low-quality sleep.' AS rationale,
        'Offer a sleep diagnostic package and a sleep hygiene coaching sequence.' AS recommended_action
    FROM base
    WHERE sleep_duration_30d_avg < 6.8 OR sleep_recovery_score < 60

    UNION ALL

    SELECT
        patient_id,
        'low_activity' AS flag_code,
        'medium' AS severity,
        'Low daily activity' AS title,
        'Recent movement levels are below a healthy prevention baseline.' AS rationale,
        'Offer a step-building plan with gentle weekly progression targets.' AS recommended_action
    FROM base
    WHERE steps_30d_avg < 7000 OR active_minutes_30d_avg < 25

    UNION ALL

    SELECT
        patient_id,
        'stress_and_wellbeing' AS flag_code,
        'medium' AS severity,
        'High stress or low wellbeing' AS title,
        'Survey results indicate a strain on resilience and recovery.' AS rationale,
        'Offer stress management content, recovery nudges, and optional coaching check-ins.' AS recommended_action
    FROM base
    WHERE stress_level >= 7 OR mental_wellbeing_who5 <= 12

    UNION ALL

    SELECT
        patient_id,
        'dyslipidaemia' AS flag_code,
        CASE
            WHEN ldl_mmol >= 4.9 THEN 'high'
            ELSE 'medium'
        END AS severity,
        'Unhealthy lipid profile' AS title,
        'Cholesterol values suggest elevated cardiovascular risk.' AS rationale,
        'Offer a heart health check-up and personalized nutrition support.' AS recommended_action
    FROM base
    WHERE total_cholesterol_mmol >= 5.2 OR ldl_mmol >= 3.0 OR triglycerides_mmol >= 1.7
) AS flags;

CREATE OR REPLACE TABLE curated.offer_opportunities AS
WITH base AS (
    SELECT *
    FROM curated.patient_profile AS profile
    LEFT JOIN curated.patient_metrics AS metrics
        USING (patient_id)
)
SELECT *
FROM (
    SELECT
        patient_id,
        1 AS priority,
        'cardiology_follow_up_visit' AS offer_code,
        'Cardiology follow-up visit' AS offer_label,
        'Recent heart attack or coronary disease context means the clearest next step is a concrete cardiology follow-up.' AS rationale
    FROM base
    WHERE icd_codes LIKE '%I21%'
       OR icd_codes LIKE '%I22%'
       OR icd_codes LIKE '%I25.1%'
       OR chronic_conditions LIKE '%coronary_artery_disease%'

    UNION ALL

    SELECT
        patient_id,
        2 AS priority,
        'preventive_cardiometabolic_panel' AS offer_code,
        'Preventive cardiometabolic panel' AS offer_label,
        'Elevated blood pressure, cholesterol, or glucose markers justify a broader preventive work-up.' AS rationale
    FROM base
    WHERE sbp_mmhg >= 140
       OR dbp_mmhg >= 90
       OR hba1c_pct >= 5.7
       OR ldl_mmol >= 3.0

    UNION ALL

    SELECT
        patient_id,
        3 AS priority,
        'cardiac_rehab_intake' AS offer_code,
        'Cardiac rehab intake' AS offer_label,
        'After a recent heart event, supervised recovery support can turn low confidence into a safer return-to-activity plan.' AS rationale
    FROM base
    WHERE icd_codes LIKE '%I21%'
       OR icd_codes LIKE '%I22%'

    UNION ALL

    SELECT
        patient_id,
        4 AS priority,
        'cardiometabolic_nutrition_consult' AS offer_code,
        'Cardiometabolic dietitian consult' AS offer_label,
        'Diabetes, dyslipidaemia, or post-cardiac recovery creates a strong case for a more clinical nutrition plan.' AS rationale
    FROM base
    WHERE (
        hba1c_pct >= 6.5
        OR fasting_glucose_mmol >= 7.0
        OR bmi >= 27
    )
      AND (
        ldl_mmol >= 3.0
        OR total_cholesterol_mmol >= 5.2
        OR diet_quality_score <= 6
        OR icd_codes LIKE '%I21%'
        OR icd_codes LIKE '%I22%'
      )

    UNION ALL

    SELECT
        patient_id,
        5 AS priority,
        'sleep_recovery_package' AS offer_code,
        'Sleep recovery package' AS offer_label,
        'Recent sleep duration or quality suggests a targeted sleep intervention could be relevant.' AS rationale
    FROM base
    WHERE sleep_recovery_score < 60

    UNION ALL

    SELECT
        patient_id,
        6 AS priority,
        'nutrition_coaching' AS offer_code,
        'Cardiometabolic nutrition coaching' AS offer_label,
        'Diet, weight, or blood sugar and lipid markers indicate that ongoing nutrition coaching could create measurable impact.' AS rationale
    FROM base
    WHERE diet_quality_score <= 5
       OR bmi >= 27
       OR fasting_glucose_mmol >= 5.6
       OR hba1c_pct >= 5.7

    UNION ALL

    SELECT
        patient_id,
        7 AS priority,
        'heart_health_supplement_review' AS offer_code,
        'Heart health supplement review' AS offer_label,
        'Supplement choices such as omega-3, soluble fiber, or plant sterols should be matched to cardiac risk and medication context.' AS rationale
    FROM base
    WHERE icd_codes LIKE '%I21%'
       OR icd_codes LIKE '%I22%'
       OR ldl_mmol >= 3.0
       OR total_cholesterol_mmol >= 5.2

    UNION ALL

    SELECT
        patient_id,
        8 AS priority,
        'movement_program' AS offer_code,
        'Movement and recovery program' AS offer_label,
        'Low activity or low cardiovascular fitness suggests a guided activity plan could improve adherence.' AS rationale
    FROM base
    WHERE steps_30d_avg < 7000
       OR cardiovascular_fitness_score < 60
) AS offers;

CREATE OR REPLACE TABLE curated.coach_context AS
WITH flag_rollup AS (
    SELECT
        patient_id,
        string_agg(
            title,
            '; '
            ORDER BY
                CASE severity
                    WHEN 'high' THEN 2
                    WHEN 'medium' THEN 1
                    ELSE 0
                END DESC,
                flag_code
        ) AS active_flags
    FROM curated.risk_flags
    GROUP BY patient_id
),
offer_rollup AS (
    SELECT
        patient_id,
        string_agg(offer_label, '; ' ORDER BY priority, offer_code) AS suggested_offers
    FROM curated.offer_opportunities
    GROUP BY patient_id
)
SELECT
    profile.patient_id,
    profile.age,
    profile.sex,
    profile.country,
    metrics.latest_wearable_date,
    metrics.estimated_biological_age,
    metrics.sleep_recovery_score,
    metrics.cardiovascular_fitness_score,
    metrics.lifestyle_behavior_score,
    metrics.metabolic_health_score,
    CASE
        WHEN metrics.sleep_recovery_score <= metrics.cardiovascular_fitness_score
         AND metrics.sleep_recovery_score <= metrics.lifestyle_behavior_score
         AND metrics.sleep_recovery_score <= metrics.metabolic_health_score
            THEN 'sleep_and_recovery'
        WHEN metrics.cardiovascular_fitness_score <= metrics.sleep_recovery_score
         AND metrics.cardiovascular_fitness_score <= metrics.lifestyle_behavior_score
         AND metrics.cardiovascular_fitness_score <= metrics.metabolic_health_score
            THEN 'cardiovascular_fitness'
        WHEN metrics.lifestyle_behavior_score <= metrics.sleep_recovery_score
         AND metrics.lifestyle_behavior_score <= metrics.cardiovascular_fitness_score
         AND metrics.lifestyle_behavior_score <= metrics.metabolic_health_score
            THEN 'lifestyle_behavior'
        ELSE 'metabolic_health'
    END AS primary_focus_area,
    COALESCE(flag_rollup.active_flags, 'No active flags generated from starter heuristics.') AS active_flags,
    COALESCE(offer_rollup.suggested_offers, 'No commercial touchpoint selected.') AS suggested_offers
FROM curated.patient_profile AS profile
LEFT JOIN curated.patient_metrics AS metrics
    USING (patient_id)
LEFT JOIN flag_rollup
    USING (patient_id)
LEFT JOIN offer_rollup
    USING (patient_id);
