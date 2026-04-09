"""Offer matching and booking heuristics aligned with the Flutter UI."""

from __future__ import annotations

import re
from datetime import datetime, timedelta
from typing import Any, Dict, Iterable, List, Optional

BOOKING_CONFIRMATION_PHRASES = [
    "book it",
    "book this",
    "please book",
    "go ahead",
    "lets do it",
    "let's do it",
    "schedule it",
    "schedule this",
    "sounds good",
    "that works",
    "do that",
    "yes",
    "yes please",
    "sure",
    "ok",
    "okay",
]

DIRECT_BOOKING_PHRASES = [
    "book ",
    "schedule ",
    "sign me up",
    "i want to book",
    "i'd like to book",
    "please book",
]

OFFER_REQUEST_PHRASES = [
    "offer",
    "support",
    "program",
    "package",
    "diagnostic",
    "diagnostics",
    "appointment",
    "visit",
    "lab",
    "screening",
    "clinic",
    "book",
    "booking",
]

TYPE_HINTS = {
    "diagnostic": ["lab", "test", "diagnostic", "blood", "panel", "screening"],
    "appointment": ["appointment", "visit", "review", "doctor", "clinician", "follow up"],
    "appointment_prep": ["appointment prep", "prep", "visit prep"],
    "program": ["program", "plan", "rehab", "movement", "recovery plan"],
    "coaching": ["coach", "coaching", "nutrition", "meal", "food"],
    "starter": ["starter", "track", "tracking", "meal tracking", "start now"],
    "supplement": ["supplement", "omega", "coq10"],
}


def normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9]+", " ", value.lower())).strip()


def offer_request_detected(message: str) -> bool:
    normalized = normalize_text(message)
    return any(phrase in normalized for phrase in OFFER_REQUEST_PHRASES)


def direct_booking_requested(message: str) -> bool:
    normalized = normalize_text(message)
    if normalized.startswith("book ") or normalized.startswith("schedule "):
        return True
    if any(
        phrase in normalized
        for phrase in DIRECT_BOOKING_PHRASES
        if phrase not in {"book ", "schedule "}
    ):
        return True
    return normalized in {"book it", "schedule it"}


def booking_confirmation_detected(message: str) -> bool:
    normalized = normalize_text(message)
    if direct_booking_requested(message):
        return True
    return normalized in BOOKING_CONFIRMATION_PHRASES


def build_offer_slots(offer: Dict[str, Any], *, now: Optional[datetime] = None) -> List[Dict[str, Any]]:
    """Mirror the slot generation used by the Flutter offer sheet."""
    current = now or datetime.now()
    offer_type = str(offer.get("offer_type") or "")
    if offer_type == "diagnostic":
        base_hour = 8
        offsets = [3, 6, 10]
    elif offer_type in {"program", "coaching"}:
        base_hour = 10
        offsets = [2, 5, 9]
    elif offer_type == "starter":
        base_hour = 9
        offsets = [1, 3, 7]
    elif offer_type == "supplement":
        base_hour = 15
        offsets = [2, 5, 8]
    else:
        base_hour = 9
        offsets = [2, 5, 8]

    slots: List[Dict[str, Any]] = []
    for index, days in enumerate(offsets):
        target_day = current + timedelta(days=days)
        scheduled_for = target_day.replace(
            hour=base_hour,
            minute=0 if index == 0 else 30,
            second=0,
            microsecond=0,
        )
        weekday = scheduled_for.strftime("%a")
        day = str(int(scheduled_for.strftime("%d")))
        month = scheduled_for.strftime("%b")
        time_label = scheduled_for.strftime("%H:%M")
        label = f"{weekday} {day} {month} • {time_label}"
        slots.append({"scheduled_for": scheduled_for, "label": label})
    return slots


def offer_lookup_tokens(offer: Dict[str, Any]) -> List[str]:
    fields = [
        offer.get("offer_code"),
        offer.get("offer_label"),
        offer.get("category"),
        offer.get("offer_type"),
        offer.get("delivery_model"),
        offer.get("summary"),
        offer.get("why_now"),
        offer.get("rationale"),
    ]
    tokens: List[str] = []
    for field in fields:
        text = normalize_text(str(field or ""))
        if text:
            tokens.extend(text.split(" "))
    return tokens


def offer_matches_message(message: str, offer: Dict[str, Any]) -> bool:
    normalized = normalize_text(message)
    if not normalized:
        return False

    label_text = normalize_text(str(offer.get("offer_label") or ""))
    code_text = normalize_text(str(offer.get("offer_code") or ""))
    if label_text and label_text in normalized:
        return True
    if code_text and code_text.replace("_", " ") in normalized:
        return True

    tokens = set(offer_lookup_tokens(offer))
    message_tokens = set(normalized.split(" "))
    overlap = len(tokens & message_tokens)
    return overlap >= 2


def merge_offer_details(primary_offer: Dict[str, Any], catalog_offer: Dict[str, Any] | None) -> Dict[str, Any]:
    merged = dict(catalog_offer or {})
    merged.update({key: value for key, value in primary_offer.items() if value not in (None, "", [])})
    return merged


def ordered_offer_pool(
    recommended_offer: Dict[str, Any] | None,
    additional_offers: Iterable[Dict[str, Any]],
    catalog_offers: Iterable[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    by_code: Dict[str, Dict[str, Any]] = {}
    catalog_map = {
        str(offer.get("offer_code") or ""): offer for offer in catalog_offers if offer.get("offer_code")
    }

    def push(offer: Dict[str, Any] | None) -> None:
        if not offer:
            return
        offer_code = str(offer.get("offer_code") or "")
        if not offer_code:
            return
        merged = merge_offer_details(offer, catalog_map.get(offer_code))
        if not merged.get("active", True):
            return
        by_code[offer_code] = merged

    push(recommended_offer)
    for item in additional_offers:
        push(item)
    for item in catalog_offers:
        push(item)

    ordered = list(by_code.values())
    ordered.sort(
        key=lambda offer: (
            0 if recommended_offer and offer.get("offer_code") == recommended_offer.get("offer_code") else 1,
            int(offer.get("priority") or 99),
            int(offer.get("sort_order") or 999),
            str(offer.get("offer_label") or ""),
        )
    )
    return ordered


def select_matching_offer(
    message: str,
    *,
    recommended_offer: Dict[str, Any] | None,
    additional_offers: Iterable[Dict[str, Any]],
    catalog_offers: Iterable[Dict[str, Any]],
) -> Dict[str, Any] | None:
    normalized = normalize_text(message)
    pool = ordered_offer_pool(recommended_offer, additional_offers, catalog_offers)
    if not pool:
        return None

    if not normalized:
        return pool[0]

    generic_request = normalized in {
        "offer",
        "offers",
        "support",
        "support option",
        "what support makes sense",
    }
    if generic_request and recommended_offer:
        recommended_code = recommended_offer.get("offer_code")
        for offer in pool:
            if offer.get("offer_code") == recommended_code:
                return offer

    best_offer = None
    best_score = -1
    message_tokens = set(normalized.split(" "))

    for offer in pool:
        score = 0
        if recommended_offer and offer.get("offer_code") == recommended_offer.get("offer_code"):
            score += 18

        if offer_matches_message(message, offer):
            score += 30

        offer_tokens = set(offer_lookup_tokens(offer))
        score += len(offer_tokens & message_tokens) * 3

        offer_type = str(offer.get("offer_type") or "")
        for hinted_type, phrases in TYPE_HINTS.items():
            if hinted_type != offer_type:
                continue
            if any(phrase in normalized for phrase in phrases):
                score += 12

        offer_code = str(offer.get("offer_code") or "")
        if "cardio" in normalized or "heart" in normalized:
            if any(
                token in offer_code
                for token in ["cardio", "lipid", "heart", "rehab"]
            ):
                score += 10
        if "nutrition" in normalized or "meal" in normalized or "food" in normalized:
            if any(token in offer_code for token in ["nutrition", "meal"]):
                score += 10
        if "movement" in normalized or "exercise" in normalized or "recovery" in normalized:
            if any(token in offer_code for token in ["movement", "rehab", "recovery"]):
                score += 10

        if score > best_score:
            best_score = score
            best_offer = offer

    if best_score <= 0 and recommended_offer:
        recommended_code = recommended_offer.get("offer_code")
        for offer in pool:
            if offer.get("offer_code") == recommended_code:
                return offer

    return best_offer or pool[0]
