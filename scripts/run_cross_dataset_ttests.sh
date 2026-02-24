#!/usr/bin/env bash

set -euo pipefail

RAW_ROOT="${RAW_ROOT:-evaluation/raw}"
ALGORITHM="${ALGORITHM:-bfd}"
ALPHA="${ALPHA:-0.05}"
TESTS="${TESTS:-machine_heavy<balanced,job_heavy>balanced}"
OUTPUT_CSV="${OUTPUT_CSV:-evaluation/results/cross_dataset/eval_raw_cost_ttest_bfd_cross_dataset.csv}"

echo "Running cross-dataset one-tailed paired t-tests"
echo "Algorithm: ${ALGORITHM}"
echo "Raw root: ${RAW_ROOT}"
echo "Tests: ${TESTS}"
echo "Alpha: ${ALPHA}"
echo "Output CSV: ${OUTPUT_CSV}"

uv run python scripts/raw_cost_dataset_ttest_one_sided.py \
  --algorithm "${ALGORITHM}" \
  --raw-root "${RAW_ROOT}" \
  --tests "${TESTS}" \
  --alpha "${ALPHA}" \
  --stats-csv "${OUTPUT_CSV}"

echo "Done. Wrote: ${OUTPUT_CSV}"
