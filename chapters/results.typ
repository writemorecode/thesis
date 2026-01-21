= Results <results_section>

This chapter presents the evaluation datasets, metrics, and empirical results for the scheduling algorithms.

== Datasets

We evaluate the algorithms on three different datasets.
For evaluation, we developed a simulator in Python using the NumPy library @python_simulator_repo_github.
Each dataset was generated using the NumPy deterministic pseudorandom number generator, using the fixed seed value $5000$.
Each dataset contains 100 randomly generated problem instances.

The first dataset ("balanced") was generated with a balanced number of job types and machine types.
The second dataset ("job heavy") was generated with a greater number of job types than machine types.
The third dataset ("machine heavy") was generated with a greater number of machine types than job types.

The table below presents the parameters used to generate each dataset.

#let all_datasets_csv_file = csv("../data/all_datasets.csv")
#table(
  columns: 9,
  [*$"Name"$*], [*$K_min$*], [*$K_max$*], [*$J_min$*], [*$J_max$*], [*$M_min$*], [*$M_max$*], [*$T_min$*], [*$T_max$*],
  ..all_datasets_csv_file.flatten(),
)

== Evaluation method

=== Paired comparison via log cost ratios

Each dataset contains the same set of problem instances evaluated by every algorithm.
Therefore, comparisons between two algorithms are based on *paired* observations.

Let $c_(A,i)$ and $c_(B,i)$ be the total costs of algorithms $A$ and $B$ on instance $i$, and define the per-instance log cost ratio

$
  d_i = log(c_(A,i) / c_(B,i)).
$

If $d_i < 0$, then $c_(A,i) < c_(B,i)$ and $A$ is better on instance $i$ (lower cost).

We test whether the algorithms differ on average using a paired two-tailed t-test on the values $d_i$:
$cal(H_0): E[d] = 0$ and $cal(H_1): E[d] != 0$, with $alpha = 0.05$.
From the same test, we report a 95% confidence interval $[L, U]$ for $E[d]$.

For interpretation, we exponentiate back to the ratio scale:

$R = exp(E[d])$ with 95% confidence interval $[exp(L), exp(U)]$.

Here, $R < 1$ indicates that $A$ has lower cost than $B$ on average, and $R > 1$ indicates the opposite.

=== Dolan-Moré performance profiles

Another method of comparing the performance of different algorithms on a set of problem instances is to use _performance profiles_, presented in 2004 by Elizabeth Dolan and Jorge Moré @dolan_more_performance_profiles_2004.
This method works as follows.

Let $S$ be the set of solvers, or algorithms to evaluate.
Let $P$ be the set of problem instances.
Let $t_(p,s)$ be the cost of the solution for problem $p in P$ returned by solver $s in S$.
Let
$
  t^*_p = min_(s in S) t_(p,s)
$
be the cost of the best solution for problem $p$ across all solvers in $S$.
Let the _performance ratio_ for solver $s$ on problem $p$ be
$
  r_(p,s) = t_(p,s) / t^*_p
$
be the ratio between the solver's cost for the problem and the optimal cost for the problem.
The _performance profile_ for solver $s$ is defined as the function

$
  rho_s (tau) = 1/abs(P) abs({p in P | r_(p,s) <= tau}).
$

The performance profile function $rho_s (tau)$ for a solver $s$ can be interpreted as the percentage of problem instances for which a performance ratio $r_(p,s)$ is within $tau$ of the optimal ratio across all problem instances.
Specifically, $rho_s (1)$ gives the percentage of problem instances for which solver $s$ achieved the optimal performance ratio, which can be interpreted as the solver's _"win rate"_.

We will use this performance profiles method as a second step in the process of determining which of the algorithms performs best on each of the datasets.

== Data

For each dataset, we first present a summary table of the evaluation results for each scheduler algorithm.
We then compare the two best algorithms for the dataset, defined as the two schedulers with the lowest average total cost in the summary table.
This comparison uses a paired two-tailed t-test on per-instance log cost ratios and reports both the $p$-value and a 95% confidence interval for the geometric mean cost ratio.
Next, we present a plot of the performance profiles for each of the algorithms.
Here, $tau$ is on the $x$-axis, and $rho_s (tau)$ is on the $y$-axis, for each solver $s$.
Finally, we present a table of the performance ratio _"win rate"_ for each algorithm.
This value is, for each algorithm $s$, given by the performance profile function $rho_s (tau)$ at $tau = 1$.
Note here that the sum of the win rates across all algorithms do not sum to $1$.
The reason for this is that multiple algorithms can be tied for certain problem instances.

Since the algorithm execution times are all nearly identical, we will not be comparing them.


=== Balanced dataset

#let summary_data_balanced_dataset = csv("../data/eval_summary_balanced.csv")
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
Using the paired log-ratio t-test, we find that the two algorithms are statistically indistinguishable at $alpha=0.05$, and any average difference is very small.

#let ttest_balanced = csv("../data/eval_log_ratio_ttest_balanced.csv")
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 4,
        [*Ratio*],
        [*Confidence interval*],
        [*Ratio exp. mean*],
        [*$p$-value*],
        [#(ttest_balanced.at(1).at(1) + " / " + ttest_balanced.at(2).at(1))],
        [#(ttest_balanced.at(13).at(1) + "–" + ttest_balanced.at(14).at(1))],
        [#(ttest_balanced.at(12).at(1))],
        [#(ttest_balanced.at(7).at(1))],
      ),
      caption: [Paired log-ratio t-test summary for balanced dataset (_BFD_ vs _FFDNew_).],
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

#let perf_profiles_balanced = csv("../data/eval_performance_profiles_balanced.csv")
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 3,
        [*Scheduler*], [*Wins*], [*Win fraction*],
        ..perf_profiles_balanced.flatten(),
      ),
      caption: [Performance profile wins for the balanced dataset.],
    )
  ])
]

=== Job-heavy dataset

#let summary_data_job_heavy = csv("../data/eval_summary_job_heavy.csv")
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
Using the paired log-ratio t-test, we find that the two algorithms are statistically indistinguishable at $alpha=0.05$, and any average difference is very small.

#let ttest_job_heavy = csv("../data/eval_log_ratio_ttest_job_heavy.csv")
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 4,
        [*Ratio*],
        [*Confidence interval*],
        [*Ratio exp. mean*],
        [*$p$-value*],
        [#(ttest_job_heavy.at(1).at(1) + " / " + ttest_job_heavy.at(2).at(1))],
        [#(ttest_job_heavy.at(13).at(1) + "–" + ttest_job_heavy.at(14).at(1))],
        [#(ttest_job_heavy.at(12).at(1))],
        [#(ttest_job_heavy.at(7).at(1))],
      ),
      caption: [Paired log-ratio t-test summary for job-heavy dataset (_BFD_ vs _FFDNew_).],
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

#let perf_profiles_job_heavy = csv("../data/eval_performance_profiles_job_heavy.csv")
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 3,
        [*Scheduler*], [*Wins*], [*Win fraction*],
        ..perf_profiles_job_heavy.flatten(),
      ),
      caption: [Performance profile wins for the job-heavy dataset.],
    )
  ])
]

=== Machine-heavy dataset

#let summary_data_machine_heavy = csv("../data/eval_summary_machine_heavy.csv")
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
Using the paired log-ratio t-test, we find that the two algorithms are statistically indistinguishable at $alpha=0.05$, and any average difference is very small.

#let ttest_machine_heavy = csv("../data/eval_log_ratio_ttest_machine_heavy.csv")
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 4,
        [*Ratio*],
        [*Confidence interval*],
        [*Ratio exp. mean*],
        [*$p$-value*],
        [#(ttest_machine_heavy.at(1).at(1) + " / " + ttest_machine_heavy.at(2).at(1))],
        [#(ttest_machine_heavy.at(13).at(1) + "–" + ttest_machine_heavy.at(14).at(1))],
        [#(ttest_machine_heavy.at(12).at(1))],
        [#(ttest_machine_heavy.at(7).at(1))],
      ),
      caption: [Paired log-ratio t-test summary for machine-heavy dataset (_BFD_ vs _FFDNew_).],
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

#let perf_profiles_machine_heavy = csv("../data/eval_performance_profiles_machine_heavy.csv")
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 3,
        [*Scheduler*], [*Wins*], [*Win fraction*],
        ..perf_profiles_machine_heavy.flatten(),
      ),
      caption: [Performance profile wins for the machine-heavy dataset.],
    )
  ])
]
