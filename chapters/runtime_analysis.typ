== Execution Time Analysis <results_runtime_section>

The raw execution-time data in the `runtime_sec` column show that the runtimes are not identical across datasets.
To test the runtime null hypothesis for RQ2, we ran paired two-tailed $t$-tests at $alpha = 0.05$ for each algorithm across the three dataset pairs.
Each test used the $N = 100$ per-instance runtime observations matched by filename.

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

The null hypothesis is rejected in $17$ of the $24$ paired tests.
The clearest pattern is that the _Machine-heavy_ dataset increases runtime for the two strongest cost-oriented algorithms, _BFD_ and _FFDNew_, whose mean runtimes rise to about $95.5$ milliseconds per instance.
For the faster _FFD_ variants, _Balanced_ is consistently faster than both _Job-heavy_ and _Machine-heavy_, while _PeakDemand_ remains the fastest overall algorithm.

For RQ2, these results suggest that optimizing for both scheduling quality and execution time does not require choosing the absolutely fastest heuristic.
The earlier cost analysis identified _BFD_ and _FFDNew_ as the strongest quality-oriented choices, and the present runtime results show that their overhead is still small in absolute terms: all average runtimes remain below $0.10$ seconds per instance.
The trade-off is therefore real, but modest, and should be reported explicitly rather than treated as identical across datasets.
