#!/usr/bin/env bash

set -euo pipefail

SCHEDULERS="${SCHEDULERS:-ffd_l2,ffd,ffd_sum,ffd_max,ffd_prod,peak_demand,ffd_new,bfd}"
SEED="${SEED:-5000}"
EVAL_ROOT="${EVAL_ROOT:-evaluation}"

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
  cp "${results_dir}/eval_summary_${name}.csv" "data/eval_summary_${name}.csv"

  echo "Running paired log-ratio t-test (BFD vs FFDNew)..."
  local dataset_label="${name}"
  case "${name}" in
    balanced) dataset_label="Balanced" ;;
    job_heavy) dataset_label="Job-heavy" ;;
    machine_heavy) dataset_label="Machine-heavy" ;;
  esac
  uv run python scripts/log_ratio_ttest.py \
    --dataset-name "${dataset_label}" \
    --results-dir "${raw_dir}" \
    --algo-a "bfd" \
    --algo-b "ffd_new" \
    --stats-csv "${results_dir}/eval_log_ratio_ttest_${name}.csv"
  cp "${results_dir}/eval_log_ratio_ttest_${name}.csv" "data/eval_log_ratio_ttest_${name}.csv"

  echo "Running performance profiles for schedulers..."
  local perf_profile_csv="${results_dir}/eval_performance_profiles_${name}.csv"
  local perf_profile_svg="${results_dir}/eval_performance_profiles_${name}.svg"
  local perf_profile_png="${results_dir}/eval_performance_profiles_${name}.png"
  local plot_file=""

  if uv run python scripts/performance_profile.py \
    --results-dir "${raw_dir}" \
    --schedulers "${SCHEDULERS}" \
    --output "${perf_profile_csv}" \
    --plot-filename "${perf_profile_svg}" \
    --verbose; then
    if [[ -s "${perf_profile_svg}" ]]; then
      echo "Wrote performance profile plot: ${perf_profile_svg}"
      plot_file="${perf_profile_svg}"
    fi
    if [[ -z "${plot_file}" ]]; then
      echo "SVG plot command succeeded but '${perf_profile_svg}' is missing/empty; falling back to PNG."
    fi
  else
    echo "Failed to generate SVG performance profile plot; falling back to PNG."
  fi

  if [[ -z "${plot_file}" ]]; then
    uv run python scripts/performance_profile.py \
      --results-dir "${raw_dir}" \
      --schedulers "${SCHEDULERS}" \
      --output "${perf_profile_csv}" \
      --plot-filename "${perf_profile_png}" \
      --verbose

    if [[ ! -s "${perf_profile_png}" ]]; then
      echo "Failed to generate performance profile plot (SVG and PNG both unavailable)."
      return 1
    fi
    echo "Wrote performance profile plot: ${perf_profile_png}"
    plot_file="${perf_profile_png}"
  fi

  cp "${perf_profile_csv}" "data/eval_performance_profiles_${name}.csv"
}

mkdir -p "${EVAL_ROOT}"

# name Kmin Kmax Jmin Jmax Mmin Mmax Tmin Tmax
DATASET_CONFIGS=(
  "balanced     3 6 12 16 12 16 100 200"
  "job_heavy    3 6 16 24  8 12 100 200"
  "machine_heavy 3 6  8 12 16 24 100 200"
)

while read -r name kmin kmax jmin jmax mmin mmax tmin tmax; do
  evaluate_dataset "${name}" "${kmin}" "${kmax}" "${jmin}" "${jmax}" "${mmin}" "${mmax}" "${tmin}" "${tmax}"
done < <(printf '%s\n' "${DATASET_CONFIGS[@]}")
