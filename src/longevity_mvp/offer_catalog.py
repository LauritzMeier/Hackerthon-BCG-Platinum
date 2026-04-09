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
        "cta_label": "Book review",
        "active": True,
        "sort_order": 10,
    },
    "cardiology_follow_up_visit": {
        "offer_label": "Cardiology follow-up visit",
        "category": "Cardiology visit",
        "offer_type": "appointment",
        "delivery_model": "Clinic or video visit",
        "summary": "Review symptoms, medications, recovery pace, and next clinical milestones with a cardiology team member.",
        "why_now_template": (
            "This is a strong fit when heart-related follow-up is still active and you need a clear next appointment instead of another generic program."
        ),
        "includes": [
            "Focused review of the last relevant cardiac visit and current medications",
            "Discussion of symptoms, blood pressure, activity tolerance, and recovery questions",
            "A clear list of what to watch at home and what needs clinician escalation",
        ],
        "expected_outcome": "You leave with a clearer medical next step and less uncertainty about what matters now.",
        "time_commitment": "30 to 45 minute visit.",
        "data_used": [
            "cardiac diagnosis and visit history",
            "current medications",
            "watch-based recovery and activity trends",
        ],
        "missing_data": [],
        "first_week": [
            "Write down symptoms, questions, or medication concerns",
            "Keep the watch on so recent recovery trends are available",
            "Bring your current medication list to the visit",
        ],
        "caution_template": "{medical_guardrail}",
        "personalization_note": "Best when the user needs clinical clarity before adding more self-guided work.",
        "cta_label": "Book cardiology visit",
        "active": True,
        "sort_order": 12,
    },
    "cardiac_rehab_intake": {
        "offer_label": "Cardiac rehab intake",
        "category": "Recovery program",
        "offer_type": "program",
        "delivery_model": "Guided intake",
        "summary": "Start a supervised recovery pathway that turns movement, monitoring, and confidence-building into one structured plan.",
        "why_now_template": (
            "This makes sense when heart recovery is active and the user needs a safe progression plan, not just encouragement to move more."
        ),
        "includes": [
            "Initial review of current activity tolerance and recovery limitations",
            "A supervised progression plan for exercise, pacing, and confidence",
            "Clear escalation guidance if symptoms or fatigue increase",
        ],
        "expected_outcome": "You gain a safer and more structured path back into exercise and recovery habits.",
        "time_commitment": "Intake plus weekly rehab sessions.",
        "data_used": [
            "recent cardiac context",
            "watch-based movement and recovery trends",
            "current medication and symptom context",
        ],
        "missing_data": [],
        "first_week": [
            "Book the intake",
            "Keep activity gentle and consistent until the plan is confirmed",
            "Bring recovery questions and recent symptoms to the session",
        ],
        "caution_template": "{medical_guardrail}",
        "personalization_note": "Best when reassurance and supervised progression matter more than pushing intensity.",
        "cta_label": "Book rehab intake",
        "active": True,
        "sort_order": 14,
    },
    "advanced_lipid_lab_panel": {
        "offer_label": "Advanced lipid lab panel",
        "category": "Diagnostics",
        "offer_type": "diagnostic",
        "delivery_model": "Lab appointment",
        "summary": "Go beyond basic cholesterol and check the markers that often shape cardiovascular risk decisions.",
        "why_now_template": (
            "This is useful when cardiovascular risk is already part of the picture and you want the next review to be anchored in better lab detail."
        ),
        "includes": [
            "Expanded lipid testing such as ApoB and Lp(a) where appropriate",
            "A clinician-ready summary for the next review",
            "Clear explanation of which markers change the plan and which do not",
        ],
        "expected_outcome": "The next clinical decision is based on stronger cardiovascular risk detail rather than guesswork.",
        "time_commitment": "One lab visit plus a short results review.",
        "data_used": [
            "cardiovascular risk markers already on file",
            "medication context",
            "doctor visit history",
        ],
        "missing_data": [],
        "first_week": [
            "Book the lab draw",
            "Follow any fasting instructions you receive",
            "Review the results with the clinic after they return",
        ],
        "caution_template": "Use this to sharpen clinician decisions, not as a substitute for medical follow-up.",
        "personalization_note": "Most valuable when the user wants clearer risk detail before the next medication or follow-up decision.",
        "cta_label": "Book lab panel",
        "active": True,
        "sort_order": 16,
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
        "cta_label": "Start movement plan",
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
        "cta_label": "Start coaching",
        "active": True,
        "sort_order": 30,
    },
    "heart_health_supplement_review": {
        "offer_label": "Heart health supplement review",
        "category": "Supplement review",
        "offer_type": "supplement",
        "delivery_model": "Clinician-reviewed add-on",
        "summary": "Review whether any evidence-backed cardiovascular supplements belong in the plan before adding them on your own.",
        "why_now_template": (
            "This is only useful after the main clinical plan is clear and should sit behind appointments, rehab, or labs in priority."
        ),
        "includes": [
            "Review of current medications before adding supplements",
            "Discussion of where options like omega-3 or CoQ10 may or may not fit",
            "A simple do-not-start list for products that could conflict with treatment",
        ],
        "expected_outcome": "You avoid random supplement decisions and only consider add-ons that fit the real medical plan.",
        "time_commitment": "Short review after the core plan is in place.",
        "data_used": [
            "medication list",
            "cardiovascular and metabolic risk context",
            "recent clinical recommendations",
        ],
        "missing_data": [],
        "first_week": [
            "List any supplements you already take",
            "Do not add new products before the review",
            "Bring the supplement questions you want answered",
        ],
        "caution_template": "Always review supplement changes against medication, blood pressure, and bleeding risk first.",
        "personalization_note": "Useful as an add-on, never as the main recommendation after active cardiac risk.",
        "cta_label": "Book supplement review",
        "active": True,
        "sort_order": 34,
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
        "cta_label": "Start sleep reset",
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
        "cta_label": "Book prep visit",
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
        "cta_label": "Start 7-day tracker",
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
