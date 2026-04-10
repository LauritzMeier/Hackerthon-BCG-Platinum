from __future__ import annotations

from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Any, Dict, List, Optional


ACUTE_CARDIO_PREFIXES = ("I21", "I22")
ESTABLISHED_CARDIO_PREFIXES = ("I20", "I21", "I22", "I25", "I50")
ESTABLISHED_CARDIO_CONDITIONS = {
    "coronary_artery_disease",
    "heart_failure",
    "angina",
    "peripheral_arterial_disease",
}


def _to_float(value: Any, default: float = 0.0) -> float:
    if value in (None, ""):
        return default
    if isinstance(value, Decimal):
        return float(value)
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _round(value: float, digits: int = 1) -> float:
    return round(float(value), digits)


def split_pipe_values(value: Any) -> List[str]:
    return [item.strip() for item in str(value or "").split("|") if item.strip()]


def _parse_date(value: Any) -> Optional[datetime]:
    if not value:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, date):
        return datetime.combine(value, datetime.min.time(), tzinfo=timezone.utc)

    text = str(value).strip()
    if not text:
        return None

    try:
        parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
        return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
    except ValueError:
        pass

    for fmt in ("%Y-%m-%d", "%Y-%m-%dT%H:%M:%S"):
        try:
            return datetime.strptime(text, fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def parse_visit_history(value: Any) -> List[Dict[str, str]]:
    visits: List[Dict[str, str]] = []
    for entry in split_pipe_values(value):
        if ":" in entry:
            date_part, code = entry.split(":", 1)
        else:
            date_part, code = "", entry
        visits.append(
            {
                "date": date_part.strip(),
                "code": code.strip(),
            }
        )
    return visits


def profile_reference_date(profile: Dict[str, Any]) -> Optional[datetime]:
    candidates: List[datetime] = []

    for field in ("latest_wearable_date", "latest_survey_date"):
        parsed = _parse_date(profile.get(field))
        if parsed is not None:
            candidates.append(parsed)

    for visit in parse_visit_history(profile.get("visit_history")):
        parsed = _parse_date(visit.get("date"))
        if parsed is not None:
            candidates.append(parsed)

    if not candidates:
        return None
    return max(candidates)


def is_recent_relative_to_profile(
    profile: Dict[str, Any],
    value: Any,
    *,
    max_age_days: int,
) -> bool:
    parsed = _parse_date(value)
    if parsed is None:
        return False

    reference = profile_reference_date(profile)
    if reference is None:
        return True

    age_days = max(0, (reference.date() - parsed.date()).days)
    return age_days <= max_age_days


def _days_since_recent_event(
    profile: Dict[str, Any],
    prefixes: tuple[str, ...],
) -> Optional[int]:
    reference = profile_reference_date(profile)
    if reference is None:
        return None

    matching_days: List[int] = []
    for visit in parse_visit_history(profile.get("visit_history")):
        code = visit.get("code", "")
        if not any(code.startswith(prefix) for prefix in prefixes):
            continue
        parsed = _parse_date(visit.get("date"))
        if parsed is None:
            continue
        matching_days.append(max(0, (reference.date() - parsed.date()).days))

    if not matching_days:
        return None
    return min(matching_days)


def _has_icd_prefix(profile: Dict[str, Any], prefixes: tuple[str, ...]) -> bool:
    codes = split_pipe_values(profile.get("icd_codes"))
    return any(any(code.startswith(prefix) for prefix in prefixes) for code in codes)


def _has_condition(profile: Dict[str, Any], condition: str) -> bool:
    conditions = set(split_pipe_values(profile.get("chronic_conditions")))
    return condition in conditions


def assess_cardiovascular_health(profile: Dict[str, Any]) -> Dict[str, Any]:
    hr_30 = _to_float(profile.get("resting_hr_30d_avg"))
    hr_7 = _to_float(profile.get("resting_hr_7d_avg"))
    hrv_30 = _to_float(profile.get("hrv_30d_avg"))
    hrv_7 = _to_float(profile.get("hrv_7d_avg"))
    sbp = _to_float(profile.get("sbp_mmhg"))
    dbp = _to_float(profile.get("dbp_mmhg"))
    ldl = _to_float(profile.get("ldl_mmol"))
    steps_30 = _to_float(profile.get("steps_30d_avg"))

    has_established_cardio_condition = any(
        _has_condition(profile, condition)
        for condition in ESTABLISHED_CARDIO_CONDITIONS
    )
    has_established_cardio = has_established_cardio_condition or _has_icd_prefix(
        profile,
        ESTABLISHED_CARDIO_PREFIXES,
    )
    has_diabetes = _has_condition(profile, "type2_diabetes") or _has_icd_prefix(
        profile,
        ("E11",),
    )
    has_dyslipidaemia = _has_condition(
        profile,
        "dyslipidaemia",
    ) or _has_icd_prefix(profile, ("E78",))
    acute_event_days = _days_since_recent_event(profile, ACUTE_CARDIO_PREFIXES)
    ldl_target = 1.8 if has_established_cardio else 3.0

    score = 100.0
    score -= max(0.0, sbp - 120.0) * 0.6
    score -= max(0.0, dbp - 80.0) * 0.8
    score -= max(0.0, ldl - 3.0) * 10.0
    score -= max(0.0, hr_30 - 65.0) * 1.7
    score -= max(0.0, 28.0 - hrv_30) * 0.8
    score += max(0.0, hrv_30 - 35.0) * 0.4
    if steps_30 >= 9000:
        score += 8.0
    elif steps_30 >= 7000:
        score += 4.0

    if has_established_cardio:
        score -= 6.0
    if has_diabetes:
        score -= 4.0
    if has_dyslipidaemia and ldl > ldl_target:
        score -= min(8.0, (ldl - ldl_target) * 4.0)

    score = max(0.0, min(100.0, score))

    if acute_event_days is not None and acute_event_days <= 30:
        score = min(score, 32.0)
    elif acute_event_days is not None and acute_event_days <= 90:
        score = min(score, 40.0)
    elif acute_event_days is not None and acute_event_days <= 180:
        score = min(score, 48.0)
    elif has_established_cardio:
        score = min(score, 68.0)

    trend_delta = (hrv_7 - hrv_30) - (hr_7 - hr_30)
    if trend_delta >= 3.0:
        trend = "improving"
    elif trend_delta <= -3.0:
        trend = "drifting"
    else:
        trend = "stable"

    if acute_event_days is not None and acute_event_days <= 30:
        trend = "drifting"
    elif acute_event_days is not None and acute_event_days <= 90 and trend != "improving":
        trend = "drifting"

    explanation_parts = [
        "Cardiovascular health balances resting heart rate, HRV, blood pressure, lipids, and cardiac history.",
    ]
    if acute_event_days is not None and acute_event_days <= 30:
        explanation_parts.append(
            "A recent heart attack keeps this pillar in active recovery, so the score is intentionally capped even if wearable signals look steadier."
        )
    elif acute_event_days is not None and acute_event_days <= 90:
        explanation_parts.append(
            "A recent acute cardiac event keeps this pillar in a recovery phase, so wearable fitness signals do not tell the whole story yet."
        )
    elif has_established_cardio:
        explanation_parts.append(
            "Established cardiovascular disease keeps this score anchored to secondary-prevention risk, not just wearable fitness."
        )

    if has_established_cardio and has_dyslipidaemia and ldl > ldl_target:
        explanation_parts.append(
            f"LDL is still above the usual secondary-prevention target of {ldl_target:.1f} mmol/L."
        )
    if has_diabetes:
        explanation_parts.append("Diabetes adds further cardiovascular risk pressure.")

    key_signals = {
        "resting_hr_7d_avg": _round(hr_7),
        "resting_hr_30d_avg": _round(hr_30),
        "hrv_7d_avg": _round(hrv_7),
        "hrv_30d_avg": _round(hrv_30),
        "sbp_mmhg": _round(sbp),
        "dbp_mmhg": _round(dbp),
        "ldl_mmol": _round(ldl, 2),
        "steps_30d_avg": _round(steps_30),
        "established_cardiovascular_disease": has_established_cardio,
        "secondary_prevention_ldl_target_mmol": _round(ldl_target, 1),
    }
    if acute_event_days is not None:
        key_signals["recent_acute_cardiac_event_days_ago"] = acute_event_days

    return {
        "score": _round(score),
        "trend": trend,
        "summary": " ".join(explanation_parts),
        "key_signals": key_signals,
        "has_established_cardio": has_established_cardio,
        "acute_event_days": acute_event_days,
    }
