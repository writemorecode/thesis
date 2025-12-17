= Results <results_section>

We evaluate the three algorithms on a dataset of 100 randomly generated problem instances.
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
