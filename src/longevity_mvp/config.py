from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional


RAW_FILE_MAP = {
    "ehr_records": "ehr_records.csv",
    "lifestyle_survey": "lifestyle_survey.csv",
    "wearable_telemetry": "wearable_telemetry_1.csv",
}


@dataclass(frozen=True)
class AppPaths:
    repo_root: Path
    data_dir: Path
    raw_dir: Path
    warehouse_dir: Path
    warehouse_path: Path
    exports_dir: Path
    docs_dir: Path
    sql_dir: Path

    @classmethod
    def from_repo_root(cls, repo_root: Optional[Path] = None) -> "AppPaths":
        root = repo_root or Path(__file__).resolve().parents[2]
        data_dir = root / "data"
        return cls(
            repo_root=root,
            data_dir=data_dir,
            raw_dir=data_dir / "raw",
            warehouse_dir=data_dir / "warehouse",
            warehouse_path=data_dir / "warehouse" / "longevity.duckdb",
            exports_dir=data_dir / "exports",
            docs_dir=root / "docs",
            sql_dir=root / "sql",
        )

    def raw_inputs(self) -> Dict[str, Path]:
        return {
            table_name: self.raw_dir / file_name
            for table_name, file_name in RAW_FILE_MAP.items()
        }

    def validate_raw_inputs(self) -> Dict[str, Path]:
        raw_inputs = self.raw_inputs()
        missing = [str(path) for path in raw_inputs.values() if not path.exists()]
        if missing:
            raise FileNotFoundError(
                "Missing raw input files:\n- " + "\n- ".join(sorted(missing))
            )
        return raw_inputs
