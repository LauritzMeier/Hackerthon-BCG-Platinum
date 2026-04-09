"""Six-pillar analysis logic using raw CSV inputs + Firestore context."""

from __future__ import annotations

import csv
from datetime import datetime
from functools import lru_cache
from pathlib import Path
from statistics import mean
from typing import Any, Dict, List, Optional

from firebase_client import get_patient_firebase_context

DATA_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"
EHR_FILE = DATA_DIR / "ehr_records.csv"
LIFESTYLE_FILE = DATA_DIR / "lifestyle_survey.csv"
WEARABLE_FILE = DATA_DIR / "wearable_telemetry_1.csv"

PILLARS = [
    "sleep_recovery",
    "cardiovascular_health",
    "metabolic_health",
    "movement_fitness",
    "nutrition_quality",
    "mental_resilience",
]


def _safe_float(value: Any, default: float = 0.0) -> float:
    try:
        if value in (None, ""):
            return default
        return float(value)
    except (TypeError, ValueError):
        return default


def _score_to_state(score: float) -> str:
    if score >= 75:
        return "strong"
    if score >= 55:
        return "watch"
    return "needs_focus"


def _trend_from_delta(delta: float) -> str:
    if delta > 2.0:
        return "improving"
    if delta < -2.0:
        return "drifting"
    return "stable"


@lru_cache(maxsize=1)
def _load_csv_rows(csv_path: Path) -> List[Dict[str, str]]:
    with csv_path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def _find_latest_row(rows: List[Dict[str, str]], patient_id: str, date_field: str) -> Optional[Dict[str, str]]:
    patient_rows = [row for row in rows if row.get("patient_id") == patient_id]
    if not patient_rows:
        return None
    return sorted(patient_rows, key=lambda row: row.get(date_field, ""), reverse=True)[0]


def _find_wearable_rows(patient_id: str) -> List[Dict[str, str]]:
    rows = _load_csv_rows(WEARABLE_FILE)
    patient_rows = [row for row in rows if row.get("patient_id") == patient_id]
    patient_rows.sort(key=lambda row: row.get("date", ""))
    return patient_rows


def _rolling_avg(values: List[float], window: int) -> float:
    if not values:
        return 0.0
    return mean(values[-window:]) if len(values) >= window else mean(values)


def _build_sleep(row: Dict[str, str], wearable_rows: List[Dict[str, str]]) -> Dict[str, Any]:
    sleep_quality = [_safe_float(r.get("sleep_quality_score")) for r in wearable_rows]
    sleep_hours = [_safe_float(r.get("sleep_duration_hrs")) for r in wearable_rows]
    quality_7 = _rolling_avg(sleep_quality, 7)
    quality_30 = _rolling_avg(sleep_quality, 30)
    duration_7 = _rolling_avg(sleep_hours, 7)
    duration_30 = _rolling_avg(sleep_hours, 30)
    score = max(0.0, min(100.0, (quality_30 * 0.7) + (min(duration_30, 8.0) / 8.0 * 30.0)))
    return {
        "id": "sleep_recovery",
        "name": "Sleep and Recovery",
        "score": round(score, 1),
        "state": _score_to_state(score),
        "trend": _trend_from_delta((quality_7 - quality_30) + ((duration_7 - duration_30) * 5)),
        "explanation": "Sleep and recovery reflects recent sleep quality, duration, and recovery consistency.",
        "key_signals": {
            "sleep_quality_7d_avg": round(quality_7, 1),
            "sleep_quality_30d_avg": round(quality_30, 1),
            "sleep_duration_7d_avg_hrs": round(duration_7, 2),
            "sleep_duration_30d_avg_hrs": round(duration_30, 2),
        },
        "data_sources": ["wearable_telemetry_1.csv"],
    }


def _build_cardio(row: Dict[str, str], wearable_rows: List[Dict[str, str]]) -> Dict[str, Any]:
    resting_hr = [_safe_float(r.get("resting_hr_bpm")) for r in wearable_rows]
    hrv = [_safe_float(r.get("hrv_rmssd_ms")) for r in wearable_rows]
    hr_30 = _rolling_avg(resting_hr, 30)
    hr_7 = _rolling_avg(resting_hr, 7)
    hrv_30 = _rolling_avg(hrv, 30)
    hrv_7 = _rolling_avg(hrv, 7)
    bp_penalty = max(0.0, (_safe_float(row.get("sbp_mmhg")) - 120.0) * 0.5) + max(
        0.0, (_safe_float(row.get("dbp_mmhg")) - 80.0) * 0.6
    )
    score = max(0.0, min(100.0, 100.0 - (hr_30 - 58.0) - bp_penalty + (hrv_30 * 0.35)))
    return {
        "id": "cardiovascular_health",
        "name": "Cardiovascular Health",
        "score": round(score, 1),
        "state": _score_to_state(score),
        "trend": _trend_from_delta((hrv_7 - hrv_30) - (hr_7 - hr_30)),
        "explanation": "Cardiovascular health combines resting heart rate, HRV, and blood pressure context.",
        "key_signals": {
            "resting_hr_7d_avg": round(hr_7, 1),
            "resting_hr_30d_avg": round(hr_30, 1),
            "hrv_7d_avg": round(hrv_7, 1),
            "hrv_30d_avg": round(hrv_30, 1),
            "sbp_mmhg": _safe_float(row.get("sbp_mmhg")),
            "dbp_mmhg": _safe_float(row.get("dbp_mmhg")),
        },
        "data_sources": ["wearable_telemetry_1.csv", "ehr_records.csv"],
    }


def _build_metabolic(row: Dict[str, str]) -> Dict[str, Any]:
    bmi = _safe_float(row.get("bmi"))
    hba1c = _safe_float(row.get("hba1c_pct"))
    glucose = _safe_float(row.get("fasting_glucose_mmol"))
    ldl = _safe_float(row.get("ldl_mmol"))
    score = max(
        0.0,
        min(100.0, 100.0 - max(0.0, (bmi - 23) * 2.4) - max(0.0, (hba1c - 5.4) * 12.0) - max(0.0, (glucose - 5.2) * 10.0) - max(0.0, (ldl - 2.6) * 7.0)),
    )
    return {
        "id": "metabolic_health",
        "name": "Metabolic Health",
        "score": round(score, 1),
        "state": _score_to_state(score),
        "trend": "stable" if score >= 60 else "drifting",
        "explanation": "Metabolic health is estimated from BMI, glycemic markers, and lipids.",
        "key_signals": {
            "bmi": bmi,
            "hba1c_pct": hba1c,
            "fasting_glucose_mmol": glucose,
            "ldl_mmol": ldl,
        },
        "data_sources": ["ehr_records.csv"],
    }


def _build_movement(lifestyle_row: Dict[str, str], wearable_rows: List[Dict[str, str]]) -> Dict[str, Any]:
    steps = [_safe_float(r.get("steps")) for r in wearable_rows]
    active = [_safe_float(r.get("active_minutes")) for r in wearable_rows]
    steps_7 = _rolling_avg(steps, 7)
    steps_30 = _rolling_avg(steps, 30)
    active_7 = _rolling_avg(active, 7)
    active_30 = _rolling_avg(active, 30)
    exercise_weekly = _safe_float(lifestyle_row.get("exercise_sessions_weekly"))
    score = min(100.0, (steps_30 / 9000.0) * 45 + (active_30 / 45.0) * 35 + (exercise_weekly / 5.0) * 20)
    return {
        "id": "movement_fitness",
        "name": "Movement and Fitness",
        "score": round(score, 1),
        "state": _score_to_state(score),
        "trend": _trend_from_delta(((steps_7 - steps_30) / 250.0) + (active_7 - active_30)),
        "explanation": "Movement and fitness combines step volume, active minutes, and exercise frequency.",
        "key_signals": {
            "steps_7d_avg": round(steps_7, 1),
            "steps_30d_avg": round(steps_30, 1),
            "active_minutes_7d_avg": round(active_7, 1),
            "active_minutes_30d_avg": round(active_30, 1),
            "exercise_sessions_weekly": exercise_weekly,
        },
        "data_sources": ["wearable_telemetry_1.csv", "lifestyle_survey.csv"],
    }


def _build_nutrition(lifestyle_row: Dict[str, str], ehr_row: Dict[str, str]) -> Dict[str, Any]:
    diet_quality = _safe_float(lifestyle_row.get("diet_quality_score"))
    fruit_veg = _safe_float(lifestyle_row.get("fruit_veg_servings_daily"))
    water = _safe_float(lifestyle_row.get("water_glasses_daily"))
    alcohol = _safe_float(lifestyle_row.get("alcohol_units_weekly") or ehr_row.get("alcohol_units_weekly"))
    alcohol_penalty = max(0.0, (alcohol - 10.0) * 3.5)
    score = max(0.0, min(100.0, (diet_quality / 10.0) * 45 + (fruit_veg / 5.0) * 30 + (water / 8.0) * 25 - alcohol_penalty))
    return {
        "id": "nutrition_quality",
        "name": "Nutrition Quality",
        "score": round(score, 1),
        "state": _score_to_state(score),
        "trend": "stable" if score >= 60 else "drifting",
        "explanation": "Nutrition quality reflects diet quality, plant intake, hydration, and alcohol load.",
        "key_signals": {
            "diet_quality_score": diet_quality,
            "fruit_veg_servings_daily": fruit_veg,
            "water_glasses_daily": water,
            "alcohol_units_weekly": alcohol,
        },
        "data_sources": ["lifestyle_survey.csv", "ehr_records.csv"],
    }


def _build_mental(lifestyle_row: Dict[str, str]) -> Dict[str, Any]:
    stress = _safe_float(lifestyle_row.get("stress_level"))
    wellbeing = _safe_float(lifestyle_row.get("mental_wellbeing_who5"))
    self_rated = _safe_float(lifestyle_row.get("self_rated_health"))
    sleep_sat = _safe_float(lifestyle_row.get("sleep_satisfaction"))
    stress_score = max(0.0, 100.0 - (stress * 10.0))
    wellbeing_score = min(100.0, (wellbeing / 25.0) * 100.0)
    self_rated_score = min(100.0, (self_rated / 5.0) * 100.0)
    sleep_sat_score = min(100.0, (sleep_sat / 7.0) * 100.0)
    score = (stress_score * 0.30) + (wellbeing_score * 0.35) + (self_rated_score * 0.20) + (sleep_sat_score * 0.15)
    trend = "improving" if stress <= 4 and wellbeing >= 18 else ("stable" if score >= 60 else "drifting")
    return {
        "id": "mental_resilience",
        "name": "Mental Resilience",
        "score": round(score, 1),
        "state": _score_to_state(score),
        "trend": trend,
        "explanation": "Mental resilience reflects stress load, wellbeing, and perceived health/recovery.",
        "key_signals": {
            "stress_level": stress,
            "mental_wellbeing_who5": wellbeing,
            "self_rated_health": self_rated,
            "sleep_satisfaction": sleep_sat,
        },
        "data_sources": ["lifestyle_survey.csv"],
    }


def analyze_patient_six_pillars(patient_id: str) -> Dict[str, Any]:
    """Analyze all six pillars from raw datasets and Firestore context."""
    ehr_row = _find_latest_row(_load_csv_rows(EHR_FILE), patient_id, "patient_id")
    lifestyle_row = _find_latest_row(_load_csv_rows(LIFESTYLE_FILE), patient_id, "survey_date")
    wearable_rows = _find_wearable_rows(patient_id)

    if ehr_row is None or lifestyle_row is None or not wearable_rows:
        return {
            "ok": False,
            "patient_id": patient_id,
            "error": "Missing patient data in one or more raw CSV files.",
            "required_files": [str(EHR_FILE), str(LIFESTYLE_FILE), str(WEARABLE_FILE)],
        }

    pillars = [
        _build_sleep(ehr_row, wearable_rows),
        _build_cardio(ehr_row, wearable_rows),
        _build_metabolic(ehr_row),
        _build_movement(lifestyle_row, wearable_rows),
        _build_nutrition(lifestyle_row, ehr_row),
        _build_mental(lifestyle_row),
    ]
    pillars.sort(key=lambda item: PILLARS.index(item["id"]))

    avg_score = round(mean(p["score"] for p in pillars), 1)
    drifting = sum(1 for p in pillars if p["trend"] == "drifting")
    overall = "drifting" if drifting >= 3 or avg_score < 55 else ("on_track" if drifting == 0 and avg_score >= 70 else "mixed")
    primary_focus = sorted(pillars, key=lambda p: (p["score"], 0 if p["trend"] == "drifting" else 1))[0]

    firebase_context = get_patient_firebase_context(patient_id)
    firebase_summary = (
        "No patient-specific Firestore documents found in checked collections."
        if not firebase_context["collections_found"]
        else f"Found data in: {', '.join(firebase_context['collections_found'])}."
    )

    return {
        "ok": True,
        "patient_id": patient_id,
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "overall_direction": overall,
        "average_score": avg_score,
        "primary_focus": {
            "pillar_id": primary_focus["id"],
            "pillar_name": primary_focus["name"],
            "why_now": f"{primary_focus['name']} has the lowest current score/trend blend and is the best immediate lever.",
        },
        "pillars": pillars,
        "firebase_context_summary": firebase_summary,
        "firebase_context": firebase_context,
        "data_sources": [
            "data/raw/ehr_records.csv",
            "data/raw/lifestyle_survey.csv",
            "data/raw/wearable_telemetry_1.csv",
            "firestore",
        ],
    }


def explain_single_pillar(patient_id: str, pillar_id: str) -> Dict[str, Any]:
    """Return a focused explanation for one requested pillar."""
    analysis = analyze_patient_six_pillars(patient_id)
    if not analysis.get("ok"):
        return analysis

    lookup = {pillar["id"]: pillar for pillar in analysis["pillars"]}
    pillar = lookup.get(pillar_id)
    if pillar is None:
        return {
            "ok": False,
            "patient_id": patient_id,
            "error": f"Unknown pillar_id '{pillar_id}'.",
            "allowed_pillars": PILLARS,
        }

    return {
        "ok": True,
        "patient_id": patient_id,
        "pillar": pillar,
        "explanation": (
            f"{pillar['name']} is currently '{pillar['state']}' with trend '{pillar['trend']}' "
            f"and score {pillar['score']}. Key signals: {pillar['key_signals']}."
        ),
        "firebase_context_summary": analysis["firebase_context_summary"],
    }


def generate_tailored_explanation(patient_id: str) -> Dict[str, Any]:
    """Generate evidence-based, personalized coaching explanation content.

    This function returns structured narrative components that the ADK model can
    turn into natural language while preserving explicit evidence citations and
    safety boundaries.
    """
    analysis = analyze_patient_six_pillars(patient_id)
    if not analysis.get("ok"):
        return analysis

    pillars = analysis["pillars"]
    sorted_by_risk = sorted(
        pillars, key=lambda p: (p["score"], 0 if p["trend"] == "drifting" else 1)
    )
    focus = sorted_by_risk[0]
    secondary = sorted_by_risk[1] if len(sorted_by_risk) > 1 else focus
    strongest = sorted(pillars, key=lambda p: p["score"], reverse=True)[0]

    claims = [
        {
            "claim": f"{focus['name']} is the top priority right now.",
            "why": "It has the weakest score/trend combination among the six pillars.",
            "evidence": [
                {
                    "pillar_id": focus["id"],
                    "score": focus["score"],
                    "trend": focus["trend"],
                    "state": focus["state"],
                    "key_signals": focus["key_signals"],
                    "data_sources": focus["data_sources"],
                }
            ],
        },
        {
            "claim": f"{strongest['name']} is currently a relative strength to protect.",
            "why": "Preserving strong areas helps maintain momentum while improving weaker pillars.",
            "evidence": [
                {
                    "pillar_id": strongest["id"],
                    "score": strongest["score"],
                    "trend": strongest["trend"],
                    "state": strongest["state"],
                    "key_signals": strongest["key_signals"],
                    "data_sources": strongest["data_sources"],
                }
            ],
        },
    ]

    trade_offs = [
        {
            "topic": "Focus depth vs. breadth",
            "detail": (
                f"Concentrating on {focus['name']} may yield faster short-term gains, "
                f"but ignoring {secondary['name']} can limit overall trajectory improvement."
            ),
            "evidence": [
                {
                    "primary_focus_score": focus["score"],
                    "secondary_score": secondary["score"],
                    "overall_direction": analysis["overall_direction"],
                }
            ],
        }
    ]

    next_best_actions = [
        {
            "action": f"Prioritize one weekly behavior change for {focus['name']}.",
            "why": "Single-habit focus improves adherence and makes trend changes measurable.",
            "evidence": {
                "focus_pillar": focus["id"],
                "focus_signals": focus["key_signals"],
            },
        },
        {
            "action": f"Protect current habits supporting {strongest['name']}.",
            "why": "Regression in strong pillars can offset progress in weaker ones.",
            "evidence": {
                "strength_pillar": strongest["id"],
                "strength_signals": strongest["key_signals"],
            },
        },
    ]

    return {
        "ok": True,
        "patient_id": patient_id,
        "context": {
            "overall_direction": analysis["overall_direction"],
            "average_score": analysis["average_score"],
            "firebase_context_summary": analysis["firebase_context_summary"],
        },
        "claims": claims,
        "trade_offs": trade_offs,
        "next_best_actions": next_best_actions,
        "evidence_index": {
            pillar["id"]: {
                "score": pillar["score"],
                "trend": pillar["trend"],
                "state": pillar["state"],
                "key_signals": pillar["key_signals"],
                "data_sources": pillar["data_sources"],
            }
            for pillar in pillars
        },
        "safety_guardrails": [
            "Do not diagnose conditions or claim clinical certainty.",
            "Use uncertainty language when data is sparse or conflicting.",
            "Frame guidance as wellness coaching support, not medical advice.",
            "Recommend clinician follow-up for elevated risk patterns.",
        ],
        "required_response_style": {
            "must_cite_evidence": True,
            "must_reference_data_points": True,
            "must_include_uncertainty_statement": True,
            "must_avoid_diagnosis": True,
        },
    }
