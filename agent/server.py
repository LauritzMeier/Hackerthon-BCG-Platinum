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

from .firebase_client import get_patient_firebase_context, get_runtime_diagnostics
from .main import analyze_six_pillars, build_tailored_explanation, explain_pillar

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
    ],
    "strength": [
        "strength",
        "strongest",
        "best",
        "doing well",
        "relative strength",
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
    ],
    "priority": [
        "top focus",
        "focus",
        "priority",
        "prioritize",
        "focus on",
        "main focus",
        "biggest risk",
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
            "I could not load enough patient data yet. Please confirm the patient id and data availability.",
            "Uncertainty note: this guidance cannot be personalized until data loads successfully.",
        ]

    ranked = _sorted_pillars_by_priority(analysis)
    weakest = ranked[0]
    next_weakest = ranked[1] if len(ranked) > 1 else ranked[0]
    strongest = max(analysis["pillars"], key=lambda pillar: pillar["score"])
    intent = _extract_priority_intent(message) or "priority"

    if intent == "weakness":
        sections = [
            f"Your biggest weakness right now is {weakest['name']}.",
            (
                f"It has the lowest priority-adjusted profile: score {weakest['score']} with a "
                f"{weakest['trend']} trend. The main signals are {weakest['key_signals']}."
            ),
            (
                f"This is why the app should focus here first, before {next_weakest['name']} or the stronger pillars."
            ),
        ]
    elif intent == "strength":
        sections = [
            f"Your strongest pillar right now is {strongest['name']}.",
            (
                f"It is currently the most resilient area: score {strongest['score']} with a "
                f"{strongest['trend']} trend. The main signals are {strongest['key_signals']}."
            ),
            "That means this pillar should be maintained, not over-managed.",
        ]
    elif intent == "deprioritize":
        sections = [
            f"What should not be your main focus right now is {strongest['name']}.",
            (
                f"It is currently your strongest area with score {strongest['score']} and trend "
                f"{strongest['trend']}, so it needs maintenance more than urgent attention."
            ),
            (
                f"The app should prioritize {weakest['name']} instead, because that is the biggest current drag on your overall trajectory."
            ),
        ]
    else:
        sections = [
            f"Your main focus right now should be {weakest['name']}.",
            (
                f"It has the weakest score and trend combination: score {weakest['score']}, trend "
                f"{weakest['trend']}, with key signals {weakest['key_signals']}."
            ),
            (
                f"What should get less attention for now is {strongest['name']}, which is comparatively stronger at score {strongest['score']}."
            ),
        ]

    sections.append(f"Context note: {analysis['firebase_context_summary']}")
    sections.append(
        "Safety note: this is wellness coaching support and not a diagnosis."
    )
    return sections


def _compose_from_tailored(payload: Dict) -> List[str]:
    context = payload["context"]
    claims = payload.get("claims", [])
    trade_offs = payload.get("trade_offs", [])
    actions = payload.get("next_best_actions", [])

    sections: List[str] = []
    sections.append(
        (
            f"Current direction is {context['overall_direction']} with average score "
            f"{context['average_score']}. {context['firebase_context_summary']}"
        )
    )

    for idx, claim in enumerate(claims, start=1):
        ev = claim["evidence"][0]
        sections.append(
            (
                f"Claim {idx}: {claim['claim']} Why: {claim['why']} "
                f"Evidence -> {ev['pillar_id']} score {ev['score']}, trend {ev['trend']}, "
                f"signals {ev['key_signals']}."
            )
        )

    for idx, trade_off in enumerate(trade_offs, start=1):
        sections.append(f"Trade-off {idx}: {trade_off['topic']}. {trade_off['detail']}")

    for idx, action in enumerate(actions, start=1):
        sections.append(
            f"Next action {idx}: {action['action']} Why: {action['why']} Evidence: {action['evidence']}."
        )

    sections.append(
        "Uncertainty note: this is wellness coaching guidance from available records; "
        "missing or delayed data can change interpretation."
    )
    sections.append(
        "Safety note: this is not a diagnosis. If risk signals are elevated, seek clinician follow-up."
    )
    return sections


def _compose_general_chat(message: str, patient_id: str) -> List[str]:
    analysis = build_tailored_explanation(patient_id)
    if not analysis.get("ok"):
        return [
            "I could not load enough patient data yet. Please confirm the patient id and data availability.",
            "Uncertainty note: this guidance cannot be personalized until data loads successfully.",
        ]

    focus = analysis["claims"][0]["evidence"][0]
    return [
        f"You asked: {message}",
        (
            "I can help with your central longevity chat and pull pillar analysis when relevant. "
            f"For {patient_id}, the current top focus is {focus['pillar_id']} "
            f"(score {focus['score']}, trend {focus['trend']})."
        ),
        "Ask me to explain any pillar, compare pillars, or recommend next-best actions.",
        "Safety note: this is wellness coaching support and not a diagnosis.",
    ]


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
            sections = [
                f"Here is your {pillar['name']} update.",
                (
                    f"State: {pillar['state']}, trend: {pillar['trend']}, score: {pillar['score']}. "
                    f"Explanation: {pillar['explanation']}"
                ),
                f"Evidence: {pillar['key_signals']} (sources: {pillar['data_sources']}).",
                f"Context note: {pillar_payload['firebase_context_summary']}",
                "Uncertainty note: interpretation can shift if new data arrives.",
                "Safety note: this is not a diagnosis; follow up with a clinician for clinical decisions.",
            ]
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
