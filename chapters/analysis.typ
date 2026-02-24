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
For all three datasets, the paired Wilcoxon signed-rank tests on raw total_cost differences fail to reject the null hypothesis at $alpha=0.05$.
This means that we can not conclude that _BFD_ outperforms _FFDNew_ on any of the datasets based on these tests alone.

The pairwise Wilcoxon signed-rank tests comparing _BFD_ to the remaining algorithms (excluding _FFDNew_) are all decisive.
Across all three datasets, the median differences are negative, the $p$-values are far below $0.05$, and the results are consistent with _BFD_ yielding lower solution cost than the other evaluated baselines.

We also observe a dataset-level shift in absolute cost scale.
Using the per-dataset summary tables, the mean of the per-scheduler average costs is lowest for _Machine-heavy_ ($8102.49$), then _Balanced_ ($8136.79$), and highest for _Job-heavy_ ($8311.13$).
This is consistent with the dataset definitions used in the evaluation script: _Machine-heavy_ has fewer job types and more machine types ($J \in [8, 12], M \in [16, 24]$), while _Job-heavy_ has more job types and fewer machine types ($J \in [16, 24], M \in [8, 12]$).
More available machine types can increase packing flexibility and reduce unused capacity, while a larger and more heterogeneous job-type set can increase matching difficulty and cost.

At the same time, this ordering should be interpreted as a tendency rather than a strict rule.
For the top algorithms (_BFD_, _FFDNew_), and also _PeakDemand_, we observe _Machine-heavy_ $<$ _Balanced_ $<$ _Job-heavy_.
For several weaker FFD variants, however, _Machine-heavy_ is slightly more expensive than _Balanced_.
Therefore, it is not sufficient to compare only per-scheduler averages when making stronger validity claims.
With $N=100$ instances per dataset, a more rigorous cross-dataset comparison should use per-instance costs with effect sizes and confidence intervals, and optionally non-parametric hypothesis tests across datasets.

== Discussion <discussion_section>

=== Threats to internal validity

It is possible that the random problem instance generation algorithms are generating problem instances which systematically favor the _BFD_ and _FFDNew_ packing algorithms to other algorithms which performed poorer.
This is a reasonable concern, since the problem instances are designed to have job and machine types with some above average resource demands and capacities, respectively.
The question is if the packing algorithms were designed with the problem instances in mind, or vice versa.
The former would be valid, while the latter would not.

We have generated each problem instance of each dataset using a single fixed seed value.
This makes the results reproducible, but it is possible that using a different seed would yield different results.
However, the conclusion we have drawn from our results are consistent across all three datasets.
Each dataset consists of $100$ problem instances.
Therefore, we do not believe this to be a serious threat to validity.

A more likely threat is that there are bugs in the scripts used for algorithm evaluation, data analysis, chart rendering, etc.
This is an error-prone process consisting of multiple steps.
First, each algorithm must be evaluated on each of the three datasets.
The solution data of each algorithm for each problem instance of each dataset must be recorded.
We use this data to compute statistical tests, and performance profiles.
Next, from this raw data we generate per-dataset summary data for each algorithm.
In order to improve reproducibility of our results, we have automated this full process with another script.
The source code for the simulator and the utility scripts can be found on GitHub @python_simulator_repo_github @python_thesis_repo_github.

It is possible that one or more of the evaluated packing algorithms were implemented incorrectly.
In order to mitigate this threat, we review the code for new algorithms before they are evaluated.
Further, each time a packing algorithm produces a solution for a problem instance, the solution is validated.
This validation step ensures that, for each time slot, the total resource demand for any machine instance does not exceed its resource capacity.

== Threats to external validity

It is likely that the problem instances generated and used to evaluate our algorithms do not accurately represent the workloads seen in real-world cloud computing environments.
These workloads may have a different structure, including bursts, seasonality, and correlations.

Our chosen simple cost model of a purchase cost and a running cost may be an invalid model of how real cloud providers charge for their services.
Our model assumes fixed running costs per machine types, and fixed purchase costs per machine type regardless of how many machines are purchased.
A more complex model may also want to model hardware depreciation, which can be an important factor for GPUs.

Our algorithms do not model operational constraints, such as machine startup delays, maintenance windows, etc.

Our results hold for the case of private clouds, in which a full hardware fleet is purchased and used for a longer time period.
These results may not hold for public and/or hybrid clouds, which may have different constraints and cost models.
