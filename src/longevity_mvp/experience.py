from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Dict, List, Optional

from .compass import build_coach_snapshot, build_compass, build_weekly_plan


def _to_float(value) -> float:
    if value is None:
        return 0.0
    if isinstance(value, Decimal):
        return float(value)
    return float(value)


def _round(value: float, digits: int = 1) -> float:
    return round(float(value), digits)


def _normalize(obj):
    if isinstance(obj, dict):
        return {key: _normalize(value) for key, value in obj.items()}
    if isinstance(obj, list):
        return [_normalize(value) for value in obj]
    if isinstance(obj, Decimal):
        return float(obj)
    if isinstance(obj, (date, datetime)):
        return obj.isoformat()
    return obj


def _metric_trend(current: float, baseline: float, positive_is_better: bool = True) -> str:
    delta = current - baseline
    threshold = 0.05 if max(abs(current), abs(baseline)) <= 10 else 1.0
    if abs(delta) <= threshold:
        return "stable"
    if positive_is_better:
        return "improving" if delta > 0 else "drifting"
    return "improving" if delta < 0 else "drifting"


def _latest_timeline_entry(timeline: List[Dict]) -> Optional[Dict]:
    return timeline[0] if timeline else None


def build_progress_summary(bundle: Dict) -> Dict:
    profile = bundle["profile"]
    latest = _latest_timeline_entry(bundle.get("timeline", []))

    headline_trends = [
        {
            "id": "movement",
            "label": "Movement",
            "current_value": _round(_to_float(profile.get("steps_7d_avg"))),
            "baseline_value": _round(_to_float(profile.get("steps_30d_avg"))),
            "unit": "steps/day",
            "trend": _metric_trend(
                _to_float(profile.get("steps_7d_avg")),
                _to_float(profile.get("steps_30d_avg")),
            ),
        },
        {
            "id": "recovery",
            "label": "Recovery",
            "current_value": _round(_to_float(profile.get("sleep_duration_7d_avg")), 2),
            "baseline_value": _round(_to_float(profile.get("sleep_duration_30d_avg")), 2),
            "unit": "hours/night",
            "trend": _metric_trend(
                _to_float(profile.get("sleep_duration_7d_avg")),
                _to_float(profile.get("sleep_duration_30d_avg")),
            ),
        },
        {
            "id": "resting_hr",
            "label": "Resting heart rate",
            "current_value": _round(_to_float(profile.get("resting_hr_7d_avg"))),
            "baseline_value": _round(_to_float(profile.get("resting_hr_30d_avg"))),
            "unit": "bpm",
            "trend": _metric_trend(
                _to_float(profile.get("resting_hr_7d_avg")),
                _to_float(profile.get("resting_hr_30d_avg")),
                positive_is_better=False,
            ),
        },
    ]

    return _normalize(
        {
            "latest_reading_date": (
                latest.get("reading_date")
                if latest is not None
                else profile.get("latest_wearable_date")
            ),
            "latest_snapshot": {
                "steps": latest.get("steps") if latest else None,
                "active_minutes": latest.get("active_minutes") if latest else None,
                "sleep_duration_hrs": latest.get("sleep_duration_hrs") if latest else None,
                "sleep_quality_score": latest.get("sleep_quality_score") if latest else None,
                "resting_hr_bpm": latest.get("resting_hr_bpm") if latest else None,
                "hrv_rmssd_ms": latest.get("hrv_rmssd_ms") if latest else None,
            },
            "headline_trends": headline_trends,
        }
    )


def build_experience(bundle: Dict) -> Dict:
    profile = bundle["profile"]
    compass = build_compass(bundle)
    weekly_plan = build_weekly_plan(bundle)
    coach = build_coach_snapshot(bundle)
    recommended_offer = compass["summary"]["recommended_offer"]
    offers = bundle.get("offers", [])
    additional_offers = [
        offer
        for offer in offers
        if recommended_offer is None
        or offer.get("offer_code") != recommended_offer.get("offer_code")
    ]
    flags = bundle.get("flags", [])
    age = _to_float(profile.get("age"))
    biological_age = profile.get("estimated_biological_age")

    return _normalize(
        {
            "patient_id": profile["patient_id"],
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "profile_summary": {
                "patient_id": profile["patient_id"],
                "age": profile.get("age"),
                "sex": profile.get("sex"),
                "country": profile.get("country"),
                "estimated_biological_age": biological_age,
                "age_gap_years": (
                    _round(_to_float(biological_age) - age, 1)
                    if biological_age is not None
                    else None
                ),
            },
            "compass": compass,
            "weekly_plan": weekly_plan,
            "coach": coach,
            "progress_summary": build_progress_summary(bundle),
            "alerts": {
                "total_count": len(flags),
                "high_priority_count": sum(
                    1 for flag in flags if flag.get("severity") == "high"
                ),
                "items": flags[:3],
            },
            "offers": {
                "recommended": recommended_offer,
                "additional_items": additional_offers[:3],
            },
        }
    )
