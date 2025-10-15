= Method

== Research questions

With this research, we aim to answer the following research questions:

RQ1: How can we create a cloud job scheduler which is optimal with respect to energy consumption? \
RQ2: How can we create a cloud job scheduler which is optimal with respect to execution time?

== Upper bound on machine types 

Before we begin to search for an optimal machine vector $bold(x)$, we want to find an upper bound $bold(x) <= bold(x)_U$.
This will restrict the search space.
We will present two possible methods for computing this upper bound.

=== Method 1

Any valid upper bound $bold(x_U)$ must be able to run the jobs given by $bold(l)_t$ for all time slots $t$.
Since we are searching for an upper bound, we only need to focus on the time slots with the most scheduled jobs.
We can also ignore all duplicate time slots.
We can do this by computing the Pareto set of the set of the time slots vectors.
This gives us a new, possibly smaller set of time slots we will call $P$.

$
P = "ParetoSet"({bold(l)_1,bold(l)_2,dots.h,bold(l)_t}) = {bold(p)_1,bold(p)_2,dots.h,bold(p)_n}, quad n <= t
$

Next, for each time slot vector $bold(p)_i in P$, we run FFD (First-Fit-Decreasing) on the jobs in $bold(p)_i$.
This gives us a machine vector $bold(v)_j$, which is guaranteed to be a valid job-machine allocation.
By the upper bound on FFD given in the Theory chapter, $bold(v)_j$ will be no more than approximately $22%$ ($11/9$) worse than the theoretical optimum.

Finally, we get our upper bound $bold(x)_U$ by taking the component-wise maximum across all $bold(p)_k$ vectors.

$
  (bold(x)_(U))_k = max_j (bold(p)_(j))_k
$

