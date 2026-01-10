= Results <results_section>

== Datasets

We evaluate the algorithms on a three different datasets.
Each dataset was generated using the NumPy deterministic pseudorandom number generator, using the fixed seed value $5000$.
Each dataset contains 100 randomly generated problem instances.

The first dataset ("balanced") was generated with a balanced number of job types and machine types.
The second dataset ("job heavy") was generated with a greater number of job types than machine types.
The third dataset ("machine heavy") was generated with a greater number of machine types than machine types.

The table below presents the parameters used to generate each dataset.

#let all_datasets_csv_file = csv("../all_datasets.csv")
#table(
  columns: 9,
  [*$"Name"$*], [*$K_min$*], [*$K_max$*], [*$J_min$*], [*$J_max$*], [*$M_min$*], [*$M_max$*], [*$T_min$*], [*$T_max$*],
  ..all_datasets_csv_file.flatten(),
)

== Evaluation

For each problem instance, we collect the best total cost value.
For each pair of algorithms $A$ and $B$ and problem instance $i$, we compare the logarithmic cost ratios

$ log(r_i)=log(c_A)-log(c_B) $.

We then compute the mean value of $log(r_i)$ across all problem instances in the dataset.
The results are compared in the table below.

#table(
  columns: 3,
  [*Algorithm A*], [*Algorithm B*], [*Log ratio*],
  [Ruin-and-recreate], [FFD], [-0.000809],
  [Ruin-and-recreate], [Local scheduler], [-0.000809],
  [FFD], [Local scheduler], [0.0],
)
