"""
Paired, one-tailed t-tests on per-instance raw total_cost values across datasets.

This script compares one algorithm evaluated on two datasets at a time. For each
matched instance filename i, it uses paired observations:

    d_i = cost_left_i - cost_right_i

For a test expression "left<right":
  H0: mean(d) = 0
  H1: mean(d) < 0

For a test expression "left>right":
  H0: mean(d) = 0
  H1: mean(d) > 0
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from pathlib import Path

import numpy as np

from eval_utils import (
    ensure_matching_filenames,
    load_total_costs,
    normalize_scheduler_name,
    scheduler_output_filename,
)

SIG_FIGS = 4


@dataclass(frozen=True)
class DatasetComparison:
    left_dataset: str
    right_dataset: str
    operator: str
    alternative: str
    comparison: str


@dataclass(frozen=True)
class ComparisonStats:
    comparison: str
    algorithm: str
    n: int
    mean_left: float
    mean_right: float
    mean_diff_left_minus_right: float
    std_diff: float
    t_statistic: float
    p_value: float
    alpha: float
    decision: str


def _fmt_sig(value: float) -> str:
    if not np.isfinite(value):
        return str(value)
    return f"{value:.{SIG_FIGS}g}"


def _parse_tests(value: str) -> list[DatasetComparison]:
    tokens = [token.strip() for token in value.split(",") if token.strip()]
    if not tokens:
        raise ValueError("No tests provided; pass at least one dataset comparison.")

    parsed: list[DatasetComparison] = []
    for token in tokens:
        has_lt = "<" in token
        has_gt = ">" in token
        if has_lt == has_gt:
            raise ValueError(
                f"Invalid test expression '{token}': use exactly one of '<' or '>'."
            )

        operator = "<" if has_lt else ">"
        left, right = [part.strip() for part in token.split(operator)]
        if not left or not right:
            raise ValueError(
                f"Invalid test expression '{token}': missing left or right dataset."
            )

        alternative = "less" if operator == "<" else "greater"
        parsed.append(
            DatasetComparison(
                left_dataset=left,
                right_dataset=right,
                operator=operator,
                alternative=alternative,
                comparison=f"{left}{operator}{right}",
            )
        )

    return parsed


def _resolve_csv(raw_root: Path, dataset: str, algorithm: str) -> Path:
    scheduler_csv = scheduler_output_filename(algorithm)
    return (raw_root / dataset / scheduler_csv).resolve()


def _scalar_float(value: object) -> float:
    arr = np.asarray(value, dtype=float)
    if arr.size != 1:
        raise ValueError(f"Expected scalar value, got shape={arr.shape}.")
    return float(arr.item())


def _write_stats_csv(output_csv: Path, rows: list[ComparisonStats]) -> None:
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with output_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "comparison",
                "algorithm",
                "n",
                "mean_left",
                "mean_right",
                "mean_diff_left_minus_right",
                "std_diff",
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
                    "mean_left": _fmt_sig(row.mean_left),
                    "mean_right": _fmt_sig(row.mean_right),
                    "mean_diff_left_minus_right": _fmt_sig(
                        row.mean_diff_left_minus_right
                    ),
                    "std_diff": _fmt_sig(row.std_diff),
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

    costs_left = load_total_costs(csv_left, duplicate_policy="min")
    costs_right = load_total_costs(csv_right, duplicate_policy="min")
    filenames = ensure_matching_filenames(
        costs_left,
        costs_right,
        label_a=f"{test.left_dataset}:{algorithm}",
        label_b=f"{test.right_dataset}:{algorithm}",
    )

    left = np.asarray([costs_left[name] for name in filenames], dtype=float)
    right = np.asarray([costs_right[name] for name in filenames], dtype=float)
    if left.size < 2:
        raise ValueError("Need at least two paired instances for a paired t-test.")
    if not np.all(np.isfinite(left)) or not np.all(np.isfinite(right)):
        raise ValueError("Found non-finite total_cost values.")

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

    try:
        res = stats.ttest_rel(left, right, alternative=test.alternative)
        t_statistic = _scalar_float(res.statistic)
        p_value = _scalar_float(res.pvalue)
    except TypeError:
        res = stats.ttest_rel(left, right)
        t_statistic = _scalar_float(res.statistic)
        df = left.size - 1
        if test.alternative == "less":
            p_value = float(stats.t.cdf(t_statistic, df))
        else:
            p_value = float(stats.t.sf(t_statistic, df))

    if not np.isfinite(t_statistic):
        t_statistic = float("nan")
    if not np.isfinite(p_value):
        p_value = float("nan")

    reject = bool(p_value < alpha) if np.isfinite(p_value) else False
    decision = "REJECT H0" if reject else "FAIL TO REJECT H0"

    print(f"Comparison: {test.comparison}")
    print(f"Algorithm: {algorithm}")
    print(f"Left dataset: {test.left_dataset} ({csv_left})")
    print(f"Right dataset: {test.right_dataset} ({csv_right})")
    print(f"Instances: {left.size}")
    print("")
    print("Test: paired one-tailed t-test on cost_left - cost_right")
    print(f"H0: mean(cost_left - cost_right) = 0   (alpha={_fmt_sig(alpha)})")
    print(f"H1: mean(cost_left - cost_right) {test.operator} 0")
    print("")
    print(f"mean(left)      = {_fmt_sig(mean_left)}")
    print(f"mean(right)     = {_fmt_sig(mean_right)}")
    print(f"mean(diff)      = {_fmt_sig(mean_diff)}")
    print(f"std(diff)       = {_fmt_sig(std_diff)}")
    print(f"t-statistic     = {_fmt_sig(t_statistic)}")
    print(f"p-value         = {_fmt_sig(p_value)}")
    print("")
    print("Decision:", decision)
    print("-" * 60)

    return ComparisonStats(
        comparison=test.comparison,
        algorithm=algorithm,
        n=int(left.size),
        mean_left=mean_left,
        mean_right=mean_right,
        mean_diff_left_minus_right=mean_diff,
        std_diff=std_diff,
        t_statistic=t_statistic,
        p_value=p_value,
        alpha=alpha,
        decision=decision,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run paired one-tailed t-tests comparing one algorithm's raw total_cost "
            "across dataset pairs."
        )
    )
    parser.add_argument(
        "--raw-root",
        type=Path,
        default=Path("evaluation/raw"),
        help="Root directory containing per-dataset raw evaluation CSVs.",
    )
    parser.add_argument(
        "--algorithm",
        type=str,
        default="bfd",
        help="Algorithm name to compare across datasets (default: bfd).",
    )
    parser.add_argument(
        "--alpha",
        type=float,
        default=0.05,
        help="Significance level (default: 0.05).",
    )
    parser.add_argument(
        "--tests",
        type=str,
        default="machine_heavy<balanced,job_heavy>balanced",
        help=(
            "Comma-separated dataset comparisons, e.g. "
            "'machine_heavy<balanced,job_heavy>balanced'."
        ),
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

    algorithm = normalize_scheduler_name(args.algorithm)
    tests = _parse_tests(args.tests)

    rows: list[ComparisonStats] = []
    for test in tests:
        row = _run_test(
            raw_root=args.raw_root,
            algorithm=algorithm,
            test=test,
            alpha=args.alpha,
        )
        rows.append(row)

    if args.stats_csv is not None:
        _write_stats_csv(output_csv=args.stats_csv, rows=rows)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
