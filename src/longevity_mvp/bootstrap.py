from .config import AppPaths
from .pipeline import build_warehouse


def ensure_local_warehouse() -> None:
    paths = AppPaths.from_repo_root()
    if paths.warehouse_path.exists():
        return
    build_warehouse(paths=paths)
