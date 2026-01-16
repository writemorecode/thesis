from __future__ import annotations

from collections.abc import Callable

import numpy as np

from simulator.algorithms import ScheduleResult
from simulator.problem import ProblemInstance
from simulator.schedulers import get_scheduler, normalize_scheduler_name


def parse_scheduler_list(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


def scheduler_output_filename(name: str) -> str:
    canonical = normalize_scheduler_name(name)
    return f"eval_{canonical}.csv"


def build_scheduler(
    name: str, *, iterations: int, rng: np.random.Generator
) -> Callable[[ProblemInstance], ScheduleResult]:
    return get_scheduler(name, iterations=iterations, rng=rng)
