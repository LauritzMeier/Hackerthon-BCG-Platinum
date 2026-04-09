#!/usr/bin/env python3

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, List

REPO_ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = REPO_ROOT / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError as exc:  # pragma: no cover - dependency guidance
    raise SystemExit(
        "Missing Firebase Admin SDK. Install dependencies with "
        "`pip install -r requirements.txt`."
    ) from exc

from longevity_mvp.bootstrap import ensure_local_warehouse
from longevity_mvp.experience import build_experience
from longevity_mvp.repository import WarehouseRepository


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Sync patient summaries and experience snapshots from the local "
            "warehouse into Firestore."
        )
    )
    parser.add_argument(
        "--project",
        required=True,
        help="Firebase project id to write into.",
    )
    parser.add_argument(
        "--database",
        default="(default)",
        help="Firestore database id to write into.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=1000,
        help="Maximum number of patients to sync when --patient-id is not used.",
    )
    parser.add_argument(
        "--patient-id",
        action="append",
        default=[],
        help="Specific patient id to sync. Can be passed multiple times.",
    )
    parser.add_argument(
        "--credentials",
        help=(
            "Optional path to a service account JSON file. If omitted, "
            "Application Default Credentials are used."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Build the payloads without writing them to Firestore.",
    )
    return parser.parse_args()


def init_firestore(
    project_id: str,
    credentials_path: str | None,
    database_id: str,
):
    options = {"projectId": project_id}
    app_name = f"firestore-sync-{project_id}"

    if credentials_path:
        credential = credentials.Certificate(credentials_path)
    else:
        credential = credentials.ApplicationDefault()

    try:
        app = firebase_admin.get_app(app_name)
    except ValueError:
        app = firebase_admin.initialize_app(
            credential=credential,
            options=options,
            name=app_name,
        )

    return firestore.client(app=app, database_id=database_id)


def iter_patient_ids(
    repository: WarehouseRepository,
    explicit_patient_ids: List[str],
    limit: int,
) -> Iterable[str]:
    if explicit_patient_ids:
        yield from explicit_patient_ids
        return

    for patient in repository.list_patients(limit=limit):
        patient_id = patient.get("patient_id")
        if patient_id:
            yield str(patient_id)


def build_patient_summary(experience: dict) -> dict:
    profile = experience["profile_summary"]
    primary_focus = experience["compass"]["primary_focus"]
    return {
        "patient_id": experience["patient_id"],
        "age": profile.get("age"),
        "sex": profile.get("sex"),
        "country": profile.get("country"),
        "primary_focus_area": primary_focus.get("pillar_name"),
        "estimated_biological_age": profile.get("estimated_biological_age"),
        "generated_at": experience.get("generated_at"),
        "synced_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    args = parse_args()
    ensure_local_warehouse()
    repository = WarehouseRepository()
    db = None if args.dry_run else init_firestore(
        args.project,
        args.credentials,
        args.database,
    )

    patient_ids = list(iter_patient_ids(repository, args.patient_id, args.limit))
    if not patient_ids:
        print("No patients found to sync.", file=sys.stderr)
        return 1

    total = 0
    for patient_id in patient_ids:
        bundle = repository.get_patient_bundle(patient_id)
        if bundle is None:
            print(f"Skipping {patient_id}: patient not found.", file=sys.stderr)
            continue

        experience = build_experience(bundle)
        summary = build_patient_summary(experience)

        if args.dry_run:
            print(f"[dry-run] Would sync {patient_id}")
            total += 1
            continue

        db.collection("patient_experiences").document(patient_id).set(experience)
        db.collection("patient_summaries").document(patient_id).set(summary)
        total += 1
        print(f"Synced {patient_id}")

    print(
        f"{'Prepared' if args.dry_run else 'Synced'} {total} patient "
        f"{'document' if total == 1 else 'documents'}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
