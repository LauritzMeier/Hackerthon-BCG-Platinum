"""Streaming API for the Longevity ADK agent."""

from __future__ import annotations

import asyncio
import json
from typing import AsyncGenerator, Dict, List

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel

from main import build_tailored_explanation

app = FastAPI(
    title="Longevity ADK Agent Server",
    version="0.1.0",
    description="SSE streaming API for six-pillar coaching explanations.",
)


class ExplainRequest(BaseModel):
    patient_id: str
    include_evidence_index: bool = False


def _compose_sections(payload: Dict) -> List[str]:
    context = payload["context"]
    claims = payload["claims"]
    trade_offs = payload["trade_offs"]
    actions = payload["next_best_actions"]

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


async def _sse_stream(payload: Dict, include_evidence_index: bool) -> AsyncGenerator[str, None]:
    yield f"event: meta\ndata: {json.dumps({'status': 'started'})}\n\n"
    await asyncio.sleep(0.02)

    for section in _compose_sections(payload):
        # Stream token-like chunks for responsive UI feedback.
        words = section.split(" ")
        chunk = ""
        for word in words:
            chunk = f"{chunk} {word}".strip()
            yield f"event: delta\ndata: {json.dumps({'text': word + ' '})}\n\n"
            await asyncio.sleep(0.01)
        yield f"event: section\ndata: {json.dumps({'text': chunk})}\n\n"
        await asyncio.sleep(0.02)

    final_payload = {"status": "completed", "patient_id": payload["patient_id"]}
    if include_evidence_index:
        final_payload["evidence_index"] = payload["evidence_index"]

    yield f"event: done\ndata: {json.dumps(final_payload)}\n\n"


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.post("/explain")
def explain_once(request: ExplainRequest):
    payload = build_tailored_explanation(request.patient_id)
    if not payload.get("ok"):
        raise HTTPException(status_code=404, detail=payload.get("error", "analysis failed"))

    response = {
        "patient_id": request.patient_id,
        "sections": _compose_sections(payload),
    }
    if request.include_evidence_index:
        response["evidence_index"] = payload["evidence_index"]
    return JSONResponse(content=response)


@app.post("/explain/stream")
async def explain_stream(request: ExplainRequest):
    payload = build_tailored_explanation(request.patient_id)
    if not payload.get("ok"):
        raise HTTPException(status_code=404, detail=payload.get("error", "analysis failed"))

    return StreamingResponse(
        _sse_stream(payload, include_evidence_index=request.include_evidence_index),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
