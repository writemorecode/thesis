= Analysis and Discussion <analysis_section>

== Analysis

This chapter interprets the evaluation results and discusses their implications for offline scheduling in private clouds.

The results of the evaluation are clear.
We can divide the packing algorithms into two classes: the naive _FFDLex_, _FFDSum_, _FFDProd_, _FFDMax_, _FFDL2_, etc, and the more intelligent _BFD_ and _FFDNew_.
We can make two initial conclusions.
The performance of the naive algorithms are all comparable, with exception of one or two outliers with exceedingly poor performance.
Any difference in performance between _BFD_ and _FFDNew_ is statistically indistinguishable.
These conclusions hold for all three datasets.

We shall study the evaluation results of the _BFD_ and _FFDNew_ algorithms.
The two algorithms have nearly identical average costs on each of the datasets.
For all three datasets, the paired two-tailed t-tests on per-instance cost ratios reject the null hypothesis at $alpha=0.05$.
This means that we can not conclude that _BFD_ outperforms _FFDNew_ on any of the datasets based on these tests alone.

The one-tailed t-tests comparing _BFD_ to the remaining algorithms (excluding _FFDNew_) are all decisive.
Across all three datasets, the mean ratios are below $1$, the one-sided $p$-values are far below $0.05$, and the 95% upper confidence bounds remain below $1$.
Taken together, these results indicate that _BFD_ consistently yields lower solution cost than the other evaluated baselines.

== Discussion

We shall now discuss the validity of our experimental methods, and of our results.

#align(center)[
  #block(breakable: false, [
    #figure(
      image(
        "../images/eval_cost_ratio_dist_balanced_bfd_vs_ffd_new.svg",
        width: 100%,
        height: 50%,
        fit: "contain",
      ),
      caption: [Distributions of cost ratios for _BFD_ vs _FFDNew_ on the balanced dataset.],
    )
  ])
]

#align(center)[
  #block(breakable: false, [
    #figure(
      image(
        "../images/eval_cost_ratio_dist_job_heavy_bfd_vs_ffd_new.svg",
        width: 100%,
        height: 50%,
        fit: "contain",
      ),
      alt: "wtf",
      caption: [Distributions of cost ratios for _BFD_ vs _FFDNew_ on the job-heavy dataset.],
    )
  ])
]

#align(center)[
  #block(breakable: false, [
    #figure(
      image(
        "../images/eval_cost_ratio_dist_machine_heavy_bfd_vs_ffd_new.svg",
        width: 100%,
        height: 50%,
        fit: "contain",
      ),
      caption: [Distributions of cost ratios for _BFD_ vs _FFDNew_ on the machine-heavy dataset.],
    )
  ])
]

#let shapiro_balanced = csv("../evaluation/results/balanced/eval_raw_cost_shapiro.csv").slice(1)
#let shapiro_balanced_bfd = shapiro_balanced.at(0)
#let shapiro_balanced_ffdnew = shapiro_balanced.at(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 3,
        table.header([*W statistic*], [*$p$-value*], [*Reject H0*]),
        table.cell(colspan: 3)[*BFD*],
        [#shapiro_balanced_bfd.at(1)],
        [#shapiro_balanced_bfd.at(2)],
        [#shapiro_balanced_bfd.at(3)],
        table.cell(colspan: 3)[*FFDNew*],
        [#shapiro_balanced_ffdnew.at(1)],
        [#shapiro_balanced_ffdnew.at(2)],
        [#shapiro_balanced_ffdnew.at(3)],
      ),
      caption: [Shapiro-Wilk normality test results for the balanced dataset.],
    )
  ])
]

#let shapiro_job_heavy = csv("../evaluation/results/job_heavy/eval_raw_cost_shapiro.csv").slice(1)
#let shapiro_job_heavy_bfd = shapiro_job_heavy.at(0)
#let shapiro_job_heavy_ffdnew = shapiro_job_heavy.at(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 3,
        table.header([*W statistic*], [*$p$-value*], [*Reject H0*]),
        table.cell(colspan: 3)[*BFD*],
        [#shapiro_job_heavy_bfd.at(1)],
        [#shapiro_job_heavy_bfd.at(2)],
        [#shapiro_job_heavy_bfd.at(3)],
        table.cell(colspan: 3)[*FFDNew*],
        [#shapiro_job_heavy_ffdnew.at(1)],
        [#shapiro_job_heavy_ffdnew.at(2)],
        [#shapiro_job_heavy_ffdnew.at(3)],
      ),
      caption: [Shapiro-Wilk normality test results for the job-heavy dataset.],
    )
  ])
]

#let shapiro_machine_heavy = csv("../evaluation/results/machine_heavy/eval_raw_cost_shapiro.csv").slice(1)
#let shapiro_machine_heavy_bfd = shapiro_machine_heavy.at(0)
#let shapiro_machine_heavy_ffdnew = shapiro_machine_heavy.at(1)
#align(center)[
  #block(breakable: false, [
    #figure(
      table(
        columns: 3,
        table.header([*W statistic*], [*$p$-value*], [*Reject H0*]),
        table.cell(colspan: 3)[*BFD*],
        [#shapiro_machine_heavy_bfd.at(1)],
        [#shapiro_machine_heavy_bfd.at(2)],
        [#shapiro_machine_heavy_bfd.at(3)],
        table.cell(colspan: 3)[*FFDNew*],
        [#shapiro_machine_heavy_ffdnew.at(1)],
        [#shapiro_machine_heavy_ffdnew.at(2)],
        [#shapiro_machine_heavy_ffdnew.at(3)],
      ),
      caption: [Shapiro-Wilk normality test results for the machine-heavy dataset.],
    )
  ])
]

For the balanced dataset, we fail to reject normality for both _BFD_ and _FFDNew_ at $alpha=0.05$.
For the job-heavy and machine-heavy datasets, the Shapiro-Wilk test rejects normality for both algorithms.
This suggests the per-instance total-cost distributions may be non-normal in those datasets, so the $t$-test assumptions should be interpreted with caution, even though the sample size is large ($n=100$).
