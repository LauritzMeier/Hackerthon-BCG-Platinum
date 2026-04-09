import json

import httpx
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from .bootstrap import ensure_local_warehouse
from .compass import build_coach_reply, build_coach_snapshot, build_compass, build_weekly_plan
from .experience import build_experience
from .repository import WarehouseRepository


app = FastAPI(
    title="Longevity MVP API",
    version="0.1.0",
    description="Thin API over the local DuckDB warehouse for the patient-facing longevity MVP.",
)

repository = WarehouseRepository()

# Allow local Flutter dev and Firebase-hosted web builds to call the API without
# adding a separate proxy layer during the hackathon.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class CoachMessageRequest(BaseModel):
    message: str


@app.on_event("startup")
def startup() -> None:
    ensure_local_warehouse()


def _require_bundle(patient_id: str):
    bundle = repository.get_patient_bundle(patient_id)
    if bundle is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return bundle


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/agent/health-proxy")
async def get_agent_health_proxy(target: str = Query(..., min_length=1)):
    target_url = target.rstrip("/")
    upstream_url = f"{target_url}/health"

    try:
        async with httpx.AsyncClient(timeout=10.0, follow_redirects=True) as client:
            upstream = await client.get(
                upstream_url,
                headers={"Accept": "application/json"},
            )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Agent health upstream request failed: {exc}",
        ) from exc

    body_text = upstream.text
    try:
        body = upstream.json()
    except json.JSONDecodeError:
        body = body_text

    return {
        "upstream_url": upstream_url,
        "status_code": upstream.status_code,
        "body": body,
    }


@app.get("/patients")
def list_patients(limit: int = Query(default=25, ge=1, le=250)):
    return {"items": repository.list_patients(limit=limit)}


@app.get("/patients/{patient_id}")
def get_patient(patient_id: str):
    return _require_bundle(patient_id)


@app.get("/patients/{patient_id}/experience")
def get_experience(patient_id: str):
    bundle = _require_bundle(patient_id)
    return build_experience(bundle)


@app.get("/patients/{patient_id}/timeline")
def get_timeline(patient_id: str, days: int = Query(default=30, ge=1, le=90)):
    _require_bundle(patient_id)
    return {"items": repository.get_patient_timeline(patient_id, days=days)}


@app.get("/patients/{patient_id}/flags")
def get_flags(patient_id: str):
    _require_bundle(patient_id)
    return {"items": repository.get_patient_flags(patient_id)}


@app.get("/patients/{patient_id}/offers")
def get_offers(patient_id: str):
    _require_bundle(patient_id)
    return {"items": repository.get_patient_offers(patient_id)}


@app.get("/patients/{patient_id}/compass")
def get_compass(patient_id: str):
    bundle = _require_bundle(patient_id)
    return build_compass(bundle)


@app.get("/patients/{patient_id}/plan")
def get_plan(patient_id: str):
    bundle = _require_bundle(patient_id)
    return build_weekly_plan(bundle)


@app.get("/patients/{patient_id}/coach")
def get_coach_snapshot(patient_id: str):
    bundle = _require_bundle(patient_id)
    return build_coach_snapshot(bundle)


@app.post("/patients/{patient_id}/coach/reply")
def post_coach_reply(patient_id: str, request: CoachMessageRequest):
    bundle = _require_bundle(patient_id)
    return build_coach_reply(bundle, message=request.message)
