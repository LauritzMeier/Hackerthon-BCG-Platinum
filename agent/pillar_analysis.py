"""Six-pillar analysis logic using raw CSV inputs + Firestore context."""

from __future__ import annotations

import csv
from datetime import datetime
from functools import lru_cache
import os
from pathlib import Path
from statistics import mean
from typing import Any, Dict, List, Optional

from .coach_voice import derive_persona_context
from .firebase_client import get_patient_conversation_state, get_patient_firebase_context
from .patient_updates import apply_patient_reported_updates
from longevity_mvp.bootstrap import ensure_local_warehouse
from longevity_mvp.cardiovascular import assess_cardiovascular_health
from longevity_mvp.repository import WarehouseRepository

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


@lru_cache(maxsize=1)
def _repository() -> WarehouseRepository:
    ensure_local_warehouse()
    return WarehouseRepository()


def _flag_enabled(*names: str) -> bool:
    return any(os.getenv(name, "").lower() in {"1", "true", "yes", "on"} for name in names)


def _is_firestore_debug_enabled() -> bool:
    return _flag_enabled("AGENT_DEBUG", "AGENT_DEBUG_FIRESTORE")


def _firebase_debug_suffix(firebase_context: Dict[str, Any]) -> str:
    if not _is_firestore_debug_enabled():
        return ""
    parts: List[str] = []
    if firebase_context.get("lookup_status"):
        parts.append(f"lookup_status={firebase_context['lookup_status']}")
    if firebase_context.get("failure_stage"):
        parts.append(f"failure_stage={firebase_context['failure_stage']}")
    if firebase_context.get("warning"):
        parts.append(f"warning={firebase_context['warning']}")
    return " | ".join(parts)


def _summarize_firebase_context(firebase_context: Dict[str, Any]) -> str:
    if firebase_context.get("warning") and not firebase_context.get("collections_found"):
        summary = "Firestore context unavailable; using CSV-only analysis for this response."
        debug_suffix = _firebase_debug_suffix(firebase_context)
        return f"{summary} Debug: {debug_suffix}." if debug_suffix else summary

    normalized = firebase_context.get("normalized") or {}
    if normalized.get("context_format") == "overview_v1":
        pillar_count = len(normalized.get("pillar_mappings") or [])
        opportunity_count = len(normalized.get("opportunities") or [])
        prompt_count = len(normalized.get("engagement_prompts") or [])
        primary_focus = normalized.get("primary_focus") or {}
        focus_name = primary_focus.get("pillar_name")
        parts = [
            f"Loaded overview context with {pillar_count} pillar mappings",
            f"{opportunity_count} actionable opportunities",
            f"and {prompt_count} engagement prompts",
        ]
        summary = " ".join([" ".join(parts[:1]), " ".join(parts[1:])]).strip()
        if focus_name:
            summary = f"{summary}. Firestore primary focus: {focus_name}."
        else:
            summary = f"{summary}."
        if firebase_context.get("warning"):
            debug_suffix = _firebase_debug_suffix(firebase_context)
            if debug_suffix:
                summary = f"{summary} Firestore note: {debug_suffix}."
            else:
                summary = f"{summary} Firestore note: partial Firestore read."
        return summary

    if firebase_context.get("warning"):
        summary = "Firestore context unavailable; using CSV-only analysis for this response."
        debug_suffix = _firebase_debug_suffix(firebase_context)
        return f"{summary} Debug: {debug_suffix}." if debug_suffix else summary
    if not firebase_context.get("collections_found"):
        return "No patient-specific Firestore documents found in checked collections."
    return f"Found data in: {', '.join(firebase_context['collections_found'])}."


def _pick_focus_prompt(firebase_context: Dict[str, Any], focus_pillar_id: str) -> Optional[Dict[str, Any]]:
    normalized = firebase_context.get("normalized") or {}
    prompts = normalized.get("engagement_prompts") or []
    for prompt in prompts:
        if focus_pillar_id in (prompt.get("derived_from_pillars") or []):
            return prompt
    return prompts[0] if prompts else None


def _pick_focus_opportunity(firebase_context: Dict[str, Any], focus_pillar_id: str) -> Optional[Dict[str, Any]]:
    normalized = firebase_context.get("normalized") or {}
    opportunities = normalized.get("opportunities") or []
    for opportunity in opportunities:
        if focus_pillar_id in (opportunity.get("trigger_pillars") or []):
            return opportunity
    return opportunities[0] if opportunities else None


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


def _safe_int(value: Any) -> int | None:
    try:
        if value in (None, ""):
            return None
        return int(float(value))
    except (TypeError, ValueError):
        return None


def _patient_profile_summary(profile: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "age": _safe_int(profile.get("age")),
        "country": profile.get("country"),
        "sex": profile.get("sex"),
        "estimated_biological_age": _safe_float(profile.get("estimated_biological_age"), default=None),
        "primary_focus_area": profile.get("primary_focus_area"),
    }


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


def _build_sleep(profile: Dict[str, Any]) -> Dict[str, Any]:
    quality_7 = _safe_float(profile.get("sleep_quality_7d_avg"))
    quality_30 = _safe_float(profile.get("sleep_quality_30d_avg"))
    duration_7 = _safe_float(profile.get("sleep_duration_7d_avg"))
    duration_30 = _safe_float(profile.get("sleep_duration_30d_avg"))
    deep_sleep_30 = _safe_float(profile.get("deep_sleep_30d_avg"))
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
            "deep_sleep_30d_avg_pct": round(deep_sleep_30, 2),
            "sleep_satisfaction": _safe_float(profile.get("sleep_satisfaction")),
        },
        "data_sources": ["curated.patient_metrics", "curated.patient_profile"],
    }


def _build_cardio(profile: Dict[str, Any]) -> Dict[str, Any]:
    assessment = assess_cardiovascular_health(profile)
    score = assessment["score"]
    return {
        "id": "cardiovascular_health",
        "name": "Cardiovascular Health",
        "score": round(score, 1),
        "state": _score_to_state(score),
        "trend": assessment["trend"],
        "explanation": assessment["summary"],
        "key_signals": {
            **assessment["key_signals"],
            "spo2_7d_avg_pct": round(_safe_float(profile.get("spo2_7d_avg")), 1),
            "spo2_30d_avg_pct": round(_safe_float(profile.get("spo2_30d_avg")), 1),
        },
        "data_sources": ["curated.patient_metrics", "curated.patient_profile"],
    }


def _build_metabolic(profile: Dict[str, Any]) -> Dict[str, Any]:
    bmi = _safe_float(profile.get("bmi"))
    hba1c = _safe_float(profile.get("hba1c_pct"))
    glucose = _safe_float(profile.get("fasting_glucose_mmol"))
    ldl = _safe_float(profile.get("ldl_mmol"))
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
            "triglycerides_mmol": _safe_float(profile.get("triglycerides_mmol")),
        },
        "data_sources": ["curated.patient_profile"],
    }


def _build_movement(profile: Dict[str, Any]) -> Dict[str, Any]:
    steps_7 = _safe_float(profile.get("steps_7d_avg"))
    steps_30 = _safe_float(profile.get("steps_30d_avg"))
    active_7 = _safe_float(profile.get("active_minutes_7d_avg"))
    active_30 = _safe_float(profile.get("active_minutes_30d_avg"))
    exercise_weekly = _safe_float(profile.get("exercise_sessions_weekly"))
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
            "sedentary_hrs_day": _safe_float(profile.get("sedentary_hrs_day")),
        },
        "data_sources": ["curated.patient_metrics", "curated.patient_profile"],
    }


def _build_nutrition(profile: Dict[str, Any]) -> Dict[str, Any]:
    diet_quality = _safe_float(profile.get("diet_quality_score"))
    fruit_veg = _safe_float(profile.get("fruit_veg_servings_daily"))
    water = _safe_float(profile.get("water_glasses_daily"))
    alcohol = _safe_float(profile.get("current_alcohol_units_weekly"))
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
            "crp_mg_l": _safe_float(profile.get("crp_mg_l")),
        },
        "data_sources": ["curated.patient_profile"],
    }


def _build_mental(profile: Dict[str, Any]) -> Dict[str, Any]:
    stress = _safe_float(profile.get("stress_level"))
    wellbeing = _safe_float(profile.get("mental_wellbeing_who5"))
    self_rated = _safe_float(profile.get("self_rated_health"))
    sleep_sat = _safe_float(profile.get("sleep_satisfaction"))
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
        "data_sources": ["curated.patient_profile"],
    }


def analyze_patient_six_pillars(
    patient_id: str,
    firebase_context: Optional[Dict[str, Any]] = None,
    conversation_context: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Analyze all six pillars from curated warehouse data and Firestore context."""
    profile = _repository().get_patient_profile(patient_id)

    if profile is None:
        return {
            "ok": False,
            "patient_id": patient_id,
            "error": "Missing patient data in curated warehouse tables.",
            "required_sources": [
                "curated.patient_profile",
                "curated.patient_metrics",
                "curated.coach_context",
            ],
        }

    pillars = [
        _build_sleep(profile),
        _build_cardio(profile),
        _build_metabolic(profile),
        _build_movement(profile),
        _build_nutrition(profile),
        _build_mental(profile),
    ]

    conversation_context = conversation_context or get_patient_conversation_state(patient_id)
    patient_update_effect = apply_patient_reported_updates(
        pillars,
        conversation_context.get("patient_reported_updates") or [],
        score_to_state=_score_to_state,
    )
    pillars = patient_update_effect["pillars"]
    pillars.sort(key=lambda item: PILLARS.index(item["id"]))
    persona_context = derive_persona_context(profile)
    patient_profile = _patient_profile_summary(profile)

    avg_score = round(mean(p["score"] for p in pillars), 1)
    drifting = sum(1 for p in pillars if p["trend"] == "drifting")
    overall = "drifting" if drifting >= 3 or avg_score < 55 else ("on_track" if drifting == 0 and avg_score >= 70 else "mixed")
    primary_focus = sorted(pillars, key=lambda p: (p["score"], 0 if p["trend"] == "drifting" else 1))[0]

    firebase_context = firebase_context or get_patient_firebase_context(patient_id)
    firebase_summary = _summarize_firebase_context(firebase_context)

    response = {
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
        "conversation_context": conversation_context,
        "patient_profile": patient_profile,
        "persona_context": persona_context,
        "patient_update_effect": patient_update_effect,
        "data_sources": [
            "curated.patient_profile",
            "curated.patient_metrics",
            "curated.coach_context",
            "firestore",
        ],
    }
    if firebase_context.get("diagnostics"):
        response["firebase_debug"] = firebase_context["diagnostics"]
    return response


def explain_single_pillar(
    patient_id: str,
    pillar_id: str,
    analysis: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Return a focused explanation for one requested pillar."""
    analysis = analysis or analyze_patient_six_pillars(patient_id)
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
        "firebase_context": analysis["firebase_context"],
        "patient_profile": analysis.get("patient_profile"),
        "persona_context": analysis.get("persona_context"),
        "firebase_debug": analysis.get("firebase_debug"),
    }


def generate_tailored_explanation(
    patient_id: str,
    analysis: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Generate evidence-based, personalized coaching explanation content.

    This function returns structured narrative components that the ADK model can
    turn into natural language while preserving explicit evidence citations and
    safety boundaries.
    """
    analysis = analysis or analyze_patient_six_pillars(patient_id)
    if not analysis.get("ok"):
        return analysis

    pillars = analysis["pillars"]
    sorted_by_risk = sorted(
        pillars, key=lambda p: (p["score"], 0 if p["trend"] == "drifting" else 1)
    )
    focus = sorted_by_risk[0]
    secondary = sorted_by_risk[1] if len(sorted_by_risk) > 1 else focus
    strongest = sorted(pillars, key=lambda p: p["score"], reverse=True)[0]
    focus_prompt = _pick_focus_prompt(analysis["firebase_context"], focus["id"])
    focus_opportunity = _pick_focus_opportunity(analysis["firebase_context"], focus["id"])

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
    if focus_opportunity:
        claims.append(
            {
                "claim": f"{focus_opportunity.get('title', 'A coaching opportunity')} is relevant right now.",
                "why": focus_opportunity.get("why_now", "The Firestore strategy context highlights it for this patient."),
                "evidence": [
                    {
                        "pillar_id": focus["id"],
                        "score": focus["score"],
                        "trend": focus["trend"],
                        "state": focus["state"],
                        "key_signals": focus["key_signals"],
                        "firestore_context": focus_opportunity.get("evidence", {}),
                        "data_sources": focus["data_sources"] + ["firestore"],
                    }
                ],
            }
        )

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
    if focus_prompt:
        next_best_actions.append(
            {
                "action": f"Ask the patient a low-friction follow-up: {focus_prompt.get('title', 'context check')}.",
                "why": focus_prompt.get(
                    "value",
                    "Capturing context makes the next coaching step more specific and more actionable.",
                ),
                "evidence": {
                    "focus_pillar": focus["id"],
                    "prompt_example": focus_prompt.get("example_prompt"),
                    "derived_from_pillars": focus_prompt.get("derived_from_pillars", []),
                },
            }
        )
    if focus_opportunity:
        next_best_actions.append(
            {
                "action": f"Consider offering: {focus_opportunity.get('title', 'support option')}.",
                "why": focus_opportunity.get(
                    "coach_prompt",
                    "The Firestore strategy context marks it as a relevant next step.",
                ),
                "evidence": {
                    "focus_pillar": focus["id"],
                    "opportunity_type": focus_opportunity.get("type"),
                    "priority": focus_opportunity.get("priority"),
                    "trigger_pillars": focus_opportunity.get("trigger_pillars", []),
                },
            }
        )

    response = {
        "ok": True,
        "patient_id": patient_id,
        "context": {
            "overall_direction": analysis["overall_direction"],
            "average_score": analysis["average_score"],
            "firebase_context_summary": analysis["firebase_context_summary"],
        },
        "firebase_context_summary": analysis["firebase_context_summary"],
        "firebase_context": analysis["firebase_context"],
        "patient_profile": analysis.get("patient_profile"),
        "persona_context": analysis.get("persona_context"),
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
    if analysis.get("firebase_debug"):
        response["firebase_debug"] = analysis["firebase_debug"]
    return response
