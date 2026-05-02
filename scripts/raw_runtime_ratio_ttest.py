"""
Paired, two-tailed t-tests on per-instance raw runtime ratios.

This script compares BFD with other algorithms evaluated on the same set of
problem instances. For each instance i, it computes:

    r_i = runtime_bfd_i / runtime_other_i

Null hypothesis (H0): mean(r) = 1  (no average runtime-ratio difference)
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
    load_runtime_seconds,
    normalize_scheduler_name,
    parse_scheduler_list,
    scheduler_output_filename,
)

SIG_FIGS = 6
DEFAULT_BASE_ALGORITHM = "bfd"
DEFAULT_COMPARISON_ALGORITHMS = (
    "ffd_l2",
    "ffd",
    "ffd_sum",
    "ffd_max",
    "ffd_prod",
    "ffd_new",
    "peak_demand",
)


@dataclass(frozen=True)
class TestResult:
    comparison: str
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


def _fmt_ci(low: float, high: float) -> str:
    return f"{_fmt_sig(low)}-{_fmt_sig(high)}"


def _scalar_float(value: object) -> float:
    arr = np.asarray(value, dtype=float)
    if arr.size != 1:
        raise ValueError(f"Expected scalar value, got shape={arr.shape}.")
    return float(arr.item())


def _resolve_csv(results_dir: Path, algorithm: str) -> Path:
    scheduler_csv = scheduler_output_filename(algorithm)
    return (results_dir / scheduler_csv).resolve()


def _write_stats_csv(output_csv: Path, rows: list[TestResult]) -> None:
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
        for row in rows:
            writer.writerow(
                {
                    "comparison": row.comparison,
                    "n": str(row.n),
                    "mean_ratio": _fmt_sig(row.mean_ratio),
                    "ci_ratio": _fmt_ci(row.ci_low_ratio, row.ci_high_ratio),
                    "t_statistic": _fmt_sig(row.t_statistic),
                    "p_value": _fmt_sig(row.p_value),
                    "decision": "REJECT H0" if row.reject else "FAIL TO REJECT H0",
                }
            )


def run_test(
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

    runtimes_a = load_runtime_seconds(csv_a, duplicate_policy="min")
    runtimes_b = load_runtime_seconds(csv_b, duplicate_policy="min")
    filenames = ensure_matching_filenames(
        runtimes_a,
        runtimes_b,
        label_a=label_a,
        label_b=label_b,
    )

    a = np.asarray([runtimes_a[name] for name in filenames], dtype=float)
    b = np.asarray([runtimes_b[name] for name in filenames], dtype=float)
    if np.any(a < 0) or np.any(b <= 0):
        raise ValueError(
            "All runtime_sec values must be non-negative, and runtime_b must be positive to compute ratios."
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

    try:
        res = stats.ttest_1samp(ratio, popmean=1.0, alternative="two-sided")
    except TypeError:
        res = stats.ttest_1samp(ratio, popmean=1.0)

    mean = float(ratio.mean())
    std = float(ratio.std(ddof=1))
    df = n - 1
    se = std / sqrt(n)
    t_crit = float(stats.t.ppf(1.0 - alpha / 2.0, df))
    ci_low = mean - t_crit * se
    ci_high = mean + t_crit * se

    p_value = _scalar_float(res.pvalue)
    if not np.isfinite(p_value):
        p_value = float("nan")
    statistic = _scalar_float(res.statistic)
    if not np.isfinite(statistic):
        statistic = float("nan")

    reject = bool(p_value < alpha) if np.isfinite(p_value) else False
    comparison = (
        f"{display_scheduler_name(label_a)} / {display_scheduler_name(label_b)}"
    )

    print(f"Comparison: {comparison}")
    print(f"Instances: {n}")
    print("Test: paired two-tailed t-test on runtime_a/runtime_b")
    print(f"H0: mean(runtime_a/runtime_b) = 1   (alpha={_fmt_sig(alpha)})")
    print(f"mean(ratio) = {_fmt_sig(mean)}")
    print(f"std(ratio)  = {_fmt_sig(std)}")
    print(f"t(df={df})  = {_fmt_sig(statistic)}")
    print(f"p-value     = {_fmt_sig(p_value)}")
    print(f"95% CI mean(ratio): [{_fmt_sig(ci_low)}, {_fmt_sig(ci_high)}]")
    print("Decision:", "REJECT H0" if reject else "FAIL TO REJECT H0")
    print("-" * 60)

    return TestResult(
        comparison=comparison,
        n=n,
        mean_ratio=mean,
        ci_low_ratio=ci_low,
        ci_high_ratio=ci_high,
        t_statistic=statistic,
        p_value=p_value,
        reject=reject,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Paired two-tailed t-tests for mean runtime ratios between algorithms."
    )
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=Path("eval_results"),
        help="Directory containing per-algorithm CSVs.",
    )
    parser.add_argument(
        "--base-algo",
        type=str,
        default=DEFAULT_BASE_ALGORITHM,
        help="Base algorithm name used as ratio numerator (default: bfd).",
    )
    parser.add_argument(
        "--algorithms",
        type=str,
        default=",".join(DEFAULT_COMPARISON_ALGORITHMS),
        help="Comma-separated denominator algorithms.",
    )
    parser.add_argument(
        "--alpha",
        type=float,
        default=0.05,
        help="Significance level (default: 0.05).",
    )
    parser.add_argument(
        "--stats-csv",
        type=Path,
        required=True,
        help="Path to write the test statistics CSV.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not (0.0 < args.alpha < 1.0):
        raise ValueError("--alpha must be between 0 and 1 (exclusive).")

    base_algorithm = normalize_scheduler_name(args.base_algo)
    comparison_algorithms = [
        normalize_scheduler_name(name)
        for name in parse_scheduler_list(args.algorithms)
        if normalize_scheduler_name(name) != base_algorithm
    ]
    if not comparison_algorithms:
        raise ValueError("Provide at least one non-base comparison algorithm.")

    csv_a = _resolve_csv(args.results_dir, base_algorithm)
    rows = [
        run_test(
            csv_a=csv_a,
            csv_b=_resolve_csv(args.results_dir, algorithm),
            label_a=base_algorithm,
            label_b=algorithm,
            alpha=args.alpha,
        )
        for algorithm in comparison_algorithms
    ]

    _write_stats_csv(args.stats_csv, rows)
    print(f"Wrote stats CSV: {args.stats_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
