= Conclusion and Future Work <conclusion_future_work_section>

== Conclusion

In this report, we have studied a job scheduling problem, presenting and evaluating a number of algorithms for solving it.
We found the solution cost difference between the _BFD_ and _FFDNew_ algorithms to be statistically insignificant.
These two algorithms greatly outperformed the other evaluated algorithms.
We concluded that these two algorithms used a larger number of machines than the others.
We also concluded that the best performing algorithm yielded lower cost solutions for problem instances with a greater number of available machine types.
For our first research question (RQ1), we have found that we can construct efficient scheduling algorithms by adapting traditional packing heuristics such as _FFD_ and _BFD_.
Regarding our second research question (RQ2), we have not noted any significant differences in the execution times of our evaluated scheduling algorithms.
This suggests that a trade-off between solution quality and execution time is not required for the algorithms we have evaluated and presented.

== Future Work
In this report, we have studied an offline job scheduling problem where the given load profile data $bold(L)$ is deterministic.
In the problem description (@problem_description_section), we make the assumption that $bold(L)$ comes from a prediction.
However, we also treat these predicted values as deterministic data.
A future study could remove this unrealistic assumption, and study the problem of efficient job-scheduling in private clouds with future workload demand uncertainty.
This presents interesting trade-offs, since higher solution costs would yield a higher probability of having sufficient available resource capacity, and vice versa.

We have not presented or evaluated any global search algorithms in this report.
We have only studied simpler local search algorithms.
A future study could apply more advanced search methods to the problem.
Such methods may include simulated annealing, tabu search, or more modern methods such as variable neighborhood search @hansen_variable_2010.
Another similar research direction would be to apply hybrid exact-heuristic methods to the problem.

The optimization problem studied in this work aims to minimize only the total cost of ownership for a given machine fleet.
A future study could expand this problem to allow for optimizing with respect to multiple objectives.
Such a problem could be to, for example, minimize both the total cost of ownership and the total machine count.
It could also be interesting to attempt to minimize the number of different machine types used.

One of the main results of this study was the similarity between the _BFD_ and _FFDNew_ algorithms.
We found that these two algorithms did not have a statistically significant solution cost difference.
A future study could attempt to determine the characteristics of the problem instances which cause the performance of these algorithms to diverge.

In this study, we have only evaluated our algorithms on synthetic randomly-generated problem instances.
A future study could expand on this study by evaluating these algorithms on more realistic workloads derived from real-world production traces.
For example, the Google Borg Cluster workload trace data could be used here @github_google_borg_cluster_trace.
This dataset has been used for other previous studies @7982333 @10626633.

The problem definition could be expanded by introducing more realistic operational constraints.
Such constraints may include machine startup and shutdown delays, maintenance windows, jobs spanning multiple time slots, etc.
This would make the theoretical model a better representation of a real-world private cloud operation.
The current cost-model is currently very simple.
The purchase cost of a machine is determined by a linear function of its machine capacity vector.
The running cost of a machine is a fixed percentage of its purchase cost.
This primitive cost-model could be expanded to support e.g. time-dependent energy costs, machine volume purchase discounts, machine maintenance costs, etc.

Finally, a future study could take a more theoretical approach and attempt to find provable bounds for the _BFD_ and _FFDNew_ algorithms, and compare these to the bounds on the existing _BFD_ and _FFD_ algorithms.
Such a study could also work on finding worst-case problem instances for these algorithms.








