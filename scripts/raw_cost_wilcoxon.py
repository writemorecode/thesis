"""
Wilcoxon signed-rank test on paired raw total_cost values.

This script compares two algorithms evaluated on the *same* set of problem
instances (paired observations). For each instance i, it computes:

    d_i = cost_a_i - cost_b_i

Null hypothesis (H0): median(d) = 0  (no median difference in costs)
Alternative (H1):     median(d) != 0 (two-tailed)

Input: two per-instance evaluation CSVs that contain at least:
  - filename
  - total_cost

Significance level: alpha = 0.05
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

ALPHA = 0.05
SIG_FIGS = 4


def _fmt_sig(x: float) -> str:
    if not np.isfinite(x):
        return str(x)
    return f"{x:.{SIG_FIGS}g}"


def _resolve_results_dir(args: argparse.Namespace) -> tuple[Path, str | None]:
    if not args.dataset:
        return args.results_dir, None

    dataset_path = Path(args.dataset)
    if dataset_path.is_dir():
        return dataset_path, dataset_path.name

    return args.raw_root / args.dataset, args.dataset


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


def write_stats_csv(
    *,
    output_csv: Path,
    label_a: str,
    label_b: str,
    statistic: float,
    p_value: float,
    n_total: int,
    n_nonzero: int,
    mean_diff: float,
    median_diff: float,
) -> None:
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with output_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "comparison",
                "n_total",
                "n_nonzero",
                "mean_diff",
                "median_diff",
                "w_statistic",
                "p_value",
            ],
        )
        writer.writeheader()
        comparison = (
            f"{display_scheduler_name(label_a)} vs {display_scheduler_name(label_b)}"
        )
        writer.writerow(
            {
                "comparison": comparison,
                "n_total": str(n_total),
                "n_nonzero": str(n_nonzero),
                "mean_diff": _fmt_sig(mean_diff),
                "median_diff": _fmt_sig(median_diff),
                "w_statistic": _fmt_sig(statistic),
                "p_value": _fmt_sig(p_value),
            }
        )


def run_test(
    *,
    csv_a: Path,
    csv_b: Path,
    label_a: str,
    label_b: str,
    dataset_hint: str,
    stats_csv: Path | None,
) -> int:
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
    if not np.all(np.isfinite(a)) or not np.all(np.isfinite(b)):
        raise ValueError("Found non-finite total_cost values.")

    diff = a - b
    n_total = int(diff.size)
    n_nonzero = int(np.count_nonzero(diff))
    if n_nonzero < 2:
        raise ValueError("Need at least two non-zero paired differences.")

    try:
        from scipy import stats
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "SciPy is required for this script (dependency: scipy)."
        ) from exc

    try:
        res = stats.wilcoxon(
            diff, zero_method="wilcox", correction=False, alternative="two-sided"
        )
    except TypeError:
        res = stats.wilcoxon(diff, zero_method="wilcox", correction=False)

    statistic = float(res.statistic)
    pvalue = float(res.pvalue)
    reject = bool(pvalue < ALPHA) if np.isfinite(pvalue) else False

    mean_diff = float(diff.mean())
    median_diff = float(np.median(diff))
    pos = int(np.sum(diff > 0))
    neg = int(np.sum(diff < 0))
    zero = int(np.sum(diff == 0))

    print(f"Algorithm A: {label_a} ({csv_a})")
    print(f"Algorithm B: {label_b} ({csv_b})")
    print(f"Dataset: {dataset_hint}")
    print(f"Instances: {n_total} (non-zero diffs: {n_nonzero})")
    print("")
    print("Test: Wilcoxon signed-rank test on cost_a - cost_b")
    print(f"H0: median(cost_a - cost_b) = 0   (alpha={_fmt_sig(ALPHA)})")
    print("")
    print(f"mean(diff)   = {_fmt_sig(mean_diff)}")
    print(f"median(diff) = {_fmt_sig(median_diff)}")
    print(f"signs (+/-/0)= {pos}/{neg}/{zero}")
    print(f"W statistic  = {_fmt_sig(statistic)}")
    print(f"p-value      = {_fmt_sig(pvalue)}")
    print("")
    print("Decision:", "REJECT H0" if reject else "FAIL TO REJECT H0")

    if stats_csv is not None:
        write_stats_csv(
            output_csv=stats_csv,
            label_a=label_a,
            label_b=label_b,
            statistic=statistic,
            p_value=pvalue,
            n_total=n_total,
            n_nonzero=n_nonzero,
            mean_diff=mean_diff,
            median_diff=median_diff,
        )

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Wilcoxon signed-rank test for paired raw total_cost values between two "
            "algorithms on a given dataset."
        )
    )
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=Path("eval_results"),
        help="Directory containing per-algorithm CSVs (used with --algo-a/--algo-b).",
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
        "--algo-a",
        type=str,
        default=None,
        help="Algorithm A name (used with --results-dir or --dataset).",
    )
    parser.add_argument(
        "--algo-b",
        type=str,
        default=None,
        help="Algorithm B name (used with --results-dir or --dataset).",
    )
    parser.add_argument(
        "--stats-csv",
        type=Path,
        default=None,
        help="Optional: write W-statistic/p-value to this CSV file.",
    )
    parser.add_argument(
        "csv_paths",
        nargs="*",
        type=Path,
        help="Optional: provide two CSV paths directly (overrides --dataset/--algo-*).",
    )
    args = parser.parse_args()

    results_dir, dataset_label = _resolve_results_dir(args)
    label_a, path_a, label_b, path_b = _resolve_pair(
        results_dir=results_dir,
        algo_a=args.algo_a,
        algo_b=args.algo_b,
        csv_paths=args.csv_paths,
    )
    dataset_hint = dataset_label or str(results_dir)
    return run_test(
        csv_a=path_a,
        csv_b=path_b,
        label_a=label_a,
        label_b=label_b,
        dataset_hint=dataset_hint,
        stats_csv=args.stats_csv,
    )


if __name__ == "__main__":
    raise SystemExit(main())
