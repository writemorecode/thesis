== Execution Time Analysis <results_runtime_section>

We measured the execution time for each algorithm implementation on each problem instance of each dataset.
These measurements describe the wall-clock behavior of the current Python implementation on the evaluation machine and generated instances.
They should therefore be interpreted as implementation-level observations, not as definitive evidence of the inherent runtime performance of the underlying algorithms.
For descriptive comparison, we analyzed execution time in the same way as solution cost.
Within each dataset, we compared the _BFD_ implementation against each other algorithm implementation using paired two-tailed $t$-tests at $alpha = 0.05$.
For each dataset $D$ and matched problem instance $i$, the tested value was the execution time ratio

$ r_(D, i) = t_("BFD", D, i) / t_(A, D, i) $

where $t_(A,D,i)$ was the measured execution time for the implementation of algorithm $A$ on problem instance $i$ of dataset $D$.
The null hypothesis $cal(H_0)$ was that there was no statistically significant difference in measured execution time between the _BFD_ implementation and the compared implementation, expressed as $mu_r = 1$.
Each test used the $N = 100$ per-instance runtime observations from one dataset.

@figure_alg_execution_time_chart shows the mean per-instance execution time for each algorithm implementation for each of the three datasets, with $95\%$ confidence intervals.
The mean execution time is below 100 milliseconds per problem instance.
The _BFD_ and _FFDNew_ implementations have the highest mean per-instance execution times, especially on the _Machine-heavy_ dataset.
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
    str(calc.round(decimal(ci_parts.at(0)), digits: 4)) + "-" + str(calc.round(decimal(ci_parts.at(1)), digits: 4))
  )
  let reject_h0 = if row.at(6) == "REJECT H0" { "Yes" } else { "No" }
  (comparison,) + row.slice(1, 3) + (ci_ratio,) + row.slice(5, 6) + (reject_h0,)
})

The tables below summarize the pairwise runtime-ratio tests.
A mean ratio above $1$ means that the _BFD_ implementation was slower on average, and a mean ratio below $1$ means that the _BFD_ implementation was faster on average.
Across the datasets, the _BFD_ implementation is consistently and significantly slower than the simpler _FFD_ variant implementations.
The comparison with _FFDNew_ is much closer.
The _BFD_ implementation is slightly slower on the balanced dataset, and slightly faster on the job-heavy and machine-heavy datasets.
The runtime-ratio test rejects the null hypothesis for the job-heavy and machine-heavy datasets, while the balanced dataset difference is not statistically significant.
Because the chart shows that all mean runtimes remain below $100$ milliseconds per instance, these differences are small in absolute terms.
They are useful for comparing the evaluated implementations, but should not be overgeneralized to optimized implementations or other execution environments.

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
        align: center,
        [*Comparison*],
        [*$n$*],
        [*Mean ratio*],
        [*$95%$ CI*],
        [*$p$-value*],
        [*Reject $H_0$?*],
        ..runtime_ttest_balanced.flatten(),
      ),
      caption: [Paired runtime-ratio $t$-tests for the balanced dataset (_BFD_ / other algorithms).],
    ) <table_runtime_ttest_balanced>
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
        align: center,
        [*Comparison*],
        [*$n$*],
        [*Mean ratio*],
        [*$95%$ CI*],
        [*$p$-value*],
        [*Reject $H_0$?*],
        ..runtime_ttest_job_heavy.flatten(),
      ),
      caption: [Paired runtime-ratio $t$-tests for the job-heavy dataset (_BFD_ / other algorithms).],
    ) <table_runtime_ttest_job_heavy>
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
        align: center,
        [*Comparison*],
        [*$n$*],
        [*Mean ratio*],
        [*$95%$ CI*],
        [*$p$-value*],
        [*Reject $H_0$?*],
        ..runtime_ttest_machine_heavy.flatten(),
      ),
      caption: [Paired runtime-ratio $t$-tests for the machine-heavy dataset (_BFD_ / other algorithms).],
    ) <table_runtime_ttest_machine_heavy>
  ])
]
