from __future__ import annotations

from datetime import datetime, timezone
from typing import Dict, List

from .offer_catalog import get_offer_catalog_entry


WELCOME_PATIENT_ID = "PT0000"


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _data_source(
    source_id: str,
    label: str,
    category: str,
    *,
    connected: bool,
    provider: str = "",
    status_text: str,
    cta_label: str,
) -> Dict:
    return {
        "source_id": source_id,
        "label": label,
        "category": category,
        "connected": connected,
        "provider": provider,
        "status_text": status_text,
        "cta_label": cta_label,
    }


def _offer_item(
    offer_code: str,
    *,
    priority: int,
    rationale: str,
) -> Dict:
    blueprint = get_offer_catalog_entry(offer_code)
    return {
        "offer_code": offer_code,
        "offer_label": blueprint["offer_label"],
        "priority": priority,
        "rationale": rationale,
        "category": blueprint["category"],
        "offer_type": blueprint["offer_type"],
        "delivery_model": blueprint["delivery_model"],
        "summary": blueprint["summary"],
        "why_now": blueprint["why_now_template"],
        "includes": list(blueprint["includes"]),
        "expected_outcome": blueprint["expected_outcome"],
        "time_commitment": blueprint["time_commitment"],
        "data_used": list(blueprint["data_used"]),
        "missing_data": list(blueprint["missing_data"]),
        "first_week": list(blueprint["first_week"]),
        "caution": blueprint["caution_template"],
        "personalization_note": blueprint["personalization_note"],
        "cta_label": blueprint.get("cta_label", ""),
        "active": bool(blueprint.get("active", True)),
        "sort_order": blueprint.get("sort_order", 999),
    }


def build_customer_profile(bundle: Dict) -> Dict:
    profile = bundle["profile"]
    has_wearable = bool(profile.get("latest_wearable_date"))
    has_medical_context = bool(profile.get("visit_history") or profile.get("medications"))
    has_labs = any(
        profile.get(field) is not None
        for field in ("hba1c_pct", "fasting_glucose_mmol", "ldl_mmol", "bmi")
    )
    has_meal_tracking = bool(profile.get("meals_logged_days"))

    data_sources = [
        _data_source(
            "smartwatch",
            "Smartwatch or wearable",
            "Wearables",
            connected=has_wearable,
            provider="Connected wearable" if has_wearable else "",
            status_text=(
                "Already feeding movement, sleep, and recovery trends into the app."
                if has_wearable
                else "Connect a watch or ring to unlock recovery and activity trends."
            ),
            cta_label="Connect wearable",
        ),
        _data_source(
            "doctor_records",
            "Doctor records",
            "Medical context",
            connected=has_medical_context,
            provider="Imported records" if has_medical_context else "",
            status_text=(
                "Your clinician context is already helping the coach start informed."
                if has_medical_context
                else "Add your last visit summary or medication list so the coach does not start blind."
            ),
            cta_label="Add doctor context",
        ),
        _data_source(
            "lab_results",
            "Lab results",
            "Diagnostics",
            connected=has_labs,
            provider="Imported labs" if has_labs else "",
            status_text=(
                "Baseline metabolic and cardiovascular markers are already on file."
                if has_labs
                else "Connect baseline labs if you want early recommendations to lean on objective markers."
            ),
            cta_label="Add labs",
        ),
        _data_source(
            "meal_tracking",
            "Meal tracking",
            "Lifestyle",
            connected=has_meal_tracking,
            provider="In-app tracking" if has_meal_tracking else "",
            status_text=(
                "Nutrition is using real meal logs instead of broad estimates."
                if has_meal_tracking
                else "Turn this on later if you want more specific nutrition guidance."
            ),
            cta_label="Turn on meal tracking",
        ),
    ]

    connected_count = sum(1 for source in data_sources if source["connected"])
    return {
        "patient_id": profile["patient_id"],
        "display_name": profile["patient_id"],
        "journey_stage": "active",
        "journey_title": "Your connected setup",
        "journey_summary": (
            "These are the data sources currently shaping your plan."
            if connected_count > 0
            else "Connect one more source if you want the app to get sharper over time."
        ),
        "possibilities": [
            "Use the coach to explain the current plan in plain language.",
            "Book clinic support when you want a real next step, not just information.",
            "Connect one more source if you want later recommendations to become more precise.",
        ],
        "data_sources": data_sources,
        "updated_at": _now_iso(),
    }


def build_welcome_customer_profile() -> Dict:
    return {
        "patient_id": WELCOME_PATIENT_ID,
        "display_name": "Patient 0",
        "journey_stage": "welcome",
        "journey_title": "Start your longevity journey",
        "journey_summary": (
            "Start with one source, one clear goal, and one first booking. "
            "That is enough to make the next screens meaningfully better."
        ),
        "possibilities": [
            "Connect a wearable to start sleep, movement, and recovery trends.",
            "Add your last doctor summary so the coach can explain your situation without starting from zero.",
            "Book an intake, screening visit, or baseline labs if you want a clinician-led starting point.",
        ],
        "data_sources": [
            _data_source(
                "smartwatch",
                "Smartwatch or wearable",
                "Wearables",
                connected=False,
                status_text="Connect Apple Watch, Garmin, Oura, Whoop, or another wearable to start trend tracking.",
                cta_label="Connect wearable",
            ),
            _data_source(
                "doctor_records",
                "Doctor records",
                "Medical context",
                connected=False,
                status_text="Add your last appointment summary, medication list, or diagnosis history.",
                cta_label="Add doctor context",
            ),
            _data_source(
                "lab_results",
                "Lab results",
                "Diagnostics",
                connected=False,
                status_text="Import baseline labs if you want earlier personalization from objective markers.",
                cta_label="Add labs",
            ),
            _data_source(
                "meal_tracking",
                "Meal tracking",
                "Lifestyle",
                connected=False,
                status_text="Save this for later. It matters most after the basics are connected.",
                cta_label="Turn on meal tracking",
            ),
        ],
        "updated_at": _now_iso(),
    }


def build_welcome_patient_summary() -> Dict:
    generated_at = _now_iso()
    return {
        "patient_id": WELCOME_PATIENT_ID,
        "age": 45,
        "sex": "female",
        "country": "Germany",
        "primary_focus_area": "Welcome journey",
        "estimated_biological_age": None,
        "generated_at": generated_at,
        "synced_at": generated_at,
    }


def build_welcome_experience() -> Dict:
    generated_at = _now_iso()
    focus = {
        "pillar_id": "foundations",
        "pillar_name": "Getting started",
        "why_now": (
            "The most helpful first move is to connect one source and choose one clear starting step, "
            "not to chase every longevity lever at once."
        ),
    }

    pillars = [
        {
            "id": "sleep_recovery",
            "name": "Sleep Recovery",
            "score": 0,
            "score_label": "?",
            "state": "watch",
            "trend": "stable",
            "why_it_matters": "Sleep becomes one of the clearest signals once a wearable is connected.",
            "has_enough_data": False,
            "score_confidence": "low",
        },
        {
            "id": "cardiovascular_health",
            "name": "Cardiovascular Health",
            "score": 0,
            "score_label": "?",
            "state": "watch",
            "trend": "stable",
            "why_it_matters": "Heart-health guidance gets stronger once records, symptoms, or baseline screening are connected.",
            "has_enough_data": False,
            "score_confidence": "low",
        },
        {
            "id": "metabolic_health",
            "name": "Metabolic Health",
            "score": 0,
            "score_label": "?",
            "state": "watch",
            "trend": "stable",
            "why_it_matters": "Labs or meal tracking are usually what make this pillar trustworthy early on.",
            "has_enough_data": False,
            "score_confidence": "low",
        },
        {
            "id": "movement_fitness",
            "name": "Movement and Fitness",
            "score": 0,
            "score_label": "?",
            "state": "watch",
            "trend": "stable",
            "why_it_matters": "A watch is the fastest way to start seeing whether movement is trending up or down.",
            "has_enough_data": False,
            "score_confidence": "low",
        },
        {
            "id": "nutrition_quality",
            "name": "Nutrition Quality",
            "score": 0,
            "score_label": "?",
            "state": "watch",
            "trend": "stable",
            "why_it_matters": "Nutrition gets more useful later, once there is at least a little real food logging.",
            "has_enough_data": False,
            "score_confidence": "low",
        },
        {
            "id": "mental_resilience",
            "name": "Mental Resilience",
            "score": 0,
            "score_label": "?",
            "state": "watch",
            "trend": "stable",
            "why_it_matters": "Stress and resilience matter from day one, even before the rest of the profile fills in.",
            "has_enough_data": False,
            "score_confidence": "low",
        },
    ]

    return {
        "patient_id": WELCOME_PATIENT_ID,
        "generated_at": generated_at,
        "profile_summary": {
            "patient_id": WELCOME_PATIENT_ID,
            "age": 45,
            "sex": "female",
            "country": "Germany",
            "estimated_biological_age": None,
            "age_gap_years": None,
        },
        "compass": {
            "overall_direction": "stable",
            "chronological_age": 45,
            "estimated_biological_age": None,
            "primary_focus": focus,
            "pillars": pillars,
            "peer_comparison": {
                "headline": "Your six-pillar compass will fill in as you connect data",
                "cohort_label": "Peer comparison appears after a little real signal is connected",
                "sample_size": 0,
                "strongest_relative_pillar_id": "",
                "biggest_gap_pillar_id": "",
                "items": [],
            },
            "summary": {
                "current_state": "Welcome journey",
                "trajectory": "stable",
                "recommended_offer": {
                    "offer_code": "longevity_intake_visit",
                    "offer_label": "Longevity intake visit",
                    "priority": 1,
                    "rationale": "A first intake visit is the clearest way to turn a blank slate into a real plan.",
                },
            },
            "suggested_questions": [
                "How do I get value from the app quickly?",
                "Which data source should I connect first?",
                "Should I start with a visit, baseline labs, or just the coach?",
            ],
        },
        "weekly_plan": {
            "title": "This week: set up the foundations",
            "primary_focus": focus,
            "actions": [
                {
                    "title": "Connect one source you can realistically keep",
                    "description": "A smartwatch or your last doctor summary is enough to make the next screens much more useful.",
                },
                {
                    "title": "Choose one starting goal",
                    "description": "Pick the thing you most want help with first, such as recovery, prevention, energy, or cardiovascular clarity.",
                },
                {
                    "title": "Book one real next step if you want clinician support",
                    "description": "Start with an intake, screening visit, or baseline labs instead of trying to do everything yourself.",
                },
            ],
            "check_in_prompt": "Tell the coach what you want from the app and what you can connect first.",
        },
        "coach": {
            "patient_id": WELCOME_PATIENT_ID,
            "coach_name": "Ava",
            "intro": (
                "Welcome. Right now, the app should help you get started without overwhelming you. "
                "Connect one useful source, choose one starting goal, and I can guide you from there."
            ),
            "suggested_prompts": [
                "What can this app help me with before I connect anything?",
                "Which data source should I connect first?",
                "What should I book first if I want a clinician-led start?",
                "How do I set this up without overcomplicating it?",
            ],
        },
        "journey_start": {
            "title": "Welcome to Longevity Compass",
            "summary": (
                "A new customer should immediately understand what the app can do, "
                "which first connections matter, and which clinic steps are worth booking early."
            ),
            "what_we_know": [
                "You are at the start of the journey, so the app should stay simple.",
                "One connected source is enough to make the next recommendations more useful.",
                "You do not need to track everything at once to get value.",
            ],
            "what_we_need": [
                "A connected wearable, doctor summary, or baseline lab panel will make the next screens more personal.",
                "A clear starting goal helps the coach filter what matters and ignore the rest.",
            ],
            "start_here": [
                "Connect a smartwatch, ring, or your last doctor summary.",
                "Tell the coach what you want help with first.",
                "Book one intake, screening, or baseline lab step if you want clinical guidance early.",
            ],
        },
        "care_context": {
            "headline": "No clinician context is connected yet.",
            "last_appointment_title": "Doctor context",
            "last_appointment_summary": (
                "No doctor summary is connected yet, so the app should stay broad until you add one."
            ),
            "medications": [],
            "conditions": [],
            "clinical_priorities": [
                "Connect one useful data source",
                "Choose a clear starting goal",
            ],
            "medical_guardrail": (
                "If you already have diagnoses, medications, or active care, add that context before following broad health suggestions."
            ),
        },
        "data_coverage": {
            "headline": "The app is ready for setup, not true personalization yet.",
            "confidence_label": "Setup stage",
            "connected_sources": [],
            "missing_sources": [
                "Connect a smartwatch or ring to start trend tracking.",
                "Add a recent doctor summary or lab result for medical context.",
                "Leave meal tracking for later unless nutrition is the main thing you want help with.",
            ],
            "tailoring_note": (
                "Start with one connection and one clear next step. That is enough to make the next screens feel much more personal."
            ),
            "needs_meal_tracking": False,
        },
        "progress_summary": {
            "latest_reading_date": None,
            "latest_snapshot": {
                "steps": None,
                "active_minutes": None,
                "sleep_duration_hrs": None,
                "sleep_quality_score": None,
                "resting_hr_bpm": None,
                "hrv_rmssd_ms": None,
            },
            "headline_trends": [],
        },
        "alerts": {
            "total_count": 0,
            "high_priority_count": 0,
            "items": [],
        },
        "offers": {
            "recommended": _offer_item(
                "longevity_intake_visit",
                priority=1,
                rationale="A first intake is the clearest way to turn a blank slate into a usable plan.",
            ),
            "additional_items": [
                _offer_item(
                    "baseline_lab_workup",
                    priority=2,
                    rationale="Baseline labs make the next recommendations less generic, even before long-term tracking exists.",
                ),
                _offer_item(
                    "cardiovascular_screening_visit",
                    priority=3,
                    rationale="A focused screening visit is useful when heart health is one of the main reasons for joining.",
                ),
            ],
        },
    }
