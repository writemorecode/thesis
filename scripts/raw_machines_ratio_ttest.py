"""
Paired, two-tailed t-tests on per-instance raw total_machines ratios.

This script compares two algorithms evaluated on the same set of problem
instances. For each instance i, it computes:

    r_i = machines_a_i / machines_b_i

Null hypothesis (H0): mean(r) = 1  (no average machine-count ratio difference)
Alternative (H1):     mean(r) != 1 (two-tailed)
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from math import sqrt
from pathlib import Path

import numpy as np

from eval_utils import (
    display_scheduler_name,
    ensure_matching_filenames,
    load_metric_values,
    normalize_scheduler_name,
    scheduler_output_filename,
)

SIG_FIGS = 6
DEFAULT_DATASETS = ("balanced", "job_heavy", "machine_heavy")


@dataclass(frozen=True)
class TestResult:
    n: int
    mean_ratio: float
    ci_low_ratio: float
    ci_high_ratio: float
    t_statistic: float
    p_value: float
    reject: bool


def _fmt_sig(value: float) -> str:
    if not np.isfinite(value):
        return str(value)
    return f"{value:.{SIG_FIGS}g}"


def _slug(name: str) -> str:
    return normalize_scheduler_name(name).replace("_", "")


def _scalar_float(value: object) -> float:
    arr = np.asarray(value, dtype=float)
    if arr.size != 1:
        raise ValueError(f"Expected scalar, got shape={arr.shape}")
    return float(arr.item())


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
                "comparison",
                "n",
                "mean_ratio",
                "ci_ratio",
                "t_statistic",
                "p_value",
                "decision",
            ],
        )
        writer.writeheader()
        comparison = (
            f"{display_scheduler_name(label_a)} / {display_scheduler_name(label_b)}"
        )
        writer.writerow(
            {
                "comparison": comparison,
                "n": str(result.n),
                "mean_ratio": _fmt_sig(result.mean_ratio),
                "ci_ratio": (
                    f"{_fmt_sig(result.ci_low_ratio)}-{_fmt_sig(result.ci_high_ratio)}"
                ),
                "t_statistic": _fmt_sig(result.t_statistic),
                "p_value": _fmt_sig(result.p_value),
                "decision": "REJECT H0" if result.reject else "FAIL TO REJECT H0",
            }
        )


def _run_dataset_test(
    *,
    csv_a: Path,
    csv_b: Path,
    label_a: str,
    label_b: str,
    alpha: float,
) -> TestResult:
    if not csv_a.is_file():
        raise FileNotFoundError(f"Missing CSV for {label_a}: {csv_a}")
    if not csv_b.is_file():
        raise FileNotFoundError(f"Missing CSV for {label_b}: {csv_b}")

    values_a = load_metric_values(
        csv_a, column="total_machines", duplicate_policy="error"
    )
    values_b = load_metric_values(
        csv_b, column="total_machines", duplicate_policy="error"
    )
    filenames = ensure_matching_filenames(
        values_a, values_b, label_a=label_a, label_b=label_b
    )

    a = np.asarray([values_a[name] for name in filenames], dtype=float)
    b = np.asarray([values_b[name] for name in filenames], dtype=float)
    if np.any(a < 0) or np.any(b <= 0):
        raise ValueError(
            "All total_machines values must be non-negative, and "
            "machines_b must be positive to compute ratios."
        )

    ratio = a / b
    n = int(ratio.size)
    if n < 2:
        raise ValueError("Need at least two paired instances for a t-test.")

    try:
        from scipy import stats
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "SciPy is required for this script (dependency: scipy)."
        ) from exc

    res = stats.ttest_1samp(ratio, popmean=1.0, alternative="two-sided")
    t_statistic = _scalar_float(res.statistic)
    p_value = _scalar_float(res.pvalue)
    if not np.isfinite(t_statistic):
        t_statistic = float("nan")
    if not np.isfinite(p_value):
        p_value = float("nan")

    mean = float(ratio.mean())
    std = float(ratio.std(ddof=1))
    df = n - 1
    se = std / sqrt(n)
    t_crit = float(stats.t.ppf(1.0 - alpha / 2.0, df))
    ci_low = mean - t_crit * se
    ci_high = mean + t_crit * se
    reject = bool(p_value < alpha) if np.isfinite(p_value) else False

    return TestResult(
        n=n,
        mean_ratio=mean,
        ci_low_ratio=ci_low,
        ci_high_ratio=ci_high,
        t_statistic=t_statistic,
        p_value=p_value,
        reject=reject,
    )


def _print_result(
    *,
    dataset: str,
    label_a: str,
    label_b: str,
    csv_a: Path,
    csv_b: Path,
    alpha: float,
    result: TestResult,
) -> None:
    print(f"Dataset: {dataset}")
    print(f"Algorithm A: {label_a} ({csv_a})")
    print(f"Algorithm B: {label_b} ({csv_b})")
    print(f"Instances: {result.n}")
    print("")
    print("Test: paired two-tailed t-test on machines_a/machines_b")
    print(f"H0: mean(machines_a/machines_b) = 1   (alpha={_fmt_sig(alpha)})")
    print("H1: mean(machines_a/machines_b) != 1")
    print("")
    print(f"mean(ratio) = {_fmt_sig(result.mean_ratio)}")
    print(
        "95% CI mean(ratio): "
        f"[{_fmt_sig(result.ci_low_ratio)}, {_fmt_sig(result.ci_high_ratio)}]"
    )
    print(f"t-statistic = {_fmt_sig(result.t_statistic)}")
    print(f"p-value     = {_fmt_sig(result.p_value)}")
    print("")
    print("Decision:", "REJECT H0" if result.reject else "FAIL TO REJECT H0")
    print("-" * 72)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Paired two-tailed t-tests for mean total_machines ratios "
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
        "--alpha",
        type=float,
        default=0.05,
        help="Significance level (default: 0.05).",
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
    if not (0.0 < args.alpha < 1.0):
        raise ValueError("--alpha must be between 0 and 1 (exclusive).")

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
            csv_a=csv_a,
            csv_b=csv_b,
            label_a=label_a,
            label_b=label_b,
            alpha=args.alpha,
        )
        _print_result(
            dataset=dataset,
            label_a=label_a,
            label_b=label_b,
            csv_a=csv_a,
            csv_b=csv_b,
            alpha=args.alpha,
            result=result,
        )

        output_csv = (
            args.stats_root
            / dataset
            / f"eval_raw_machines_ratio_ttest_{slug_a}_vs_{slug_b}_{dataset}.csv"
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
