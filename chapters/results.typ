= Results <results_section>

This chapter presents the evaluation datasets, metrics, and empirical results for the scheduling algorithms.

== Data

For each dataset, we first present a summary table of the evaluation results for each scheduler algorithm.
We then compare the two best algorithms for the dataset, defined as the two schedulers with the lowest average total cost in the summary table.
This comparison uses a paired two-tailed t-test on per-instance cost ratios and reports both the $p$-value and a 95% confidence interval for the mean cost ratio.
Next, we present a plot of the performance profiles for each of the algorithms.
Here, $tau$ is on the $x$-axis, and $rho_s (tau)$ is on the $y$-axis, for each solver $s$.
Finally, we present a table of the performance ratio _"win rate"_ for each algorithm.
This value is, for each algorithm $s$, given by the performance profile function $rho_s (tau)$ at $tau = 1$.
Note here that the sum of the win rates across all algorithms do not sum to $1$.
The reason for this is that multiple algorithms can be tied for certain problem instances.

Since the algorithm execution times are all nearly identical, we will not be comparing them.


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
Using the paired raw-ratio t-test, we find that the two algorithms are statistically indistinguishable at $alpha=0.05$, and any average difference is very small.

#let ttest_balanced = csv("../evaluation/results/balanced/eval_raw_ratio_ttest_balanced.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 4,
        [*Comparison*], [*Confidence interval*], [*Mean ratio*], [*$p$-value*],
        ..ttest_balanced.flatten(),
      ),
      caption: [Paired raw-ratio t-test summary for balanced dataset (_BFD_ vs _FFDNew_).],
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
Using the paired raw-ratio t-test, we find that the two algorithms are statistically indistinguishable at $alpha=0.05$, and any average difference is very small.

#let ttest_job_heavy = csv("../evaluation/results/job_heavy/eval_raw_ratio_ttest_job_heavy.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 4,
        [*Comparison*], [*Confidence interval*], [*Mean ratio*], [*$p$-value*],
        ..ttest_job_heavy.flatten(),
      ),
      caption: [Paired raw-ratio t-test summary for job-heavy dataset (_BFD_ vs _FFDNew_).],
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
Using the paired raw-ratio t-test, we find that the two algorithms are statistically indistinguishable at $alpha=0.05$, and any average difference is very small.

#let ttest_machine_heavy = csv("../evaluation/results/machine_heavy/eval_raw_ratio_ttest_machine_heavy.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 4,
        [*Comparison*], [*Confidence interval*], [*Mean ratio*], [*$p$-value*],
        ..ttest_machine_heavy.flatten(),
      ),
      caption: [Paired raw-ratio t-test summary for machine-heavy dataset (_BFD_ vs _FFDNew_).],
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
