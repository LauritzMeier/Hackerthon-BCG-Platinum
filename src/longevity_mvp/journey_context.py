from __future__ import annotations

from datetime import datetime
from typing import Dict, List, Optional

from .offer_catalog import get_offer_catalog_entry


CONDITION_LABELS = {
    "coronary_artery_disease": "coronary artery disease",
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

CARDIO_CONDITIONS = {
    "coronary_artery_disease",
    "heart_failure",
    "hypertension",
    "atrial_fibrillation",
}

CARDIO_VISIT_PREFIXES = ("I20", "I21", "I22", "I25", "I50")
ACUTE_CARDIO_VISIT_PREFIXES = ("I21", "I22")


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

    for visit in reversed(visits):
        code = visit.get("code", "")
        if any(code.startswith(prefix) for prefix in ACUTE_CARDIO_VISIT_PREFIXES):
            return visit

    prefixes = FOCUS_CODE_PREFIXES.get(primary_focus.get("pillar_id", ""), tuple())
    if prefixes:
        for visit in reversed(visits):
            code = visit.get("code", "")
            if any(code.startswith(prefix) for prefix in prefixes):
                return visit

    return visits[-1]


def _has_cardiovascular_context(bundle: Dict, primary_focus: Dict) -> bool:
    if primary_focus.get("pillar_id") == "cardiovascular_health":
        return True

    profile = bundle["profile"]
    conditions = set(split_pipe_values(profile.get("chronic_conditions")))
    if conditions.intersection(CARDIO_CONDITIONS):
        return True

    visits = parse_visit_history(profile.get("visit_history"))
    return any(
        visit.get("code", "").startswith(CARDIO_VISIT_PREFIXES)
        for visit in visits
    )


def _needs_cardiology_follow_up(bundle: Dict) -> bool:
    profile = bundle["profile"]
    conditions = set(split_pipe_values(profile.get("chronic_conditions")))
    if conditions.intersection({"coronary_artery_disease", "heart_failure"}):
        return True

    visits = parse_visit_history(profile.get("visit_history"))
    return any(
        visit.get("code", "").startswith(CARDIO_VISIT_PREFIXES)
        for visit in visits
    )


def _select_support_recommended_offer(
    bundle: Dict,
    primary_focus: Dict,
    recommended_offer: Optional[Dict],
) -> Optional[Dict]:
    raw_offers = bundle.get("offers", [])

    if _needs_cardiology_follow_up(bundle):
        return {
            "offer_code": "cardiology_follow_up_visit",
            "offer_label": "Cardiology follow-up visit",
            "priority": 1,
            "rationale": "Heart-related follow-up is still active, so the clearest support offer is a concrete cardiology visit.",
        }

    if _has_cardiovascular_context(bundle, primary_focus):
        for offer in raw_offers:
            if offer.get("offer_code") == "preventive_cardiometabolic_panel":
                return offer

    return recommended_offer


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
    has_meal_tracking = bool(profile.get("meals_logged_days"))
    has_survey_context = bool(profile.get("latest_survey_date"))

    connected_sources: List[str] = []
    if profile.get("latest_wearable_date"):
        connected_sources.append(
            "Your smartwatch is connected, so we can already see movement, sleep, resting heart rate, and recovery trends."
        )
    if profile.get("visit_history") or profile.get("medications"):
        connected_sources.append(
            "Your medical record gives the coach diagnoses, medications, and earlier doctor visits for context."
        )
    if has_survey_context:
        connected_sources.append(
            "One lifestyle survey adds broad self-reported context on stress, hydration, and nutrition habits."
        )
    if has_meal_tracking:
        connected_sources.append(
            "Meal logging is active, so nutrition recommendations can start reacting to real eating patterns."
        )

    missing_sources: List[str] = []
    if not has_meal_tracking:
        missing_sources.append(
            "A week of simple meal logging would make nutrition guidance much more specific."
        )
    missing_sources.append(
        "A short symptom or recovery check-in would help the app understand how you feel after exercise or meals."
    )

    focus_name = primary_focus.get("pillar_name", "your current focus area")
    if primary_focus.get("pillar_id") in {"metabolic_health", "nutrition_quality"} and not has_meal_tracking:
        headline = "We can already see the clinical risk picture, but nutrition is still only a broad estimate."
        confidence_label = "Strong clinical context, lighter nutrition detail"
        tailoring_note = (
            "The app can already use medical history and recovery trends well. "
            "Nutrition becomes meaningfully more personal after a small amount of meal logging."
        )
    else:
        headline = f"We can already tailor {focus_name.lower()} well from the data that is connected."
        confidence_label = "Good recovery signal coverage"
        tailoring_note = (
            "The coach can already personalize movement, recovery, and trend explanations. "
            "Nutrition can get sharper later with a little meal logging."
        )

    return {
        "headline": headline,
        "confidence_label": confidence_label,
        "connected_sources": connected_sources,
        "missing_sources": missing_sources,
        "tailoring_note": tailoring_note,
        "needs_meal_tracking": not has_meal_tracking,
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
        "One week of simple meal tracking would make nutrition guidance much more specific.",
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


def _format_offer_template(
    value,
    primary_focus: Dict,
    care_context: Dict,
    data_coverage: Dict,
):
    if isinstance(value, str):
        return value.format(
            focus_name=primary_focus.get("pillar_name", "your current focus area"),
            focus_name_lower=primary_focus.get("pillar_name", "your current focus area").lower(),
            medical_guardrail=care_context.get("medical_guardrail", ""),
            tailoring_note=data_coverage.get("tailoring_note", ""),
        )

    if isinstance(value, list):
        return [
            _format_offer_template(item, primary_focus, care_context, data_coverage)
            for item in value
        ]

    return value


def _offer_blueprint(
    offer_code: str,
    primary_focus: Dict,
    care_context: Dict,
    data_coverage: Dict,
) -> Dict:
    blueprint = get_offer_catalog_entry(offer_code)
    return {
        "label": _format_offer_template(
            blueprint["offer_label"], primary_focus, care_context, data_coverage
        ),
        "category": _format_offer_template(
            blueprint["category"], primary_focus, care_context, data_coverage
        ),
        "offer_type": _format_offer_template(
            blueprint.get("offer_type", ""), primary_focus, care_context, data_coverage
        ),
        "delivery_model": _format_offer_template(
            blueprint.get("delivery_model", ""), primary_focus, care_context, data_coverage
        ),
        "summary": _format_offer_template(
            blueprint["summary"], primary_focus, care_context, data_coverage
        ),
        "why_now": _format_offer_template(
            blueprint["why_now_template"], primary_focus, care_context, data_coverage
        ),
        "includes": _format_offer_template(
            blueprint["includes"], primary_focus, care_context, data_coverage
        ),
        "expected_outcome": _format_offer_template(
            blueprint["expected_outcome"], primary_focus, care_context, data_coverage
        ),
        "time_commitment": _format_offer_template(
            blueprint["time_commitment"], primary_focus, care_context, data_coverage
        ),
        "data_used": _format_offer_template(
            blueprint["data_used"], primary_focus, care_context, data_coverage
        ),
        "missing_data": _format_offer_template(
            blueprint["missing_data"], primary_focus, care_context, data_coverage
        ),
        "first_week": _format_offer_template(
            blueprint["first_week"], primary_focus, care_context, data_coverage
        ),
        "caution": _format_offer_template(
            blueprint["caution_template"], primary_focus, care_context, data_coverage
        ),
        "personalization_note": _format_offer_template(
            blueprint["personalization_note"], primary_focus, care_context, data_coverage
        ),
        "cta_label": _format_offer_template(
            blueprint.get("cta_label", ""), primary_focus, care_context, data_coverage
        ),
        "active": bool(blueprint.get("active", True)),
        "sort_order": blueprint.get("sort_order", 999),
    }


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
            "offer_type": blueprint["offer_type"],
            "delivery_model": blueprint["delivery_model"],
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
            "cta_label": blueprint["cta_label"],
            "active": blueprint["active"],
            "sort_order": blueprint["sort_order"],
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
    selected_recommended = _select_support_recommended_offer(
        bundle,
        primary_focus,
        recommended_offer,
    )
    recommended_code = (
        selected_recommended.get("offer_code") if selected_recommended else None
    )
    is_cardio_context = _has_cardiovascular_context(bundle, primary_focus)

    additional_items: List[Dict] = []
    if is_cardio_context:
        additional_items.extend(
            [
                enrich_offer(
                    {
                        "offer_code": "cardiac_rehab_intake",
                        "offer_label": "Cardiac rehab intake",
                        "priority": 2,
                        "rationale": "A supervised recovery plan can turn uncertainty into a safer return to activity.",
                    },
                    primary_focus,
                    care_context,
                    data_coverage,
                ),
                enrich_offer(
                    {
                        "offer_code": "advanced_lipid_lab_panel",
                        "offer_label": "Advanced lipid lab panel",
                        "priority": 3,
                        "rationale": "Stronger lipid detail can make the next cardiovascular review more concrete.",
                    },
                    primary_focus,
                    care_context,
                    data_coverage,
                ),
                enrich_offer(
                    {
                        "offer_code": "heart_health_supplement_review",
                        "offer_label": "Heart health supplement review",
                        "priority": 4,
                        "rationale": "Supplement decisions only add value once they are grounded in the current medical plan.",
                    },
                    primary_focus,
                    care_context,
                    data_coverage,
                ),
            ]
        )

    if care_context.get("last_appointment_summary"):
        additional_items.append(
            enrich_offer(
                {
                    "offer_code": "follow_up_prep",
                    "offer_label": "Next appointment prep",
                    "priority": 5 if is_cardio_context else 2,
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
                    "priority": 7 if is_cardio_context else 3,
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
        raw_offer = dict(offer)
        if is_cardio_context and raw_offer.get("offer_code") == "movement_program":
            raw_offer["priority"] = max(raw_offer.get("priority", 99), 6)
            raw_offer["rationale"] = (
                "Structured movement support still helps, but clinic-facing cardiac offers should come first."
            )
        additional_items.append(
            enrich_offer(raw_offer, primary_focus, care_context, data_coverage)
        )

    seen_codes = set()
    deduped_additional: List[Dict] = []
    for offer in additional_items:
        offer_code = offer.get("offer_code")
        if offer_code in seen_codes:
            continue
        seen_codes.add(offer_code)
        if offer.get("active", True):
            deduped_additional.append(offer)

    deduped_additional.sort(
        key=lambda offer: (
            offer.get("priority", 99),
            offer.get("sort_order", 999),
            offer.get("offer_label", ""),
        )
    )

    return {
        "recommended": (
            enrich_offer(
                selected_recommended,
                primary_focus,
                care_context,
                data_coverage,
            )
            if selected_recommended
            else None
        ),
        "additional_items": deduped_additional[:4],
    }
