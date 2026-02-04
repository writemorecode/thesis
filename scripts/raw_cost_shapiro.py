"""
Shapiro-Wilk test for normality on per-instance raw total_cost values.

Input: one eval_*.csv file (single algorithm/scheduler) containing at least:
  - filename
  - total_cost

Output: prints test statistics to stdout.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

import numpy as np

from eval_utils import (
    display_scheduler_name,
    load_total_costs,
    parse_scheduler_list,
    resolve_results_csv,
)

SIG_FIGS = 4


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Shapiro-Wilk normality test for raw per-instance total_cost values "
            "from eval_*.csv files for one or more algorithms/schedulers."
        )
    )
    parser.add_argument(
        "--algorithm",
        "--scheduler",
        dest="algorithm",
        type=str,
        required=True,
        help=("Algorithm/scheduler name(s) (comma-separated, e.g. ffd, bfd, ffd_new)."),
    )
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=Path("eval_results"),
        help="Directory containing per-scheduler CSVs (eval_*.csv).",
    )
    parser.add_argument(
        "--raw-root",
        type=Path,
        default=Path("evaluation/raw"),
        help=(
            "Root directory containing dataset subfolders with eval_*.csv files "
            "(used with --dataset)."
        ),
    )
    parser.add_argument(
        "--dataset",
        type=str,
        default=None,
        help=(
            "Optional dataset selection. If this points to an existing directory, "
            "it is used as the results directory. Otherwise it is treated as a "
            "subfolder name under --raw-root (e.g. balanced)."
        ),
    )
    parser.add_argument(
        "--alpha",
        type=float,
        default=0.05,
        help="Significance level for the decision rule (default: 0.05).",
    )
    parser.add_argument(
        "--stats-csv",
        type=Path,
        default=None,
        help="Optional: write W-statistic/p-value/reject decision to this CSV file.",
    )
    return parser.parse_args()


def _resolve_results_dir(args: argparse.Namespace) -> tuple[Path, str | None]:
    if not args.dataset:
        return args.results_dir, None

    dataset_path = Path(args.dataset)
    if dataset_path.is_dir():
        return dataset_path, dataset_path.name

    return args.raw_root / args.dataset, args.dataset


def _summary(values: np.ndarray) -> str:
    if values.size == 0:
        return "N=0"
    mean = float(values.mean())
    median = float(np.median(values))
    std = float(values.std(ddof=1)) if values.size >= 2 else 0.0
    min_val = float(values.min())
    max_val = float(values.max())
    return (
        f"N={values.size}, mean={mean:.6g}, median={median:.6g}, std={std:.6g}, "
        f"min={min_val:.6g}, max={max_val:.6g}"
    )


def _fmt_sig(x: float) -> str:
    if not np.isfinite(x):
        return str(x)
    return f"{x:.{SIG_FIGS}g}"


def write_stats_csv(*, output_csv: Path, rows: list[dict[str, str]]) -> None:
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with output_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["algorithm", "w_statistic", "p_value", "reject"],
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    args = parse_args()

    if not (0.0 < args.alpha < 1.0):
        raise ValueError("--alpha must be between 0 and 1 (exclusive).")

    algorithms = parse_scheduler_list(args.algorithm)
    if not algorithms:
        raise ValueError("No algorithms provided; pass at least one name.")

    results_dir, dataset_label = _resolve_results_dir(args)
    dataset_hint = dataset_label or results_dir

    try:
        from scipy import stats
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "SciPy is required for this script (dependency: scipy)."
        ) from exc

    rows: list[dict[str, str]] = []
    for algo in algorithms:
        canonical, csv_path = resolve_results_csv(results_dir, algo)
        if not csv_path.is_file():
            raise FileNotFoundError(f"Missing results file for {canonical}: {csv_path}")

        costs_by_file = load_total_costs(csv_path, duplicate_policy="min")
        values = np.asarray(list(costs_by_file.values()), dtype=float)
        if not np.all(np.isfinite(values)):
            raise ValueError("Found non-finite total_cost values.")

        n = int(values.size)
        if n < 3:
            raise ValueError("Shapiro-Wilk test requires at least 3 observations.")

        statistic, pvalue = stats.shapiro(values)
        statistic = float(statistic)
        pvalue = float(pvalue)

        display_name = display_scheduler_name(canonical)

        print(f"{display_name} ({dataset_hint}): {_summary(values)}")
        print("")
        print("Test: Shapiro-Wilk normality test")
        print(
            f"H0: data are drawn from a normal distribution (alpha={_fmt_sig(args.alpha)})"
        )
        print("")
        print(f"W statistic = {_fmt_sig(statistic)}")
        print(f"p-value     = {_fmt_sig(pvalue)}")
        print("")

        if np.isfinite(pvalue) and pvalue < args.alpha:
            decision = "REJECT H0"
            reject = "YES"
        else:
            decision = "FAIL TO REJECT H0"
            reject = "NO"
        print("Decision:", decision)

        if n > 5000:
            print(
                "Note: for N > 5000, SciPy warns that Shapiro-Wilk p-values may be inaccurate."
            )
        print("")

        rows.append(
            {
                "algorithm": display_name,
                "w_statistic": _fmt_sig(statistic),
                "p_value": _fmt_sig(pvalue),
                "reject": reject,
            }
        )

    if args.stats_csv is not None:
        write_stats_csv(output_csv=args.stats_csv, rows=rows)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
