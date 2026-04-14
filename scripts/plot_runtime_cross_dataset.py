"""
Summarize and plot per-instance runtime_sec across datasets and algorithms.

The figure is intended for the thesis runtime discussion: it shows each
algorithm's mean runtime with a 95% confidence interval for each dataset.
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
    load_runtime_seconds,
    normalize_scheduler_name,
    parse_scheduler_list,
)

SIG_FIGS = 4


@dataclass(frozen=True)
class RuntimeSummary:
    dataset: str
    algorithm: str
    n: int
    mean_runtime_sec: float
    std_runtime_sec: float
    ci_low_runtime_sec: float
    ci_high_runtime_sec: float


def _fmt_sig(value: float) -> str:
    if not np.isfinite(value):
        return str(value)
    return f"{value:.{SIG_FIGS}g}"


def _discover_algorithms(raw_root: Path, dataset: str) -> list[str]:
    dataset_dir = raw_root / dataset
    if not dataset_dir.is_dir():
        raise FileNotFoundError(f"Missing dataset directory: {dataset_dir}")

    algorithms = sorted(
        normalize_scheduler_name(path.stem.removeprefix("eval_"))
        for path in dataset_dir.glob("eval_*.csv")
        if path.is_file()
    )
    if not algorithms:
        raise FileNotFoundError(f"No eval_*.csv files found in {dataset_dir}")
    return algorithms


def _summarize_runtime(values: np.ndarray) -> tuple[float, float, float, float]:
    if values.size < 2:
        raise ValueError("Need at least two runtime values to summarize.")
    try:
        from scipy import stats
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "SciPy is required for this script (dependency: scipy)."
        ) from exc

    mean = float(values.mean())
    std = float(values.std(ddof=1))
    se = std / sqrt(values.size)
    t_crit = float(stats.t.ppf(0.975, values.size - 1))
    half_width = t_crit * se
    return mean, std, mean - half_width, mean + half_width


def _load_summaries(
    *, raw_root: Path, datasets: list[str], algorithms: list[str]
) -> list[RuntimeSummary]:
    rows: list[RuntimeSummary] = []
    for dataset in datasets:
        dataset_dir = raw_root / dataset
        if not dataset_dir.is_dir():
            raise FileNotFoundError(f"Missing dataset directory: {dataset_dir}")
        for algorithm in algorithms:
            csv_path = dataset_dir / f"eval_{algorithm}.csv"
            if not csv_path.is_file():
                raise FileNotFoundError(
                    f"Missing CSV for {dataset}:{algorithm}: {csv_path}"
                )
            runtime_values = load_runtime_seconds(csv_path, duplicate_policy="min")
            values = np.asarray(list(runtime_values.values()), dtype=float)
            if not np.all(np.isfinite(values)):
                raise ValueError(f"Found non-finite runtime_sec values in {csv_path}")
            mean, std, ci_low, ci_high = _summarize_runtime(values)
            rows.append(
                RuntimeSummary(
                    dataset=dataset,
                    algorithm=algorithm,
                    n=int(values.size),
                    mean_runtime_sec=mean,
                    std_runtime_sec=std,
                    ci_low_runtime_sec=ci_low,
                    ci_high_runtime_sec=ci_high,
                )
            )
    return rows


def _write_summary_csv(path: Path, rows: list[RuntimeSummary]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "dataset",
                "algorithm",
                "n",
                "mean_runtime_sec",
                "std_runtime_sec",
                "ci_low_runtime_sec",
                "ci_high_runtime_sec",
            ],
        )
        writer.writeheader()
        for row in rows:
            writer.writerow(
                {
                    "dataset": row.dataset,
                    "algorithm": row.algorithm,
                    "n": row.n,
                    "mean_runtime_sec": _fmt_sig(row.mean_runtime_sec),
                    "std_runtime_sec": _fmt_sig(row.std_runtime_sec),
                    "ci_low_runtime_sec": _fmt_sig(row.ci_low_runtime_sec),
                    "ci_high_runtime_sec": _fmt_sig(row.ci_high_runtime_sec),
                }
            )


def _plot(rows: list[RuntimeSummary], output_path: Path) -> None:
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
            "legend.fontsize": 9,
        }
    )

    grouped: dict[str, list[RuntimeSummary]] = {}
    for row in rows:
        grouped.setdefault(row.algorithm, []).append(row)

    algorithms = sorted(
        grouped,
        key=lambda algorithm: np.mean(
            [entry.mean_runtime_sec for entry in grouped[algorithm]]
        ),
    )
    datasets = sorted({row.dataset for row in rows})
    colors = {
        "balanced": "#4C78A8",
        "job_heavy": "#F58518",
        "machine_heavy": "#54A24B",
    }
    markers = {
        "balanced": "o",
        "job_heavy": "s",
        "machine_heavy": "D",
    }
    offsets = {
        "balanced": -0.24,
        "job_heavy": 0.0,
        "machine_heavy": 0.24,
    }
    dataset_labels = {
        "balanced": "Balanced",
        "job_heavy": "Job-heavy",
        "machine_heavy": "Machine-heavy",
    }

    fig, ax = plt.subplots(figsize=(7.2, 4.2), constrained_layout=True)
    base_positions = np.arange(len(algorithms))

    for dataset in datasets:
        dataset_rows = {row.algorithm: row for row in rows if row.dataset == dataset}
        means_ms = [
            dataset_rows[algorithm].mean_runtime_sec * 1000.0
            for algorithm in algorithms
        ]
        lower_ms = [
            (
                dataset_rows[algorithm].mean_runtime_sec
                - dataset_rows[algorithm].ci_low_runtime_sec
            )
            * 1000.0
            for algorithm in algorithms
        ]
        upper_ms = [
            (
                dataset_rows[algorithm].ci_high_runtime_sec
                - dataset_rows[algorithm].mean_runtime_sec
            )
            * 1000.0
            for algorithm in algorithms
        ]
        y_positions = base_positions + offsets.get(dataset, 0.0)
        ax.errorbar(
            means_ms,
            y_positions,
            xerr=[lower_ms, upper_ms],
            fmt=markers.get(dataset, "o"),
            color=colors.get(dataset, "black"),
            markersize=4.2,
            capsize=2.5,
            elinewidth=1.0,
            linewidth=1.0,
            label=dataset_labels.get(dataset, dataset.replace("_", "-").title()),
        )

    ax.set_yticks(base_positions)
    ax.set_yticklabels([display_scheduler_name(name) for name in algorithms])
    ax.set_xlabel("Mean runtime (ms)")
    ax.set_ylabel("Algorithm")
    ax.grid(True, axis="x", linestyle=":", linewidth=0.7, alpha=0.8)
    ax.set_axisbelow(True)
    ax.legend(loc="lower right", frameon=False)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path)
    plt.close(fig)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize runtime_sec across datasets and create a cross-dataset SVG plot."
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
        help="Comma-separated dataset names to summarize.",
    )
    parser.add_argument(
        "--algorithms",
        type=str,
        default=None,
        help="Optional comma-separated algorithm names. Defaults to auto-discovery.",
    )
    parser.add_argument(
        "--summary-csv",
        type=Path,
        default=Path(
            "evaluation/results/cross_dataset/eval_runtime_summary_cross_dataset.csv"
        ),
        help="Where to write the runtime summary CSV.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("images/eval_runtime_cross_dataset.svg"),
        help="Where to write the runtime SVG plot.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datasets = parse_scheduler_list(args.datasets)
    if len(datasets) < 2:
        raise ValueError("Provide at least two datasets in --datasets.")

    if args.algorithms:
        algorithms = [
            normalize_scheduler_name(name)
            for name in parse_scheduler_list(args.algorithms)
        ]
    else:
        algorithms = _discover_algorithms(args.raw_root, datasets[0])

    rows = _load_summaries(
        raw_root=args.raw_root,
        datasets=datasets,
        algorithms=algorithms,
    )
    _write_summary_csv(args.summary_csv, rows)
    _plot(rows, args.output)
    print(f"Wrote summary CSV: {args.summary_csv}")
    print(f"Wrote figure: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
