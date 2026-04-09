"""Single-chat streaming API for the Longevity ADK agent."""

from __future__ import annotations

import asyncio
import json
from typing import AsyncGenerator, Dict, List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel

from main import analyze_six_pillars, build_tailored_explanation, explain_pillar

app = FastAPI(
    title="Longevity ADK Agent Server",
    version="0.1.0",
    description="Single central chat API with SSE streaming and pillar-aware routing.",
)


class ChatRequest(BaseModel):
    message: str
    patient_id: str = "PT0001"
    include_evidence_index: bool = False


PILLAR_KEYWORDS = {
    "sleep_recovery": ["sleep", "recovery"],
    "cardiovascular_health": ["cardio", "heart", "blood pressure", "cardiovascular", "hrv", "resting hr"],
    "metabolic_health": ["metabolic", "glucose", "hba1c", "cholesterol", "lipid", "insulin"],
    "movement_fitness": ["movement", "fitness", "steps", "activity", "exercise", "active minutes"],
    "nutrition_quality": ["nutrition", "diet", "food", "alcohol", "hydration", "water"],
    "mental_resilience": ["mental", "stress", "wellbeing", "resilience", "mood"],
}


def _extract_target_pillar(message: str) -> Optional[str]:
    lower_message = message.lower()
    for pillar_id, words in PILLAR_KEYWORDS.items():
        if any(word in lower_message for word in words):
            return pillar_id
    return None


def _is_pillar_related(message: str) -> bool:
    lower_message = message.lower()
    generic_signals = [
        "pillar",
        "longevity",
        "analyze",
        "analysis",
        "score",
        "trajectory",
        "focus area",
        "compass",
    ]
    return any(token in lower_message for token in generic_signals) or _extract_target_pillar(message) is not None


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


def _build_chat_sections(request: ChatRequest) -> Dict[str, object]:
    patient_id = request.patient_id
    message = request.message.strip()
    if not message:
        raise HTTPException(status_code=400, detail="message is required")

    if _is_pillar_related(message):
        target_pillar = _extract_target_pillar(message)
        if target_pillar:
            pillar_payload = explain_pillar(patient_id, target_pillar)
            if not pillar_payload.get("ok"):
                raise HTTPException(status_code=404, detail=pillar_payload.get("error", "analysis failed"))
            pillar = pillar_payload["pillar"]
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
            sections = _compose_from_tailored(tailored)
            evidence_index = tailored.get("evidence_index", {})
    else:
        sections = _compose_general_chat(message, patient_id)
        analysis = analyze_six_pillars(patient_id)
        evidence_index = analysis.get("pillars", []) if analysis.get("ok") else {}

    return {"patient_id": patient_id, "sections": sections, "evidence_index": evidence_index}


async def _sse_stream(chat_payload: Dict, include_evidence_index: bool) -> AsyncGenerator[str, None]:
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

    yield f"event: done\ndata: {json.dumps(final_payload)}\n\n"


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.post("/chat")
def chat_once(request: ChatRequest):
    chat_payload = _build_chat_sections(request)
    response = {
        "patient_id": request.patient_id,
        "sections": chat_payload["sections"],
    }
    if request.include_evidence_index:
        response["evidence_index"] = chat_payload["evidence_index"]
    return JSONResponse(content=response)


@app.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    chat_payload = _build_chat_sections(request)
    return StreamingResponse(
        _sse_stream(chat_payload, include_evidence_index=request.include_evidence_index),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
