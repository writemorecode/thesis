"""
Paired, two-tailed t-tests on per-instance runtime_sec values across datasets.

This script compares one algorithm evaluated on dataset pairs. For each matched
instance filename i, it uses paired observations:

    d_i = runtime_left_i - runtime_right_i

Null hypothesis (H0): mean(d) = 0
Alternative (H1):     mean(d) != 0
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from itertools import combinations
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

SIG_FIGS = 4


@dataclass(frozen=True)
class DatasetComparison:
    left_dataset: str
    right_dataset: str
    comparison: str


@dataclass(frozen=True)
class ComparisonStats:
    comparison: str
    algorithm: str
    n: int
    mean_left_runtime_sec: float
    mean_right_runtime_sec: float
    mean_diff_left_minus_right_sec: float
    ci_low_diff_sec: float
    ci_high_diff_sec: float
    std_diff_sec: float
    t_statistic: float
    p_value: float
    alpha: float
    decision: str


def _fmt_sig(value: float) -> str:
    if not np.isfinite(value):
        return str(value)
    return f"{value:.{SIG_FIGS}g}"


def _scalar_float(value: object) -> float:
    arr = np.asarray(value, dtype=float)
    if arr.size != 1:
        raise ValueError(f"Expected scalar value, got shape={arr.shape}.")
    return float(arr.item())


def _dataset_pairs(datasets: list[str]) -> list[DatasetComparison]:
    if len(datasets) < 2:
        raise ValueError("Need at least two datasets for cross-dataset comparisons.")
    return [
        DatasetComparison(
            left_dataset=left,
            right_dataset=right,
            comparison=f"{left} vs {right}",
        )
        for left, right in combinations(datasets, 2)
    ]


def _discover_algorithms(raw_root: Path, datasets: list[str]) -> list[str]:
    first_dataset = raw_root / datasets[0]
    if not first_dataset.is_dir():
        raise FileNotFoundError(f"Missing dataset directory: {first_dataset}")

    algorithms = sorted(
        normalize_scheduler_name(path.stem.removeprefix("eval_"))
        for path in first_dataset.glob("eval_*.csv")
        if path.is_file()
    )
    if not algorithms:
        raise FileNotFoundError(f"No eval_*.csv files found in {first_dataset}")
    return algorithms


def _resolve_csv(raw_root: Path, dataset: str, algorithm: str) -> Path:
    scheduler_csv = scheduler_output_filename(algorithm)
    return (raw_root / dataset / scheduler_csv).resolve()


def _write_stats_csv(output_csv: Path, rows: list[ComparisonStats]) -> None:
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with output_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "comparison",
                "algorithm",
                "n",
                "mean_left_runtime_sec",
                "mean_right_runtime_sec",
                "mean_diff_left_minus_right_sec",
                "ci_low_diff_sec",
                "ci_high_diff_sec",
                "std_diff_sec",
                "t_statistic",
                "p_value",
                "alpha",
                "decision",
            ],
        )
        writer.writeheader()
        for row in rows:
            writer.writerow(
                {
                    "comparison": row.comparison,
                    "algorithm": row.algorithm,
                    "n": row.n,
                    "mean_left_runtime_sec": _fmt_sig(row.mean_left_runtime_sec),
                    "mean_right_runtime_sec": _fmt_sig(row.mean_right_runtime_sec),
                    "mean_diff_left_minus_right_sec": _fmt_sig(
                        row.mean_diff_left_minus_right_sec
                    ),
                    "ci_low_diff_sec": _fmt_sig(row.ci_low_diff_sec),
                    "ci_high_diff_sec": _fmt_sig(row.ci_high_diff_sec),
                    "std_diff_sec": _fmt_sig(row.std_diff_sec),
                    "t_statistic": _fmt_sig(row.t_statistic),
                    "p_value": _fmt_sig(row.p_value),
                    "alpha": _fmt_sig(row.alpha),
                    "decision": row.decision,
                }
            )


def _run_test(
    *,
    raw_root: Path,
    algorithm: str,
    test: DatasetComparison,
    alpha: float,
) -> ComparisonStats:
    left_dir = raw_root / test.left_dataset
    right_dir = raw_root / test.right_dataset
    if not left_dir.is_dir():
        raise FileNotFoundError(f"Missing dataset directory: {left_dir}")
    if not right_dir.is_dir():
        raise FileNotFoundError(f"Missing dataset directory: {right_dir}")

    csv_left = _resolve_csv(raw_root, test.left_dataset, algorithm)
    csv_right = _resolve_csv(raw_root, test.right_dataset, algorithm)
    if not csv_left.is_file():
        raise FileNotFoundError(
            f"Missing CSV for dataset '{test.left_dataset}' and algorithm '{algorithm}': {csv_left}"
        )
    if not csv_right.is_file():
        raise FileNotFoundError(
            f"Missing CSV for dataset '{test.right_dataset}' and algorithm '{algorithm}': {csv_right}"
        )

    runtime_left = load_runtime_seconds(csv_left, duplicate_policy="min")
    runtime_right = load_runtime_seconds(csv_right, duplicate_policy="min")
    filenames = ensure_matching_filenames(
        runtime_left,
        runtime_right,
        label_a=f"{test.left_dataset}:{algorithm}",
        label_b=f"{test.right_dataset}:{algorithm}",
    )

    left = np.asarray([runtime_left[name] for name in filenames], dtype=float)
    right = np.asarray([runtime_right[name] for name in filenames], dtype=float)
    if left.size < 2:
        raise ValueError("Need at least two paired instances for a paired t-test.")
    if not np.all(np.isfinite(left)) or not np.all(np.isfinite(right)):
        raise ValueError("Found non-finite runtime_sec values.")

    diff = left - right
    mean_left = float(left.mean())
    mean_right = float(right.mean())
    mean_diff = float(diff.mean())
    std_diff = float(diff.std(ddof=1))

    try:
        from scipy import stats
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "SciPy is required for this script (dependency: scipy)."
        ) from exc

    res = stats.ttest_rel(left, right, alternative="two-sided")
    t_statistic = _scalar_float(res.statistic)
    p_value = _scalar_float(res.pvalue)
    if not np.isfinite(t_statistic):
        t_statistic = float("nan")
    if not np.isfinite(p_value):
        p_value = float("nan")

    df = left.size - 1
    se = std_diff / sqrt(left.size)
    t_crit = float(stats.t.ppf(1.0 - alpha / 2.0, df))
    ci_low = mean_diff - t_crit * se
    ci_high = mean_diff + t_crit * se

    reject = bool(p_value < alpha) if np.isfinite(p_value) else False
    decision = "REJECT H0" if reject else "FAIL TO REJECT H0"

    print(f"Comparison: {test.comparison}")
    print(f"Algorithm: {display_scheduler_name(algorithm)}")
    print(f"Left dataset: {test.left_dataset} ({csv_left})")
    print(f"Right dataset: {test.right_dataset} ({csv_right})")
    print(f"Instances: {left.size}")
    print("")
    print("Test: paired two-tailed t-test on runtime_left - runtime_right")
    print(f"H0: mean(runtime_left - runtime_right) = 0   (alpha={_fmt_sig(alpha)})")
    print("H1: mean(runtime_left - runtime_right) != 0")
    print("")
    print(f"mean(left)      = {_fmt_sig(mean_left)} sec")
    print(f"mean(right)     = {_fmt_sig(mean_right)} sec")
    print(f"mean(diff)      = {_fmt_sig(mean_diff)} sec")
    print(f"95% CI(diff)    = [{_fmt_sig(ci_low)}, {_fmt_sig(ci_high)}] sec")
    print(f"std(diff)       = {_fmt_sig(std_diff)} sec")
    print(f"t-statistic     = {_fmt_sig(t_statistic)}")
    print(f"p-value         = {_fmt_sig(p_value)}")
    print("")
    print("Decision:", decision)
    print("-" * 60)

    return ComparisonStats(
        comparison=test.comparison,
        algorithm=algorithm,
        n=int(left.size),
        mean_left_runtime_sec=mean_left,
        mean_right_runtime_sec=mean_right,
        mean_diff_left_minus_right_sec=mean_diff,
        ci_low_diff_sec=ci_low,
        ci_high_diff_sec=ci_high,
        std_diff_sec=std_diff,
        t_statistic=t_statistic,
        p_value=p_value,
        alpha=alpha,
        decision=decision,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run paired two-tailed t-tests comparing raw runtime_sec across dataset "
            "pairs for each algorithm."
        )
    )
    parser.add_argument(
        "--raw-root",
        type=Path,
        default=Path("evaluation/raw"),
        help="Root directory containing per-dataset raw evaluation CSVs.",
    )
    parser.add_argument(
        "--datasets",
        type=str,
        default="balanced,job_heavy,machine_heavy",
        help="Comma-separated dataset names to compare pairwise.",
    )
    parser.add_argument(
        "--algorithms",
        type=str,
        default=None,
        help="Optional comma-separated algorithm names. Defaults to auto-discovery.",
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
        help="Optional path to write test statistics as CSV.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not (0.0 < args.alpha < 1.0):
        raise ValueError("--alpha must be between 0 and 1 (exclusive).")

    datasets = parse_scheduler_list(args.datasets)
    if len(datasets) < 2:
        raise ValueError("Provide at least two datasets in --datasets.")

    if args.algorithms:
        algorithms = [
            normalize_scheduler_name(name)
            for name in parse_scheduler_list(args.algorithms)
        ]
    else:
        algorithms = _discover_algorithms(args.raw_root, datasets)

    tests = _dataset_pairs(datasets)

    rows: list[ComparisonStats] = []
    for algorithm in algorithms:
        for test in tests:
            row = _run_test(
                raw_root=args.raw_root,
                algorithm=algorithm,
                test=test,
                alpha=args.alpha,
            )
            rows.append(row)

    if args.stats_csv is not None:
        _write_stats_csv(args.stats_csv, rows)
        print(f"Wrote stats CSV: {args.stats_csv}")

    rejected = sum(row.decision == "REJECT H0" for row in rows)
    print(f"Rejected H0 in {rejected}/{len(rows)} tests.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
