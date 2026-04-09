from datetime import datetime, timezone
from decimal import Decimal
from typing import Dict, List, Optional

from .journey_context import build_care_context, build_data_coverage


PILLAR_DISPLAY_ORDER = [
    "sleep_recovery",
    "cardiovascular_health",
    "metabolic_health",
    "movement_fitness",
    "nutrition_quality",
    "mental_resilience",
]


def _to_float(value) -> float:
    if value is None:
        return 0.0
    if isinstance(value, Decimal):
        return float(value)
    return float(value)


def _round(value: float, digits: int = 1) -> float:
    return round(float(value), digits)


def _average(values: List[float]) -> float:
    if not values:
        return 0.0
    return sum(values) / len(values)


def _score_to_state(score: float) -> str:
    if score >= 75:
        return "strong"
    if score >= 55:
        return "watch"
    return "needs_focus"


def _delta_to_trend(delta: float, positive_is_better: bool = True) -> str:
    threshold = 3.0
    if abs(delta) < threshold:
        return "stable"
    if positive_is_better:
        return "improving" if delta > 0 else "drifting"
    return "improving" if delta < 0 else "drifting"


def _normalize(obj):
    if isinstance(obj, dict):
        return {key: _normalize(value) for key, value in obj.items()}
    if isinstance(obj, list):
        return [_normalize(value) for value in obj]
    if isinstance(obj, Decimal):
        return float(obj)
    return obj


def _build_sleep_pillar(profile: Dict) -> Dict:
    score = _to_float(profile.get("sleep_recovery_score"))
    quality_delta = _to_float(profile.get("sleep_quality_7d_avg")) - _to_float(
        profile.get("sleep_quality_30d_avg")
    )
    duration_delta = (_to_float(profile.get("sleep_duration_7d_avg")) - _to_float(
        profile.get("sleep_duration_30d_avg")
    )) * 8
    combined_delta = quality_delta + duration_delta
    return {
        "id": "sleep_recovery",
        "name": "Sleep and Recovery",
        "score": _round(score),
        "state": _score_to_state(score),
        "trend": _delta_to_trend(combined_delta),
        "why_it_matters": "Sleep and recovery influence resilience, mood, and long-term health.",
        "key_signals": {
            "sleep_duration_7d_avg": _round(_to_float(profile.get("sleep_duration_7d_avg")), 2),
            "sleep_duration_30d_avg": _round(_to_float(profile.get("sleep_duration_30d_avg")), 2),
            "sleep_quality_7d_avg": _round(_to_float(profile.get("sleep_quality_7d_avg"))),
            "sleep_quality_30d_avg": _round(_to_float(profile.get("sleep_quality_30d_avg"))),
        },
    }


def _build_cardiovascular_pillar(profile: Dict) -> Dict:
    score = _to_float(profile.get("cardiovascular_fitness_score"))
    resting_hr_delta = _to_float(profile.get("resting_hr_7d_avg")) - _to_float(
        profile.get("resting_hr_30d_avg")
    )
    hrv_delta = _to_float(profile.get("hrv_7d_avg")) - _to_float(profile.get("hrv_30d_avg"))
    trend = "stable"
    if hrv_delta >= 1.5 and resting_hr_delta <= -1.0:
        trend = "improving"
    elif hrv_delta <= -1.5 and resting_hr_delta >= 1.0:
        trend = "drifting"
    return {
        "id": "cardiovascular_health",
        "name": "Cardiovascular Health",
        "score": _round(score),
        "state": _score_to_state(score),
        "trend": trend,
        "why_it_matters": "Cardiovascular health affects endurance, prevention, and long-term risk.",
        "key_signals": {
            "resting_hr_7d_avg": _round(_to_float(profile.get("resting_hr_7d_avg"))),
            "resting_hr_30d_avg": _round(_to_float(profile.get("resting_hr_30d_avg"))),
            "hrv_7d_avg": _round(_to_float(profile.get("hrv_7d_avg"))),
            "hrv_30d_avg": _round(_to_float(profile.get("hrv_30d_avg"))),
            "sbp_mmhg": _round(_to_float(profile.get("sbp_mmhg"))),
            "dbp_mmhg": _round(_to_float(profile.get("dbp_mmhg"))),
        },
    }


def _build_metabolic_pillar(profile: Dict) -> Dict:
    score = _to_float(profile.get("metabolic_health_score"))
    trend = "stable" if score >= 60 else "drifting"
    if _to_float(profile.get("hba1c_pct")) < 5.7 and _to_float(profile.get("fasting_glucose_mmol")) < 5.6:
        trend = "stable"
    return {
        "id": "metabolic_health",
        "name": "Metabolic Health",
        "score": _round(score),
        "state": _score_to_state(score),
        "trend": trend,
        "why_it_matters": "Metabolic health influences energy, chronic disease risk, and ageing trajectory.",
        "key_signals": {
            "bmi": _round(_to_float(profile.get("bmi"))),
            "hba1c_pct": _round(_to_float(profile.get("hba1c_pct")), 1),
            "fasting_glucose_mmol": _round(_to_float(profile.get("fasting_glucose_mmol")), 1),
            "ldl_mmol": _round(_to_float(profile.get("ldl_mmol")), 1),
        },
    }


def _build_movement_pillar(profile: Dict) -> Dict:
    steps_score = min(100.0, (_to_float(profile.get("steps_30d_avg")) / 9000.0) * 100.0)
    active_score = min(
        100.0, (_to_float(profile.get("active_minutes_30d_avg")) / 45.0) * 100.0
    )
    exercise_score = min(
        100.0, (_to_float(profile.get("exercise_sessions_weekly")) / 5.0) * 100.0
    )
    score = _round((steps_score * 0.45) + (active_score * 0.35) + (exercise_score * 0.20))
    steps_delta = (_to_float(profile.get("steps_7d_avg")) - _to_float(profile.get("steps_30d_avg"))) / 250.0
    active_delta = _to_float(profile.get("active_minutes_7d_avg")) - _to_float(
        profile.get("active_minutes_30d_avg")
    )
    trend = _delta_to_trend(steps_delta + active_delta)
    return {
        "id": "movement_fitness",
        "name": "Movement and Fitness",
        "score": score,
        "state": _score_to_state(score),
        "trend": trend,
        "why_it_matters": "Movement shapes cardiovascular resilience, metabolic health, and energy.",
        "key_signals": {
            "steps_7d_avg": _round(_to_float(profile.get("steps_7d_avg"))),
            "steps_30d_avg": _round(_to_float(profile.get("steps_30d_avg"))),
            "active_minutes_7d_avg": _round(_to_float(profile.get("active_minutes_7d_avg"))),
            "active_minutes_30d_avg": _round(_to_float(profile.get("active_minutes_30d_avg"))),
            "exercise_sessions_weekly": _round(_to_float(profile.get("exercise_sessions_weekly"))),
        },
    }


def _build_nutrition_pillar(profile: Dict) -> Dict:
    diet_score = (_to_float(profile.get("diet_quality_score")) / 10.0) * 100.0
    fruit_veg_score = min(100.0, (_to_float(profile.get("fruit_veg_servings_daily")) / 5.0) * 100.0)
    water_score = min(100.0, (_to_float(profile.get("water_glasses_daily")) / 8.0) * 100.0)
    alcohol_penalty = max(0.0, (_to_float(profile.get("current_alcohol_units_weekly")) - 10.0) * 3.5)
    score = _round(max(0.0, (diet_score * 0.45) + (fruit_veg_score * 0.30) + (water_score * 0.25) - alcohol_penalty))
    trend = "stable" if score >= 60 else "drifting"
    return {
        "id": "nutrition_quality",
        "name": "Nutrition Quality",
        "score": score,
        "state": _score_to_state(score),
        "trend": trend,
        "why_it_matters": "Nutrition quality affects metabolic health, recovery, and long-term prevention.",
        "key_signals": {
            "diet_quality_score": _round(_to_float(profile.get("diet_quality_score"))),
            "fruit_veg_servings_daily": _round(_to_float(profile.get("fruit_veg_servings_daily")), 1),
            "water_glasses_daily": _round(_to_float(profile.get("water_glasses_daily"))),
            "alcohol_units_weekly": _round(_to_float(profile.get("current_alcohol_units_weekly"))),
        },
    }


def _build_mental_pillar(profile: Dict) -> Dict:
    stress_score = max(0.0, 100.0 - (_to_float(profile.get("stress_level")) * 10.0))
    wellbeing_score = min(100.0, (_to_float(profile.get("mental_wellbeing_who5")) / 25.0) * 100.0)
    self_rated_score = min(100.0, (_to_float(profile.get("self_rated_health")) / 5.0) * 100.0)
    sleep_satisfaction_score = min(100.0, (_to_float(profile.get("sleep_satisfaction")) / 7.0) * 100.0)
    score = _round(
        (stress_score * 0.30)
        + (wellbeing_score * 0.35)
        + (self_rated_score * 0.20)
        + (sleep_satisfaction_score * 0.15)
    )
    trend = "stable" if score >= 60 else "drifting"
    if _to_float(profile.get("stress_level")) <= 4 and _to_float(profile.get("mental_wellbeing_who5")) >= 18:
        trend = "improving"
    return {
        "id": "mental_resilience",
        "name": "Mental Resilience",
        "score": score,
        "state": _score_to_state(score),
        "trend": trend,
        "why_it_matters": "Mental resilience shapes consistency, recovery, and the ability to sustain healthy behavior.",
        "key_signals": {
            "stress_level": _round(_to_float(profile.get("stress_level"))),
            "mental_wellbeing_who5": _round(_to_float(profile.get("mental_wellbeing_who5"))),
            "self_rated_health": _round(_to_float(profile.get("self_rated_health"))),
            "sleep_satisfaction": _round(_to_float(profile.get("sleep_satisfaction"))),
        },
    }


def _build_pillars(profile: Dict) -> List[Dict]:
    pillars = [
        _build_sleep_pillar(profile),
        _build_cardiovascular_pillar(profile),
        _build_metabolic_pillar(profile),
        _build_movement_pillar(profile),
        _build_nutrition_pillar(profile),
        _build_mental_pillar(profile),
    ]
    pillars.sort(key=lambda pillar: PILLAR_DISPLAY_ORDER.index(pillar["id"]))
    return pillars


def _pillar_by_id(pillars: List[Dict], pillar_id: str) -> Optional[Dict]:
    for pillar in pillars:
        if pillar["id"] == pillar_id:
            return pillar
    return None


def _overall_direction(pillars: List[Dict]) -> str:
    drifting = sum(1 for pillar in pillars if pillar["trend"] == "drifting")
    avg_score = sum(pillar["score"] for pillar in pillars) / max(1, len(pillars))
    if drifting >= 3 or avg_score < 55:
        return "drifting"
    if drifting == 0 and avg_score >= 70:
        return "on_track"
    return "mixed"


def _choose_primary_focus(pillars: List[Dict]) -> Dict:
    def focus_rank(pillar: Dict):
        trend_weight = {"drifting": 0, "stable": 1, "improving": 2}[pillar["trend"]]
        state_weight = {"needs_focus": 0, "watch": 1, "strong": 2}[pillar["state"]]
        return (trend_weight, state_weight, pillar["score"])

    focus_pillar = sorted(pillars, key=focus_rank)[0]
    return {
        "pillar_id": focus_pillar["id"],
        "pillar_name": focus_pillar["name"],
        "why_now": (
            f"{focus_pillar['name']} is the strongest lever right now because it is "
            f"{focus_pillar['trend']} and currently rated {focus_pillar['state']}."
        ),
    }


def _build_peer_comparison(profile: Dict, pillars: List[Dict], age_peers: List[Dict]) -> Dict:
    if not age_peers:
        return {
            "headline": "How your six pillars compare with your age cohort",
            "cohort_label": "Peer comparison not available yet",
            "sample_size": 0,
            "strongest_relative_pillar_id": "",
            "biggest_gap_pillar_id": "",
            "items": [],
        }

    peer_pillars = [_build_pillars(peer_profile) for peer_profile in age_peers]
    peer_ages = [
        int(_to_float(peer_profile.get("age")))
        for peer_profile in age_peers
        if peer_profile.get("age") is not None
    ]

    items = []
    for pillar in pillars:
        peer_scores = []
        for peer_set in peer_pillars:
            peer_pillar = _pillar_by_id(peer_set, pillar["id"])
            if peer_pillar is not None:
                peer_scores.append(_to_float(peer_pillar["score"]))

        if not peer_scores:
            continue

        peer_score = _round(_average(peer_scores))
        items.append(
            {
                "pillar_id": pillar["id"],
                "pillar_name": pillar["name"],
                "patient_score": _round(_to_float(pillar["score"])),
                "peer_score": peer_score,
                "difference": _round(_to_float(pillar["score"]) - peer_score),
            }
        )

    if not items:
        return {
            "headline": "How your six pillars compare with your age cohort",
            "cohort_label": "Peer comparison not available yet",
            "sample_size": 0,
            "strongest_relative_pillar_id": "",
            "biggest_gap_pillar_id": "",
            "items": [],
        }

    strongest_relative = max(items, key=lambda item: item["difference"])
    biggest_gap = min(items, key=lambda item: item["difference"])
    if peer_ages:
        min_age = min(peer_ages)
        max_age = max(peer_ages)
    else:
        current_age = int(_to_float(profile.get("age")))
        min_age = current_age
        max_age = current_age

    return {
        "headline": "How your six pillars compare with your age cohort",
        "cohort_label": f"Compared with {len(age_peers)} people aged {min_age}-{max_age}",
        "sample_size": len(age_peers),
        "strongest_relative_pillar_id": strongest_relative["pillar_id"],
        "biggest_gap_pillar_id": biggest_gap["pillar_id"],
        "items": items,
    }


def _weekly_actions_for_pillar(pillar_id: str, profile: Dict) -> List[Dict]:
    action_map = {
        "sleep_recovery": [
            {
                "title": "Protect a consistent sleep window",
                "description": "Aim for the same bedtime and wake time on at least 5 nights this week.",
            },
            {
                "title": "Build a 30-minute wind-down",
                "description": "Reduce screens or stimulating work before bed to improve recovery quality.",
            },
            {
                "title": "Check in with the coach after two nights",
                "description": "Use the coach to adjust the plan if stress or schedule gets in the way.",
            },
        ],
        "cardiovascular_health": [
            {
                "title": "Add one heart-rate-raising session",
                "description": "Plan one extra brisk walk, cycle, or workout session this week.",
            },
            {
                "title": "Support blood-pressure habits",
                "description": "Pair movement with one low-sodium or high-fiber meal choice each day.",
            },
            {
                "title": "Review the coach explanation",
                "description": "Ask why your cardiovascular pillar is drifting or stable and what matters most.",
            },
        ],
        "metabolic_health": [
            {
                "title": "Stabilize the first meal of the day",
                "description": "Choose a protein- and fiber-first breakfast or lunch on at least 4 days.",
            },
            {
                "title": "Walk after meals",
                "description": "Add a 10-minute walk after your largest meal to support glucose response.",
            },
            {
                "title": "Consider a preventive check",
                "description": "Use the app to review whether a cardiometabolic diagnostic package is relevant now.",
            },
        ],
        "movement_fitness": [
            {
                "title": "Lift the movement floor",
                "description": "Add one short walk or movement break every day to raise your weekly average.",
            },
            {
                "title": "Set a realistic activity target",
                "description": f"Aim to move above your recent baseline of about {_round(_to_float(profile.get('steps_30d_avg')))} steps.",
            },
            {
                "title": "Ask the coach to adapt the plan",
                "description": "Tune your plan to your schedule, travel, or motivation level.",
            },
        ],
        "nutrition_quality": [
            {
                "title": "Improve meal quality at one consistent moment",
                "description": "Upgrade one meal each day with more fiber, plants, or protein rather than changing everything at once.",
            },
            {
                "title": "Reduce one nutrition drag",
                "description": "Pick one habit to reduce this week, such as alcohol, late snacking, or low hydration.",
            },
            {
                "title": "Review the nutrition support option",
                "description": "Check whether a nutrition coaching offer would accelerate progress.",
            },
        ],
        "mental_resilience": [
            {
                "title": "Protect one recovery block",
                "description": "Schedule one short daily recovery moment you can realistically keep.",
            },
            {
                "title": "Track stress triggers with the coach",
                "description": "Use the coach chat to notice what is pushing your resilience up or down this week.",
            },
            {
                "title": "Link resilience to sleep",
                "description": "Prioritize the behavior most likely to improve both stress and recovery this week.",
            },
        ],
    }
    return action_map[pillar_id]


def _recommended_offer(primary_focus: Dict, offers: List[Dict]) -> Optional[Dict]:
    pillar_offer_preference = {
        "sleep_recovery": {"sleep_recovery_package"},
        "cardiovascular_health": {"preventive_cardiometabolic_panel"},
        "metabolic_health": {"preventive_cardiometabolic_panel", "nutrition_coaching"},
        "movement_fitness": {"movement_program"},
        "nutrition_quality": {"nutrition_coaching"},
        "mental_resilience": {"sleep_recovery_package", "nutrition_coaching"},
    }
    allowed = pillar_offer_preference.get(primary_focus["pillar_id"], set())
    for offer in offers:
        if offer.get("offer_code") in allowed:
            return offer
    return offers[0] if offers else None


def build_compass(bundle: Dict) -> Dict:
    profile = bundle["profile"]
    pillars = _build_pillars(profile)
    peer_comparison = _build_peer_comparison(
        profile,
        pillars,
        bundle.get("age_peers", []),
    )
    overall_direction = _overall_direction(pillars)
    primary_focus = _choose_primary_focus(pillars)
    recommended_offer = _recommended_offer(primary_focus, bundle.get("offers", []))
    return _normalize(
        {
            "patient_id": profile["patient_id"],
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "chronological_age": profile["age"],
            "estimated_biological_age": profile.get("estimated_biological_age"),
            "overall_direction": overall_direction,
            "primary_focus": primary_focus,
            "pillars": pillars,
            "peer_comparison": peer_comparison,
            "summary": {
                "current_state": "Six-pillar longevity snapshot",
                "trajectory": overall_direction,
                "recommended_offer": recommended_offer,
            },
            "suggested_questions": [
                "Why is this my main focus right now?",
                "Which pillar is drifting fastest?",
                "What should I do this week to improve my direction?",
            ],
        }
    )


def build_weekly_plan(bundle: Dict) -> Dict:
    compass = build_compass(bundle)
    primary_focus = compass["primary_focus"]
    actions = _weekly_actions_for_pillar(primary_focus["pillar_id"], bundle["profile"])
    return _normalize(
        {
            "patient_id": bundle["profile"]["patient_id"],
            "title": f"This week: focus on {primary_focus['pillar_name']}",
            "primary_focus": primary_focus,
            "actions": actions,
            "check_in_prompt": (
                f"Ask the coach to adapt your {primary_focus['pillar_name']} plan to your week."
            ),
        }
    )


def build_coach_snapshot(bundle: Dict) -> Dict:
    compass = build_compass(bundle)
    focus = compass["primary_focus"]["pillar_name"]
    care_context = build_care_context(bundle, compass["primary_focus"])
    data_coverage = build_data_coverage(bundle, compass["primary_focus"])
    return _normalize(
        {
            "patient_id": bundle["profile"]["patient_id"],
            "coach_name": "Ava",
            "intro": (
                f"I already have your watch trends and your doctor context on file. "
                f"Right now, {focus} is the most important area to work on first. "
                f"{care_context['last_appointment_summary']} "
                f"{data_coverage['tailoring_note']}"
            ),
            "suggested_prompts": [
                "Summarize what you already know about me.",
                "What from my last doctor visit matters most now?",
                "I recently had a heart event. What should I focus on first?",
                "How should I start tracking meals so advice gets more personal?",
            ],
        }
    )


def build_coach_reply(bundle: Dict, message: str) -> Dict:
    compass = build_compass(bundle)
    plan = build_weekly_plan(bundle)
    focus = compass["primary_focus"]
    care_context = build_care_context(bundle, focus)
    data_coverage = build_data_coverage(bundle, focus)
    lower_message = message.lower()

    reply = (
        f"Your compass currently points most strongly toward {focus['pillar_name']}. "
        f"{focus['why_now']} "
        f"{data_coverage['tailoring_note']} "
        "A good next step is to follow this week's action plan and then reassess your trajectory."
    )

    if "sleep" in lower_message:
        reply = (
            "Your sleep and recovery pillar explains how well you are resting and bouncing back. "
            "Improving sleep consistency and recovery quality is often the fastest way to improve weekly momentum."
        )
    elif "doctor" in lower_message or "appointment" in lower_message or "visit" in lower_message:
        reply = (
            f"{care_context['last_appointment_summary']} "
            "That context should shape the next step, so the app should support your follow-up rather than act like it is starting from zero."
        )
    elif "heart attack" in lower_message or "heart event" in lower_message:
        reply = (
            "If you are recovering from a recent heart attack or other serious heart event, "
            "the app should reinforce your clinician's recovery plan, medication instructions, and rehab guidance rather than replace them. "
            f"Within that guardrail, the most helpful use of the app is to support {focus['pillar_name'].lower()}, "
            "keep watch-based recovery visible, and turn your next appointment into a clearer plan."
        )
    elif "meal" in lower_message or "food" in lower_message or "nutrition" in lower_message or "track" in lower_message:
        reply = (
            f"{data_coverage['tailoring_note']} "
            "The easiest way to improve this is to log one meal a day for the next 7 days. "
            "That is enough to move nutrition support from generic advice toward something that actually fits your routine."
        )
    elif "offer" in lower_message or "package" in lower_message or "diagnostic" in lower_message:
        offer = compass["summary"]["recommended_offer"]
        if offer:
            reply = (
                f"The most relevant support option right now is {offer['offer_label']}. "
                f"It appears because {offer['rationale']}"
            )
    elif "week" in lower_message or "plan" in lower_message or "next" in lower_message:
        action_titles = ", ".join(action["title"] for action in plan["actions"])
        reply = (
            f"This week's plan focuses on {focus['pillar_name']}. Start with: {action_titles}."
        )

    return _normalize(
        {
            "patient_id": bundle["profile"]["patient_id"],
            "message": message,
            "reply": reply,
            "primary_focus": focus,
        }
    )
