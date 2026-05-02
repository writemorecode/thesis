== Execution Time Analysis <results_runtime_section>

We measured the execution time for each algorithm on each problem instance of each dataset.
We then ran paired two-tailed $t$-tests at $alpha = 0.05$ for each algorithm across the dataset pairs.
For $8$ algorithms and $3$ datasets, this resulted in a total of $24$ $t$-tests.
Each test used the $N = 100$ per-instance runtime observations.
The null hypothesis $cal(H_0)$ was that there was no statistically significant difference in execution time for the same algorithm between any two datasets.
In other words, for each algorithm and for each pair $A$, $B$ of datasets, there should be no statistically significant difference in execution time for the algorithm on the datasets $A$ and $B$.

All algorithm evaluations were ran sequentially.
The execution time of each algorithm on each problem instance was measured only once with no warm-up period
Execution times were measured using the Python standard library method `time.monotonic()` @python_time_time.

@figure_alg_execution_time_chart shows the mean per-instance execution time for each algorithm for each of the three datasets, with $95\%$ confidence intervals.
The mean execution time is below 100 milliseconds per problem instance.
The _BFD_ and _FFDNew_ algorithms have the highest mean per-instance execution times, especially on the _Machine-heavy_ dataset.
However, the absolute differences are only on the order of milliseconds to tens of milliseconds.

#align(center)[
  #block(breakable: false, [
    #figure(
      image(
        "../images/eval_runtime_cross_dataset.svg",
        width: 100%,
        height: 30%,
        fit: "contain",
      ),
      caption: [Mean per-instance runtime with $95%$ confidence intervals for all algorithms and datasets.],
    ) <figure_alg_execution_time_chart>
  ])
]
