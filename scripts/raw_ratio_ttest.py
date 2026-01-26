"""
Paired, two-tailed t-test on per-instance raw cost ratios.

This script compares two algorithms evaluated on the *same* set of problem
instances (paired observations). For each instance i, it computes:

    r_i = cost_a_i / cost_b_i

Null hypothesis (H0): mean(r) = 1  (no average difference in cost ratio)
Alternative (H1):     mean(r) != 1 (two-tailed)

Input: two per-instance evaluation CSVs that contain at least:
  - filename
  - total_cost

Output: prints test statistics to stdout and can optionally write key stats to a CSV file.
"""

from __future__ import annotations

import argparse
import csv
from math import sqrt
from pathlib import Path

import numpy as np

from eval_utils import (
    display_scheduler_name,
    ensure_matching_filenames,
    load_total_costs,
    normalize_scheduler_name,
    scheduler_output_filename,
)

SIG_FIGS = 4


def write_stats_csv(
    *,
    output_csv: Path,
    label_a: str,
    label_b: str,
    p_value: float,
    mean_ratio: float,
    ci_low_ratio: float,
    ci_high_ratio: float,
) -> None:
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with output_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "comparison",
                "ci_ratio",
                "mean_ratio",
                "p_value",
            ],
        )
        writer.writeheader()
        comparison = (
            f"{display_scheduler_name(label_a)} / {display_scheduler_name(label_b)}"
        )
        ci_ratio = f"{_fmt_sig(ci_low_ratio)}-{_fmt_sig(ci_high_ratio)}"
        writer.writerow(
            {
                "comparison": comparison,
                "ci_ratio": ci_ratio,
                "mean_ratio": _fmt_sig(mean_ratio),
                "p_value": _fmt_sig(p_value),
            }
        )


def _scalar_float(x: object) -> float:
    arr = np.asarray(x, dtype=float)
    if arr.size != 1:
        raise ValueError(f"Expected scalar, got shape={arr.shape}")
    return float(arr.item())


def _fmt_sig(x: float) -> str:
    if not np.isfinite(x):
        return str(x)
    return f"{x:.{SIG_FIGS}g}"


def _fmt_ci(low: float, high: float) -> str:
    return f"[{_fmt_sig(low)}, {_fmt_sig(high)}]"


def _resolve_pair(
    *, results_dir: Path, algo_a: str | None, algo_b: str | None, csv_paths: list[Path]
) -> tuple[str, Path, str, Path]:
    if csv_paths:
        if len(csv_paths) != 2:
            raise SystemExit("Pass exactly two CSV paths, or use --algo-a/--algo-b.")
        a_path, b_path = (path.resolve() for path in csv_paths)
        if a_path.parent != b_path.parent:
            raise SystemExit("Both CSV paths must be in the same directory.")
        label_a = a_path.stem.removeprefix("eval_")
        label_b = b_path.stem.removeprefix("eval_")
        return label_a, a_path, label_b, b_path

    if not algo_a or not algo_b:
        raise SystemExit("Missing --algo-a/--algo-b (or pass two CSV paths).")

    label_a = normalize_scheduler_name(algo_a)
    label_b = normalize_scheduler_name(algo_b)
    a_path = (results_dir / scheduler_output_filename(label_a)).resolve()
    b_path = (results_dir / scheduler_output_filename(label_b)).resolve()
    return label_a, a_path, label_b, b_path


def run_test(
    *,
    csv_a: Path,
    csv_b: Path,
    label_a: str,
    label_b: str,
    alpha: float,
    stats_csv: Path | None,
) -> int:
    if not (0.0 < alpha < 1.0):
        raise ValueError("--alpha must be between 0 and 1 (exclusive).")

    if not csv_a.is_file():
        raise FileNotFoundError(f"Missing CSV for {label_a}: {csv_a}")
    if not csv_b.is_file():
        raise FileNotFoundError(f"Missing CSV for {label_b}: {csv_b}")

    costs_a = load_total_costs(csv_a, duplicate_policy="min")
    costs_b = load_total_costs(csv_b, duplicate_policy="min")
    filenames = ensure_matching_filenames(
        costs_a, costs_b, label_a=label_a, label_b=label_b
    )

    a = np.asarray([costs_a[name] for name in filenames], dtype=float)
    b = np.asarray([costs_b[name] for name in filenames], dtype=float)
    if np.any(a < 0) or np.any(b <= 0):
        raise ValueError(
            "All total_cost values must be non-negative, and cost_b must be positive to compute ratios."
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

    # Equivalent to ttest_rel(a / b, 1); explicitly tests mean(ratio)=1.
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

    pvalue = _scalar_float(res.pvalue)
    if not np.isfinite(pvalue):
        pvalue = float("nan")
    reject = bool(pvalue < alpha) if np.isfinite(pvalue) else False
    confidence_level = 1.0 - alpha
    statistic = _scalar_float(res.statistic)
    if not np.isfinite(statistic):
        statistic = float("nan")

    if stats_csv is not None:
        write_stats_csv(
            output_csv=stats_csv,
            label_a=label_a,
            label_b=label_b,
            p_value=pvalue,
            mean_ratio=mean,
            ci_low_ratio=ci_low,
            ci_high_ratio=ci_high,
        )

    print(f"Algorithm A: {label_a} ({csv_a})")
    print(f"Algorithm B: {label_b} ({csv_b})")
    print(f"Instances: {n}")
    print("")
    print("Test: paired two-tailed t-test on cost_a/cost_b")
    print(f"H0: mean(cost_a/cost_b) = 1   (alpha={_fmt_sig(alpha)})")
    print("")
    print(f"mean(ratio) = {_fmt_sig(mean)}")
    print(f"std(ratio)  = {_fmt_sig(std)}")
    print(f"t(df={df})       = {_fmt_sig(statistic)}")
    print(f"p-value          = {_fmt_sig(pvalue)}")
    print(
        f"{_fmt_sig(confidence_level * 100)}% CI mean(ratio): {_fmt_ci(ci_low, ci_high)}"
    )
    print("")
    print("Decision:", "REJECT H0" if reject else "FAIL TO REJECT H0")

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Paired two-tailed t-test for mean total_cost ratio between two algorithms."
    )
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=Path("eval_results"),
        help="Directory containing per-algorithm CSVs (used with --algo-a/--algo-b).",
    )
    parser.add_argument(
        "--algo-a",
        type=str,
        default=None,
        help="Algorithm A name (used with --results-dir).",
    )
    parser.add_argument(
        "--algo-b",
        type=str,
        default=None,
        help="Algorithm B name (used with --results-dir).",
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
        help="Optional: write alpha/p-value/t-statistic to this CSV file.",
    )
    parser.add_argument(
        "csv_paths",
        nargs="*",
        type=Path,
        help="Optional: provide two CSV paths directly (overrides --results-dir/--algo-*).",
    )
    args = parser.parse_args()

    label_a, path_a, label_b, path_b = _resolve_pair(
        results_dir=args.results_dir,
        algo_a=args.algo_a,
        algo_b=args.algo_b,
        csv_paths=args.csv_paths,
    )
    return run_test(
        csv_a=path_a,
        csv_b=path_b,
        label_a=label_a,
        label_b=label_b,
        alpha=args.alpha,
        stats_csv=args.stats_csv,
    )


if __name__ == "__main__":
    raise SystemExit(main())
