= Results <results_section>

== Datasets

We evaluate the algorithms on a three different datasets.
Each dataset was generated using the NumPy deterministic pseudorandom number generator, using the fixed seed value $5000$.
Each dataset contains 100 randomly generated problem instances.

The first dataset ("balanced") was generated with a balanced number of job types and machine types.
The second dataset ("job heavy") was generated with a greater number of job types than machine types.
The third dataset ("machine heavy") was generated with a greater number of machine types than machine types.

The table below presents the parameters used to generate each dataset.

#let all_datasets_csv_file = csv("../data/all_datasets.csv")
#table(
  columns: 9,
  [*$"Name"$*], [*$K_min$*], [*$K_max$*], [*$J_min$*], [*$J_max$*], [*$M_min$*], [*$M_max$*], [*$T_min$*], [*$T_max$*],
  ..all_datasets_csv_file.flatten(),
)

== Evaluation method

=== Mean cost ratio confidence intervals

We want to determine which algorithm performs best on each of the three datasets.
Let $N$ be the number of problem instances (fixed to 100 in this case).
Let $c_(A,i)$ be the cost of algorithm $A$ for problem instance $i$, for $1<=i<=N$.
Let

$
  r_(A,B,i) = c_(A,i) / c_(B,i)
$

be the ratio of costs for algorithms $A$ and $B$ on problem instance $i$.
Because raw ratios are asymmetric.
To see why this is the case, consider the case of two different algorithms $A$ and $B$, and two problem instances.
On the first problem instance, algorithm $A$ performs twice as well as algorithm $B$.
On the second problem instance, algorithm $B$ performs twice as well as algorithm $A$.
This gives us the following cost ratios:

$
  r_(A,B,1) = (0.5 c_(B,1)) / c_(B,1) = 0.5, quad r_(A,B,2) = (c_(B,2)) / (0.5 c_(B,2)) = 2
$

Together, we compute the raw mean cost ratio value $mu_(A,B)$.

$
  mu_(A, B) = (0.5 + 2) / 2 = 1.25
$

This results is unexpected, since each of the two algorithm outperformed the other algorithm equally much on one of the two problem instances.
Therefore, none of the algorithm outperformed the other, and we would expect to have $mu_(A,B) = 1$.
If we instead use logarithmic mean ratios, then we get the expected value of:

$
  mu_(A,B) = (log(2) + log(0.5))/2 = 0
$

Therefore, we choose to compute the logarithmic ratios $l_(A,B,i) = log(r_(A,B,i))$.


Next, we compute the mean value $mu_(A,B)$ of $l_(A,B,i)$ across all problem instances $i$.

$
  mu_(A,B) = 1/N sum_(i=1)^N l_(A,B,i)
$

Next, we compute a 95% confidence interval for the value of $l_(A,B,i)$.
Let the upper and lower bounds of this confidence interval be $[L_(A,B), U_(A,B)]$.
If this confidence interval does not contain the value $1$, i.e. $1 in.not [L_(A,B), U_(A,B)]$ , then it is statistically likely that algorithm $A$ outperforms algorithm $B$ on each problem instance of the dataset.
For example, suppose the confidence interval $[L_(A,B), U_(A,B)] = [0.895, 0.982]$.
In this case, we can conclude with some degree of confidence that $mu_(A,B)$ is slightly less than $1$.
This would then mean that, with some degree of confidence, algorithm $A$ has a lower average cost than algorithm $B$ across each problem instance of the dataset.

=== Dolan-Moré performance profiles

Another method of comparing the performance of different algorithms on a set of problem instances is to use _performance profiles_, presented by Elizabeth Doran and Jorge Moré @dolan_more_performance_profiles_2004.
This method works as follows.

Let $S$ be the set of solvers, or algorithms to evaluate.
Let $P$ be the set of problem instances.
Let $t_(p,s)$ be the cost of the solution for problem $p in P$ returned by solver $s in S$.
Let
$
  t^*_p = min_(s in S) t_(p,s)
$
be the cost of the optimal solution for problem $p$.
Let the _performance ratio_ for solver $s$ on problem $p$ be
$
  r_(p,s) = t_(p,s) / t^*_p
$
be the ratio between the solver's cost for the problem and the optimal cost for the problem.

The _performance profile_ for solver $s$ is defined as the function

$
  rho_s (tau) = 1/abs(P) abs({p in P | r_(p,s) < tau}).
$

The performance profile function $rho_s (tau)$ for a solver $s$ can be interpreted as the percentage of problem instances for which a performance ratio $r_(p,s)$ is within $tau$ of the optimal ratio across all problem instances.
Specifically, $rho_s (1)$ gives the percentage of problem instances for which solver $s$ achieved the optimal performance ratio, which can be interpreted as the solver's _"win rate"_.

We will use this performance profiles method as a second step in the process of deciding which of the $sans("FFDNew")$ and $sans("BFD")$ algorithms is best.

== Data

For each of the three datasets, we present a summary table of the evaluation results for each scheduler algorithm.

=== Balanced dataset

#let summary_data_balanced_dataset = csv("../data/eval_summary_balanced.csv")
#block(breakable: false, [
  #figure(
    table(
      columns: 6,
      [*Scheduler*], [*Average cost*], [*Min cost*], [*Max cost*], [*Average runtime (sec)*], [*Average machine count*],
      ..summary_data_balanced_dataset.flatten(),
    ),
    caption: [Summary of evaluation results for balanced dataset.],
  )

])


#let ci_data_balanced = csv("../data/eval_log_ratio_balanced.csv")
#block(breakable: false, [
  #figure(
    table(
      columns: 9,
      [*Alg. A*], [*Alg. B*], [*Mean*], [*Median*], [*Std. dev.*], [*Min*], [*Max*], [*CI low*], [*CI high*],
      ..ci_data_balanced.flatten(),
    ),
    caption: [Confidence interval for mean algorithm cost ratios for balanced dataset.],
  )

])

#block(breakable: false, [
  #figure(
    image(
      "../images/eval_performance_profiles_balanced.svg",
      width: 100%,
      height: 70%,
      fit: "contain",
    ),
    caption: [Performance profiles for the balanced dataset.],
  )
])

=== Job-heavy dataset

#let summary_data_job_heavy = csv("../data/eval_summary_job_heavy.csv")
#block(breakable: false, [
  #figure(
    table(
      columns: 6,
      [*Scheduler*], [*Average cost*], [*Min cost*], [*Max cost*], [*Average runtime (sec)*], [*Average machine count*],
      ..summary_data_job_heavy.flatten(),
    ),
    caption: [Summary of evaluation results for job-heavy dataset.],
  )
])

#let ci_data_job_heavy = csv("../data/eval_log_ratio_job_heavy.csv")
#block(breakable: false, [
  #figure(
    table(
      columns: 9,
      [*Alg. A*], [*Alg. B*], [*Mean*], [*Median*], [*Std. dev.*], [*Min*], [*Max*], [*CI low*], [*CI high*],
      ..ci_data_job_heavy.flatten(),
    ),
    caption: [Confidence interval for mean algorithm cost ratios for job-heavy dataset.],
  )

])

#block(breakable: false, [
  #figure(
    image(
      "../images/eval_performance_profiles_job_heavy.svg",
      width: 100%,
      height: 70%,
      fit: "contain",
    ),
    caption: [Performance profiles for the job-heavy dataset.],
  )
])

=== Machine-heavy dataset

#let summary_data_machine_heavy = csv("../data/eval_summary_machine_heavy.csv")
#block(breakable: false, [
  #figure(
    table(
      columns: 6,
      [*Scheduler*], [*Average cost*], [*Min cost*], [*Max cost*], [*Average runtime (sec)*], [*Average machine count*],
      ..summary_data_machine_heavy.flatten(),
    ),
    caption: [Summary of evaluation results for machine-heavy dataset.],
  )
])

#let ci_data_machine_heavy = csv("../data/eval_log_ratio_machine_heavy.csv")
#block(breakable: false, [
  #figure(
    table(
      columns: 9,
      [*Alg. A*], [*Alg. B*], [*Mean*], [*Median*], [*Std. dev.*], [*Min*], [*Max*], [*CI low*], [*CI high*],
      ..ci_data_machine_heavy.flatten(),
    ),
    caption: [Confidence interval for mean algorithm cost ratios for machine-heavy dataset.],
  )

])

#block(breakable: false, [
  #figure(
    image(
      "../images/eval_performance_profiles_machine_heavy.svg",
      width: 100%,
      height: 70%,
      fit: "contain",
    ),
    caption: [Performance profiles for the machine-heavy dataset.],
  )
])
