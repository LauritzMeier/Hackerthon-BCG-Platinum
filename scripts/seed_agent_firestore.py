#!/usr/bin/env python3
"""
Lazy-seed Firestore with overview-driven documents for the agent.

Collections (document id = patient_id for each):
  - patients
  - longevity_data_overview
  - pillar_mappings
  - actionable_opportunities
  - engagement_queries

Lazy behaviour: by default, skips a document if it already exists. Use --force to overwrite.

Data is derived from the local DuckDB warehouse, the curated schema reference in
sql/schema_reference.sql, and the strategy described in data/data_overview.md so the
Firestore payload mirrors the same data vocabulary used by the agent toolkit.
"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Literal

REPO_ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = REPO_ROOT / "src"
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Missing firebase-admin. Install with: python3 -m pip install firebase-admin "
        "(or: python3 -m pip install -r requirements.txt from repo root)"
    ) from exc

from agent.pillar_analysis import analyze_patient_six_pillars
from longevity_mvp.bootstrap import ensure_local_warehouse
from longevity_mvp.experience import build_experience
from longevity_mvp.repository import WarehouseRepository

AGENT_COLLECTIONS = (
    "patients",
    "longevity_data_overview",
    "pillar_mappings",
    "actionable_opportunities",
    "engagement_queries",
)

PILLAR_BLUEPRINTS = {
    "sleep_recovery": {
        "data_used": [
            "raw.wearable_telemetry.sleep_duration_hrs",
            "raw.wearable_telemetry.sleep_quality_score",
            "raw.wearable_telemetry.deep_sleep_pct",
            "raw.lifestyle_survey.sleep_satisfaction",
        ],
        "insight_summary": (
            "Compare objective sleep telemetry with subjective sleep satisfaction to catch "
            "under-recovery before it snowballs."
        ),
        "query_prompt": (
            "Your recovery took a hit last night. Did you have a late heavy meal, alcohol, or a stressful day?"
        ),
    },
    "cardiovascular_health": {
        "data_used": [
            "raw.ehr_records.sbp_mmhg",
            "raw.ehr_records.dbp_mmhg",
            "raw.wearable_telemetry.resting_hr_bpm",
            "raw.wearable_telemetry.hrv_rmssd_ms",
            "raw.wearable_telemetry.spo2_avg_pct",
        ],
        "insight_summary": (
            "Use HRV and resting heart rate trends as early warning signals before blood pressure worsens."
        ),
        "query_prompt": "Have you noticed extra fatigue, poor sleep, or unusual strain in the last few days?",
    },
    "metabolic_health": {
        "data_used": [
            "raw.ehr_records.hba1c_pct",
            "raw.ehr_records.fasting_glucose_mmol",
            "raw.ehr_records.ldl_mmol",
            "raw.ehr_records.triglycerides_mmol",
            "raw.ehr_records.bmi",
        ],
        "insight_summary": (
            "Project longer-term metabolic risk from clinical markers and use it to justify focused nutrition and movement changes."
        ),
        "query_prompt": "Would you commit to a 10-minute walk after dinner for the next 3 days?",
    },
    "movement_fitness": {
        "data_used": [
            "raw.wearable_telemetry.steps",
            "raw.wearable_telemetry.active_minutes",
            "raw.lifestyle_survey.exercise_sessions_weekly",
            "raw.lifestyle_survey.sedentary_hrs_day",
        ],
        "insight_summary": (
            "Separate being generally active from getting enough moderate-to-vigorous activity for long-term cardiovascular benefit."
        ),
        "query_prompt": "Did you get at least one session of moderate effort movement in today?",
    },
    "nutrition_quality": {
        "data_used": [
            "raw.lifestyle_survey.diet_quality_score",
            "raw.lifestyle_survey.fruit_veg_servings_daily",
            "raw.lifestyle_survey.water_glasses_daily",
            "raw.lifestyle_survey.alcohol_units_weekly",
            "raw.ehr_records.crp_mg_l",
        ],
        "insight_summary": (
            "Connect inflammatory markers and self-reported nutrition habits so the coach can suggest practical dietary changes."
        ),
        "query_prompt": "Did you hit your 5 servings of veg today, and how was your hydration?",
    },
    "mental_resilience": {
        "data_used": [
            "raw.lifestyle_survey.stress_level",
            "raw.lifestyle_survey.mental_wellbeing_who5",
            "raw.lifestyle_survey.self_rated_health",
            "raw.wearable_telemetry.hrv_rmssd_ms",
            "raw.wearable_telemetry.sleep_quality_score",
        ],
        "insight_summary": (
            "Map stress and wellbeing to recovery signals so the patient can see the physical cost of psychological strain."
        ),
        "query_prompt": "How are you feeling right now on a scale of 1-5?",
    },
}


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--project",
        default=os.getenv("FIREBASE_PROJECT_ID") or os.getenv("GOOGLE_CLOUD_PROJECT"),
        help="Firebase / GCP project id (default: FIREBASE_PROJECT_ID or GOOGLE_CLOUD_PROJECT).",
    )
    p.add_argument(
        "--database",
        default=os.getenv("FIRESTORE_DATABASE_ID", "(default)"),
        help='Firestore database id (default: "(default)" or FIRESTORE_DATABASE_ID).',
    )
    p.add_argument(
        "--credentials",
        help="Path to service account JSON. Else Application Default Credentials.",
    )
    p.add_argument(
        "--patient-id",
        action="append",
        default=[],
        dest="patient_ids",
        help="Patient id (e.g. PT0001). Repeat for multiple.",
    )
    p.add_argument(
        "--limit",
        type=int,
        default=25,
        help="Max patients when no --patient-id (default 25).",
    )
    p.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing documents (default: skip if doc exists).",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Print actions only; do not write to Firestore.",
    )
    return p.parse_args()


def init_firestore(project_id: str, credentials_path: str | None, database_id: str):
    options = {"projectId": project_id}
    app_name = f"agent-firestore-seed-{project_id}"

    if credentials_path:
        cred = credentials.Certificate(credentials_path)
    else:
        cred = credentials.ApplicationDefault()

    try:
        app = firebase_admin.get_app(app_name)
    except ValueError:
        app = firebase_admin.initialize_app(
            credential=cred,
            options=options,
            name=app_name,
        )

    if database_id == "(default)":
        return firestore.client(app=app)
    return firestore.client(app=app, database_id=database_id)


def iter_patient_ids(repository: WarehouseRepository, ids: List[str], limit: int) -> Iterable[str]:
    if ids:
        yield from ids
        return
    for row in repository.list_patients(limit=limit):
        pid = row.get("patient_id")
        if pid:
            yield str(pid)


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _compact(data: Dict[str, Any]) -> Dict[str, Any]:
    return {key: value for key, value in data.items() if value is not None}


def _latest_timeline_entry(bundle: Dict[str, Any]) -> Dict[str, Any]:
    timeline = bundle.get("timeline") or []
    return timeline[0] if timeline else {}


def _safe_round(value: Any, digits: int = 1) -> float | None:
    try:
        if value in (None, ""):
            return None
        return round(float(value), digits)
    except (TypeError, ValueError):
        return None


def _build_available_datasets(bundle: Dict[str, Any]) -> List[Dict[str, Any]]:
    profile = bundle["profile"]
    latest = _latest_timeline_entry(bundle)
    return [
        {
            "dataset_id": "ehr_records",
            "name": "Clinical Baseline",
            "schema_table": "raw.ehr_records",
            "source_file": "data/raw/ehr_records.csv",
            "key_fields": [
                "age",
                "bmi",
                "sbp_mmhg",
                "dbp_mmhg",
                "total_cholesterol_mmol",
                "hdl_mmol",
                "ldl_mmol",
                "triglycerides_mmol",
                "hba1c_pct",
                "fasting_glucose_mmol",
                "crp_mg_l",
                "egfr_ml_min",
                "chronic_conditions",
                "medications",
            ],
            "patient_snapshot": _compact(
                {
                    "age": profile.get("age"),
                    "bmi": _safe_round(profile.get("bmi")),
                    "sbp_mmhg": _safe_round(profile.get("sbp_mmhg")),
                    "dbp_mmhg": _safe_round(profile.get("dbp_mmhg")),
                    "ldl_mmol": _safe_round(profile.get("ldl_mmol"), 2),
                    "hba1c_pct": _safe_round(profile.get("hba1c_pct"), 2),
                    "fasting_glucose_mmol": _safe_round(profile.get("fasting_glucose_mmol"), 2),
                    "crp_mg_l": _safe_round(profile.get("crp_mg_l"), 2),
                }
            ),
        },
        {
            "dataset_id": "lifestyle_survey",
            "name": "Subjective Baseline",
            "schema_table": "raw.lifestyle_survey",
            "source_file": "data/raw/lifestyle_survey.csv",
            "key_fields": [
                "smoking_status",
                "alcohol_units_weekly",
                "diet_quality_score",
                "fruit_veg_servings_daily",
                "water_glasses_daily",
                "exercise_sessions_weekly",
                "sedentary_hrs_day",
                "stress_level",
                "mental_wellbeing_who5",
                "self_rated_health",
                "sleep_satisfaction",
            ],
            "patient_snapshot": _compact(
                {
                    "diet_quality_score": _safe_round(profile.get("diet_quality_score")),
                    "fruit_veg_servings_daily": _safe_round(profile.get("fruit_veg_servings_daily")),
                    "water_glasses_daily": _safe_round(profile.get("water_glasses_daily")),
                    "exercise_sessions_weekly": _safe_round(profile.get("exercise_sessions_weekly")),
                    "sedentary_hrs_day": _safe_round(profile.get("sedentary_hrs_day"), 1),
                    "stress_level": _safe_round(profile.get("stress_level")),
                    "mental_wellbeing_who5": _safe_round(profile.get("mental_wellbeing_who5")),
                    "self_rated_health": _safe_round(profile.get("self_rated_health")),
                }
            ),
        },
        {
            "dataset_id": "wearable_telemetry",
            "name": "Continuous Telemetry - 90 Days",
            "schema_table": "raw.wearable_telemetry",
            "source_file": "data/raw/wearable_telemetry_1.csv",
            "key_fields": [
                "resting_hr_bpm",
                "hrv_rmssd_ms",
                "steps",
                "active_minutes",
                "sleep_duration_hrs",
                "sleep_quality_score",
                "deep_sleep_pct",
                "spo2_avg_pct",
                "calories_burned_kcal",
            ],
            "patient_snapshot": _compact(
                {
                    "latest_reading_date": latest.get("reading_date"),
                    "resting_hr_bpm": _safe_round(latest.get("resting_hr_bpm")),
                    "hrv_rmssd_ms": _safe_round(latest.get("hrv_rmssd_ms")),
                    "steps": _safe_round(latest.get("steps")),
                    "active_minutes": _safe_round(latest.get("active_minutes")),
                    "sleep_duration_hrs": _safe_round(latest.get("sleep_duration_hrs"), 2),
                    "sleep_quality_score": _safe_round(latest.get("sleep_quality_score")),
                    "deep_sleep_pct": _safe_round(latest.get("deep_sleep_pct"), 2),
                    "spo2_avg_pct": _safe_round(latest.get("spo2_avg_pct"), 1),
                    "calories_burned_kcal": _safe_round(latest.get("calories_burned_kcal")),
                }
            ),
        },
    ]


def _build_pillar_mappings(analysis: Dict[str, Any]) -> List[Dict[str, Any]]:
    mappings: List[Dict[str, Any]] = []
    for pillar in analysis["pillars"]:
        blueprint = PILLAR_BLUEPRINTS[pillar["id"]]
        mappings.append(
            {
                "pillar_id": pillar["id"],
                "pillar_name": pillar["name"],
                "data_used": blueprint["data_used"],
                "insight_summary": blueprint["insight_summary"],
                "current_state": {
                    "score": pillar["score"],
                    "state": pillar["state"],
                    "trend": pillar["trend"],
                },
                "key_signals": pillar["key_signals"],
                "recommended_micro_prompt": blueprint["query_prompt"],
                "data_sources": pillar["data_sources"],
            }
        )
    return mappings


def _build_actionable_opportunities(
    patient_id: str,
    analysis: Dict[str, Any],
    experience: Dict[str, Any],
) -> List[Dict[str, Any]]:
    recommended_offer = (
        experience.get("offers", {}).get("recommended")
        or experience.get("offers", {}).get("recommended_offer")
    )
    pillars = {pillar["id"]: pillar for pillar in analysis["pillars"]}
    movement = pillars["movement_fitness"]
    cardio = pillars["cardiovascular_health"]
    metabolic = pillars["metabolic_health"]
    sleep = pillars["sleep_recovery"]
    mental = pillars["mental_resilience"]

    diagnostics_priority = "high" if (
        (movement["trend"] == "improving" or cardio["trend"] == "improving")
        and (metabolic["score"] < 65 or metabolic["trend"] == "drifting")
    ) else "medium"

    package_priority = "high" if (
        sleep["trend"] == "drifting" and mental["trend"] == "drifting"
    ) else "medium"

    return [
        {
            "opportunity_id": f"{patient_id}_diagnostics_upsell",
            "title": "Follow-up metabolic blood test",
            "type": "episodic_revenue",
            "priority": diagnostics_priority,
            "why_now": (
                "Movement or cardiovascular signals are improving, but metabolic markers still need validation."
            ),
            "trigger_pillars": ["movement_fitness", "cardiovascular_health", "metabolic_health"],
            "evidence": {
                "movement_trend": movement["trend"],
                "cardiovascular_trend": cardio["trend"],
                "metabolic_score": metabolic["score"],
                "metabolic_trend": metabolic["trend"],
            },
            "coach_prompt": (
                "Your activity signals are moving in the right direction. A follow-up metabolic panel would validate whether the internal markers are improving too."
            ),
        },
        {
            "opportunity_id": f"{patient_id}_stress_support_package",
            "title": "Stress-management digital therapeutic or telehealth coaching session",
            "type": "hybrid_retention_offer",
            "priority": package_priority,
            "why_now": (
                "Sleep and resilience are tightly linked, so a combined support offer can address both adherence and acute recovery."
            ),
            "trigger_pillars": ["sleep_recovery", "mental_resilience"],
            "evidence": {
                "sleep_score": sleep["score"],
                "sleep_trend": sleep["trend"],
                "mental_score": mental["score"],
                "mental_trend": mental["trend"],
            },
            "coach_prompt": (
                "Both recovery and resilience need support right now. A focused stress-management program could reduce friction and improve daily consistency."
            ),
        },
        {
            "opportunity_id": f"{patient_id}_primary_focus_offer",
            "title": f"Primary focus support for {analysis['primary_focus']['pillar_name']}",
            "type": "coaching_nudge",
            "priority": "high",
            "why_now": analysis["primary_focus"]["why_now"],
            "trigger_pillars": [analysis["primary_focus"]["pillar_id"]],
            "evidence": {
                "overall_direction": analysis["overall_direction"],
                "average_score": analysis["average_score"],
                "primary_focus": analysis["primary_focus"],
                "recommended_offer": recommended_offer,
            },
            "coach_prompt": (
                f"Keep the next step focused on {analysis['primary_focus']['pillar_name']} so progress is easier to measure and easier to sustain."
            ),
        },
    ]


def _build_engagement_queries(analysis: Dict[str, Any]) -> List[Dict[str, Any]]:
    primary_focus = analysis["primary_focus"]
    pillar_lookup = {pillar["id"]: pillar for pillar in analysis["pillars"]}
    focus_prompt = PILLAR_BLUEPRINTS[primary_focus["pillar_id"]]["query_prompt"]
    return [
        {
            "query_id": "daily_contextual_tags",
            "category": "context",
            "title": "Daily contextual tags",
            "example_prompt": focus_prompt,
            "value": "Explains anomalies in recovery or performance and trains the coach on likely causes.",
            "when_to_ask": "When wearable metrics drop suddenly or trend negatively over 2-3 days.",
            "derived_from_pillars": [primary_focus["pillar_id"]],
        },
        {
            "query_id": "nutrition_hydration_tracking",
            "category": "behavior_tracking",
            "title": "Frictionless nutrition and hydration check",
            "example_prompt": "Did you hit your 5 servings of veg today or want to snap a quick meal photo?",
            "value": "Improves the weakest continuous data gap in the current dataset mix.",
            "when_to_ask": "On days when nutrition quality is a weak or drifting pillar.",
            "derived_from_pillars": ["nutrition_quality"],
        },
        {
            "query_id": "acute_emotional_state",
            "category": "resilience",
            "title": "Acute emotional state check",
            "example_prompt": "How are you feeling right now on a scale of 1-5?",
            "value": "Helps distinguish physical stress from psychological stress when HRV or sleep worsens.",
            "when_to_ask": "When sleep or resilience trends drift, or HRV drops below baseline.",
            "derived_from_pillars": ["mental_resilience", "sleep_recovery", "cardiovascular_health"],
        },
        {
            "query_id": "goal_commitment",
            "category": "adherence",
            "title": "Goal commitment prompt",
            "example_prompt": (
                f"Will you commit to one small {primary_focus['pillar_name'].lower()} action over the next 3 days?"
            ),
            "value": "Feeds the weekly guided engagement rate and turns weak-pillar advice into measurable commitment.",
            "when_to_ask": "At the end of any coaching response centered on the primary focus pillar.",
            "derived_from_pillars": [primary_focus["pillar_id"]],
            "current_focus_snapshot": pillar_lookup[primary_focus["pillar_id"]]["key_signals"],
        },
    ]


def build_agent_seed_payloads(
    patient_id: str,
    bundle: Dict[str, Any],
    experience: Dict[str, Any],
) -> Dict[str, Dict[str, Any]]:
    recommended_offer = (
        experience.get("offers", {}).get("recommended")
        or experience.get("offers", {}).get("recommended_offer")
    )
    analysis = analyze_patient_six_pillars(
        patient_id,
        firebase_context={
            "patient_id": patient_id,
            "collections_checked": [],
            "collections_found": [],
            "data": {},
            "normalized": {},
            "firebase_available": False,
        },
    )
    if not analysis.get("ok"):
        raise ValueError(f"Could not analyze patient {patient_id}: {analysis.get('error', 'unknown error')}")

    patients_doc = {
        "patientId": patient_id,
        "displayName": f"Patient {patient_id}",
        "locale": "en",
        "onboardingComplete": True,
        "schemaVersion": "overview_v1",
        "northStarMetric": "weekly_guided_engagement_rate",
        "primaryFocusPillarId": analysis["primary_focus"]["pillar_id"],
        "primaryFocusPillarName": analysis["primary_focus"]["pillar_name"],
        "overallDirection": analysis["overall_direction"],
        "averageScore": analysis["average_score"],
        "coachName": experience["coach"].get("coach_name"),
        "seededAt": _now_iso(),
        "source": "seed_agent_firestore",
    }

    overview_doc = {
        "patient_id": patient_id,
        "schema_version": "overview_v1",
        "title": "Longevity Data Overview & Insights Strategy",
        "core_product": "Longevity Compass",
        "schema_reference_path": "sql/schema_reference.sql",
        "summary": (
            "Strategic overview of available raw data, six-pillar mapping, actionable opportunities, "
            "and the micro-interactions the app should ask to keep coaching relevant."
        ),
        "available_datasets": _build_available_datasets(bundle),
        "insights_strategy": {
            "overall_direction": analysis["overall_direction"],
            "average_score": analysis["average_score"],
            "primary_focus": analysis["primary_focus"],
            "coach_intro": experience["coach"].get("intro"),
            "recommended_offer": recommended_offer,
        },
        "seededAt": _now_iso(),
    }

    pillar_mappings_doc = {
        "patient_id": patient_id,
        "schema_version": "overview_v1",
        "pillars": _build_pillar_mappings(analysis),
        "seededAt": _now_iso(),
    }

    actionable_opportunities_doc = {
        "patient_id": patient_id,
        "schema_version": "overview_v1",
        "opportunities": _build_actionable_opportunities(patient_id, analysis, experience),
        "seededAt": _now_iso(),
    }

    engagement_queries_doc = {
        "patient_id": patient_id,
        "schema_version": "overview_v1",
        "prompts": _build_engagement_queries(analysis),
        "seededAt": _now_iso(),
    }

    return {
        "patients": patients_doc,
        "longevity_data_overview": overview_doc,
        "pillar_mappings": pillar_mappings_doc,
        "actionable_opportunities": actionable_opportunities_doc,
        "engagement_queries": engagement_queries_doc,
    }


def lazy_write(
    db,
    collection: str,
    patient_id: str,
    data: Dict[str, Any],
    *,
    force: bool,
    dry_run: bool,
) -> Literal["skipped", "written", "dry_run"]:
    if dry_run:
        return "dry_run"
    ref = db.collection(collection).document(patient_id)
    if not force:
        snap = ref.get()
        if snap.exists:
            return "skipped"
    ref.set(data)
    return "written"


def main() -> int:
    args = parse_args()
    if not args.project:
        print(
            "Error: --project is required or set FIREBASE_PROJECT_ID / GOOGLE_CLOUD_PROJECT.",
            file=sys.stderr,
        )
        return 1

    ensure_local_warehouse()
    repository = WarehouseRepository()
    patient_ids = list(iter_patient_ids(repository, args.patient_ids, args.limit))
    if not patient_ids:
        print("No patient ids to seed.", file=sys.stderr)
        return 1

    db = None if args.dry_run else init_firestore(args.project, args.credentials, args.database)

    stats = {"written": 0, "skipped": 0, "dry_run": 0, "patients": 0}

    for patient_id in patient_ids:
        bundle = repository.get_patient_bundle(patient_id)
        if bundle is None:
            print(f"Skip {patient_id}: not in warehouse.", file=sys.stderr)
            continue

        experience = build_experience(bundle)
        payloads = build_agent_seed_payloads(patient_id, bundle, experience)

        for coll in AGENT_COLLECTIONS:
            data = payloads[coll]
            status = lazy_write(
                db,
                coll,
                patient_id,
                data,
                force=args.force,
                dry_run=args.dry_run,
            )
            stats[status] = stats.get(status, 0) + 1
            if args.dry_run:
                print(f"[dry-run] {coll}/{patient_id} ({len(data)} fields)")
            elif status == "written":
                print(f"Wrote {coll}/{patient_id}")
            else:
                print(f"Skipped {coll}/{patient_id} (exists, use --force)")

        stats["patients"] += 1

    print(
        f"Done. patients_processed={stats['patients']} "
        f"writes={stats['written']} skipped={stats['skipped']} dry_run_fields={stats['dry_run']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
