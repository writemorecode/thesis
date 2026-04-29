== Execution Time Analysis <results_runtime_section>

We collected the execution time for each algorithm on each of the datasets.
We then ran paired two-tailed $t$-tests at $alpha = 0.05$ for each algorithm across the dataset pairs.
For $8$ algorithms and $3$ datasets, this results in a total of $24$ $t$-tests.
Each test used the $N = 100$ per-instance runtime observations.
The null hypothesis $cal(H_0)$ is that there is no statistically significant difference for the same algorithm between any two datasets.

@figure_alg_execution_time_chart shows the mean per-instance execution time for each algorithm for each of the three datasets, with $95\%$ confidence intervals.
The mean execution time is below 100 milliseconds per problem instance.
The _BFD_ and _FFDNew_ algorithms have the longest mean execution times, especially on the _Machine-heavy_ dataset.
However, the absolute differences are only on the order of milliseconds to tens of milliseconds.

#align(center)[
  #block(breakable: false, [
    #figure(
      image(
        "../images/eval_runtime_cross_dataset.svg",
        width: 100%,
        height: 50%,
        fit: "contain",
      ),
      caption: [Mean per-instance runtime with $95%$ confidence intervals for all algorithms and datasets.],
    ) <figure_alg_execution_time_chart>
  ])
]
