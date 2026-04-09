from fastapi import FastAPI, HTTPException, Query

from .repository import WarehouseRepository


app = FastAPI(
    title="Longevity MVP API",
    version="0.1.0",
    description="Thin API over the local DuckDB warehouse for the patient-facing longevity MVP.",
)

repository = WarehouseRepository()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/patients")
def list_patients(limit: int = Query(default=25, ge=1, le=250)):
    return {"items": repository.list_patients(limit=limit)}


@app.get("/patients/{patient_id}")
def get_patient(patient_id: str):
    patient = repository.get_patient_bundle(patient_id)
    if patient is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient


@app.get("/patients/{patient_id}/timeline")
def get_timeline(patient_id: str, days: int = Query(default=30, ge=1, le=90)):
    if repository.get_patient_profile(patient_id) is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return {"items": repository.get_patient_timeline(patient_id, days=days)}


@app.get("/patients/{patient_id}/flags")
def get_flags(patient_id: str):
    if repository.get_patient_profile(patient_id) is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return {"items": repository.get_patient_flags(patient_id)}


@app.get("/patients/{patient_id}/offers")
def get_offers(patient_id: str):
    if repository.get_patient_profile(patient_id) is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return {"items": repository.get_patient_offers(patient_id)}
