from __future__ import annotations

from copy import deepcopy
from typing import Dict, List


_OFFER_CATALOG = {
    "preventive_cardiometabolic_panel": {
        "offer_label": "Cardiometabolic recovery review",
        "category": "Clinical review",
        "offer_type": "appointment",
        "delivery_model": "Specialist review",
        "summary": "Bring your current risk picture, medications, and recovery trends into one practical follow-up plan.",
        "why_now_template": (
            "This is the best fit when cardiovascular or metabolic risk is active "
            "and you need a clear clinical next step."
        ),
        "includes": [
            "Review of cardiovascular and metabolic risk markers already on file",
            "Medication and follow-up question prep for the next clinician visit",
            "A simple decision on what to monitor at home versus in clinic",
        ],
        "expected_outcome": "You understand what needs clinician follow-up now and what can improve through behavior support.",
        "time_commitment": "One focused review plus a short follow-up.",
        "data_used": [
            "medical record history",
            "current medications",
            "watch-based recovery and movement trends",
        ],
        "missing_data": [
            "A week of meal logging would make any nutrition follow-up more specific.",
        ],
        "first_week": [
            "Collect the questions you want answered in the next visit",
            "Keep wearing the watch so recovery trends stay visible",
            "Stick to the current medical plan while the review is being prepared",
        ],
        "caution_template": "{medical_guardrail}",
        "personalization_note": "Best when you need medically grounded prioritization, not a generic wellness package.",
        "active": True,
        "sort_order": 10,
    },
    "movement_program": {
        "offer_label": "Guided recovery movement plan",
        "category": "Habit support",
        "offer_type": "program",
        "delivery_model": "Coached plan",
        "summary": "Restart activity with a realistic floor, safe progression, and watch-based feedback.",
        "why_now_template": "This is most useful when {focus_name_lower} is the clearest weekly lever and consistency matters more than intensity.",
        "includes": [
            "A simple weekly movement target based on current watch data",
            "Progression that starts with consistency before intensity",
            "Check-ins that connect movement back to recovery",
        ],
        "expected_outcome": "You move more consistently without feeling dropped into a hard training plan.",
        "time_commitment": "Short daily movement blocks plus one weekly review.",
        "data_used": [
            "steps",
            "active minutes",
            "resting heart rate and recovery trends",
        ],
        "missing_data": [
            "Symptom check-ins after exercise would make the pacing more precise.",
        ],
        "first_week": [
            "Set a floor you can keep every day",
            "Notice how energy and recovery respond",
            "Adjust the plan if recovery feels off",
        ],
        "caution_template": "{medical_guardrail}",
        "personalization_note": "Good when you need structure and reassurance more than intensity.",
        "active": True,
        "sort_order": 20,
    },
    "nutrition_coaching": {
        "offer_label": "Nutrition coaching reset",
        "category": "Behavior coaching",
        "offer_type": "coaching",
        "delivery_model": "Coach-led program",
        "summary": "Start with simple meal tracking so nutrition support becomes personal instead of generic.",
        "why_now_template": (
            "Nutrition matters here, but this offer makes the most sense once a small amount of real meal logging is in place."
        ),
        "includes": [
            "A one-meal-a-day tracking habit to get real signal",
            "Pattern review around fiber, protein, hydration, and alcohol",
            "Small changes that fit the current recovery or risk-reduction goal",
        ],
        "expected_outcome": "You get a more trustworthy nutrition plan because the app finally sees real eating patterns.",
        "time_commitment": "A few minutes per day for logging and one short weekly review.",
        "data_used": [
            "survey-level nutrition habits",
            "metabolic risk markers",
            "watch-based energy and activity context",
        ],
        "missing_data": [
            "Meal-by-meal logs would make this meaningfully more tailored.",
        ],
        "first_week": [
            "Log one meal a day for seven days",
            "Notice one repeated nutrition drag",
            "Choose one change instead of trying to fix everything",
        ],
        "caution_template": (
            "Use this for personalization and habit support, not as a substitute for clinician advice after an acute event."
        ),
        "personalization_note": "Useful, but it becomes much stronger after one week of meal tracking.",
        "active": True,
        "sort_order": 30,
    },
    "sleep_recovery_package": {
        "offer_label": "Sleep and recovery reset",
        "category": "Recovery support",
        "offer_type": "program",
        "delivery_model": "Recovery package",
        "summary": "Use recovery habits and sleep structure to improve resilience before everything else feels harder.",
        "why_now_template": "This fits when {focus_name_lower} is limited by poor sleep, stress, or low recovery capacity.",
        "includes": [
            "Simple sleep window and wind-down adjustments",
            "Recovery review using watch data",
            "A plan that links sleep improvements back to energy and consistency",
        ],
        "expected_outcome": "You feel steadier and better able to follow the rest of the plan.",
        "time_commitment": "Short nightly routine changes and one weekly review.",
        "data_used": [
            "sleep duration",
            "sleep quality",
            "resting heart rate and HRV",
        ],
        "missing_data": [
            "Daytime symptom and caffeine timing data would make this more specific.",
        ],
        "first_week": [
            "Protect one consistent bedtime window",
            "Reduce one friction point before bed",
            "Review what helped or hurt recovery this week",
        ],
        "caution_template": "Use this as support, not as a substitute for clinician follow-up if symptoms or recovery worsen.",
        "personalization_note": "Good when sleep is the bottleneck behind everything else.",
        "active": True,
        "sort_order": 40,
    },
    "follow_up_prep": {
        "offer_label": "Next appointment prep",
        "category": "Follow-up support",
        "offer_type": "appointment_prep",
        "delivery_model": "Preparation visit",
        "summary": "Turn your doctor history and current signals into better questions for the next visit.",
        "why_now_template": "This is useful early in the journey, before you trust the plan and while the next clinical decision still feels unclear.",
        "includes": [
            "A short summary of the last relevant doctor context on file",
            "Questions to bring to the next visit",
            "A checklist of what to monitor before the appointment",
        ],
        "expected_outcome": "You arrive at the next appointment feeling prepared instead of overwhelmed.",
        "time_commitment": "One preparation session before the next visit.",
        "data_used": [
            "doctor visit history",
            "medication list",
            "current compass priorities",
        ],
        "missing_data": [],
        "first_week": [
            "Save questions while they come up",
            "Keep the coach updated on changes or concerns",
            "Track one habit the clinician is likely to ask about",
        ],
        "caution_template": "{medical_guardrail}",
        "personalization_note": "Especially useful early in the journey, before the rest of the plan feels intuitive.",
        "active": True,
        "sort_order": 50,
    },
    "meal_tracking_reset": {
        "offer_label": "7-day meal tracking starter",
        "category": "Data setup",
        "offer_type": "starter",
        "delivery_model": "Self-guided starter",
        "summary": "Give the app enough real food data to tailor nutrition instead of guessing.",
        "why_now_template": "Use this when nutrition should matter more, but the app still needs a little real food signal before coaching can be specific.",
        "includes": [
            "One simple meal log per day",
            "A review of repeated patterns after one week",
            "A clearer handoff into nutrition support if it is still needed",
        ],
        "expected_outcome": "Nutrition recommendations stop feeling generic because the app finally sees real eating behavior.",
        "time_commitment": "Two to three minutes per day.",
        "data_used": [
            "broad lifestyle habits",
            "metabolic signals",
        ],
        "missing_data": [],
        "first_week": [
            "Log the first meal that feels easiest to remember",
            "Do not try to be perfect; just be consistent",
            "Review the pattern at the end of the week",
        ],
        "caution_template": "This is a setup step for better personalization, not a clinical treatment.",
        "personalization_note": "Low effort, high value for a new user.",
        "active": True,
        "sort_order": 60,
    },
}


def get_offer_catalog_entry(offer_code: str) -> Dict:
    return deepcopy(_OFFER_CATALOG[offer_code])


def list_offer_catalog() -> List[Dict]:
    items = []
    for offer_code, entry in _OFFER_CATALOG.items():
        document = deepcopy(entry)
        document["offer_code"] = offer_code
        items.append(document)
    items.sort(key=lambda item: item.get("sort_order", 999))
    return items
