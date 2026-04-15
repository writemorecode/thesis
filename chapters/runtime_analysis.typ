== Execution Time Analysis <results_runtime_section>

We collected the execution time for each algorithm on each of the datasets.
We then ran paired two-tailed $t$-tests at $alpha = 0.05$ for each algorithm across the dataset pairs.
For $8$ algorithms and $3$ datasets, this results in a total of $24$ $t$-tests.
Each test used the $N = 100$ per-instance runtime observations.
The null hypothesis $cal(H_0)$ is that there is no statistically significant difference in execution times for any of the algorithm across all datasets.

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
    )
  ])
]
