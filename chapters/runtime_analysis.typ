== Execution Time Analysis <results_runtime_section>

We measured the execution time for each algorithm on each problem instance of each dataset.
We analyzed execution time in the same way as solution cost: within each dataset, we compared _BFD_ against each other algorithm using paired two-tailed $t$-tests at $alpha = 0.05$.
For each matched problem instance $i$, the tested value was the runtime ratio $r_i = "runtime"_("BFD", i) / "runtime"_("other", i)$.
The null hypothesis $cal(H_0)$ was that there was no statistically significant difference in execution time between _BFD_ and the compared algorithm, expressed as $mu_r = 1$.
Each test used the $N = 100$ per-instance runtime observations from one dataset.

@figure_alg_execution_time_chart shows the mean per-instance execution time for each algorithm for each of the three datasets, with $95\%$ confidence intervals.
The mean execution time is below 100 milliseconds per problem instance.
The _BFD_ and _FFDNew_ algorithms have the highest mean per-instance execution times, especially on the _Machine-heavy_ dataset.
However, the absolute differences are only on the order of milliseconds to tens of milliseconds.

#align(center)[
  #block(breakable: false, [
    #figure(
      image(
        "../images/eval_runtime_cross_dataset.svg",
        width: 100%,
        height: 30%,
        fit: "contain",
      ),
      caption: [Mean per-instance runtime with $95%$ confidence intervals for all algorithms and datasets.],
    ) <figure_alg_execution_time_chart>
  ])
]

#let compact_runtime_ttest_rows(rows) = rows.map(row => {
  let comparison = row.at(0).replace("BFD / ", "")
  let ci_parts = row.at(3).split("-")
  let ci_ratio = (
    str(calc.round(decimal(ci_parts.at(0)), digits: 4))
    + "-"
    + str(calc.round(decimal(ci_parts.at(1)), digits: 4))
  )
  let reject_h0 = if row.at(6) == "REJECT H0" { "Yes" } else { "No" }
  (comparison,) + row.slice(1, 3) + (ci_ratio,) + row.slice(5, 6) + (reject_h0,)
})

The tables below summarize the pairwise runtime-ratio tests.
A mean ratio above $1$ means that _BFD_ was slower on average; a mean ratio below $1$ means that _BFD_ was faster on average.
Across the datasets, _BFD_ is consistently and significantly slower than the simpler _FFD_ variants and _PeakDemand_.
The comparison with _FFDNew_ is much closer: _BFD_ is slightly slower on the balanced dataset, slightly faster on the job-heavy dataset, and not significantly different on the machine-heavy dataset.
Because the chart shows that all mean runtimes remain below $100$ milliseconds per instance, these differences are small in absolute terms, but they still help separate algorithms with similar solution quality.

#let runtime_ttest_balanced = compact_runtime_ttest_rows(
  csv("../evaluation/results/balanced/eval_raw_runtime_ratio_ttest_pairwise_balanced.csv").slice(
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
        ..runtime_ttest_balanced.flatten(),
      ),
      caption: [Paired runtime-ratio $t$-tests for the balanced dataset (_BFD_ / other algorithms).],
    )
  ])
]

#let runtime_ttest_job_heavy = compact_runtime_ttest_rows(
  csv("../evaluation/results/job_heavy/eval_raw_runtime_ratio_ttest_pairwise_job_heavy.csv").slice(
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
        ..runtime_ttest_job_heavy.flatten(),
      ),
      caption: [Paired runtime-ratio $t$-tests for the job-heavy dataset (_BFD_ / other algorithms).],
    )
  ])
]

#let runtime_ttest_machine_heavy = compact_runtime_ttest_rows(
  csv("../evaluation/results/machine_heavy/eval_raw_runtime_ratio_ttest_pairwise_machine_heavy.csv").slice(
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
        ..runtime_ttest_machine_heavy.flatten(),
      ),
      caption: [Paired runtime-ratio $t$-tests for the machine-heavy dataset (_BFD_ / other algorithms).],
    )
  ])
]
