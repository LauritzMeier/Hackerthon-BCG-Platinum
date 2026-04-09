#!/usr/bin/env python3

import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "src"))

from longevity_mvp.pipeline import build_warehouse


def main() -> None:
    warehouse_path = build_warehouse()
    print(f"Warehouse created at {warehouse_path}")


if __name__ == "__main__":
    main()
