from pathlib import Path

from .config import AppPaths


def _require_duckdb():
    try:
        import duckdb  # type: ignore
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "duckdb is not installed. Create a virtual environment and run "
            "`pip install -r requirements.txt` from the repository root."
        ) from exc
    return duckdb


def _load_raw_table(connection, table_name: str, csv_path: Path) -> None:
    safe_path = csv_path.as_posix().replace("'", "''")
    connection.execute(
        f"""
        CREATE SCHEMA IF NOT EXISTS raw;
        CREATE OR REPLACE TABLE raw.{table_name} AS
        SELECT *
        FROM read_csv_auto(
            '{safe_path}',
            HEADER = TRUE,
            DELIM = ',',
            SAMPLE_SIZE = -1,
            STRICT_MODE = FALSE
        );
        """
    )


def _execute_sql_file(connection, sql_path: Path) -> None:
    connection.execute(sql_path.read_text())


def build_warehouse(paths: AppPaths = None) -> Path:
    app_paths = paths or AppPaths.from_repo_root()
    raw_inputs = app_paths.validate_raw_inputs()
    app_paths.warehouse_dir.mkdir(parents=True, exist_ok=True)

    duckdb = _require_duckdb()
    connection = duckdb.connect(str(app_paths.warehouse_path))

    try:
        for table_name, csv_path in raw_inputs.items():
            _load_raw_table(connection, table_name, csv_path)
        _execute_sql_file(connection, app_paths.sql_dir / "marts.sql")
    finally:
        connection.close()

    return app_paths.warehouse_path
