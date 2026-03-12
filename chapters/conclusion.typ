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
For this problem, higher solution costs would yield a higher probability of having sufficient available resource capacity, and vice versa.
This presents interesting trade-offs.

We have not presented or evaluated any global search algorithms in this report.
We have only studied simpler local search algorithms.
A future study could apply more advanced search methods such as simulated annealing, tabu search, or more modern methods such as variable neighborhood search @hansen_variable_2010.

