#!/usr/bin/env python3

import json
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "src"))

from longevity_mvp.repository import WarehouseRepository


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("Usage: python3 scripts/query_patient.py <PATIENT_ID> [days]")

    patient_id = sys.argv[1]
    days = int(sys.argv[2]) if len(sys.argv) > 2 else 30

    repository = WarehouseRepository()
    bundle = repository.get_patient_bundle(patient_id, days=days)

    if bundle is None:
        raise SystemExit(f"Patient not found: {patient_id}")

    print(json.dumps(bundle, indent=2, default=str))


if __name__ == "__main__":
    main()
