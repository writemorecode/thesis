from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np

from problem_generation import (
    DEFAULT_BASE_CAPACITY,
    DEFAULT_BASE_DEMAND,
    RESOURCE_COUNT,
    generate_dataset_instances,
    write_dataset,
    write_dataset_parameters_csv,
)

NUM_INSTANCES = 100


def parse_args():
    parser = argparse.ArgumentParser(description="Run scheduler.")
    parser.add_argument("--seed", type=int, help="Seed for random instance generation.")
    parser.add_argument(
        "--iterations",
        type=int,
        default=50,
        help="Number of algorithm iterations.",
    )
    parser.add_argument(
        "--K-min",
        dest="K_min",
        type=int,
        default=RESOURCE_COUNT,
        help="Minimum value for K range.",
    )
    parser.add_argument(
        "--K-max",
        dest="K_max",
        type=int,
        default=RESOURCE_COUNT,
        help="Maximum value for K range.",
    )
    parser.add_argument(
        "--base-capacity-cpu",
        dest="base_capacity_cpu",
        type=int,
        default=DEFAULT_BASE_CAPACITY["cpu"],
        help="Base CPU capacity value.",
    )
    parser.add_argument(
        "--base-capacity-memory",
        dest="base_capacity_memory",
        type=int,
        default=DEFAULT_BASE_CAPACITY["memory"],
        help="Base memory capacity value.",
    )
    parser.add_argument(
        "--base-capacity-disk",
        dest="base_capacity_disk",
        type=int,
        default=DEFAULT_BASE_CAPACITY["disk"],
        help="Base disk capacity value.",
    )
    parser.add_argument(
        "--base-capacity-io",
        dest="base_capacity_io",
        type=int,
        default=DEFAULT_BASE_CAPACITY["io"],
        help="Base I/O capacity value.",
    )
    parser.add_argument(
        "--base-demand-cpu",
        dest="base_demand_cpu",
        type=int,
        default=DEFAULT_BASE_DEMAND["cpu"],
        help="Base CPU demand value.",
    )
    parser.add_argument(
        "--base-demand-memory",
        dest="base_demand_memory",
        type=int,
        default=DEFAULT_BASE_DEMAND["memory"],
        help="Base memory demand value.",
    )
    parser.add_argument(
        "--base-demand-disk",
        dest="base_demand_disk",
        type=int,
        default=DEFAULT_BASE_DEMAND["disk"],
        help="Base disk demand value.",
    )
    parser.add_argument(
        "--base-demand-io",
        dest="base_demand_io",
        type=int,
        default=DEFAULT_BASE_DEMAND["io"],
        help="Base I/O demand value.",
    )
    parser.add_argument(
        "--J-min",
        dest="J_min",
        type=int,
        default=10,
        help="Minimum value for J range.",
    )
    parser.add_argument(
        "--J-max",
        dest="J_max",
        type=int,
        default=15,
        help="Maximum value for J range.",
    )
    parser.add_argument(
        "--M-min",
        dest="M_min",
        type=int,
        default=5,
        help="Minimum value for M range.",
    )
    parser.add_argument(
        "--M-max",
        dest="M_max",
        type=int,
        default=10,
        help="Maximum value for M range.",
    )
    parser.add_argument(
        "--T-min",
        dest="T_min",
        type=int,
        default=100,
        help="Minimum value for T range.",
    )
    parser.add_argument(
        "--T-max",
        dest="T_max",
        type=int,
        default=200,
        help="Maximum value for T range.",
    )
    parser.add_argument(
        "--output-dir",
        dest="output_dir",
        default="dataset",
        help="Output directory for the generated dataset.",
    )
    args = parser.parse_args()

    if args.K_min != RESOURCE_COUNT or args.K_max != RESOURCE_COUNT:
        parser.error(
            f"K is fixed to {RESOURCE_COUNT}; set --K-min and --K-max to {RESOURCE_COUNT}."
        )
    return args


def generate_instances(args, rng: np.random.Generator):
    base_capacity = {
        "cpu": args.base_capacity_cpu,
        "memory": args.base_capacity_memory,
        "disk": args.base_capacity_disk,
        "io": args.base_capacity_io,
    }
    base_demand = {
        "cpu": args.base_demand_cpu,
        "memory": args.base_demand_memory,
        "disk": args.base_demand_disk,
        "io": args.base_demand_io,
    }
    return generate_dataset_instances(
        num_instances=NUM_INSTANCES,
        K_range=(args.K_min, args.K_max),
        J_range=(args.J_min, args.J_max),
        M_range=(args.M_min, args.M_max),
        T_range=(args.T_min, args.T_max),
        base_capacity=base_capacity,
        base_demand=base_demand,
        rng=rng,
    )


def write_instances(instances, output_dir: str):
    return write_dataset(instances, dataset_dir=output_dir)


def main():
    args = parse_args()

    seed = args.seed if args.seed is not None else np.random.randint(1_000_000)
    args.seed = seed
    print(f"SEED: {seed}")
    rng = np.random.default_rng(seed)

    instances = generate_instances(args, rng)
    _ = write_instances(instances, args.output_dir)
    write_dataset_parameters_csv(
        {"num_instances": NUM_INSTANCES, **vars(args)},
        dataset_dir=Path(args.output_dir),
    )


if __name__ == "__main__":
    main()
