from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np

from eval_utils import (
    ensure_matching_filenames,
    load_total_costs,
    resolve_results_csv,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Plot a histogram of paired per-instance total_cost differences "
            "d_i = cost(A)_i - cost(B)_i from eval_*.csv files."
        )
    )
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=Path("eval_results"),
        help="Directory containing per-scheduler CSVs (eval_*.csv).",
    )
    parser.add_argument(
        "--a",
        type=str,
        required=True,
        help="Algorithm/scheduler A (d = A - B).",
    )
    parser.add_argument(
        "--b",
        type=str,
        required=True,
        help="Algorithm/scheduler B (d = A - B).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Output image path (default: images/eval_diff_hist_{a}_minus_{b}.svg).",
    )
    parser.add_argument(
        "--show",
        action="store_true",
        help="Show the plot interactively (default: off).",
    )
    parser.add_argument(
        "--no-save",
        action="store_true",
        help="Do not save the plot to disk (default: off).",
    )
    parser.add_argument(
        "--bins",
        type=int,
        default=None,
        help="Explicit number of histogram bins (overrides --bin-method).",
    )
    parser.add_argument(
        "--bin-method",
        type=str,
        choices=["fd", "sturges", "sqrt", "scott", "auto"],
        default="fd",
        help="Histogram bin selection rule (default: fd).",
    )
    parser.add_argument(
        "--density",
        action="store_true",
        help="Plot density instead of counts (default: off).",
    )
    parser.add_argument(
        "--title",
        type=str,
        default=None,
        help="Optional plot title override.",
    )
    return parser.parse_args()


def _default_output_path(a: str, b: str) -> Path:
    return Path("images") / f"eval_diff_hist_{a}_minus_{b}.svg"


def _summary(differences: np.ndarray) -> str:
    if differences.size == 0:
        return "N=0"
    mean = float(differences.mean())
    median = float(np.median(differences))
    std = float(differences.std(ddof=1)) if differences.size >= 2 else 0.0
    min_val = float(differences.min())
    max_val = float(differences.max())
    fraction_negative = float((differences < 0).mean())
    return (
        f"N={differences.size}, mean={mean:.6g}, median={median:.6g}, std={std:.6g}, "
        f"min={min_val:.6g}, max={max_val:.6g}, frac(d<0)={fraction_negative:.3f}"
    )


def _compute_bin_edges(
    differences: np.ndarray, *, bins: int | None, method: str
) -> np.ndarray:
    if differences.size == 0:
        raise ValueError("No paired instances to plot.")
    if bins is not None:
        if bins <= 0:
            raise ValueError("--bins must be a positive integer.")
        edges = np.histogram_bin_edges(differences, bins=bins)
        return edges

    edges = np.histogram_bin_edges(differences, bins=method)
    if edges.size < 2 or not np.all(np.isfinite(edges)):
        edges = np.histogram_bin_edges(differences, bins="sturges")
    return edges


def main() -> None:
    args = parse_args()

    algo_a, csv_a = resolve_results_csv(args.results_dir, args.a)
    algo_b, csv_b = resolve_results_csv(args.results_dir, args.b)

    if not csv_a.is_file():
        raise FileNotFoundError(f"Missing results file for {algo_a}: {csv_a}")
    if not csv_b.is_file():
        raise FileNotFoundError(f"Missing results file for {algo_b}: {csv_b}")

    costs_a = load_total_costs(csv_a, duplicate_policy="min")
    costs_b = load_total_costs(csv_b, duplicate_policy="min")
    filenames = ensure_matching_filenames(
        costs_a,
        costs_b,
        label_a=algo_a,
        label_b=algo_b,
    )

    differences = np.asarray(
        [costs_a[name] - costs_b[name] for name in filenames], dtype=float
    )
    print(f"{algo_a} vs {algo_b}: {_summary(differences)}")

    bin_edges = _compute_bin_edges(differences, bins=args.bins, method=args.bin_method)

    import matplotlib as mpl
    import matplotlib.pyplot as plt

    mpl.rcParams.update(
        {
            "font.family": "serif",
            "mathtext.fontset": "stix",
            "font.size": 10,
            "axes.labelsize": 10,
            "legend.fontsize": 9,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
        }
    )

    fig, ax = plt.subplots()
    ax.hist(
        differences,
        bins=bin_edges.tolist(),
        density=args.density,
        color="#4c72b0",
        edgecolor="white",
    )
    ax.axvline(0.0, color="black", linewidth=1.0, linestyle="--", label="d=0")
    ax.axvline(
        float(differences.mean()),
        color="black",
        linewidth=1.0,
        linestyle=":",
        label="mean(d)",
    )

    ax.set_xlabel(f"total_cost_{algo_a} − total_cost_{algo_b}")
    ax.set_ylabel("Density" if args.density else "Count")
    ax.set_title(args.title or f"Cost differences ({algo_a} − {algo_b})")
    ax.grid(True, which="both", linestyle=":", linewidth=0.6)
    ax.legend()
    fig.tight_layout()

    output_path = args.output or _default_output_path(algo_a, algo_b)
    if not args.no_save:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(output_path)
        print(f"Wrote plot to {output_path}")

    if args.show:
        plt.show()

    plt.close(fig)


if __name__ == "__main__":
    main()
