"""
Visualize and summarize per-instance cost ratios for paired comparisons.

This is primarily intended to sanity-check the distributional assumptions behind
the paired raw-ratio t-tests (see raw_ratio_ttest.py).

For each dataset directory (containing eval_*.csv files), this script:
  - loads per-instance total_cost for two algorithms (A and B),
  - computes r_i = cost_a_i / cost_b_i,
  - prints summary stats and the most extreme ratios,
  - writes an SVG figure with:
      (1) histogram of r_i.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

import numpy as np

from eval_utils import (
    display_scheduler_name,
    ensure_matching_filenames,
    load_total_costs,
    normalize_scheduler_name,
    resolve_results_csv,
)


@dataclass(frozen=True)
class RatioSummary:
    n: int
    mean: float
    median: float
    std: float
    min: float
    p1: float
    p5: float
    p95: float
    p99: float
    max: float


def _quantile(x: np.ndarray, q: float) -> float:
    return float(np.quantile(x, q))


def _summarize(ratio: np.ndarray) -> RatioSummary:
    if ratio.size < 2:
        raise ValueError("Need at least two ratios to summarize.")
    return RatioSummary(
        n=int(ratio.size),
        mean=float(ratio.mean()),
        median=float(np.median(ratio)),
        std=float(ratio.std(ddof=1)),
        min=float(ratio.min()),
        p1=_quantile(ratio, 0.01),
        p5=_quantile(ratio, 0.05),
        p95=_quantile(ratio, 0.95),
        p99=_quantile(ratio, 0.99),
        max=float(ratio.max()),
    )


def _hist_edges(x: np.ndarray) -> np.ndarray:
    # "fd" is reasonably stable and adapts when ratios are tightly clustered.
    edges = np.histogram_bin_edges(x, bins="fd")
    # Fall back if the estimator degenerates (e.g., all values equal).
    if edges.size < 3:
        edges = np.histogram_bin_edges(x, bins=20)
    return edges


def _top_extremes(
    filenames: list[str], ratio: np.ndarray, *, k: int = 5
) -> tuple[list[tuple[str, float]], list[tuple[str, float]]]:
    if ratio.size != len(filenames):
        raise ValueError("filenames and ratio length mismatch.")
    order = np.argsort(ratio)
    low = [(filenames[i], float(ratio[i])) for i in order[:k]]
    high = [(filenames[i], float(ratio[i])) for i in order[-k:][::-1]]
    return low, high


def _plot(
    *,
    dataset_label: str,
    label_a: str,
    label_b: str,
    ratio: np.ndarray,
    output_path: Path,
) -> None:
    import matplotlib as mpl
    import matplotlib.pyplot as plt

    mpl.rcParams.update(
        {
            "font.family": "serif",
            "mathtext.fontset": "stix",
            "font.size": 10,
            "axes.labelsize": 10,
            "axes.titlesize": 10,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
        }
    )

    fig, ax_hist = plt.subplots(figsize=(6.4, 3.0), constrained_layout=True)

    edges = _hist_edges(ratio)
    ax_hist.hist(
        ratio, bins=edges.tolist(), color="#EEEEEE", edgecolor="black", linewidth=0.5
    )
    mean = float(ratio.mean())
    std = float(ratio.std(ddof=1))
    # ax_hist.axvline(1.0, color="black", linestyle="--", linewidth=1.0)
    # ax_hist.axvline(mean, color="#E45756", linestyle="-", linewidth=1.2)
    ax_hist.axvline(mean - std, color="#E45756", linestyle="--", linewidth=1.0)
    ax_hist.axvline(mean + std, color="#E45756", linestyle="--", linewidth=1.0)
    ax_hist.axvline(mean - 2 * std, color="#F58518", linestyle=":", linewidth=1.0)
    ax_hist.axvline(mean + 2 * std, color="#F58518", linestyle=":", linewidth=1.0)
    ax_hist.set_xlabel(
        f"Cost ratio ({display_scheduler_name(label_a)} / {display_scheduler_name(label_b)})"
    )
    ax_hist.set_ylabel("Count")
    dataset_label_title = dataset_label.replace("_", "-")
    ax_hist.set_title(f"Histogram of BFD/FFDNew cost ratios for {dataset_label_title} dataset")
    ax_hist.grid(True, which="both", linestyle=":", linewidth=0.6, alpha=0.8)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path)
    plt.close(fig)


def _analyze_dataset(
    *,
    results_dir: Path,
    dataset_label: str,
    algo_a: str,
    algo_b: str,
    out_dir: Path,
) -> None:
    label_a, csv_a = resolve_results_csv(results_dir, algo_a)
    label_b, csv_b = resolve_results_csv(results_dir, algo_b)

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
    summary = _summarize(ratio)
    low, high = _top_extremes(filenames, ratio, k=5)

    print(f"=== {dataset_label} ===")
    print(
        f"Comparison: {display_scheduler_name(label_a)} / {display_scheduler_name(label_b)}"
    )
    print(f"N = {summary.n}")
    print(
        "mean={mean:.6f} median={median:.6f} std={std:.6f}".format(
            mean=summary.mean,
            median=summary.median,
            std=summary.std,
        )
    )
    print(
        "min={min:.6f} p1={p1:.6f} p5={p5:.6f} p95={p95:.6f} p99={p99:.6f} max={max:.6f}".format(
            min=summary.min,
            p1=summary.p1,
            p5=summary.p5,
            p95=summary.p95,
            p99=summary.p99,
            max=summary.max,
        )
    )
    print("Lowest ratios:")
    for filename, value in low:
        print(f"  {filename}: {value:.6f}")
    print("Highest ratios:")
    for filename, value in high:
        print(f"  {filename}: {value:.6f}")
    print("")

    out_name = f"eval_cost_ratio_dist_{dataset_label}_{label_a}_vs_{label_b}.svg"
    output_path = out_dir / out_name
    _plot(
        dataset_label=dataset_label,
        label_a=label_a,
        label_b=label_b,
        ratio=ratio,
        output_path=output_path,
    )
    print(f"Wrote: {output_path}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Summarize and plot per-instance cost ratio distributions for paired comparisons."
    )
    parser.add_argument(
        "--eval-root",
        type=Path,
        default=Path("evaluation/raw"),
        help="Root directory containing per-dataset raw evaluation folders.",
    )
    parser.add_argument(
        "--datasets",
        type=str,
        default="balanced,job_heavy,machine_heavy",
        help="Comma-separated dataset folder names under --eval-root.",
    )
    parser.add_argument(
        "--algo-a",
        type=str,
        default="bfd",
        help="Algorithm A (numerator).",
    )
    parser.add_argument(
        "--algo-b",
        type=str,
        default="ffd_new",
        help="Algorithm B (denominator).",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path("images"),
        help="Where to write SVG plots.",
    )
    args = parser.parse_args()

    algo_a = normalize_scheduler_name(args.algo_a)
    algo_b = normalize_scheduler_name(args.algo_b)
    datasets = [item.strip() for item in args.datasets.split(",") if item.strip()]
    if not datasets:
        raise SystemExit("No datasets provided.")

    for dataset in datasets:
        results_dir = (args.eval_root / dataset).resolve()
        if not results_dir.is_dir():
            raise FileNotFoundError(f"Missing dataset directory: {results_dir}")
        _analyze_dataset(
            results_dir=results_dir,
            dataset_label=dataset,
            algo_a=algo_a,
            algo_b=algo_b,
            out_dir=args.out_dir,
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
