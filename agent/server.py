"""Single-chat streaming API for the Longevity ADK agent."""

from __future__ import annotations

import asyncio
import json
import logging
import os
import re
from typing import Any, AsyncGenerator, Dict, List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel

from .coach_voice import (
    compose_general_sections,
    compose_offer_booking_sections,
    compose_offer_recommendation_sections,
    compose_pillar_sections,
    compose_priority_sections,
    compose_tailored_sections,
    firebase_context_line,
    safety_footers,
)
from .firebase_client import (
    create_support_booking,
    get_patient_firebase_context,
    get_patient_offer_context,
    get_runtime_diagnostics,
    save_agent_offer_state,
)
from .main import analyze_six_pillars, build_tailored_explanation, explain_pillar
from .offer_actions import (
    booking_confirmation_detected,
    build_offer_slots,
    direct_booking_requested,
    normalize_text,
    offer_request_detected,
    select_matching_offer,
)

app = FastAPI(
    title="Longevity ADK Agent Server",
    version="0.1.0",
    description="Single central chat API with SSE streaming and pillar-aware routing.",
)
logger = logging.getLogger(__name__)


def _flag_enabled(*names: str) -> bool:
    return any(os.getenv(name, "").lower() in {"1", "true", "yes", "on"} for name in names)


def _debug_enabled() -> bool:
    return _flag_enabled("AGENT_DEBUG")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    message: str
    patient_id: str = "PT0001"
    include_evidence_index: bool = False
    include_debug: bool = False


def _chat_debug_enabled(request: Optional[ChatRequest] = None) -> bool:
    return bool(request and request.include_debug) or _flag_enabled("AGENT_DEBUG", "AGENT_DEBUG_CHAT")


PILLAR_KEYWORDS = {
    "sleep_recovery": ["sleep", "recovery"],
    "cardiovascular_health": ["cardio", "heart", "blood pressure", "cardiovascular", "hrv", "resting hr"],
    "metabolic_health": ["metabolic", "glucose", "hba1c", "cholesterol", "lipid", "insulin"],
    "movement_fitness": ["movement", "fitness", "steps", "activity", "exercise", "active minutes"],
    "nutrition_quality": ["nutrition", "diet", "food", "alcohol", "hydration", "water"],
    "mental_resilience": ["mental", "stress", "wellbeing", "resilience", "mood"],
}

PRIORITY_INTENT_KEYWORDS = {
    "weakness": [
        "weakness",
        "weakest",
        "biggest weakness",
        "worst",
        "lowest",
        "struggling",
        "biggest issue",
        "main problem",
        "burning out",
        "burnout",
        "worried",
        "worry about",
        "concerned",
        "slipping",
        "warning signs",
        "what am i missing",
        "afraid of",
        "riskiest",
        "vulnerable",
    ],
    "strength": [
        "strength",
        "strongest",
        "best",
        "doing well",
        "relative strength",
        "bright spot",
        "what am i good at",
        "where am i strong",
        "winning",
        "what is working",
    ],
    "deprioritize": [
        "shouldnt focus",
        "shouldn't focus",
        "should not focus",
        "shouldnt be my focus",
        "shouldn't be my focus",
        "should not be my focus",
        "not be my focus",
        "not focus",
        "least important",
        "deprioritize",
        "ignore",
        "focus less",
        "dont obsess",
        "don't obsess",
        "stop worrying",
        "worry less about",
        "not worth obsessing",
        "overthinking",
    ],
    "priority": [
        "top focus",
        "focus",
        "priority",
        "prioritize",
        "focus on",
        "main focus",
        "biggest risk",
        "this week",
        "where do i start",
        "what should i work on",
        "help me prioritize",
        "on track",
        "biggest lever",
        "one thing",
        "first step",
        "coach me",
        "what matters most",
        "explain my",
        "guide me",
        "too busy",
        "no time",
        "simplest",
        "straightforward",
    ],
}


def _normalized_text(message: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9]+", " ", message.lower())).strip()


def _extract_target_pillar(message: str) -> Optional[str]:
    lower_message = _normalized_text(message)
    for pillar_id, words in PILLAR_KEYWORDS.items():
        if any(word in lower_message for word in words):
            return pillar_id
    return None


def _is_pillar_related(message: str) -> bool:
    lower_message = _normalized_text(message)
    generic_signals = [
        "pillar",
        "longevity",
        "healthspan",
        "analyze",
        "analysis",
        "score",
        "trajectory",
        "focus area",
        "focus",
        "weakness",
        "weakest",
        "strongest",
        "priority",
        "compass",
        "independence",
        "energy",
        "prevention",
        "optimize",
        "overwhelmed",
        "sustainable",
        "routine",
        "habit",
        "recovery",
        "burnout",
        "stress",
        "credibility",
        "trust",
        "data driven",
        "measurable",
        "roi",
    ]
    return any(token in lower_message for token in generic_signals) or _extract_target_pillar(message) is not None


def _extract_priority_intent(message: str) -> Optional[str]:
    lower_message = _normalized_text(message)
    for intent, keywords in PRIORITY_INTENT_KEYWORDS.items():
        if any(keyword in lower_message for keyword in keywords):
            return intent
    return None


def _sorted_pillars_by_priority(analysis: Dict[str, Any]) -> List[Dict[str, Any]]:
    return sorted(
        analysis["pillars"],
        key=lambda pillar: (pillar["score"], 0 if pillar["trend"] == "drifting" else 1),
    )


def _compose_priority_answer(message: str, analysis: Dict[str, Any]) -> List[str]:
    if not analysis.get("ok"):
        return [
            "I couldn't pull enough structured data for this patient id yet — double-check the id and that records synced.",
            "Until the warehouse loads, I can't personalize this; treat anything generic as placeholder.",
        ]

    ranked = _sorted_pillars_by_priority(analysis)
    weakest = ranked[0]
    next_weakest = ranked[1] if len(ranked) > 1 else ranked[0]
    strongest = max(analysis["pillars"], key=lambda pillar: pillar["score"])
    intent = _extract_priority_intent(message) or "priority"
    persona_context = analysis.get("persona_context")

    sections = compose_priority_sections(
        intent,
        weakest,
        strongest,
        next_weakest,
        persona_context=persona_context,
    )
    sections.append(firebase_context_line(analysis["firebase_context_summary"]))
    sections.extend(safety_footers())
    return sections


def _find_booked_offer(offer_context: Dict[str, Any], offer_code: str | None) -> Optional[Dict[str, Any]]:
    if not offer_code:
        return None
    for booking in offer_context.get("support_bookings") or []:
        if booking.get("offer_code") == offer_code and booking.get("status") == "booked":
            return booking
    return None


def _find_offer_by_code(offer_context: Dict[str, Any], offer_code: str | None) -> Optional[Dict[str, Any]]:
    if not offer_code:
        return None
    candidates = []
    if offer_context.get("recommended_offer"):
        candidates.append(offer_context["recommended_offer"])
    candidates.extend(offer_context.get("additional_offers") or [])
    candidates.extend(offer_context.get("catalog_offers") or [])
    for offer in candidates:
        if offer.get("offer_code") == offer_code:
            return offer
    return None


def _serialize_offer_slot(slot: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    if not slot:
        return None
    scheduled_for = slot.get("scheduled_for")
    if hasattr(scheduled_for, "isoformat"):
        scheduled_for = scheduled_for.isoformat()
    return {
        "scheduled_for": scheduled_for,
        "label": slot.get("label"),
    }


def _build_offer_response(
    request: ChatRequest,
    *,
    analysis: Dict[str, Any],
    offer_context: Dict[str, Any],
) -> Optional[Dict[str, Any]]:
    message = request.message.strip()
    if not (offer_request_detected(message) or booking_confirmation_detected(message)):
        return None

    persona_context = analysis.get("persona_context")
    primary_focus = offer_context.get("primary_focus") or analysis.get("primary_focus") or {}
    recommended_offer = offer_context.get("recommended_offer")
    additional_offers = offer_context.get("additional_offers") or []
    catalog_offers = offer_context.get("catalog_offers") or []
    agent_offer_state = offer_context.get("agent_offer_state") or {}
    normalized_message = normalize_text(message)
    generic_booking_confirmation = normalized_message in {
        "book it",
        "book this",
        "schedule it",
        "schedule this",
        "please book",
        "go ahead",
        "lets do it",
        "let s do it",
        "sounds good",
        "that works",
        "do that",
        "yes",
        "yes please",
        "sure",
        "ok",
        "okay",
    }

    if not any([recommended_offer, additional_offers, catalog_offers]):
        sections = [
            "I couldn't find any support offers for this patient yet, so I shouldn't pretend there is something ready to book.",
            "Once `patient_experiences` and `offer_catalog` are synced, I can recommend the best fit and book it from chat.",
        ]
        sections.append(firebase_context_line(analysis.get("firebase_context_summary", "")))
        sections.extend(safety_footers())
        return {
            "patient_id": request.patient_id,
            "sections": sections,
            "evidence_index": analysis.get("pillars", []) if analysis.get("ok") else {},
            "offer_action": {
                "type": "unavailable",
            },
            "source_payload": {
                **analysis,
                "offer_context": offer_context,
            },
        }

    selected_offer = None
    if booking_confirmation_detected(message) and agent_offer_state.get("status") == "proposed" and generic_booking_confirmation:
        selected_offer = _find_offer_by_code(
            offer_context,
            agent_offer_state.get("offer_code"),
        )
    elif direct_booking_requested(message):
        selected_offer = select_matching_offer(
            message,
            recommended_offer=recommended_offer,
            additional_offers=additional_offers,
            catalog_offers=catalog_offers,
        )
        if selected_offer is None and agent_offer_state.get("status") == "proposed":
            selected_offer = _find_offer_by_code(
                offer_context,
                agent_offer_state.get("offer_code"),
            )
    elif booking_confirmation_detected(message) and agent_offer_state.get("status") == "proposed":
        selected_offer = _find_offer_by_code(
            offer_context,
            agent_offer_state.get("offer_code"),
        )

    if selected_offer is not None:
        existing_booking = _find_booked_offer(offer_context, selected_offer.get("offer_code"))
        if existing_booking:
            sections = compose_offer_recommendation_sections(
                selected_offer,
                primary_focus=primary_focus,
                persona_context=persona_context,
                existing_booking=existing_booking,
            )
            sections.append(firebase_context_line(analysis.get("firebase_context_summary", "")))
            sections.extend(safety_footers())
            return {
                "patient_id": request.patient_id,
                "sections": sections,
                "evidence_index": analysis.get("pillars", []) if analysis.get("ok") else {},
                "offer_action": {
                    "type": "already_booked",
                    "offer": selected_offer,
                    "booking": existing_booking,
                },
                "source_payload": {
                    **analysis,
                    "offer_context": offer_context,
                    "booking": existing_booking,
                },
            }

        first_slot = build_offer_slots(selected_offer)[0]
        booking = create_support_booking(
            request.patient_id,
            offer=selected_offer,
            scheduled_for=first_slot["scheduled_for"],
            scheduled_label=first_slot["label"],
        )
        save_agent_offer_state(
            request.patient_id,
            status="booked",
            offer=selected_offer,
            booking=booking,
        )
        sections = compose_offer_booking_sections(
            selected_offer,
            booking,
            persona_context=persona_context,
        )
        sections.append(firebase_context_line(analysis.get("firebase_context_summary", "")))
        sections.extend(safety_footers())
        return {
            "patient_id": request.patient_id,
            "sections": sections,
            "evidence_index": analysis.get("pillars", []) if analysis.get("ok") else {},
            "offer_action": {
                "type": "booking_created",
                "offer": selected_offer,
                "booking": booking,
            },
            "booking": booking,
            "source_payload": {
                **analysis,
                "offer_context": offer_context,
                "booking": booking,
            },
        }

    if offer_request_detected(message):
        selected_offer = select_matching_offer(
            message,
            recommended_offer=recommended_offer,
            additional_offers=additional_offers,
            catalog_offers=catalog_offers,
        )
        if selected_offer is None:
            return None
        existing_booking = _find_booked_offer(offer_context, selected_offer.get("offer_code"))
        first_slot = build_offer_slots(selected_offer)[0] if not existing_booking else None
        save_agent_offer_state(
            request.patient_id,
            status="proposed",
            offer=selected_offer,
            booking=existing_booking,
        )
        sections = compose_offer_recommendation_sections(
            selected_offer,
            primary_focus=primary_focus,
            persona_context=persona_context,
            scheduled_label=None if existing_booking else (first_slot or {}).get("label"),
            existing_booking=existing_booking,
        )
        sections.append(firebase_context_line(analysis.get("firebase_context_summary", "")))
        sections.extend(safety_footers())
        return {
            "patient_id": request.patient_id,
            "sections": sections,
            "evidence_index": analysis.get("pillars", []) if analysis.get("ok") else {},
            "offer_action": {
                "type": "proposal",
                "offer": selected_offer,
                "first_slot": _serialize_offer_slot(first_slot),
                "already_booked": bool(existing_booking),
            },
            "source_payload": {
                **analysis,
                "offer_context": offer_context,
            },
        }

    if booking_confirmation_detected(message):
        sections = [
            "I can book that for you, but I need one offer to anchor on first.",
            "Ask me which support option fits best, or name the visit, lab, or program you want booked.",
        ]
        sections.extend(safety_footers())
        return {
            "patient_id": request.patient_id,
            "sections": sections,
            "evidence_index": analysis.get("pillars", []) if analysis.get("ok") else {},
            "offer_action": {
                "type": "booking_needs_offer",
            },
            "source_payload": {
                **analysis,
                "offer_context": offer_context,
            },
        }

    return None


def _compose_from_tailored(payload: Dict) -> List[str]:
    return compose_tailored_sections(payload)


def _compose_general_chat(message: str, patient_id: str) -> List[str]:
    analysis = build_tailored_explanation(patient_id)
    if not analysis.get("ok"):
        return [
            "I couldn't load a full picture for that patient id — worth verifying the id and data pipeline.",
            "Once records are in, I can answer in a much more personal tone.",
        ]

    focus = analysis["claims"][0]["evidence"][0]
    return compose_general_sections(
        message,
        patient_id,
        focus,
        persona_context=analysis.get("persona_context"),
    )


def _extract_debug_payload(source_payload: Dict[str, Any], request: ChatRequest) -> Dict[str, Any]:
    firebase_context = source_payload.get("firebase_context") or {}
    payload: Dict[str, Any] = {
        "request": {
            "patient_id": request.patient_id,
            "message": request.message,
            "include_evidence_index": request.include_evidence_index,
            "include_debug": request.include_debug,
        },
        "firebase_context_summary": source_payload.get("firebase_context_summary")
        or (source_payload.get("context") or {}).get("firebase_context_summary"),
    }
    if firebase_context:
        normalized = firebase_context.get("normalized") or {}
        payload["firebase"] = {
            "lookup_status": firebase_context.get("lookup_status"),
            "failure_stage": firebase_context.get("failure_stage"),
            "warning": firebase_context.get("warning"),
            "project_id": firebase_context.get("project_id"),
            "database_id": firebase_context.get("database_id"),
            "collections_found": firebase_context.get("collections_found"),
            "collections_checked": firebase_context.get("collections_checked"),
            "context_format": normalized.get("context_format"),
        }
    if source_payload.get("firebase_debug"):
        payload["firebase_diagnostics"] = source_payload["firebase_debug"]
    if source_payload.get("offer_context"):
        offer_context = source_payload["offer_context"]
        payload["offers"] = {
            "experience_available": offer_context.get("experience_available"),
            "recommended_offer_code": (offer_context.get("recommended_offer") or {}).get("offer_code"),
            "additional_offer_codes": [
                offer.get("offer_code") for offer in (offer_context.get("additional_offers") or [])
            ],
            "catalog_offer_count": len(offer_context.get("catalog_offers") or []),
            "support_booking_count": len(offer_context.get("support_bookings") or []),
            "agent_offer_state": offer_context.get("agent_offer_state"),
            "warning": offer_context.get("warning"),
        }
    if source_payload.get("offer_action"):
        payload["offer_action"] = source_payload["offer_action"]
    if source_payload.get("booking"):
        payload["booking"] = source_payload["booking"]
    if source_payload.get("persona_context"):
        persona_context = source_payload["persona_context"]
        payload["persona"] = {
            "matched_persona": persona_context.get("persona_name"),
            "patient_age": persona_context.get("patient_age"),
            "patient_country": persona_context.get("patient_country"),
            "life_stage": persona_context.get("life_stage"),
            "digital_fluency": persona_context.get("digital_fluency"),
            "main_motivation": persona_context.get("main_motivation"),
            "main_fear": persona_context.get("main_fear"),
        }
    if source_payload.get("patient_profile"):
        payload["patient_profile"] = source_payload["patient_profile"]
    payload["runtime"] = get_runtime_diagnostics()
    return payload


def _build_debug_section(debug_payload: Dict[str, Any]) -> Optional[str]:
    firebase = debug_payload.get("firebase") or {}
    if not firebase:
        return None
    parts = []
    if firebase.get("lookup_status"):
        parts.append(f"lookup_status={firebase['lookup_status']}")
    if firebase.get("failure_stage"):
        parts.append(f"failure_stage={firebase['failure_stage']}")
    if firebase.get("warning"):
        parts.append(f"warning={firebase['warning']}")
    if firebase.get("context_format"):
        parts.append(f"context_format={firebase['context_format']}")
    return f"Debug note: {' | '.join(parts)}" if parts else None


def _build_chat_sections(request: ChatRequest) -> Dict[str, object]:
    patient_id = request.patient_id
    message = request.message.strip()
    if not message:
        raise HTTPException(status_code=400, detail="message is required")

    source_payload: Dict[str, Any] = {}
    if offer_request_detected(message) or booking_confirmation_detected(message):
        analysis = analyze_six_pillars(patient_id)
        offer_context = get_patient_offer_context(patient_id)
        offer_payload = _build_offer_response(
            request,
            analysis=analysis,
            offer_context=offer_context,
        )
        if offer_payload is not None:
            source_payload = offer_payload.get("source_payload") or {}
            debug_payload = _extract_debug_payload(source_payload, request) if _chat_debug_enabled(request) else None
            sections = list(offer_payload["sections"])
            if debug_payload:
                debug_section = _build_debug_section(debug_payload)
                if debug_section:
                    sections.append(debug_section)
            return {
                "patient_id": patient_id,
                "sections": sections,
                "evidence_index": offer_payload.get("evidence_index", {}),
                "debug": debug_payload,
                "offer_action": offer_payload.get("offer_action"),
                "booking": offer_payload.get("booking"),
            }

    priority_intent = _extract_priority_intent(message)
    if priority_intent and _extract_target_pillar(message) is None:
        analysis = analyze_six_pillars(patient_id)
        source_payload = analysis
        sections = _compose_priority_answer(message, analysis)
        evidence_index = analysis.get("pillars", []) if analysis.get("ok") else {}
    elif _is_pillar_related(message):
        target_pillar = _extract_target_pillar(message)
        if target_pillar:
            pillar_payload = explain_pillar(patient_id, target_pillar)
            if not pillar_payload.get("ok"):
                raise HTTPException(status_code=404, detail=pillar_payload.get("error", "analysis failed"))
            pillar = pillar_payload["pillar"]
            source_payload = pillar_payload
            sections = compose_pillar_sections(
                pillar,
                pillar_payload["firebase_context_summary"],
                persona_context=pillar_payload.get("persona_context"),
            )
            evidence_index = {pillar["id"]: pillar}
        else:
            tailored = build_tailored_explanation(patient_id)
            if not tailored.get("ok"):
                raise HTTPException(status_code=404, detail=tailored.get("error", "analysis failed"))
            source_payload = tailored
            sections = _compose_from_tailored(tailored)
            evidence_index = tailored.get("evidence_index", {})
    else:
        sections = _compose_general_chat(message, patient_id)
        analysis = analyze_six_pillars(patient_id)
        source_payload = analysis
        evidence_index = analysis.get("pillars", []) if analysis.get("ok") else {}

    debug_payload = _extract_debug_payload(source_payload, request) if _chat_debug_enabled(request) else None
    if debug_payload:
        debug_section = _build_debug_section(debug_payload)
        if debug_section:
            sections.append(debug_section)

    return {
        "patient_id": patient_id,
        "sections": sections,
        "evidence_index": evidence_index,
        "debug": debug_payload,
        "offer_action": None,
        "booking": None,
    }


async def _sse_stream(
    chat_payload: Dict,
    include_evidence_index: bool,
    include_debug: bool,
) -> AsyncGenerator[str, None]:
    yield f"event: meta\ndata: {json.dumps({'status': 'started'})}\n\n"
    await asyncio.sleep(0.02)

    for section in chat_payload["sections"]:
        # Stream token-like chunks for responsive UI feedback.
        words = section.split(" ")
        chunk = ""
        for word in words:
            chunk = f"{chunk} {word}".strip()
            yield f"event: delta\ndata: {json.dumps({'text': word + ' '})}\n\n"
            await asyncio.sleep(0.01)
        yield f"event: section\ndata: {json.dumps({'text': chunk})}\n\n"
        await asyncio.sleep(0.02)

    final_payload = {"status": "completed", "patient_id": chat_payload["patient_id"]}
    if include_evidence_index:
        final_payload["evidence_index"] = chat_payload["evidence_index"]
    if include_debug and chat_payload.get("debug") is not None:
        final_payload["debug"] = chat_payload["debug"]
    if chat_payload.get("offer_action") is not None:
        final_payload["offer_action"] = chat_payload["offer_action"]
    if chat_payload.get("booking") is not None:
        final_payload["booking"] = chat_payload["booking"]

    yield f"event: done\ndata: {json.dumps(final_payload)}\n\n"


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/debug/runtime")
def debug_runtime() -> Dict[str, object]:
    """Return non-secret runtime diagnostics for deployment debugging."""
    return {
        "debug_enabled": _debug_enabled(),
        "runtime": get_runtime_diagnostics(),
    }


@app.get("/debug/firebase/{patient_id}")
def debug_firebase(patient_id: str) -> Dict[str, object]:
    """Return patient-scoped Firestore lookup diagnostics."""
    return {
        "debug_enabled": _debug_enabled(),
        "runtime": get_runtime_diagnostics(),
        "firebase_context": get_patient_firebase_context(patient_id),
    }


@app.post("/chat")
def chat_once(request: ChatRequest):
    try:
        chat_payload = _build_chat_sections(request)
    except HTTPException:
        raise
    except Exception as exc:  # pylint: disable=broad-except
        logger.exception("Unhandled chat error for patient_id=%s", request.patient_id)
        debug_line = f"Debug reference: {type(exc).__name__}"
        if _debug_enabled():
            debug_line = f"{debug_line} | {exc}"
        return JSONResponse(
            status_code=200,
            content={
                "patient_id": request.patient_id,
                "sections": [
                    "I hit a temporary backend issue while preparing your detailed response.",
                    "I can still help with high-level guidance right now, but evidence details may be limited.",
                    debug_line,
                    "Safety note: this is wellness coaching support and not a diagnosis.",
                ],
            },
        )
    response = {
        "patient_id": request.patient_id,
        "sections": chat_payload["sections"],
    }
    if request.include_evidence_index:
        response["evidence_index"] = chat_payload["evidence_index"]
    if chat_payload.get("offer_action") is not None:
        response["offer_action"] = chat_payload["offer_action"]
    if chat_payload.get("booking") is not None:
        response["booking"] = chat_payload["booking"]
    if _chat_debug_enabled(request) and chat_payload.get("debug") is not None:
        response["debug"] = chat_payload["debug"]
    return JSONResponse(content=response)


@app.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    try:
        chat_payload = _build_chat_sections(request)
    except HTTPException:
        raise
    except Exception as exc:  # pylint: disable=broad-except
        logger.exception("Unhandled chat stream error for patient_id=%s", request.patient_id)
        debug_line = f"Debug reference: {type(exc).__name__}"
        if _debug_enabled():
            debug_line = f"{debug_line} | {exc}"
        fallback_payload = {
            "patient_id": request.patient_id,
            "sections": [
                "I hit a temporary backend issue while preparing your detailed streaming response.",
                "Please retry in a moment. I can still provide general guidance in the meantime.",
                debug_line,
            ],
            "evidence_index": {},
            "debug": {"runtime": get_runtime_diagnostics()} if _chat_debug_enabled(request) else None,
        }
        return StreamingResponse(
            _sse_stream(
                fallback_payload,
                include_evidence_index=False,
                include_debug=_chat_debug_enabled(request),
            ),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
            },
        )
    return StreamingResponse(
        _sse_stream(
            chat_payload,
            include_evidence_index=request.include_evidence_index,
            include_debug=_chat_debug_enabled(request),
        ),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
