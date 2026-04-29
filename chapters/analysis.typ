= Analysis and Discussion

== Analysis <analysis_section>

This chapter interprets the evaluation results and discusses their implications for offline scheduling in private clouds.

The results of the evaluation are clear.
We can divide the packing algorithms into two classes: the naive _FFDLex_, _FFDSum_, _FFDProd_, _FFDMax_, _FFDL2_, etc, and the more intelligent _BFD_ and _FFDNew_.
We can make two initial conclusions.
The performance of the naive algorithms are all comparable, with exception of one or two outliers with exceedingly poor performance.
Any difference in performance between _BFD_ and _FFDNew_ is statistically indistinguishable.
These conclusions hold for all three datasets.

Next, we consider the execution times of the algorithms.
Our null hypothesis was that there was no statistically significant difference in execution times between any of the algorithms across all of the datasets.
The null hypothesis is rejected in $17$ of the $24$ paired tests.
The clearest pattern is that the _Machine-heavy_ dataset increases runtime for the two strongest cost-oriented algorithms, _BFD_ and _FFDNew_, whose mean runtimes rise to about $95.5$ milliseconds per instance.
For the faster _FFD_ variants, _Balanced_ is consistently faster than both _Job-heavy_ and _Machine-heavy_, while _PeakDemand_ remains the fastest overall algorithm.

For RQ2, these results suggest that optimizing for both scheduling quality and execution time does not require choosing the absolutely fastest heuristic.
The earlier cost analysis identified _BFD_ and _FFDNew_ as the strongest quality-oriented choices, and the present runtime results show that their overhead is still small in absolute terms: all average runtimes remain below 100 milliseconds per instance.
It shall be noted that the algorithms were not implemented with performance in mind.
It is possible that more efficient implementations would have yielded in different results.

We shall study the evaluation results of the _BFD_ and _FFDNew_ algorithms.
The two algorithms have nearly identical average costs on each of the datasets.
For all three datasets, the paired Wilcoxon signed-rank tests on raw total cost differences fail to reject the null hypothesis at $alpha=0.05$.
This means that we can not conclude that _BFD_ outperforms _FFDNew_ on any of the datasets based on these tests alone.

The pairwise Wilcoxon signed-rank tests comparing _BFD_ to the remaining algorithms (excluding _FFDNew_) are all decisive.
Across all three datasets, the median differences are negative, the $p$-values are far below $0.05$, and the results are consistent with _BFD_ yielding lower solution cost than the other evaluated baselines.

There are notable relationships between the total machine count and the solution cost for different algorithms.
We find that the two algorithms with the lowest solution costs, _BFD_ and _FFDNew_, have the highest total machine count.
We have run paired Wilcoxon signed-rank tests ($alpha=0.05$) between the total machine counts for the _BFD_ and _FFDMax_ algorithms.
The null hypothesis was rejected for all three datasets.
For the _Balanced_ dataset, the mean and median differences are $7.33$ and $7$ machines (_BFD_ - _FFDMax_), and $p=1.837 dot 10^(-16)$.
For the _Job-heavy_ dataset, the mean and median differences are $8.87$ and $9$, with and $p=6.389 dot 10^(-18)$.
For the _Machine-heavy_ dataset, the mean and median differences are $5.67$ and $7$, with and $p=4.76 dot 10^(-12)$.
These results indicate that the _BFD_ algorithm consistently activates more machines than the _FFDMax_ algorithm, even while achieving lower total solution cost.
This supports the interpretation that lower cost in our setting does not imply fewer active machines, but instead a more cost-efficient allocation across machine types over time.

We also observe a dataset-level shift in absolute cost scale.
This is consistent with the dataset definitions: the _Machine-heavy_ dataset has twice as many machine types as the other two datasets.
A greater number of available machine types can, but is not guaranteed to, increase packing flexibility and reduce unused capacity.
Using paired one-tailed cross-dataset $t$-tests for the _BFD_ algorithm on per-instance raw total costs, we find support for our hypothesis.
For _Machine-heavy_ $<$ _Balanced_, the test rejects the null hypothesis at $alpha=0.05$ ($t=-2.279$, $p=0.01242$), with mean costs of $6983$ vs $8134$ and mean paired difference $-1151$.
This supports the claim that the machine-heavy dataset yields lower _BFD_ cost.
Thus, with the current data, our directional hypothesis is supported.

We note that the Dolan-Moré performance profiles are generally consistent across all datasets.
The _BFD_ and _FFDNew_ algorithms are dominant over all other algorithms.
These two algorithms are tied on between $80%$ and $86$ of problem instances, for the _Balanced_ and _Machine-heavy_ datasets.
For the _Job-heavy_ dataset, there are some notable differences.
Here, the two algorithms are tied on only $43%$ of problem instances.

== Discussion <discussion_section>

=== Introduction to validity

The concept of validity is typically separated into internal and external validity.
The internal validity of a study is concerned with whether the study's results can actually be used to provide an explanation of its research question, or if there exists some alternative explanation of the results @book_research_methodology_safsten_gustavsson.
The external validity of a study is concerned with what can be stated regarding the scope and transferability, or generalizability of the results @book_research_methodology_safsten_gustavsson.

=== Threats to internal validity

It is possible that the random problem instance generation algorithm produces instances that systematically favor _BFD_ and _FFDNew_ over algorithms that performed worse.
This is a plausible concern for our work because the datasets are constructed with job types and machine types that include some above-average resource demands and capacities, respectively.
We mitigate this threat by treating it as a design risk and making the instance generation approach explicit.
The key validity condition is that algorithms are evaluated on independently generated problem instances, not instances tailored to specific algorithms.

Each problem instance in each dataset was generated with a single fixed seed value.
This is relevant because fixed seeds improve reproducibility, but different seeds could still produce different outcomes.
We mitigate this by evaluating on three separate datasets with $100$ problem instances each.
We also note that our conclusions are consistent across all three datasets, which reduces, but does not eliminate, seed value sensitivity as a threat.

The algorithm evaluation workflow includes multiple error-prone steps: evaluating each algorithm on each problem instance of each dataset, recording per-instance solution data, computing statistical tests and performance profiles, and generating per-dataset summaries.
This makes pipeline bugs a valid threat because errors in any step could invalidate results.
We mitigate this by automating the full workflow to reduce manual data handling errors and by making the simulator and utility scripts publicly available on GitHub @python_simulator_repo_github @python_thesis_repo_github.

If one or more packing algorithms are implemented incorrectly, measured performance differences may not reflect true algorithm behavior.
This also applies to the problem instance generation algorithms described in @problem_instance_generation.
This is directly relevant to our study because all conclusions depend on the correctness of algorithm implementations.
We mitigate this threat by code-reviewing new implementations before evaluation and by validating every produced solution so that, for each time slot, total resource demand assigned to any machine instance does not exceed that machine's resource capacity.

In @analysis_section we identified two empirical patterns that are consistent with the expected scheduler algorithm behavior.
First, the best-performing algorithms with the lowest average solution costs used more machines on average than weaker algorithms.
This indicates that lower solution costs are achieved through better job-machine placements rather than using fewer active machines.
Second, solution costs were lower for datasets with a larger number of available machine types.
This is as expected given the problem instance generation algorithms which were described in @problem_instance_generation.
If there is a higher number of available machine types then for each job type with a primary resource there is a higher probability for there to exist more machine types with a matching primary resource.
In other words, for datasets with more machine types, there may be a higher maximum number of feasible job-machine placements.
It is therefore possible for these datasets to have certain less expensive job-machine placements which do not exist in other datasets with fewer machine types.

This was consistent with increased packing flexibility.
These patterns provide support for, but not proof of, the validity of our results.

Finally, we mention a few things regarding algorithm execution time analysis.
Since the execution time for algorithm for each problem instance was measured only once, the measurements may have been affected by noise from the machine on which they were collected.
We used a laptop to run all algorithm evaluation and execution time collection.
At this time, the laptop was running a minimal number of tasks required to carry out the evaluation and measurement tasks.
A more rigorous algorithm benchmarking study would repeat each run multiple times, randomize execution order, collect all measurements on a dedicated server machine, and use a high-resolution monotonic timer.
Further, such a study would also compare algorithms pairwise on the same problem instances.

== Threats to external validity

The generated problem instances may not fully capture real-world workload characteristics such as bursts, seasonality, and correlations.
This is a valid external threat because differences between synthetic and real workloads can limit generalizability.
We mitigate this by framing conclusions as evidence within the studied workload model rather than as universal claims across all cloud workloads.

The model uses fixed purchase and running costs per machine type.
This is a relevant threat because real cloud pricing can be more complex and may include volume pricing, non-linear billing rules, and hardware depreciation, especially for GPUs.
We mitigate this by explicitly scoping claims to the defined cost model and presenting results as comparative insights under that model, not as direct predictions of provider-specific costs.

The algorithms do not model operational factors such as startup delays and maintenance windows.
This is relevant because such factors can influence both feasible schedules and realized costs in practice.
We mitigate this by explicitly acknowledging these omitted constraints and limiting interpretation of results to settings where they are negligible or can be approximated externally.

Our conclusions are derived for private cloud settings where a hardware fleet is purchased and used over longer periods.
This is a clear external validity limitation because public and hybrid clouds can have different constraints and pricing structures.
We mitigate overgeneralization by not extending the findings to those environments without additional targeted evaluation.

Previously, we assumed a deterministic load profile and the lack of an initial hardware fleet.
However, these assumptions are not load-bearing and could be relaxed.
This would allow our algorithms to be applied to more general problems which do not involve these assumptions.

