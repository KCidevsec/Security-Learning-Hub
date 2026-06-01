"""Discover the exercise catalogue from exercises/*/meta.yaml."""
import logging
from functools import lru_cache

import yaml

from . import config

log = logging.getLogger("slh.exercises")


def _load() -> dict[str, dict]:
    catalogue: dict[str, dict] = {}
    if not config.EXERCISES_DIR.exists():
        log.warning("Exercises dir %s does not exist", config.EXERCISES_DIR)
        return catalogue
    for meta_path in sorted(config.EXERCISES_DIR.glob("*/meta.yaml")):
        try:
            meta = yaml.safe_load(open(meta_path)) or {}
            meta["_dir"] = meta_path.parent
            meta.setdefault("id", meta_path.parent.name)
            catalogue[meta["id"]] = meta
        except Exception as e:  # noqa: BLE001
            log.error("Skipping %s: %s", meta_path, e)
    log.info("Loaded %d exercises: %s", len(catalogue), list(catalogue))
    return catalogue


@lru_cache(maxsize=1)
def all_exercises() -> dict[str, dict]:
    return _load()


def get(exercise_id: str) -> dict | None:
    return all_exercises().get(exercise_id)


def listing() -> list[dict]:
    """Lightweight view for the dashboard."""
    out = []
    for ex in all_exercises().values():
        arch = ex.get("arch", {})
        out.append({
            "id": ex["id"],
            "title": ex.get("title", ex["id"]),
            "category": ex.get("category", "misc"),
            "summary": ex.get("summary", ""),
            "emulated_on_apple_silicon": ex.get("emulated_on_apple_silicon", False),
            "arch": arch,
        })
    return out
