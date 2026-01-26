from __future__ import annotations

import csv
from collections.abc import Callable
from pathlib import Path
from typing import Literal

import numpy as np

from simulator.algorithms import ScheduleResult
from simulator.problem import ProblemInstance
from simulator.schedulers import get_scheduler, normalize_scheduler_name

DISPLAY_SCHEDULER_NAMES = {
    "bfd": "BFD",
    "ffd": "FFD",
    "ffd_l2": "FFDL2",
    "ffd_max": "FFDMax",
    "ffd_new": "FFDNew",
    "ffd_prod": "FFDProd",
    "ffd_sum": "FFDSum",
    "peak_demand": "PeakDemand",
}


def parse_scheduler_list(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


def scheduler_output_filename(name: str) -> str:
    canonical = normalize_scheduler_name(name)
    return f"eval_{canonical}.csv"


def display_scheduler_name(name: str) -> str:
    canonical = normalize_scheduler_name(name)
    return DISPLAY_SCHEDULER_NAMES.get(canonical, canonical)


def build_scheduler(
    name: str, *, iterations: int, rng: np.random.Generator
) -> Callable[[ProblemInstance], ScheduleResult]:
    return get_scheduler(name, iterations=iterations, rng=rng)


def resolve_results_csv(results_dir: Path, scheduler_name: str) -> tuple[str, Path]:
    canonical = normalize_scheduler_name(scheduler_name)
    csv_path = (results_dir / scheduler_output_filename(canonical)).resolve()
    return canonical, csv_path


def load_total_costs(
    csv_path: Path, *, duplicate_policy: Literal["min", "error"] = "min"
) -> dict[str, float]:
    costs: dict[str, float] = {}
    with csv_path.open(newline="") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            raise ValueError(f"{csv_path} has no header row.")
        required = {"filename", "total_cost"}
        missing = required - set(reader.fieldnames)
        if missing:
            raise ValueError(f"{csv_path} missing required columns: {sorted(missing)}.")

        for row in reader:
            filename = row["filename"]
            try:
                total_cost = float(row["total_cost"])
            except ValueError as exc:
                raise ValueError(
                    f"{csv_path} has invalid total_cost for {filename}: {row['total_cost']}"
                ) from exc

            if filename in costs:
                if duplicate_policy == "error":
                    raise ValueError(
                        f"{csv_path} has duplicate filename entry: {filename}."
                    )
                if duplicate_policy == "min":
                    costs[filename] = min(costs[filename], total_cost)
                else:
                    raise ValueError(f"Unknown duplicate policy: {duplicate_policy}")
            else:
                costs[filename] = total_cost

    if not costs:
        raise ValueError(f"{csv_path} has no rows to evaluate.")
    return costs


def ensure_matching_filenames(
    costs_a: dict[str, float],
    costs_b: dict[str, float],
    *,
    label_a: str,
    label_b: str,
) -> list[str]:
    filenames_a = set(costs_a.keys())
    filenames_b = set(costs_b.keys())
    missing_in_b = filenames_a - filenames_b
    missing_in_a = filenames_b - filenames_a
    if missing_in_a or missing_in_b:
        details = [f"Mismatched instances between {label_a} and {label_b}."]
        if missing_in_b:
            details.append(f"Missing in {label_b}: {len(missing_in_b)} instance(s).")
        if missing_in_a:
            details.append(f"Missing in {label_a}: {len(missing_in_a)} instance(s).")
        raise ValueError(" ".join(details))

    return sorted(filenames_a)
