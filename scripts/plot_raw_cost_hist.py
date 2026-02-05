from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np

from eval_utils import (
    display_scheduler_name,
    load_total_costs,
    resolve_results_csv,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Plot a histogram of raw per-instance total_cost values from an eval_*.csv "
            "file for a single algorithm/scheduler."
        )
    )
    parser.add_argument(
        "--algorithm",
        "--scheduler",
        dest="algorithm",
        type=str,
        required=True,
        help="Algorithm/scheduler name (e.g. ffd, bfd, peak_demand).",
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
        "--output",
        type=Path,
        default=None,
        help="Output image path (default: images/eval_cost_hist_{dataset}_{algo}.svg).",
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
        "--log-x",
        action="store_true",
        help="Use a log10 x-axis (requires all plotted costs to be > 0).",
    )
    parser.add_argument(
        "--title",
        type=str,
        default=None,
        help="Optional plot title override.",
    )
    return parser.parse_args()


def _resolve_results_dir(args: argparse.Namespace) -> tuple[Path, str | None]:
    if not args.dataset:
        return args.results_dir, None

    dataset_path = Path(args.dataset)
    if dataset_path.is_dir():
        return dataset_path, dataset_path.name

    return args.raw_root / args.dataset, args.dataset


def _default_output_path(dataset: str | None, algo: str) -> Path:
    if dataset:
        return Path("images") / f"eval_cost_hist_{dataset}_{algo}.svg"
    return Path("images") / f"eval_cost_hist_{algo}.svg"


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


def _compute_bin_edges(
    values: np.ndarray, *, bins: int | None, method: str
) -> np.ndarray:
    if values.size == 0:
        raise ValueError("No instances to plot.")
    if bins is not None:
        if bins <= 0:
            raise ValueError("--bins must be a positive integer.")
        edges = np.histogram_bin_edges(values, bins=bins)
        return edges

    edges = np.histogram_bin_edges(values, bins=method)
    if edges.size < 2 or not np.all(np.isfinite(edges)):
        edges = np.histogram_bin_edges(values, bins="sturges")
    return edges


def _normal_pdf(x: np.ndarray, mean: float, variance: float) -> np.ndarray:
    return np.exp(-0.5 * ((x - mean) ** 2) / variance) / np.sqrt(2.0 * np.pi * variance)


def main() -> None:
    args = parse_args()

    results_dir, dataset_label = _resolve_results_dir(args)
    algo, csv_path = resolve_results_csv(results_dir, args.algorithm)
    if not csv_path.is_file():
        raise FileNotFoundError(f"Missing results file for {algo}: {csv_path}")

    costs_by_file = load_total_costs(csv_path, duplicate_policy="min")
    values = np.asarray(list(costs_by_file.values()), dtype=float)

    if args.log_x:
        values = values[values > 0]
        if values.size == 0:
            raise ValueError("--log-x requires at least one positive cost value.")

    mean = float(values.mean())
    median = float(np.median(values))
    variance = float(values.var(ddof=0)) if values.size >= 2 else 0.0

    print(f"{algo} ({dataset_label or results_dir}): {_summary(values)}")

    bin_edges = _compute_bin_edges(values, bins=args.bins, method=args.bin_method)

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
        values,
        bins=bin_edges.tolist(),
        density=args.density,
        color="#55a868",
        edgecolor="white",
    )
    ax.axvline(
        mean,
        color="black",
        linewidth=1.0,
        linestyle=":",
        label="mean",
    )
    ax.axvline(
        median,
        color="black",
        linewidth=1.0,
        linestyle="--",
        label="median",
    )

    if variance > 0:
        x_min = float(bin_edges[0])
        x_max = float(bin_edges[-1])
        if x_min == x_max:
            x_min -= 1.0
            x_max += 1.0
        if args.log_x:
            x_min = max(x_min, np.finfo(float).tiny)
            x_grid = np.logspace(np.log10(x_min), np.log10(x_max), 400)
        else:
            x_grid = np.linspace(x_min, x_max, 400)

        pdf = _normal_pdf(x_grid, mean, variance)
        pdf_label = "Normal PDF"
        if not args.density:
            bin_widths = np.diff(bin_edges)
            if bin_widths.size > 0:
                pdf = pdf * values.size * float(bin_widths.mean())
                pdf_label = "Normal PDF (scaled)"

        ax.plot(
            x_grid,
            pdf,
            color="#4c72b0",
            linewidth=1.5,
            label=pdf_label,
        )
    else:
        print("Variance is zero; skipping normal PDF overlay.")

    if args.log_x:
        ax.set_xscale("log")
        xlabel = "total_cost (log scale)"
    else:
        xlabel = "total_cost"

    display_name = display_scheduler_name(algo)
    title = args.title
    if title is None:
        if dataset_label:
            title = f"Raw costs: {display_name} ({dataset_label})"
        else:
            title = f"Raw costs: {display_name}"

    ax.set_xlabel(xlabel)
    ax.set_ylabel("Density" if args.density else "Count")
    ax.set_title(title)
    ax.grid(True, which="both", linestyle=":", linewidth=0.6)
    ax.legend()
    fig.tight_layout()

    output_path = args.output or _default_output_path(dataset_label, algo)
    if not args.no_save:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(output_path)
        print(f"Wrote plot to {output_path}")

    if args.show:
        plt.show()

    plt.close(fig)


if __name__ == "__main__":
    main()
