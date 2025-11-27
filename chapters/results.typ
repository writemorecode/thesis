= Results <results_section>

We present a comparison of the results of the described algorithms.
Algorithm 1 refers to the algorithm described in @first_alg.
Algorithm 2 refers to the second version of algorithm 1, with the improved initial solution method described in @alt_initial_soln.
Algorithm 3 refers to the "recreate and ruin" algorithm described in @rnr_alg.

All three algorithms were run on a randomly generated problem instance, with parameters $K=5,J=10,M=6,T=100$.

#figure(
  image("../results_plot.png"),
  caption: [
    Graph comparing cost curves of scheduler algorithms
  ],
) <cost_graph_results>

