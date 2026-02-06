= Results <results_section>

This chapter presents the evaluation datasets, metrics, and empirical results for the scheduling algorithms.

== Data

For each dataset, we first present a summary table of the evaluation results for each scheduler algorithm.
We then compare the two best algorithms for the dataset, defined as the two schedulers with the lowest average total cost in the summary table.
This comparison uses a paired Wilcoxon signed-rank test on per-instance raw total_cost differences and reports the $W$ statistic, $p$-value, and summary statistics for the paired differences.
Because the cost data are not normally distributed, we avoid $t$-tests and use this non-parametric alternative instead; see the normality investigation in the Discussion section @discussion_section.
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
Using the paired Wilcoxon signed-rank test on raw total_cost differences, we fail to reject the null hypothesis at $alpha=0.05$, and the average differences are small.

#let wilcoxon_balanced = csv("../evaluation/results/balanced/eval_raw_cost_wilcoxon_balanced.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 7,
        [*Comparison*],
        [*$n$*],
        [*Non-zero*],
        [*Mean diff*],
        [*Median diff*],
        [*$W$*],
        [*$p$-value*],
        ..wilcoxon_balanced.flatten(),
      ),
      caption: [Paired Wilcoxon signed-rank test summary for balanced dataset (_BFD_ vs _FFDNew_).],
    )
  ])
]

The table below summarizes the pairwise Wilcoxon signed-rank tests between _BFD_ and the remaining algorithms (excluding _FFDNew_).

#let wilcoxon_pairwise_balanced = csv("../evaluation/results/balanced/eval_raw_cost_wilcoxon_pairwise_balanced.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 7,
        [*Comparison*],
        [*$n$*],
        [*Non-zero*],
        [*Mean diff*],
        [*Median diff*],
        [*$W$*],
        [*$p$-value*],
        ..wilcoxon_pairwise_balanced.flatten(),
      ),
      caption: [Paired Wilcoxon signed-rank tests for balanced dataset (_BFD_ vs other algorithms except _FFDNew_).],
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
Using the paired Wilcoxon signed-rank test on raw total_cost differences, we fail to reject the null hypothesis at $alpha=0.05$, and the average differences are small.

#let wilcoxon_job_heavy = csv("../evaluation/results/job_heavy/eval_raw_cost_wilcoxon_job_heavy.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 7,
        [*Comparison*],
        [*$n$*],
        [*Non-zero*],
        [*Mean diff*],
        [*Median diff*],
        [*$W$*],
        [*$p$-value*],
        ..wilcoxon_job_heavy.flatten(),
      ),
      caption: [Paired Wilcoxon signed-rank test summary for job-heavy dataset (_BFD_ vs _FFDNew_).],
    )
  ])
]

The table below summarizes the pairwise Wilcoxon signed-rank tests between _BFD_ and the remaining algorithms (excluding _FFDNew_).

#let wilcoxon_pairwise_job_heavy = csv("../evaluation/results/job_heavy/eval_raw_cost_wilcoxon_pairwise_job_heavy.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 7,
        [*Comparison*],
        [*$n$*],
        [*Non-zero*],
        [*Mean diff*],
        [*Median diff*],
        [*$W$*],
        [*$p$-value*],
        ..wilcoxon_pairwise_job_heavy.flatten(),
      ),
      caption: [Paired Wilcoxon signed-rank tests for job-heavy dataset (_BFD_ vs other algorithms except _FFDNew_).],
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
Using the paired Wilcoxon signed-rank test on raw total_cost differences, we fail to reject the null hypothesis at $alpha=0.05$, and the average differences are small.

#let wilcoxon_machine_heavy = csv("../evaluation/results/machine_heavy/eval_raw_cost_wilcoxon_machine_heavy.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 7,
        [*Comparison*],
        [*$n$*],
        [*Non-zero*],
        [*Mean diff*],
        [*Median diff*],
        [*$W$*],
        [*$p$-value*],
        ..wilcoxon_machine_heavy.flatten(),
      ),
      caption: [Paired Wilcoxon signed-rank test summary for machine-heavy dataset (_BFD_ vs _FFDNew_).],
    )
  ])
]

The table below summarizes the pairwise Wilcoxon signed-rank tests between _BFD_ and the remaining algorithms (excluding _FFDNew_).

#let wilcoxon_pairwise_machine_heavy = csv("../evaluation/results/machine_heavy/eval_raw_cost_wilcoxon_pairwise_machine_heavy.csv").slice(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 7,
        [*Comparison*],
        [*$n$*],
        [*Non-zero*],
        [*Mean diff*],
        [*Median diff*],
        [*$W$*],
        [*$p$-value*],
        ..wilcoxon_pairwise_machine_heavy.flatten(),
      ),
      caption: [Paired Wilcoxon signed-rank tests for machine-heavy dataset (_BFD_ vs other algorithms except _FFDNew_).],
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
