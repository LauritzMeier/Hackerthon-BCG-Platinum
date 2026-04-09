from __future__ import annotations

from datetime import datetime
from typing import Dict, List, Optional


CONDITION_LABELS = {
    "type2_diabetes": "type 2 diabetes",
    "dyslipidaemia": "an unhealthy cholesterol pattern",
    "hypertension": "high blood pressure",
    "sleep_apnoea": "sleep apnoea",
    "depression": "depression",
}

ICD_LABELS = {
    "E11": "type 2 diabetes follow-up",
    "E78.5": "cholesterol management review",
    "I21": "heart attack follow-up",
    "I22": "repeat heart attack follow-up",
    "I25.1": "coronary artery disease review",
    "I20": "angina review",
    "I50": "heart failure review",
    "F32.9": "mental health follow-up",
    "K21.0": "reflux review",
    "R05": "respiratory symptom review",
}

FOCUS_CODE_PREFIXES = {
    "cardiovascular_health": ("I", "E78"),
    "metabolic_health": ("E11", "E78"),
    "movement_fitness": ("I", "M"),
    "nutrition_quality": ("E11", "E78", "K"),
    "sleep_recovery": ("G47", "I"),
    "mental_resilience": ("F",),
}


def split_pipe_values(value) -> List[str]:
    return [item.strip() for item in str(value or "").split("|") if item.strip()]


def _title_case_words(value: str) -> str:
    return value.replace("_", " ").strip().title()


def label_condition(value: str) -> str:
    return CONDITION_LABELS.get(value, value.replace("_", " ").strip())


def label_icd(code: str) -> str:
    if not code:
        return "general follow-up"
    for known_code, label in ICD_LABELS.items():
        if code.startswith(known_code):
            return label
    return f"{code} follow-up"


def parse_visit_history(value) -> List[Dict]:
    visits: List[Dict] = []
    for entry in split_pipe_values(value):
      if ":" in entry:
        date_part, code = entry.split(":", 1)
      else:
        date_part, code = "", entry

      visits.append(
          {
              "date": date_part,
              "code": code,
              "label": label_icd(code),
          }
      )
    return visits


def _format_date(value: str) -> str:
    if not value:
        return "an earlier visit"
    try:
        return datetime.strptime(value, "%Y-%m-%d").strftime("%d %b %Y")
    except ValueError:
        return value


def _select_relevant_visit(visits: List[Dict], primary_focus: Dict) -> Optional[Dict]:
    if not visits:
        return None

    prefixes = FOCUS_CODE_PREFIXES.get(primary_focus.get("pillar_id", ""), tuple())
    if prefixes:
        for visit in reversed(visits):
            code = visit.get("code", "")
            if any(code.startswith(prefix) for prefix in prefixes):
                return visit

    return visits[-1]


def build_care_context(bundle: Dict, primary_focus: Dict) -> Dict:
    profile = bundle["profile"]
    flags = bundle.get("flags", [])
    visits = parse_visit_history(profile.get("visit_history"))
    relevant_visit = _select_relevant_visit(visits, primary_focus)
    medications = split_pipe_values(profile.get("medications"))[:3]
    conditions = [label_condition(item) for item in split_pipe_values(profile.get("chronic_conditions"))[:3]]

    last_appointment_summary = (
        f"The most relevant doctor context on file is {relevant_visit['label']} "
        f"from {_format_date(relevant_visit['date'])}. "
        if relevant_visit
        else "Your doctor history is linked, but there is no structured appointment summary on file yet. "
    )

    if medications:
        last_appointment_summary += (
            f"Your current record also lists {', '.join(medications[:2])}, which helps the coach avoid generic advice."
        )
    else:
        last_appointment_summary += (
            "Medication data is still thin, so the coach should keep recommendations broad and conservative."
        )

    clinical_priorities = [flag.get("title", "") for flag in flags[:3] if flag.get("title")]
    if not clinical_priorities and conditions:
        clinical_priorities = [_title_case_words(item) for item in conditions[:2]]

    return {
        "headline": "Your coach should start informed, not blind.",
        "last_appointment_title": "Last doctor context on file",
        "last_appointment_summary": last_appointment_summary,
        "medications": medications,
        "conditions": conditions,
        "clinical_priorities": clinical_priorities,
        "medical_guardrail": (
            "If your clinician has given you medication, rehab, or activity limits, those instructions stay above the app."
        ),
    }


def build_data_coverage(bundle: Dict, primary_focus: Dict) -> Dict:
    profile = bundle["profile"]

    connected_sources: List[str] = []
    if profile.get("latest_wearable_date"):
        connected_sources.append(
            "Your smartwatch is connected, so we can already see movement, sleep, resting heart rate, and recovery trends."
        )
    if profile.get("visit_history") or profile.get("medications"):
        connected_sources.append(
            "Your medical record gives the coach diagnoses, medications, and earlier doctor visits for context."
        )
    if profile.get("latest_survey_date"):
        connected_sources.append(
            "A lifestyle survey adds broad context on stress, hydration, and nutrition habits."
        )

    missing_sources = [
        "Meals are not being logged yet, so nutrition advice is still broad rather than day-by-day personalized.",
        "Symptoms and recovery check-ins are not being tracked yet, so the app cannot see how you feel after exercise or meals.",
    ]

    focus_name = primary_focus.get("pillar_name", "your current focus area")
    return {
        "headline": f"We can already tailor {focus_name.lower()} better than nutrition.",
        "confidence_label": "Good recovery signal coverage, limited nutrition detail",
        "connected_sources": connected_sources,
        "missing_sources": missing_sources,
        "tailoring_note": (
            "The coach can already personalize movement, recovery, and trend explanations. "
            "Nutrition recommendations stay general until meal logging starts."
        ),
        "needs_meal_tracking": True,
    }


def build_journey_start(
    bundle: Dict,
    primary_focus: Dict,
    care_context: Dict,
    data_coverage: Dict,
) -> Dict:
    profile = bundle["profile"]
    flags = bundle.get("flags", [])
    focus_name = primary_focus.get("pillar_name", "your current focus area")
    top_flag = flags[0].get("title") if flags else None

    what_we_know = [
        "Your watch is already giving us useful recovery and activity data.",
        care_context["last_appointment_summary"],
        (
            f"The strongest issue we should work on first is {focus_name.lower()}."
            if focus_name
            else "There is already enough signal to choose one main focus for this week."
        ),
    ]

    if top_flag:
        what_we_know.append(f"The clearest risk signal right now is {top_flag.lower()}.")

    what_we_need = [
        "Meals are not being tracked yet, so the app cannot tell whether your current eating pattern is helping or hurting.",
        "If you want more tailored nutrition guidance, start by logging one meal a day for the next 7 days.",
    ]

    medications = split_pipe_values(profile.get("medications"))
    start_here = [
        "Ask the coach to explain your last doctor context in plain language.",
        f"Follow this week's {focus_name.lower()} actions before trying to change everything at once.",
        "Track one meal a day for 7 days so the next nutrition recommendation is actually tailored.",
    ]
    if medications:
        start_here.insert(
            1,
            "Keep your medication plan and clinician instructions as the foundation, and use the app to support follow-through.",
        )

    return {
        "title": "Start with clarity, recovery, and one easy habit.",
        "summary": (
            "A new user should immediately understand what the app already knows, what is still missing, "
            "and what one realistic next step will make the experience more useful."
        ),
        "what_we_know": what_we_know[:4],
        "what_we_need": what_we_need,
        "start_here": start_here[:4],
    }


def _offer_blueprint(
    offer_code: str,
    primary_focus: Dict,
    care_context: Dict,
    data_coverage: Dict,
) -> Dict:
    focus_name = primary_focus.get("pillar_name", "your current focus area")

    blueprints = {
        "preventive_cardiometabolic_panel": {
            "label": "Cardiometabolic recovery review",
            "category": "Clinical review",
            "summary": "Bring your current risk picture, medications, and recovery trends into one practical follow-up plan.",
            "why_now": (
                "This makes sense when cardiovascular or metabolic risk is active and the user needs clarity, "
                "not another generic wellness package."
            ),
            "includes": [
                "Review of current cardiovascular and metabolic risk markers",
                "Medication and follow-up question prep for the next clinician visit",
                "A clear decision on what to monitor first at home versus in clinic",
            ],
            "expected_outcome": "The user understands what needs clinician follow-up now and what can improve through behavior support.",
            "time_commitment": "One focused review plus a short follow-up.",
            "data_used": [
                "medical record history",
                "current medications",
                "watch-based recovery and movement trends",
            ],
            "missing_data": [
                "meal logs for more specific nutrition guidance",
            ],
            "first_week": [
                "Bring recent questions and concerns into one note",
                "Keep wearing the watch so recovery trends stay visible",
                "Log one meal a day so the next nutrition recommendation gets sharper",
            ],
            "caution": care_context["medical_guardrail"],
            "personalization_note": "Best when the user needs medically grounded prioritization, not a broad lifestyle package.",
        },
        "movement_program": {
            "label": "Guided recovery movement plan",
            "category": "Habit support",
            "summary": "Restart activity with a realistic floor, safe progression, and watch-based feedback.",
            "why_now": f"This is most useful when {focus_name.lower()} is lagging and confidence is lower than motivation.",
            "includes": [
                "A simple weekly movement target based on current watch data",
                "Progression that starts with consistency before intensity",
                "Light check-ins that connect movement back to recovery",
            ],
            "expected_outcome": "The user moves more consistently without feeling like they were dropped into a hard training plan.",
            "time_commitment": "Short daily movement blocks plus one weekly review.",
            "data_used": [
                "steps",
                "active minutes",
                "resting heart rate and recovery trends",
            ],
            "missing_data": [
                "symptom check-ins after exercise",
            ],
            "first_week": [
                "Set a floor you can keep every day",
                "Notice how energy and recovery respond",
                "Ask the coach to adjust the plan if recovery feels off",
            ],
            "caution": care_context["medical_guardrail"],
            "personalization_note": "Good when the user needs structure and reassurance more than intensity.",
        },
        "nutrition_coaching": {
            "label": "Nutrition reset with meal tracking",
            "category": "Behavior coaching",
            "summary": "Start with simple meal tracking so nutrition support becomes personal instead of generic.",
            "why_now": (
                "Nutrition clearly matters, but the app should admit that advice stays broad until actual meals are logged."
            ),
            "includes": [
                "A one-meal-a-day tracking habit to get real signal",
                "Pattern review around fiber, protein, hydration, and alcohol",
                "Small changes that fit the current recovery or risk-reduction goal",
            ],
            "expected_outcome": "The user gets a more trustworthy nutrition plan because the app finally sees real eating patterns.",
            "time_commitment": "A few minutes per day for logging and one short weekly review.",
            "data_used": [
                "survey-level nutrition habits",
                "metabolic risk markers",
                "watch-based energy and activity context",
            ],
            "missing_data": [
                "meal-by-meal logs",
            ],
            "first_week": [
                "Log one meal a day for seven days",
                "Notice one repeated nutrition drag",
                "Use the coach to decide what to change first",
            ],
            "caution": "This is best for personalization and habit support, not for replacing clinician advice after an acute event.",
            "personalization_note": "Useful, but it becomes much stronger after one week of meal tracking.",
        },
        "sleep_recovery_package": {
            "label": "Sleep and recovery reset",
            "category": "Recovery support",
            "summary": "Use recovery habits and sleep structure to improve resilience before everything else feels harder.",
            "why_now": f"This fits when {focus_name.lower()} is limited by poor sleep, stress, or low recovery capacity.",
            "includes": [
                "Simple sleep window and wind-down adjustments",
                "Recovery review using watch data",
                "A plan that links sleep improvements back to energy and consistency",
            ],
            "expected_outcome": "The user feels steadier and better able to follow the rest of the plan.",
            "time_commitment": "Short nightly routine changes and one weekly review.",
            "data_used": [
                "sleep duration",
                "sleep quality",
                "resting heart rate and HRV",
            ],
            "missing_data": [
                "daytime symptom and caffeine timing data",
            ],
            "first_week": [
                "Protect one consistent bedtime window",
                "Reduce one friction point before bed",
                "Ask the coach what improved or worsened recovery this week",
            ],
            "caution": "Use this as support, not as a substitute for clinician follow-up if symptoms or recovery worsen.",
            "personalization_note": "Good when sleep is the bottleneck behind everything else.",
        },
        "follow_up_prep": {
            "label": "Next appointment prep",
            "category": "Follow-up support",
            "summary": "Turn your doctor history and current signals into better questions for the next visit.",
            "why_now": "New users often need help understanding what their last appointment means before they can commit to a plan.",
            "includes": [
                "A short summary of the last relevant doctor context on file",
                "Questions to bring to the next visit",
                "A checklist of what to monitor before the appointment",
            ],
            "expected_outcome": "The user arrives at the next appointment feeling prepared instead of overwhelmed.",
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
            "caution": care_context["medical_guardrail"],
            "personalization_note": "Especially useful early in the journey, before the user trusts the rest of the plan.",
        },
        "meal_tracking_reset": {
            "label": "7-day meal tracking starter",
            "category": "Data setup",
            "summary": "Give the app enough real food data to tailor nutrition instead of guessing.",
            "why_now": data_coverage["tailoring_note"],
            "includes": [
                "One simple meal log per day",
                "A review of repeated patterns after one week",
                "A clearer handoff into nutrition support if it is still needed",
            ],
            "expected_outcome": "Nutrition recommendations stop feeling generic because the app finally sees real eating behavior.",
            "time_commitment": "Two to three minutes per day.",
            "data_used": [
                "survey habits",
                "metabolic signals",
            ],
            "missing_data": [],
            "first_week": [
                "Log the first meal that feels easiest to remember",
                "Do not try to be perfect; just be consistent",
                "Ask the coach what pattern it sees at the end of the week",
            ],
            "caution": "This is a setup step for better personalization, not a clinical treatment.",
            "personalization_note": "Low effort, high value for a new user.",
        },
    }

    return blueprints[offer_code]


def enrich_offer(
    offer: Dict,
    primary_focus: Dict,
    care_context: Dict,
    data_coverage: Dict,
) -> Dict:
    blueprint = _offer_blueprint(offer["offer_code"], primary_focus, care_context, data_coverage)
    enriched = dict(offer)
    enriched.update(
        {
            "offer_label": blueprint["label"],
            "category": blueprint["category"],
            "summary": blueprint["summary"],
            "why_now": blueprint["why_now"],
            "includes": blueprint["includes"],
            "expected_outcome": blueprint["expected_outcome"],
            "time_commitment": blueprint["time_commitment"],
            "data_used": blueprint["data_used"],
            "missing_data": blueprint["missing_data"],
            "first_week": blueprint["first_week"],
            "caution": blueprint["caution"],
            "personalization_note": blueprint["personalization_note"],
        }
    )
    return enriched


def build_offer_summary(
    bundle: Dict,
    primary_focus: Dict,
    recommended_offer: Optional[Dict],
    care_context: Dict,
    data_coverage: Dict,
) -> Dict:
    raw_offers = bundle.get("offers", [])
    recommended_code = recommended_offer.get("offer_code") if recommended_offer else None

    additional_items: List[Dict] = []
    if care_context.get("last_appointment_summary"):
        additional_items.append(
            enrich_offer(
                {
                    "offer_code": "follow_up_prep",
                    "offer_label": "Next appointment prep",
                    "priority": 2,
                    "rationale": "Turn your existing care context into clear follow-up questions.",
                },
                primary_focus,
                care_context,
                data_coverage,
            )
        )

    if data_coverage.get("needs_meal_tracking"):
        additional_items.append(
            enrich_offer(
                {
                    "offer_code": "meal_tracking_reset",
                    "offer_label": "7-day meal tracking starter",
                    "priority": 3,
                    "rationale": "You need better food signal before nutrition support can become truly personal.",
                },
                primary_focus,
                care_context,
                data_coverage,
            )
        )

    for offer in raw_offers:
        if offer.get("offer_code") == recommended_code:
            continue
        additional_items.append(
            enrich_offer(offer, primary_focus, care_context, data_coverage)
        )

    seen_codes = set()
    deduped_additional: List[Dict] = []
    for offer in additional_items:
        offer_code = offer.get("offer_code")
        if offer_code in seen_codes:
            continue
        seen_codes.add(offer_code)
        deduped_additional.append(offer)

    return {
        "recommended": (
            enrich_offer(recommended_offer, primary_focus, care_context, data_coverage)
            if recommended_offer
            else None
        ),
        "additional_items": deduped_additional[:3],
    }
