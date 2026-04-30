"""
Shapiro-Wilk test for normality on per-instance raw total_cost ratios.

Input: two eval_*.csv files containing at least:
  - filename
  - total_cost
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

import numpy as np

from eval_utils import (
    display_scheduler_name,
    ensure_matching_filenames,
    load_total_costs,
    normalize_scheduler_name,
    scheduler_output_filename,
)

SIG_FIGS = 6


def _fmt_sig(value: float) -> str:
    if not np.isfinite(value):
        return str(value)
    return f"{value:.{SIG_FIGS}g}"


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


def _write_stats_csv(
    *,
    output_csv: Path,
    label_a: str,
    label_b: str,
    statistic: float,
    p_value: float,
    reject: bool,
) -> None:
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with output_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["comparison", "w_statistic", "p_value", "reject"],
        )
        writer.writeheader()
        comparison = (
            f"{display_scheduler_name(label_a)} / {display_scheduler_name(label_b)}"
        )
        writer.writerow(
            {
                "comparison": comparison,
                "w_statistic": _fmt_sig(statistic),
                "p_value": _fmt_sig(p_value),
                "reject": "YES" if reject else "NO",
            }
        )


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
    if ratio.size < 3:
        raise ValueError("Shapiro-Wilk test requires at least 3 observations.")

    try:
        from scipy import stats
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "SciPy is required for this script (dependency: scipy)."
        ) from exc

    statistic, p_value = stats.shapiro(ratio)
    statistic = float(statistic)
    p_value = float(p_value)
    reject = bool(p_value < alpha) if np.isfinite(p_value) else False

    comparison = (
        f"{display_scheduler_name(label_a)} / {display_scheduler_name(label_b)}"
    )
    print(f"Comparison: {comparison}")
    print(f"Instances: {ratio.size}")
    print("")
    print("Test: Shapiro-Wilk normality test on total_cost ratio")
    print(f"H0: ratios are drawn from a normal distribution (alpha={_fmt_sig(alpha)})")
    print("")
    print(f"W statistic = {_fmt_sig(statistic)}")
    print(f"p-value     = {_fmt_sig(p_value)}")
    print("Decision:", "REJECT H0" if reject else "FAIL TO REJECT H0")

    if stats_csv is not None:
        _write_stats_csv(
            output_csv=stats_csv,
            label_a=label_a,
            label_b=label_b,
            statistic=statistic,
            p_value=p_value,
            reject=reject,
        )

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Shapiro-Wilk normality test for raw total_cost ratios."
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
        help="Optional: write W-statistic/p-value/reject decision to this CSV file.",
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
