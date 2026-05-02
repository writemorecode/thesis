#!/usr/bin/env bash

set -euo pipefail

SCHEDULERS="${SCHEDULERS:-ffd_l2,ffd,ffd_sum,ffd_max,ffd_prod,peak_demand,ffd_new,bfd}"
SEED="${SEED:-5000}"
EVAL_ROOT="${EVAL_ROOT:-evaluation}"
IMAGE_DIR="${IMAGE_DIR:-images}"

evaluate_dataset() {
  local name="$1"
  local k_min="$2"
  local k_max="$3"
  local j_min="$4"
  local j_max="$5"
  local m_min="$6"
  local m_max="$7"
  local t_min="$8"
  local t_max="$9"

  local dataset_dir="${EVAL_ROOT}/datasets/${name}"
  local raw_dir="${EVAL_ROOT}/raw/${name}"
  local results_dir="${EVAL_ROOT}/results/${name}"

  mkdir -p "${dataset_dir}" "${raw_dir}" "${results_dir}"

  echo "=== Dataset: ${name} (K=${k_min}-${k_max}, J=${j_min}-${j_max}, M=${m_min}-${m_max}, T=${t_min}-${t_max}) ==="
  uv run python scripts/generate_dataset.py \
    --output-dir "${dataset_dir}" \
    --seed "${SEED}" \
    --K-min "${k_min}" --K-max "${k_max}" \
    --J-min "${j_min}" --J-max "${j_max}" \
    --M-min "${m_min}" --M-max "${m_max}" \
    --T-min "${t_min}" --T-max "${t_max}"

  echo "Evaluating schedulers..."
  uv run python scripts/eval.py \
    --dataset "${dataset_dir}" \
    --schedulers "${SCHEDULERS}" \
    --output-dir "${raw_dir}" \
    --seed "${SEED}"

  echo "Running per-scheduler summary..."
  uv run python scripts/eval_multi_summary.py \
    --results-dir "${raw_dir}" \
    --output "${results_dir}/eval_summary_${name}.csv" \
    --verbose

  echo "Running paired ratio t-test on raw costs (BFD vs FFDNew)..."
  uv run python scripts/raw_ratio_ttest.py \
    --results-dir "${raw_dir}" \
    --algo-a "bfd" \
    --algo-b "ffd_new" \
    --stats-csv "${results_dir}/eval_raw_cost_ratio_ttest_${name}.csv"

  echo "Running Shapiro-Wilk test on raw cost ratios (BFD / FFDNew)..."
  uv run python scripts/raw_cost_ratio_shapiro.py \
    --results-dir "${raw_dir}" \
    --algo-a "bfd" \
    --algo-b "ffd_new" \
    --stats-csv "${results_dir}/eval_raw_cost_ratio_shapiro.csv"

  echo "Running paired ratio t-tests on raw costs (BFD vs others)..."
  local pairwise_ratio_ttest_csv="${results_dir}/eval_raw_cost_ratio_ttest_pairwise_${name}.csv"
  cat > "${pairwise_ratio_ttest_csv}" <<'EOF'
comparison,n,mean_ratio,ci_ratio,t_statistic,p_value,decision
EOF

  for scheduler in ${SCHEDULERS//,/ }; do
    if [[ "${scheduler}" == "bfd" || "${scheduler}" == "ffd_new" ]]; then
      continue
    fi
    local pair_output_csv="${results_dir}/eval_raw_cost_ratio_ttest_bfd_vs_${scheduler}_${name}.csv"
    uv run python scripts/raw_ratio_ttest.py \
      --results-dir "${raw_dir}" \
      --algo-a "bfd" \
      --algo-b "${scheduler}" \
      --stats-csv "${pair_output_csv}"
    tail -n +2 "${pair_output_csv}" >> "${pairwise_ratio_ttest_csv}"
  done

  echo "Running paired ratio t-test on raw machine counts (BFD vs FFDMax)..."
  uv run python scripts/raw_machines_ratio_ttest.py \
    --raw-root "${EVAL_ROOT}/raw" \
    --datasets "${name}" \
    --algo-a "bfd" \
    --algo-b "ffd_max" \
    --stats-root "${EVAL_ROOT}/results"

  echo "Running performance profiles for schedulers..."
  local perf_profile_csv="${results_dir}/eval_performance_profiles_${name}.csv"
  local perf_profile_svg="${results_dir}/eval_performance_profiles_${name}.svg"
  local chapter_plot_svg="${IMAGE_DIR}/eval_performance_profiles_${name}.svg"

  uv run python scripts/performance_profile.py \
    --results-dir "${raw_dir}" \
    --schedulers "${SCHEDULERS}" \
    --output "${perf_profile_csv}" \
    --plot-filename "${perf_profile_svg}" \
    --verbose

  if [[ ! -s "${perf_profile_svg}" ]]; then
    echo "Failed to generate SVG performance profile plot: ${perf_profile_svg}"
    return 1
  fi

  mkdir -p "${IMAGE_DIR}"
  cp "${perf_profile_svg}" "${chapter_plot_svg}"
  echo "Wrote performance profile plot: ${perf_profile_svg}"
  echo "Copied performance profile plot for thesis chapter: ${chapter_plot_svg}"

}

mkdir -p "${EVAL_ROOT}"
mkdir -p "${IMAGE_DIR}"

# name Kmin Kmax Jmin Jmax Mmin Mmax Tmin Tmax
DATASET_CONFIGS=(
  "balanced         4 4 6 8 6 8 100 200"
  "job_heavy        4 4 12 16 6 8 100 200"
  "machine_heavy    4 4 6 8 12 16 100 200"
)

while read -r name kmin kmax jmin jmax mmin mmax tmin tmax; do
  evaluate_dataset "${name}" "${kmin}" "${kmax}" "${jmin}" "${jmax}" "${mmin}" "${mmax}" "${tmin}" "${tmax}"
done < <(printf '%s\n' "${DATASET_CONFIGS[@]}")

echo "Running cost ratio distribution plots..."
uv run python scripts/plot_cost_ratio_distributions.py \
  --eval-root "${EVAL_ROOT}/raw" \
  --out-dir "${IMAGE_DIR}"

echo "Plotting cross-dataset runtime summary..."
uv run python scripts/plot_runtime_cross_dataset.py \
  --raw-root "${EVAL_ROOT}/raw" \
  --datasets "balanced,job_heavy,machine_heavy" \
  --algorithms "${SCHEDULERS}" \
  --summary-csv "${EVAL_ROOT}/results/cross_dataset/eval_runtime_summary_cross_dataset.csv" \
  --output "${IMAGE_DIR}/eval_runtime_cross_dataset.svg"
