= Appendix

== Data normality <appendix_data_normality>

We shall now discuss the validity of our experimental methods, and of our results.
We begin with discussing the paired comparison between the _BFD_ and _FFDNew_ algorithms.
We use a Wilcoxon signed-rank test on per-instance raw total cost differences, which does not require normality assumptions.
Nevertheless, it is instructive to examine the distribution of cost ratios to understand why we avoid $t$-tests here.

First of all, all data points must be independent.
We meet this requirement, since all problem instances are randomly generated using a deterministic pseudo-random number generated with a fixed seed value.
No problem instances were generated based on other problem instances as input.

The second requirement for a $t$-test is that the data must be, at least approximately, normally distributed.
This requirement is met by only the balanced dataset.
Below, we present a histogram plot and a quantile-quantile (Q-Q) plot for each of the three datasets.
For each dataset, the histogram plot is generated from the set of cost-ratio values (see @cost_ratios)
$
  r_i = c_("BFD",i) / c_("FFDNew",i),
$
for each problem instance $i$.
In order for such $t$-tests to be valid, we must have $r_i ~ cal(N)(mu_r, sigma_r^2)$ for some distribution parameters $mu_r$ and $sigma_r$.
Note that for all three datasets, the two algorithms perform equally well on a large number of problem instances (see also the performance profile plots in @results_section).
This is shown in the histograms as the large spike at the cost ratio value at $1.0$.

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

The two red dotted and dashed lines represent the points $mu_r plus.minus sigma_r$ and $mu_r plus.minus 2 sigma_r$.
The histograms shows that the majority of data points lie within $2 sigma_r$ of $mu_r$, with some outliers.
Specifically, we see that the cost ratios of the balanced dataset have a very heavy concentration of values at $mu_r$, with only a few extreme outliers.
The job-heavy dataset has a comparable spike at the mean, but with a more even distribution around the mean.
The machine-heavy dataset has the most extreme spike at the mean, with very few outliers.

Below the histogram plots, we present a Q-Q plot of the data against the quantiles of a normal distribution.
These plots give a better visualization of the outliers of each dataset.
We see that the balanced dataset fits quite well to a normal distribution, with the exception of a few outliers.
The machine-heavy dataset has the most extreme outliers.
Comparing the $R^2$ values, it is the job-heavy dataset that fits a normal distribution best.

#align(center)[
  #block(breakable: false, [
    #figure(
      image(
        "../images/eval_cost_ratio_dist_job_heavy_bfd_vs_ffd_new.svg",
        width: 100%,
        height: 50%,
        fit: "contain",
      ),
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

In order to determine more rigorously if the cost ratio values for each dataset are normally distributed, we will use the _Shapiro-Wilk_ test of normality @shapiro_wilk_article.
The test tests the null hypothesis $cal(H)_0$ that a sample came from a normally distributed population.
As before, we use a significance level of $alpha = 0.05$.
The results of these tests for _BFD_ and _FFDNew_ on all three datasets are presented below.

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
This suggests the per-instance cost-ratio distributions are non-normal in those datasets, which motivates using the Wilcoxon signed-rank test instead of ratio-based $t$-tests, even though the sample size is large ($n=100$).

We see here how a few outliers can affect the outcome of statistical tests.
The outliers represent solution costs to problem instances which were either much easier or much more difficult than average.
It may be a good idea to see if the test outcomes change if these outliers are controlled for.
This could be done by, for example, dropping all data points further than $2$ or $3$ standard deviations from the mean.

Since the sample size ($n = 100$) is greater than $30-40$, the _Central Limit Theorem_ does generally allow using $t$-tests on data that is not from a normal distribution.
Nevertheless, we prefer the Wilcoxon signed-rank test here to avoid reliance on distributional assumptions for the paired comparisons.

