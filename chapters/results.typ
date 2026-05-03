= Results <results_section>

This chapter presents the evaluation datasets, metrics, and empirical results for the scheduling algorithms.

== Data

For each dataset, we first present a summary table of the evaluation results for each scheduler algorithm.
We then compare the two best algorithms for the dataset, defined as the two schedulers with the lowest average total cost in the summary table.
This comparison uses a paired two-tailed $t$-test on per-instance total-cost ratios and reports the mean ratio, the $95%$ confidence interval for the mean ratio, the $p$-value, and whether the null hypothesis is rejected.
// The ratio-distribution diagnostics are discussed in the appendix @appendix_data_normality.
Next, we present a plot of the performance profiles for each of the algorithms.
Here, $tau$ is on the $x$-axis, and $rho_s (tau)$ is on the $y$-axis, for each solver $s$.
Finally, we present a table of the performance ratio _"win rate"_ for each algorithm.
This value is, for each algorithm $s$, given by the performance profile function $rho_s (tau)$ at $tau = 1$.
Note here that the sum of the win rates across all algorithms do not sum to $1$.
The reason for this is that multiple algorithms can be tied for certain problem instances.

#let compact_ratio_ttest_rows(rows, strip_bfd_prefix: false) = rows.map(row => {
  let comparison = if strip_bfd_prefix {
    row.at(0).replace("BFD / ", "")
  } else {
    row.at(0)
  }
  let ci_parts = row.at(3).split("-")
  let ci_ratio = (
    str(calc.round(decimal(ci_parts.at(0)), digits: 4)) + "-" + str(calc.round(decimal(ci_parts.at(1)), digits: 4))
  )
  let reject_h0 = if row.at(6) == "REJECT H0" { "Yes" } else { "No" }
  (comparison,) + row.slice(1, 3) + (ci_ratio,) + row.slice(5, 6) + (reject_h0,)
})


=== Balanced dataset

#let summary_data_balanced_dataset = csv("../evaluation/results/balanced/eval_summary_balanced.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 6,
        [*Scheduler*],
        [*Average cost*],
        [*Min cost*],
        [*Max cost*],
        [*Average runtime (sec)*],
        [*Average machine count*],
        ..summary_data_balanced_dataset.flatten(),
      ),
      caption: [Summary of evaluation results for balanced dataset.],
    )
  ])
]

The two best algorithms on this dataset are _BFD_ and _FFDNew_.
Using the paired ratio $t$-test on raw total cost ratios, we fail to reject the null hypothesis at $alpha=0.05$ ($p approx 0.170$), and the mean ratio is close to $1$.

#let ratio_ttest_balanced = compact_ratio_ttest_rows(
  csv("../evaluation/results/balanced/eval_raw_cost_ratio_ttest_balanced.csv").slice(1),
)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 6,
        [*Comparison*],
        [*$n$*],
        [*Mean ratio*],
        [*$95%$ CI*],
        [*$p$-value*],
        [*Reject $H_0$?*],
        ..ratio_ttest_balanced.flatten(),
      ),
      caption: [Paired ratio $t$-test summary for balanced dataset (_BFD_ / _FFDNew_).],
    )
  ])
]

The table below summarizes the pairwise ratio $t$-tests between _BFD_ and the remaining algorithms (excluding _FFDNew_).

#let ratio_ttest_pairwise_balanced = csv(
  "../evaluation/results/balanced/eval_raw_cost_ratio_ttest_pairwise_balanced.csv",
).slice(1)
#let ratio_ttest_pairwise_balanced = compact_ratio_ttest_rows(
  ratio_ttest_pairwise_balanced,
  strip_bfd_prefix: true,
)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 6,
        [*Comparison*],
        [*$n$*],
        [*Mean ratio*],
        [*$95%$ CI*],
        [*$p$-value*],
        [*Reject $H_0$?*],
        ..ratio_ttest_pairwise_balanced.flatten(),
      ),
      caption: [Paired ratio $t$-tests for balanced dataset (_BFD_ / other algorithms except _FFDNew_).],
    )
  ])
]

#align(center)[
  #block(breakable: false, [
    #figure(
      image(
        "../images/eval_performance_profiles_balanced.svg",
        width: 100%,
        height: 50%,
        fit: "contain",
      ),
      caption: [Performance profiles for the balanced dataset.],
    )
  ])
]

#let perf_profiles_balanced = csv("../evaluation/results/balanced/eval_performance_profiles_balanced.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 4,
        [*Scheduler*], [*Wins*], [*Ties*], [*Total*],
        ..perf_profiles_balanced.flatten(),
      ),
      caption: [Performance profile wins for the balanced dataset.],
    )
  ])
]

=== Job-heavy dataset

#let summary_data_job_heavy = csv("../evaluation/results/job_heavy/eval_summary_job_heavy.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 6,
        [*Scheduler*],
        [*Average cost*],
        [*Min cost*],
        [*Max cost*],
        [*Average runtime (sec)*],
        [*Average machine count*],
        ..summary_data_job_heavy.flatten(),
      ),
      caption: [Summary of evaluation results for job-heavy dataset.],
    )
  ])
]

The two best algorithms on this dataset are _BFD_ and _FFDNew_.
Using the paired ratio $t$-test on raw total cost ratios, we reject the null hypothesis at $alpha=0.05$ ($p approx 0.0407$).
The effect is very small since the mean ratio is approximately $1.00044$, meaning that _BFD_ is only slightly more costly than _FFDNew_ on average.

#let ratio_ttest_job_heavy = compact_ratio_ttest_rows(
  csv("../evaluation/results/job_heavy/eval_raw_cost_ratio_ttest_job_heavy.csv").slice(1),
)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 6,
        [*Comparison*],
        [*$n$*],
        [*Mean ratio*],
        [*$95%$ CI*],
        [*$p$-value*],
        [*Reject $H_0$?*],
        ..ratio_ttest_job_heavy.flatten(),
      ),
      caption: [Paired ratio $t$-test summary for job-heavy dataset (_BFD_ / _FFDNew_).],
    )
  ])
]

The table below summarizes the pairwise ratio $t$-tests between _BFD_ and the remaining algorithms (excluding _FFDNew_).

#let ratio_ttest_pairwise_job_heavy = csv(
  "../evaluation/results/job_heavy/eval_raw_cost_ratio_ttest_pairwise_job_heavy.csv",
).slice(1)
#let ratio_ttest_pairwise_job_heavy = compact_ratio_ttest_rows(
  ratio_ttest_pairwise_job_heavy,
  strip_bfd_prefix: true,
)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 6,
        [*Comparison*],
        [*$n$*],
        [*Mean ratio*],
        [*$95%$ CI*],
        [*$p$-value*],
        [*Reject $H_0$?*],
        ..ratio_ttest_pairwise_job_heavy.flatten(),
      ),
      caption: [Paired ratio $t$-tests for job-heavy dataset (_BFD_ / other algorithms except _FFDNew_).],
    )
  ])
]

#align(center)[
  #block(breakable: false, [
    #figure(
      image(
        "../images/eval_performance_profiles_job_heavy.svg",
        width: 100%,
        height: 50%,
        fit: "contain",
      ),
      caption: [Performance profiles for the job-heavy dataset.],
    )
  ])
]

#let perf_profiles_job_heavy = csv("../evaluation/results/job_heavy/eval_performance_profiles_job_heavy.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 4,
        [*Scheduler*], [*Wins*], [*Ties*], [*Total*],
        ..perf_profiles_job_heavy.flatten(),
      ),
      caption: [Performance profile wins for the job-heavy dataset.],
    )
  ])
]

=== Machine-heavy dataset

#let summary_data_machine_heavy = csv("../evaluation/results/machine_heavy/eval_summary_machine_heavy.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 6,
        [*Scheduler*],
        [*Average cost*],
        [*Min cost*],
        [*Max cost*],
        [*Average runtime (sec)*],
        [*Average machine count*],
        ..summary_data_machine_heavy.flatten(),
      ),
      caption: [Summary of evaluation results for machine-heavy dataset.],
    )
  ])
]

The two best algorithms on this dataset are _BFD_ and _FFDNew_.
Using the paired ratio $t$-test on raw total cost ratios, we fail to reject the null hypothesis at $alpha=0.05$ ($p approx 0.522$), and the mean ratio is close to $1$.

#let ratio_ttest_machine_heavy = compact_ratio_ttest_rows(
  csv("../evaluation/results/machine_heavy/eval_raw_cost_ratio_ttest_machine_heavy.csv").slice(
    1,
  ),
)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 6,
        [*Comparison*],
        [*$n$*],
        [*Mean ratio*],
        [*$95%$ CI*],
        [*$p$-value*],
        [*Reject $H_0$?*],
        ..ratio_ttest_machine_heavy.flatten(),
      ),
      caption: [Paired ratio $t$-test summary for machine-heavy dataset (_BFD_ / _FFDNew_).],
    )
  ])
]

The table below summarizes the pairwise ratio $t$-tests between _BFD_ and the remaining algorithms (excluding _FFDNew_).

#let ratio_ttest_pairwise_machine_heavy = csv(
  "../evaluation/results/machine_heavy/eval_raw_cost_ratio_ttest_pairwise_machine_heavy.csv",
).slice(1)
#let ratio_ttest_pairwise_machine_heavy = compact_ratio_ttest_rows(
  ratio_ttest_pairwise_machine_heavy,
  strip_bfd_prefix: true,
)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 6,
        [*Comparison*],
        [*$n$*],
        [*Mean ratio*],
        [*$95%$ CI*],
        [*$p$-value*],
        [*Reject $H_0$?*],
        ..ratio_ttest_pairwise_machine_heavy.flatten(),
      ),
      caption: [Paired ratio $t$-tests for machine-heavy dataset (_BFD_ / other algorithms except _FFDNew_).],
    )
  ])
]

#align(center)[
  #block(breakable: false, [
    #figure(
      image(
        "../images/eval_performance_profiles_machine_heavy.svg",
        width: 100%,
        height: 50%,
        fit: "contain",
      ),
      caption: [Performance profiles for the machine-heavy dataset.],
    )
  ])
]

#let perf_profiles_machine_heavy = csv(
  "../evaluation/results/machine_heavy/eval_performance_profiles_machine_heavy.csv",
).slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 4,
        [*Scheduler*], [*Wins*], [*Ties*], [*Total*],
        ..perf_profiles_machine_heavy.flatten(),
      ),
      caption: [Performance profile wins for the machine-heavy dataset.],
    )
  ])
]
