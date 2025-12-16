= Problem description <problem_description_section>

#let ZZnonneg = $ZZ_(>=0)$
#let ZZpos = $ZZ_(>0)$

There are $J$ different types of jobs.
Each job type has a certain hardware resource requirement.
There are $K$ different types of hardware resources, e.g. CPU, memory, disk, GPU.
The hardware requirements of job type $j$, for $1<=j<=J$, is described with a vector $bold(r)_j in ZZnonneg^K$.
We collect these job resource requirements as column vectors in a requirements matrix $bold(R)$ with dimensions $(K,J)$.

$
  bold(R) = mat(|, |, , |; bold(r)_1, bold(r)_2, dots.c, bold(r)_J; |, |, , |)
$

The customer workloads will run for a total of $T$ equally-sized time slots.
For the sake of simplicity, time slots will have unit duration.
Each job must run during its given time slot, and cannot be scheduled for some other future time slot.
For each time slot $t$, the vector $bold(l)_t in ZZnonneg^J$ gives the number of each job type which must run during the slot.
We collect these job time slot vectors as column vectors in a $(J , T)$ load profile matrix $bold(L)$.

$
  bold(L) = mat(|, |, , |; bold(l)_1, bold(l)_2, dots.c, bold(l)_T; |, |, , |)
$

There are $M$ different kinds of machines available to buy.
The initial purchase cost of each machine type is given by the vector $bold(c^p) in ZZnonneg^M$.
A machine instance of type $i$ costs $c_i^p$ to buy.
We will not be considering constraints on the maximum number of instances of a given machine type.
For each time slot, a machine instance can either be running or powered off.
The per time-slot running cost of each machine type is given by the vector $bold(c^r) in ZZnonneg^M$.
A running machine instance of type $i$ has a running cost of $c_i^r$ per time slot.
We will be assuming a constant running cost for running instances, regardless of the jobs running on the instances.

The purchase and running costs of the machines types are a function of their respective capacity vectors.
The purchase and running cost vectors are given by:

$
  bold(c^p) = bold(C)^T bold(alpha), quad bold(c^r) = gamma bold(c^p), quad bold(alpha) in [0,1)^K, quad gamma in (0,1)
$

where $bold(alpha)$ is a vector where the element $alpha_k$ represents the weight of resource $k$.

We will not allow a single job to be split across multiple machines.
Machines incur no running cost while powered off.
Each machine type has a different hardware configuration, e.g. CPU, memory, disk, GPU, etc.
We assume here that there exists some method for mapping machine hardware resource capacities to non-negative integers.
The hardware configuration of machine type $i$, for $1<=i<=M$, is described with a vector $bold(m)_i in ZZnonneg^K$.
Suppose a machine type $i$ has the following hardware capacity values: 2 CPU, 4 memory, 3 disk, 0 GPU.
Then machine type $i$ would be described as $bold(m)_i=mat(2, 4, 3, 0)^T$.
We collect these machine types as column vectors in a $(K , M)$ capacity matrix $bold(C)$.

$
  bold(C) = mat(|, |, , |; bold(m)_1, bold(m)_2, dots.c, bold(m)_M; |, |, , |)
$


Let the vector $bold(x) in ZZnonneg^M$ be the decision variable representing our selection of machine types.
The vector element $x_i$ equals the number of machines of type $i$ we choose to buy.
The total initial cost of buying our selected machines will then be given by $bold(x)^(T)bold(c^p)$.

To calculate our total running cost, we introduce the variables $z_(t) in ZZnonneg^M$, where $z_(t,m)$ denotes the number of instances of machine type $m$ which are powered on during time slot $t$.

Since the number of powered on instances of any machine type can not exceed the number of purchased instances of the given type, we must add the constraints $bold(z)_t<=bold(x) ,forall t$.

The cost of running our machine instances will be given by i.e. $sum_(t=1)^T bold(z)_t^T bold(c^r)$.
This is the sum over all time slots of the scalar product of the vector of machine type running costs and the vector of the number of each machine type running during the time slot.

The total hardware resource capacity available for time slot $t$ is then given by $bold(C) bold(z)_t$.
In order to be able to schedule and run all pending jobs, the following constraints must be satisfied.

$
  bold(C z)_t >= bold(R l)_t , forall t
$

Finally, we can state an optimization problem.

$
  "minimize" \ bold(x)^(T)bold(c^p) + sum_(t=1)^T bold(z)_t^T bold(c^r)\
  "subject to" \
  bold(C z)_t >= bold(R l)_t , forall t \
  bold(z)_t <= bold(x) ,forall t \
  bold(x) in ZZnonneg^M quad
  bold(z)_t in ZZnonneg^M ,forall t
$

However, this is not an accurate model of the problem.
The solutions given by the simplified optimization problem above are not guaranteed to be valid allocations of jobs to machines.
In reality, jobs must be _packed_ into machines.
For each time slot and for each machine type, the sum of the resource requirements for all jobs allocated to the machine type must not exceed its resource capacities.
This is a form of _bin-packing_, in which the machine types are the bins, and the job types are the objects which must be placed in the bins.
Specifically, is is a _multi-dimensional heterogeneous bin-packing_ problem.
The problem is _multi-dimensional_ since the jobs have multiple dimensions in the form of resource requirements.
The problem is _heterogeneous_ since the bins have different resource capacities.

Because the stated problem does not have these packing constraints, it can only yield _lower bound_ solutions.

Let us now describe the variables and constraints required to state an optimization problem which will guarantee valid allocations of jobs to machines.
We introduce the vectors $bold(y)_t^((i)) in ZZnonneg^J$ to denote the number of each job type allocated per powered-on instance of machine type $i$ to time slot $t$.

Using these new variables, we define two new constraints.
First, the constraint
$
  sum_(i=1)^M z_(i,t) bold(y)_t^((i)) >= bold(l)_t , forall 1<=t<=T
$
ensures that all jobs scheduled for each time slot will be run.

// The vector $bold(y)_t^((i))$ gives the number of each job type which will run per powered-on instance of machine type $i$ during time slot $t$.
// For time slot $t$, there are $z_t^i$ instances of machine type $i$ powered on.

Second, the constraint

$
  bold(R) bold(y)_t^((i)) <= bold(m)_i ,forall 1<=i<=M, 1<=t<=T
$

ensures that the sum of the resource requirements for all jobs allocated to the machine type must not exceed its resource capacities at any time slot.
To understand this constraint, note that element $r_(k,j)$ of $bold(R)$ is the requirement for resource $k$ for job type $j$.
Therefore, the row vector for row $k$ of $bold(R)$, call it $bold(q^((k)))$, gives the resource requirement of resource $k$ of each job type.
The scalar product of $bold(q^((k)))$ and $bold(y)_t^((i))$ is then the sum of the resource requirement of resource $k$ of each job type, scaled by the number of jobs of type $j$ allocated to machine type $i$ in time slot $t$.
This must hold for each resource type $k$, and machine type $i$.
Thus, we must have $bold(R) bold(y)_t^((i)) <= bold(m)_i ,forall i,t$.

Now we may state a more realistic optimization problem.

$
  "minimize" \ bold(x)^(T)bold(c^p) + sum_(t=1)^T bold(z)_t^T bold(c^r) \
  "subject to" \
  sum_(i=1)^M z_(i,t) bold(y)_t^((i)) >= bold(l)_t quad forall 1<=t<=T \
  bold(R) bold(y)_t^((i)) <= bold(m)_i quad forall 1<=i<=M ,quad 1<=t<=T \
  bold(x) in ZZnonneg^M, quad
  bold(z)_t in ZZnonneg^M forall t, quad
  bold(y)_t^((i)) in ZZnonneg^J forall t,i
$


However, this formulation only allows for a single job packing configuration per machine type.
In reality, there will exist a large set of valid job packing configurations per machine type.
In order to express this, we require new notation.
Let $S_i$ be the set of all valid job packings for machine type $i$.

$
  S_i = {bold(y) in ZZnonneg^J | bold(R y) <= bold(m)_i}
$

Let $bold(n)_(i,t) in ZZnonneg^(abs(S_i))$ be a vector where element $n_(i,t,k)$ is the number of machine instances of type $i$ that are running job packing configuration $k$ during time slot $t$.
For each machine type $i$, let $bold(Y)_i in ZZnonneg^(J crossmark abs(S_i))$ be a matrix with column vectors from the set $S_i$.

$
  bold(Y)_i = mat(|, |, , |; bold(y)_(i,1), bold(y)_(i,2), dots.c, bold(y)_(i,abs(S_i)); |, |, , |)
$

The column vectors of $bold(Y)_i$ will be ordered by size: $forall i,j,k: j<k <=> bold(y)_(i,j) < bold(y)_(i,k)$.
We can now state our constraints.
As before, for each time slot, the powered-on machines must be able to run all pending jobs.
We express this constraint as following.

$
  sum_(i=1)^M bold(Y)_i bold(n)_(i,t) >= bold(l)_t quad forall t
$

Remember that the column vectors of $bold(Y)_i$ are elements of the set $S_i$.
For each vector $bold(y) in S_i$, we have $bold(R)bold(y)<=bold(m)_i$.
Each column vector of $bold(Y)_i$ represents a possible valid job packing configuration of jobs for a machine instance of type $i$.
The vector $bold(n)_(i,t)$ gives the number of machine instances of type $i$ running each job packing configuration during time slot $t$.
Therefore, row $j$ of $bold(Y)_i bold(n)_(i,t)$ gives the total number of jobs of type $j$ running on machine instances of type $i$ during time slot $t$.

Note that:
$ sum_(k=1)^(abs(S_i)) n_(i,t,k) = z_(i,t) quad forall i,t $
We can now state our new optimization problem.

$
  "minimize" \
  bold(x)^T bold(c^p) + sum_(i=1)^(M) c^r_i sum_(t=1)^(T) sum_(k=1)^(abs(S_i)) n_(i,t,k) =
  bold(x)^T bold(c^p) + sum_(t=1)^(T) bold(z_t^T) bold(c^r) \
  "subject to" \
  bold(y)_(i,j) in S_i quad forall i, j \
  bold(Y)_i = mat(bold(y)_(i,1), ..., bold(y)_(i,abs(S_i))) \
  S_i = {bold(y) in ZZnonneg^J | bold(R y) <= bold(m)_i} quad forall i \
  sum_(i=1)^M bold(Y)_i bold(n)_(i,t) >= bold(l)_t quad forall t \
$

How shall we approach this problem?
One idea would be to leverage the previous optimization problem.
Since it has fewer constraints, it may be easier to solve.
If we could solve that problem, then we could use its lower-bound solutions to help us find solutions to the real problem.
We could accept approximate solutions to the real problem if they are close enough to a lower-bound solution.

Another approach would be to view the problem as an integer linear programming problem.
These problems are not convex, which makes them more difficult to solve than ordinary fractional LP problems.
We could use an optimized version of the branch-and-bound algorithm where we choose to only round fractional variables up, and not down.
For example, if at some step of the algorithm we find we should purchase $5.8$ of some machine type, we would only round this number up to $6$, and not down to $5$.
With this optimization, we would only need to solve a single subproblem for each fractional variable.

However, since bin-packing is an NP-hard problem, it is very likely that using exact solution methods will become computationally infeasible for problem instances involving a larger numbers of time slots
A more suitable approach method may be to solve the problem in multiple stages.
First, for each time slot, solve for the set of all valid job-machine allocations.
This stage may be run in parallel across time slots.
Next, given the set of all valid job-machine allocations for each time slot, find the subset of allocations which are valid for all time slots.
Finally, find the optimal allocation from this subset.
Solving for the valid allocations for each time slot can be considered a trivial problem.
The cost function of a given allocation is also very easy to compute.
The second stage is by far the most difficult.
Just as there can be an extremely large number of valid placements of objects in bins, there can be an extremely large number of valid allocations for each time slot.
Here we will need to study heuristics-based methods of pruning the search space.

== Symbol reference table

#figure(
  table(
    columns: 4,
    align: horizon,
    table.header([*Symbol*], [*Type*], [*Shape*], [*Description*]),
    [K], [Scalar], [-], [Number of resource types],
    [J], [Scalar], [-], [Number of job types],
    [M], [Scalar], [-], [Number of machine types],
    [T], [Scalar], [-], [Number of time slots],
    [$bold(R)$], [Matrix], [(K,J)], [Resource requirement of each job type],
    [$bold(C)$], [Matrix], [(K,M)], [Resource capacity of each machine type],
    [$bold(L)$], [Matrix], [(J,T)], [Number of each job type scheduled for each time slot],
    [$bold(r)_j$], [Vector], [K], [Resource requirement of job type $j$],
    [$bold(m)_i$], [Vector], [K], [Resource capacity of machine type $i$],
    [$bold(x)$], [Vector], [M], [Number of each machine type purchased],
    [$bold(c)^p$], [Vector], [M], [Cost to buy one of each machine type],
    [$bold(c)^r$], [Vector], [M], [Per time-slot (powered-on) running cost for each machine type],
    [$bold(z)_t$], [Vector], [M], [Number of each machine type powered-on during time slot $t$],
    [$S_i$], [Set], [-], [All valid job packing configurations for machine type $i$],
    [$bold(y)_(i,j)$], [Vector], [J], [A valid job packing configuration for machine type $i$],
    [$bold(Y)_(i)$], [Matrix], [(J,$abs(S_i)$)], [Matrix with column vectors in $S_i$],
    [$bold(n)_(i,t)$], [Vector], [$abs(S_i)$], [Number of each machine type $i$ job packing used for time slot $t$],
  ),
  caption: [Symbol reference table],
) <symbol_ref_table>

#pagebreak()
== Example

We will now show a small example of the problem.

$
  J=2, M=2, K=3, T=3 \
  R = mat(2, 1; 1, 1; 0, 1) quad C = mat(3, 1; 2, 3; 1, 0) quad L = mat(1, 2, 0; 1, 0, 1) \
  bold(c^p) = mat(5, 6) quad bold(c^r) = mat(1, 1/2)
$

This problem instance has two job types, two machine types, three resource types, and three time slots.
We now present a solution to the problem.
This solution is not guaranteed to be optimal.

$
  bold(x) = mat(2, 0) quad
  bold(Y)_1 = mat(1, 0; 0, 1) quad
  bold(Y)_2 = mat(0, 0; 0, 0) \
  bold(n)_(1,1) = mat(1, 1) quad
  bold(n)_(1,2) = mat(2, 0) quad
  bold(n)_(1,3) = mat(0, 1) \
  bold(n)_(2,t) = mat(0, 0) quad forall t \
$

Let us now interpret this solution.

We shall buy $2$ instances of machine type $1$, and $0$ instances of machine type $2$.

For time slot $1$, one machine instance will run $1$ type $1$ job and the other machine instance will run $1$ type $2$ job.

For time slot $2$, both machine instances will each run $1$ type $1$ job.

For time slot $3$, one machine instance will run $1$ type $2$ job. The other machine will be powered off.

The solution can also be represented by this table.

#let example_solution_data = csv("../example_job_schedule_solution.csv")

#table(
  columns: 6,
  ..example_solution_data.flatten()
)

The matrices $bold(Y)_1$, $bold(Y)_2$ shown here do not contain all possible job packings for each respective machine type.
We only show the job packings which we use for this specific solution.

We shall now show that this is a valid solution.

We begin with showing that all job packing configurations for all machine types are valid.
In other words, for each machine type and for each job packing configuration for the machine type, the total resource demand for the configuration does not exceed the resource capacity of the machine type.

$
  bold(y) in bold(S)_i <=> bold(R)bold(y) <= bold(m)_i quad forall i
$

#let Rmat = $mat(2, 1; 1, 1; 0, 1)$

$
  i=1:\
  Rmat vec(1, 0) <= vec(3, 2, 1) ,quad
  Rmat vec(0, 1) <= vec(3, 2, 1) \
  i=2:\
  Rmat bold(arrow(0)) <= vec(1, 3, 0)
$

Next, we show that our machines can run all scheduled jobs for all time slots.

$
  sum_(i=1)^M bold(Y)_i bold(n)_(i,t) >= bold(l)_t quad forall t \
$

We see that the constraint is satisfied for all time slots.

#let Yone = $mat(1, 0; 0, 1)$
#let Ytwo = $mat(0, 0; 0, 0)$
$
  t=1: Yone vec(1, 1) + Ytwo vec(0, 0) >= vec(1, 1) \
  t=2: Yone vec(2, 0) + Ytwo vec(0, 0) >= vec(2, 0) \
  t=3: Yone vec(0, 1) + Ytwo vec(0, 0) >= vec(0, 1)
$


Now, we can calculate the cost of buying and running these machines.
The cost to buy the machines is $2 * 5 + 0 * 4 = 10$.
The type $1$ machine costs $5$ to buy, and we buy $2$ instances.
We do not buy any type $2$ instances.
The cost to run the machines is $1 * 5 + 1/2 * 0 = 5$.
The type $1$ machine costs $1$ per time slot to run, and we run them for a total of $5$ time slots.
We do not own any type $2$ machines.

The total cost for this solution is $10 + 5 = 15$.

This solution shows how we can use different job packing configurations for a single machine type.
