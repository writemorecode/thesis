= Results <results_section>

We present a medium-sized problem instance, and the job schedule produced by the current algorithm.

== Problem instance

$
  C = mat(
    15, 12, 18, 10;
    14, 10, 18, 12
  ) quad
  R = mat(
    4, 6, 5, 9;
    3, 5, 7, 6
  ) quad
  L = mat(
    3, 4, 2, 1, 5, 0;
    1, 2, 3, 0, 2, 4;
    0, 1, 2, 3, 2, 1;
    2, 0, 1, 2, 1, 3
  ) \
  bold(c^p) = mat(9, 6, 12, 10) quad
  bold(c^r) = mat(10, 2, 4, 3)
$

== Algorithm result

The algorithm generated the following job solution.

The machine vector $bold(x)$ and total cost $c^*$ of the solution were:
$ bold(x) = mat(4, 0, 0, 0), quad c^* = 246. $

#let alg1_results_data_csv = csv("../data.csv")

#table(
  columns: 6,
  table.header([*Time slot*], [*Machine type*], [*Job 0*], [*Job 1*], [*Job 2*], [*Job 3*]),
  ..alg1_results_data_csv.slice(1).flatten(),
)
