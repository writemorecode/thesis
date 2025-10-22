#import "@preview/fletcher:0.5.6" as fletcher: diagram, edge, node

= Method

== Solution flowchart

This flowchart represents a simplified view of the solution.
The problem variables, representing the machines, resource requirements, scheduled jobs, and costs, are passed to the scheduler.
The scheduler then computes a solution, including the machines to buy, and the job packing configurations to use for each time slot.

#diagram(
  node-stroke: 1pt,
  node((-1, 1), [
    Problem instance \
    $C,R,L,c^r,c^p$
  ]),
  edge("-|>"),
  node((0, 1), align(center)[
    Scheduler
  ]),
  edge("-|>"),
  node((1, 1), [
    Problem solution \
    $bold(x), bold(Y)_i, bold(n)_(i,t)$
  ]),
)


== Research questions

With this research, we aim to answer the following research questions:

RQ1: How can we create a cloud job scheduler which is efficient with respect to energy consumption? \
RQ2: How can we create a cloud job scheduler which is optimized for both scheduling quality and execution time?

== Upper bound on machine types

Before we begin to search for an optimal machine vector $bold(x)$, we want to find an upper bound $bold(x) <= bold(x)_U$.
This will restrict the search space.

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

// == Lower bound on machine types
// 
// Let $S_(t,m)$ be the set of all jobs running on machines of type $m$ during time slot $t$.
// For each resource $k$, the job's demand is $r_(j,k)$ and the machine's capacity is $C_(m,k)$.
// If we are running $N_(t,m)$ machines of type $m$ during time slot $t$, then for each resource $k$, total demand must not exceed total capacity:
// 
// $
//   sum_(j in S_(t,m)) r_(j,k) <= N_(t,m) C_(m,k)
// $
// 
// Rearranging, we have
// 
// $
//   ceil(sum_(j in S_(t,m)) r_(j,k)/C_(m,k)) <= N_(t,m), quad forall k
// $
// 
// This must hold for every resource, so
// 
// $
//   max_k ceil(sum_(j in S_(t,m)) r_(j,k)/C_(m,k)) <= N_(t,m), quad forall k \
// $
// 
// We see that we have found a lower bound on the number of machines of each type needed for each time slot.
// Since we can reuse machines between time slots, we need to own enough machines to handle the highest (lowest) demand over all time slots.
// 
// $
//   N_m = max_t N_(t,m)
// $
// This gives us a lower bound $bold(x)_L$ to $bold(x)$.
