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
