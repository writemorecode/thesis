"""
Wilcoxon signed-rank test on paired raw total_machines values.

This script compares two algorithms evaluated on the same set of problem
instances (paired observations). For each instance i, it computes:

    d_i = machines_a_i - machines_b_i

Null hypothesis (H0): median(d) = 0  (no median difference in machine counts)
Alternative (H1):     median(d) != 0 (two-tailed)

Input: two per-instance evaluation CSVs per dataset that contain at least:
  - filename
  - total_machines
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from pathlib import Path

import numpy as np

from eval_utils import (
    display_scheduler_name,
    ensure_matching_filenames,
    normalize_scheduler_name,
    scheduler_output_filename,
)

ALPHA = 0.05
SIG_FIGS = 4
DEFAULT_DATASETS = ("balanced", "job_heavy", "machine_heavy")


def _fmt_sig(x: float) -> str:
    if not np.isfinite(x):
        return str(x)
    return f"{x:.{SIG_FIGS}g}"


def load_total_machines(csv_path: Path) -> dict[str, float]:
    values: dict[str, float] = {}
    with csv_path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            raise ValueError(f"{csv_path} has no header row.")
        required = {"filename", "total_machines"}
        missing = required - set(reader.fieldnames)
        if missing:
            raise ValueError(f"{csv_path} missing required columns: {sorted(missing)}.")

        for row in reader:
            filename = row["filename"]
            try:
                total_machines = float(row["total_machines"])
            except ValueError as exc:
                raise ValueError(
                    f"{csv_path} has invalid total_machines for {filename}: "
                    f"{row['total_machines']}"
                ) from exc

            if filename in values:
                raise ValueError(
                    f"{csv_path} has duplicate filename entry: {filename}."
                )
            values[filename] = total_machines

    if not values:
        raise ValueError(f"{csv_path} has no rows to evaluate.")
    return values


def _slug(name: str) -> str:
    return normalize_scheduler_name(name).replace("_", "")


@dataclass(frozen=True)
class TestResult:
    dataset: str
    n_total: int
    n_nonzero: int
    mean_diff: float
    median_diff: float
    w_statistic: float
    p_value: float
    reject: bool
    pos: int
    neg: int
    zero: int


def _write_stats_csv(
    *,
    output_csv: Path,
    label_a: str,
    label_b: str,
    result: TestResult,
) -> None:
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with output_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "dataset",
                "comparison",
                "n_total",
                "n_nonzero",
                "mean_diff",
                "median_diff",
                "w_statistic",
                "p_value",
                "decision",
                "signs_pos",
                "signs_neg",
                "signs_zero",
            ],
        )
        writer.writeheader()
        comparison = (
            f"{display_scheduler_name(label_a)} vs {display_scheduler_name(label_b)}"
        )
        writer.writerow(
            {
                "dataset": result.dataset,
                "comparison": comparison,
                "n_total": str(result.n_total),
                "n_nonzero": str(result.n_nonzero),
                "mean_diff": _fmt_sig(result.mean_diff),
                "median_diff": _fmt_sig(result.median_diff),
                "w_statistic": _fmt_sig(result.w_statistic),
                "p_value": _fmt_sig(result.p_value),
                "decision": "REJECT_H0" if result.reject else "FAIL_TO_REJECT_H0",
                "signs_pos": str(result.pos),
                "signs_neg": str(result.neg),
                "signs_zero": str(result.zero),
            }
        )


def _run_dataset_test(
    *,
    dataset: str,
    csv_a: Path,
    csv_b: Path,
    label_a: str,
    label_b: str,
) -> TestResult:
    if not csv_a.is_file():
        raise FileNotFoundError(f"Missing CSV for {label_a}: {csv_a}")
    if not csv_b.is_file():
        raise FileNotFoundError(f"Missing CSV for {label_b}: {csv_b}")

    values_a = load_total_machines(csv_a)
    values_b = load_total_machines(csv_b)
    filenames = ensure_matching_filenames(
        values_a, values_b, label_a=label_a, label_b=label_b
    )

    a = np.asarray([values_a[name] for name in filenames], dtype=float)
    b = np.asarray([values_b[name] for name in filenames], dtype=float)
    if not np.all(np.isfinite(a)) or not np.all(np.isfinite(b)):
        raise ValueError("Found non-finite total_machines values.")

    diff = a - b
    n_total = int(diff.size)
    n_nonzero = int(np.count_nonzero(diff))
    if n_nonzero < 2:
        raise ValueError(
            f"{dataset}: need at least two non-zero paired differences for Wilcoxon."
        )

    try:
        from scipy import stats
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "SciPy is required for this script (dependency: scipy)."
        ) from exc

    try:
        wilcoxon_result = stats.wilcoxon(
            diff, zero_method="wilcox", correction=False, alternative="two-sided"
        )
    except TypeError:
        wilcoxon_result = stats.wilcoxon(diff, zero_method="wilcox", correction=False)

    w_statistic = float(wilcoxon_result.statistic)
    p_value = float(wilcoxon_result.pvalue)
    reject = bool(p_value < ALPHA) if np.isfinite(p_value) else False

    return TestResult(
        dataset=dataset,
        n_total=n_total,
        n_nonzero=n_nonzero,
        mean_diff=float(diff.mean()),
        median_diff=float(np.median(diff)),
        w_statistic=w_statistic,
        p_value=p_value,
        reject=reject,
        pos=int(np.sum(diff > 0)),
        neg=int(np.sum(diff < 0)),
        zero=int(np.sum(diff == 0)),
    )


def _print_result(
    *, label_a: str, label_b: str, csv_a: Path, csv_b: Path, result: TestResult
) -> None:
    print(f"Dataset: {result.dataset}")
    print(f"Algorithm A: {label_a} ({csv_a})")
    print(f"Algorithm B: {label_b} ({csv_b})")
    print(f"Instances: {result.n_total} (non-zero diffs: {result.n_nonzero})")
    print("")
    print("Test: Wilcoxon signed-rank test on machines_a - machines_b")
    print(f"H0: median(machines_a - machines_b) = 0   (alpha={_fmt_sig(ALPHA)})")
    print("")
    print(f"mean(diff)   = {_fmt_sig(result.mean_diff)}")
    print(f"median(diff) = {_fmt_sig(result.median_diff)}")
    print(f"signs (+/-/0)= {result.pos}/{result.neg}/{result.zero}")
    print(f"W statistic  = {_fmt_sig(result.w_statistic)}")
    print(f"p-value      = {_fmt_sig(result.p_value)}")
    print("")
    print("Decision:", "REJECT H0" if result.reject else "FAIL TO REJECT H0")
    print("-" * 72)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Wilcoxon signed-rank tests for paired raw total_machines values "
            "between two algorithms across one or more datasets."
        )
    )
    parser.add_argument(
        "--raw-root",
        type=Path,
        default=Path("evaluation/raw"),
        help="Root directory containing dataset subfolders with eval_*.csv files.",
    )
    parser.add_argument(
        "--datasets",
        type=str,
        default=",".join(DEFAULT_DATASETS),
        help=(
            "Comma-separated dataset names under --raw-root. "
            f"Default: {','.join(DEFAULT_DATASETS)}"
        ),
    )
    parser.add_argument(
        "--algo-a",
        type=str,
        default="bfd",
        help="Algorithm A name. Default: bfd",
    )
    parser.add_argument(
        "--algo-b",
        type=str,
        default="ffd_max",
        help="Algorithm B name. Default: ffd_max",
    )
    parser.add_argument(
        "--stats-root",
        type=Path,
        default=Path("evaluation/results"),
        help=(
            "Root directory where per-dataset stats CSV files are written. "
            "Each output goes to <stats-root>/<dataset>/."
        ),
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datasets = [d.strip() for d in args.datasets.split(",") if d.strip()]
    if not datasets:
        raise SystemExit("No datasets selected.")

    label_a = normalize_scheduler_name(args.algo_a)
    label_b = normalize_scheduler_name(args.algo_b)
    slug_a = _slug(label_a)
    slug_b = _slug(label_b)

    for dataset in datasets:
        dataset_dir = args.raw_root / dataset
        csv_a = (dataset_dir / scheduler_output_filename(label_a)).resolve()
        csv_b = (dataset_dir / scheduler_output_filename(label_b)).resolve()
        result = _run_dataset_test(
            dataset=dataset,
            csv_a=csv_a,
            csv_b=csv_b,
            label_a=label_a,
            label_b=label_b,
        )
        _print_result(
            label_a=label_a,
            label_b=label_b,
            csv_a=csv_a,
            csv_b=csv_b,
            result=result,
        )

        output_csv = (
            args.stats_root
            / dataset
            / f"eval_raw_machines_wilcoxon_{slug_a}_vs_{slug_b}_{dataset}.csv"
        )
        _write_stats_csv(
            output_csv=output_csv,
            label_a=label_a,
            label_b=label_b,
            result=result,
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
