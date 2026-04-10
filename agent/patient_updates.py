"""Parse and apply patient-reported lifestyle updates from chat messages."""

from __future__ import annotations

from datetime import datetime, timezone
import re
from typing import Any, Dict, List, Optional

PILLAR_NAMES = {
    "sleep_recovery": "Sleep and Recovery",
    "cardiovascular_health": "Cardiovascular Health",
    "metabolic_health": "Metabolic Health",
    "movement_fitness": "Movement and Fitness",
    "nutrition_quality": "Nutrition Quality",
    "mental_resilience": "Mental Resilience",
}

QUESTION_STARTERS = {
    "what",
    "why",
    "how",
    "when",
    "where",
    "should",
    "can",
    "could",
    "would",
    "do",
    "did",
    "is",
    "are",
    "am",
    "will",
}

SELF_REPORT_TOKENS = {
    "i",
    "im",
    "ive",
    "my",
    "today",
    "yesterday",
    "this",
    "felt",
    "feeling",
}

UPDATE_PATTERNS = [
    {
        "event_type": "walk",
        "phrases": ["went for a walk", "walked", "walking", "walk today", "hiked", "hiking"],
        "label": "walking or light movement",
        "pillar_deltas": {
            "movement_fitness": 6.0,
            "mental_resilience": 1.5,
        },
    },
    {
        "event_type": "exercise",
        "phrases": [
            "worked out",
            "workout",
            "exercised",
            "exercise today",
            "ran",
            "run today",
            "jogged",
            "cycled",
            "bike ride",
            "swam",
            "gym",
            "training session",
        ],
        "label": "exercise or training",
        "pillar_deltas": {
            "movement_fitness": 7.0,
            "cardiovascular_health": 2.0,
            "mental_resilience": 1.5,
        },
    },
    {
        "event_type": "poor_movement",
        "phrases": ["sat all day", "sedentary all day", "didn't move much", "did not move much"],
        "label": "low movement or sedentary time",
        "pillar_deltas": {
            "movement_fitness": -4.0,
            "mental_resilience": -1.0,
        },
    },
    {
        "event_type": "good_sleep",
        "phrases": ["slept well", "good sleep", "slept great", "restful sleep", "rested well"],
        "label": "good sleep or recovery",
        "pillar_deltas": {
            "sleep_recovery": 6.0,
            "mental_resilience": 2.0,
        },
    },
    {
        "event_type": "poor_sleep",
        "phrases": ["slept badly", "poor sleep", "didn't sleep well", "did not sleep well", "insomnia", "restless night"],
        "label": "poor sleep or disrupted recovery",
        "pillar_deltas": {
            "sleep_recovery": -6.0,
            "mental_resilience": -2.0,
        },
    },
    {
        "event_type": "healthy_food",
        "phrases": [
            "healthy meal",
            "ate vegetables",
            "ate a salad",
            "meal logged",
            "logged my meals",
            "drank water",
            "hydrated well",
        ],
        "label": "helpful nutrition or hydration",
        "pillar_deltas": {
            "nutrition_quality": 4.5,
            "metabolic_health": 1.5,
        },
    },
    {
        "event_type": "unhealthy_food",
        "phrases": ["fast food", "junk food", "takeout", "drank alcohol", "too much alcohol", "binge ate"],
        "label": "nutrition strain or alcohol load",
        "pillar_deltas": {
            "nutrition_quality": -4.5,
            "metabolic_health": -2.0,
            "mental_resilience": -1.0,
        },
    },
    {
        "event_type": "stress_relief",
        "phrases": ["meditated", "felt calm", "relaxed", "therapy session", "breathing exercise"],
        "label": "stress relief or recovery support",
        "pillar_deltas": {
            "mental_resilience": 5.0,
            "sleep_recovery": 1.5,
        },
    },
    {
        "event_type": "stress_load",
        "phrases": ["stressed", "overwhelmed", "anxious", "burned out", "burnt out", "panic attack"],
        "label": "high stress load",
        "pillar_deltas": {
            "mental_resilience": -6.0,
            "sleep_recovery": -2.0,
        },
    },
]


def normalize_patient_update_text(message: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9]+", " ", message.lower())).strip()


def _looks_like_question(message: str, normalized: str) -> bool:
    if "?" in message:
        return True
    tokens = normalized.split()
    return bool(tokens and tokens[0] in QUESTION_STARTERS)


def _looks_like_self_report(normalized: str) -> bool:
    tokens = normalized.split()
    if not tokens:
        return False
    if tokens[0] in SELF_REPORT_TOKENS:
        return True
    return " i " in f" {normalized} "


def _aggregate_pillar_impacts(events: List[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    impacts: Dict[str, Dict[str, Any]] = {}
    for event in events:
        for pillar_id, delta in (event.get("pillar_deltas") or {}).items():
            entry = impacts.setdefault(
                pillar_id,
                {
                    "score_delta": 0.0,
                    "reasons": [],
                },
            )
            entry["score_delta"] += float(delta)
            label = event.get("label")
            if label and label not in entry["reasons"]:
                entry["reasons"].append(label)

    for pillar_id, impact in impacts.items():
        impact["score_delta"] = round(impact["score_delta"], 1)
        reasons = impact.pop("reasons", [])
        impact["reason"] = ", ".join(reasons) if reasons else PILLAR_NAMES.get(pillar_id, pillar_id)
    return impacts


def derive_patient_reported_update(message: str) -> Optional[Dict[str, Any]]:
    normalized = normalize_patient_update_text(message)
    if not normalized or _looks_like_question(message, normalized) or not _looks_like_self_report(normalized):
        return None

    events: List[Dict[str, Any]] = []
    for pattern in UPDATE_PATTERNS:
        if any(phrase in normalized for phrase in pattern["phrases"]):
            events.append(
                {
                    "event_type": pattern["event_type"],
                    "label": pattern["label"],
                    "pillar_deltas": dict(pattern["pillar_deltas"]),
                }
            )

    if not events:
        return None

    pillar_impacts = _aggregate_pillar_impacts(events)
    affected_pillars = sorted(
        pillar_impacts.keys(),
        key=lambda pillar_id: abs(float(pillar_impacts[pillar_id]["score_delta"])),
        reverse=True,
    )
    top_names = [PILLAR_NAMES.get(pillar_id, pillar_id) for pillar_id in affected_pillars[:2]]
    if not top_names:
        return None

    if len(top_names) == 1:
        summary = f"Recent chat update mainly affects {top_names[0]}."
    else:
        summary = f"Recent chat update mainly affects {top_names[0]} and {top_names[1]}."

    return {
        "message": message.strip(),
        "normalized_message": normalized,
        "events": events,
        "pillar_impacts": pillar_impacts,
        "summary": summary,
    }


def _parse_timestamp(value: Any) -> Optional[datetime]:
    if isinstance(value, datetime):
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)
    if not value:
        return None
    try:
        text = str(value).replace("Z", "+00:00")
        parsed = datetime.fromisoformat(text)
        if parsed.tzinfo is None:
            return parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)
    except ValueError:
        return None


def _update_weight(update: Dict[str, Any], *, now: Optional[datetime] = None) -> float:
    current = now or datetime.now(timezone.utc)
    created_at = _parse_timestamp(update.get("created_at"))
    if created_at is None:
        return 0.4

    age_days = max(0.0, (current - created_at).total_seconds() / 86400.0)
    if age_days <= 1:
        return 1.0
    if age_days <= 3:
        return 0.75
    if age_days <= 7:
        return 0.5
    if age_days <= 14:
        return 0.25
    return 0.0


def apply_patient_reported_updates(
    pillars: List[Dict[str, Any]],
    updates: List[Dict[str, Any]],
    *,
    score_to_state: Any,
    now: Optional[datetime] = None,
) -> Dict[str, Any]:
    if not pillars:
        return {
            "pillars": [],
            "summary": "",
            "applied_update_count": 0,
            "affected_pillars": [],
        }

    decorated_pillars = []
    for pillar in pillars:
        decorated_pillars.append(
            {
                **pillar,
                "key_signals": dict(pillar.get("key_signals") or {}),
                "data_sources": list(pillar.get("data_sources") or []),
            }
        )

    deltas: Dict[str, float] = {}
    counts: Dict[str, int] = {}
    latest_reason: Dict[str, str] = {}
    applied_updates = 0

    for update in updates:
        weight = _update_weight(update, now=now)
        if weight <= 0.0:
            continue
        impacts = update.get("pillar_impacts") or {}
        if not impacts:
            continue
        applied_updates += 1
        for pillar_id, impact in impacts.items():
            raw_delta = float((impact or {}).get("score_delta") or 0.0)
            if raw_delta == 0.0:
                continue
            deltas[pillar_id] = deltas.get(pillar_id, 0.0) + (raw_delta * weight)
            counts[pillar_id] = counts.get(pillar_id, 0) + 1
            reason = str((impact or {}).get("reason") or "").strip()
            if reason:
                latest_reason[pillar_id] = reason

    for pillar_id in list(deltas.keys()):
        deltas[pillar_id] = max(-12.0, min(12.0, round(deltas[pillar_id], 1)))

    affected_pillars = sorted(deltas.keys(), key=lambda pillar_id: abs(deltas[pillar_id]), reverse=True)

    for pillar in decorated_pillars:
        pillar_id = pillar["id"]
        delta = deltas.get(pillar_id, 0.0)
        if abs(delta) < 0.1:
            continue
        adjusted_score = max(0.0, min(100.0, float(pillar["score"]) + delta))
        pillar["score"] = round(adjusted_score, 1)
        pillar["state"] = score_to_state(adjusted_score)
        if delta >= 2.0:
            pillar["trend"] = "improving"
        elif delta <= -2.0:
            pillar["trend"] = "drifting"
        pillar["key_signals"]["patient_reported_delta_14d"] = round(delta, 1)
        pillar["key_signals"]["patient_reported_updates_14d"] = counts.get(pillar_id, 0)
        if latest_reason.get(pillar_id):
            pillar["key_signals"]["latest_patient_report"] = latest_reason[pillar_id]
        if "patient_reported_chat_updates" not in pillar["data_sources"]:
            pillar["data_sources"].append("patient_reported_chat_updates")
        note = " Recent patient-reported chat updates were also factored into this pillar."
        if note.strip() not in pillar.get("explanation", ""):
            pillar["explanation"] = f"{pillar.get('explanation', '').rstrip()}{note}".strip()

    if not affected_pillars:
        return {
            "pillars": decorated_pillars,
            "summary": "",
            "applied_update_count": applied_updates,
            "affected_pillars": [],
        }

    names = [PILLAR_NAMES.get(pillar_id, pillar_id) for pillar_id in affected_pillars[:2]]
    if len(names) == 1:
        summary = f"Recent chat updates are currently nudging {names[0]}."
    else:
        summary = f"Recent chat updates are currently nudging {names[0]} and {names[1]}."

    return {
        "pillars": decorated_pillars,
        "summary": summary,
        "applied_update_count": applied_updates,
        "affected_pillars": affected_pillars,
        "pillar_deltas": {pillar_id: deltas[pillar_id] for pillar_id in affected_pillars},
    }
