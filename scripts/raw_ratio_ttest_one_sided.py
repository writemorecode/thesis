"""
Paired, one-tailed t-tests on per-instance raw cost ratios.

This script compares a base algorithm against one or more other algorithms
evaluated on the *same* set of problem instances (paired observations). For
each instance i, it computes:

    r_i = cost_base_i / cost_other_i

Null hypothesis (H0): mean(r) = 1  (no average difference in cost ratio)
Alternative (H1):     mean(r) < 1  (base has lower cost)
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
    load_total_costs,
    normalize_scheduler_name,
    parse_scheduler_list,
    scheduler_output_filename,
)

SIG_FIGS = 4


@dataclass(frozen=True)
class ComparisonStats:
    comparison: str
    upper_bound: float
    mean_ratio: float
    p_value: float


def _scalar_float(x: object) -> float:
    arr = np.asarray(x, dtype=float)
    if arr.size != 1:
        raise ValueError(f"Expected scalar, got shape={arr.shape}")
    return float(arr.item())


def _fmt_sig(x: float) -> str:
    if not np.isfinite(x):
        return str(x)
    return f"{x:.{SIG_FIGS}g}"


def _discover_schedulers(results_dir: Path) -> list[str]:
    schedulers: list[str] = []
    for path in sorted(results_dir.glob("eval_*.csv")):
        if not path.is_file():
            continue
        name = path.stem.removeprefix("eval_")
        if name:
            schedulers.append(name)
    return schedulers


def _resolve_csv(results_dir: Path, name: str) -> Path:
    canonical = normalize_scheduler_name(name)
    return (results_dir / scheduler_output_filename(canonical)).resolve()


def _compute_one_sided_stats(
    *, ratio: np.ndarray, alpha: float
) -> tuple[float, float, float, float, float, float]:
    if ratio.size < 2:
        raise ValueError("Need at least two paired instances for a t-test.")

    try:
        from scipy import stats
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "SciPy is required for this script (dependency: scipy)."
        ) from exc

    mean = float(ratio.mean())
    std = float(ratio.std(ddof=1))
    n = int(ratio.size)
    df = n - 1
    se = std / sqrt(n)

    try:
        res = stats.ttest_1samp(ratio, popmean=1.0, alternative="less")
        pvalue = _scalar_float(res.pvalue)
        t_stat = _scalar_float(res.statistic)
    except TypeError:
        res = stats.ttest_1samp(ratio, popmean=1.0)
        t_stat = _scalar_float(res.statistic)
        pvalue = float(stats.t.cdf(t_stat, df)) if np.isfinite(t_stat) else float("nan")

    t_crit = float(stats.t.ppf(1.0 - alpha, df))
    upper_bound = mean + t_crit * se

    if not np.isfinite(pvalue):
        pvalue = float("nan")
    if not np.isfinite(t_stat):
        t_stat = float("nan")

    return mean, std, t_stat, pvalue, upper_bound, df


def _run_pair(
    *,
    csv_base: Path,
    csv_other: Path,
    label_base: str,
    label_other: str,
    alpha: float,
) -> ComparisonStats:
    if not csv_base.is_file():
        raise FileNotFoundError(f"Missing CSV for {label_base}: {csv_base}")
    if not csv_other.is_file():
        raise FileNotFoundError(f"Missing CSV for {label_other}: {csv_other}")

    costs_base = load_total_costs(csv_base, duplicate_policy="min")
    costs_other = load_total_costs(csv_other, duplicate_policy="min")
    filenames = ensure_matching_filenames(
        costs_base, costs_other, label_a=label_base, label_b=label_other
    )

    base = np.asarray([costs_base[name] for name in filenames], dtype=float)
    other = np.asarray([costs_other[name] for name in filenames], dtype=float)
    if np.any(base < 0) or np.any(other <= 0):
        raise ValueError(
            "All total_cost values must be non-negative, and cost_other must be positive to compute ratios."
        )

    ratio = base / other
    mean, std, t_stat, pvalue, upper_bound, df = _compute_one_sided_stats(
        ratio=ratio, alpha=alpha
    )

    reject = bool(pvalue < alpha) if np.isfinite(pvalue) else False
    confidence_level = 1.0 - alpha

    print(f"Base: {label_base} ({csv_base})")
    print(f"Other: {label_other} ({csv_other})")
    print(f"Instances: {ratio.size}")
    print("")
    print("Test: paired one-tailed t-test on cost_base/cost_other")
    print(f"H0: mean(cost_base/cost_other) = 1   (alpha={_fmt_sig(alpha)})")
    print("H1: mean(cost_base/cost_other) < 1")
    print("")
    print(f"mean(ratio) = {_fmt_sig(mean)}")
    print(f"std(ratio)  = {_fmt_sig(std)}")
    print(f"t(df={df})       = {_fmt_sig(t_stat)}")
    print(f"p-value          = {_fmt_sig(pvalue)}")
    print(f"{_fmt_sig(confidence_level * 100)}% upper bound: {_fmt_sig(upper_bound)}")
    print("")
    print("Decision:", "REJECT H0" if reject else "FAIL TO REJECT H0")
    print("-" * 60)

    comparison = (
        f"{display_scheduler_name(label_base)} / {display_scheduler_name(label_other)}"
    )
    return ComparisonStats(
        comparison=comparison,
        upper_bound=upper_bound,
        mean_ratio=mean,
        p_value=pvalue,
    )


def write_stats_csv(*, output_csv: Path, rows: list[ComparisonStats]) -> None:
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with output_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "comparison",
                "upper_bound",
                "mean_ratio",
                "p_value",
            ],
        )
        writer.writeheader()
        for row in rows:
            writer.writerow(
                {
                    "comparison": row.comparison,
                    "upper_bound": _fmt_sig(row.upper_bound),
                    "mean_ratio": _fmt_sig(row.mean_ratio),
                    "p_value": _fmt_sig(row.p_value),
                }
            )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Paired one-tailed t-tests for mean total_cost ratios between a base "
            "algorithm and one or more other algorithms."
        )
    )
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=Path("eval_results"),
        help="Directory containing per-algorithm CSVs.",
    )
    parser.add_argument(
        "--base",
        type=str,
        default="bfd",
        help="Base algorithm name (default: bfd).",
    )
    parser.add_argument(
        "--compare",
        type=str,
        default=None,
        help="Comma-separated list of algorithms to compare against base.",
    )
    parser.add_argument(
        "--exclude",
        type=str,
        default=None,
        help="Comma-separated list of algorithms to exclude when auto-discovering.",
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
        default=None,
        help="Optional: write stats to this CSV file.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not (0.0 < args.alpha < 1.0):
        raise ValueError("--alpha must be between 0 and 1 (exclusive).")

    base_label = normalize_scheduler_name(args.base)
    compare_list: list[str]
    if args.compare:
        compare_list = parse_scheduler_list(args.compare)
        if not compare_list:
            raise SystemExit("No algorithms specified for --compare.")
    else:
        compare_list = _discover_schedulers(args.results_dir)
        if not compare_list:
            raise SystemExit("No eval_*.csv files found in results dir.")

    exclude = set()
    if args.exclude:
        exclude = {
            normalize_scheduler_name(name)
            for name in parse_scheduler_list(args.exclude)
        }

    seen: set[str] = set()
    comparisons: list[str] = []
    for name in compare_list:
        canonical = normalize_scheduler_name(name)
        if canonical == base_label or canonical in exclude:
            continue
        if canonical in seen:
            continue
        seen.add(canonical)
        comparisons.append(canonical)

    if not comparisons:
        raise SystemExit("No comparison algorithms remain after filtering.")

    rows: list[ComparisonStats] = []
    for other_label in comparisons:
        row = _run_pair(
            csv_base=_resolve_csv(args.results_dir, base_label),
            csv_other=_resolve_csv(args.results_dir, other_label),
            label_base=base_label,
            label_other=other_label,
            alpha=args.alpha,
        )
        rows.append(row)

    if args.stats_csv is not None:
        write_stats_csv(output_csv=args.stats_csv, rows=rows)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
