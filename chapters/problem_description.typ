= Problem Description <problem_description_section>

This chapter formalizes the offline job scheduling problem and introduces the notation used throughout the thesis.

#let ZZnonneg = $ZZ_(>=0)$
#let ZZpos = $ZZ_(>0)$

There are $J$ different types of jobs.
For a positive integer $n$, let $cal(n) = {1,dots.h,n}$ denote the index set from $1$ to $n$.
Each job type has certain hardware resource requirements.
There are $K$ different types of hardware resources, e.g. CPU, memory, disk, GPU, etc.
The resource demands of job type $j in cal(J)$ is described with a $K$-dimensional vector $bold(r)_j in ZZnonneg^K$ with non-negative integer elements.
We assume that every job type has non-zero total demand, i.e. $sum_(k=1)^K r_(k,j) > 0$ for all $j in cal(J)$.
We collect these job resource requirements as column vectors in a job resource demand matrix $bold(R)$ with dimensions $(K,J)$.

$
  bold(R) = mat(|, |, , |; bold(r)_1, bold(r)_2, dots.c, bold(r)_J; |, |, , |)
$

There are $M$ different kinds of machines available to buy.
Each machine type has a certain hardware resource capacity.
The resource capacity of machine type $i in cal(M)$ is described with a $K$-dimensional vector $bold(m)_i in ZZnonneg^K$ with non-negative integer elements.
We collect these machine types as column vectors in a machine resource capacity matrix $bold(C)$ with dimensions $(K , M)$.
// Suppose a machine type $i$ has the following hardware capacity values: 2 CPU, 4 memory, 3 disk, 0 GPU.
// Then machine type $i$ would be described as $bold(m)_i=mat(2, 4, 3, 0)^T$.
// We assume here that there exists some method for mapping machine hardware resource capacities to non-negative integers.

$
  bold(C) = mat(|, |, , |; bold(m)_1, bold(m)_2, dots.c, bold(m)_M; |, |, , |)
$

The predicted workload will be divided into $T$ time slots of equal duration.
For each time slot $t$, the $J$-dimensional vector $bold(l)_t in ZZnonneg^J$ gives the number of jobs of each type which must be scheduled during the slot.
All jobs will run for the entirety of their assigned time slot.
Each job must run during its given time slot, and cannot be scheduled for some other time slot.
The $bold(l)_t$ values should be assumed to be a prediction of future workload demand.
However, we shall consider these values to be deterministic.
We collect these job time slot vectors as column vectors in a $(J , T)$ workload matrix $bold(L)$.

$
  bold(L) = mat(|, |, , |; bold(l)_1, bold(l)_2, dots.c, bold(l)_T; |, |, , |)
$

The initial purchase cost of each machine type is given by the $M$-dimensional vector $bold(c^p) in ZZnonneg^M$ of non-negative integers.
A machine instance of type $i$ costs $c_i^p$ to buy.
We will not be considering constraints on the maximum number of instances of a given machine type.
For each time slot, a machine instance can either be running or powered off.
The per time-slot running cost of each machine type is given by the $M$-dimensional vector $bold(c^r) in ZZnonneg^M$ of non-negative integers.
A running machine instance of type $i$ has a running cost of $c_i^r$ per time slot.
We will be assuming a constant running cost for running instances, regardless of the jobs running on the instances.
The purchase and running costs of the machines types are a function of their respective capacity vectors.
The purchase and running cost vectors are given by:

$
  bold(c^p) = bold(C)^T bold(alpha), quad bold(c^r) = gamma bold(c^p), quad bold(alpha) in [0,1)^K, quad gamma in (0,1)
$

where $bold(alpha)$ is a vector where the element $alpha_k$ represents the weight of resource $k$.
The vector $bold(c^r)$ of machine type per-slot running costs is a fixed percentage $gamma$ of the vector $bold(c^p)$ of machine type purchase costs.
That is, the running cost of each machine type is a fixed percentage $gamma$ of its up-front purchase cost.
We will not allow a single job to be split across multiple machines.
Supporting fragmented jobs would likely greatly increase the complexity of the problem.
Machines incur no running cost while powered off.
Let the $M$-dimensional vector $bold(x) in ZZnonneg^M$ be the decision variable representing our selection of machine types.
The vector element $x_i$ equals the number of machines of type $i$ we choose to buy.
The total initial cost of buying our selected machines will then be given by the scalar product $bold(x)^(T)bold(c^p)$.
To calculate our total running cost, we introduce the variables $bold(z)_t in ZZnonneg^M$, where $z_(t,i)$ denotes the number of instances of machine type $i$ which are powered on during time slot $t$.
Since the number of powered on instances of any machine type can not exceed the number of purchased instances of the given type, we must add the constraints $bold(z)_t<=bold(x) ,forall t in cal(T)$.
The cost of running our selected machine instances will be given by the following expression.
$
  sum_(t=1)^T sum_(i=1)^M z_(t,i) c^r_i
$
This is the sum over all time slots of the scalar product of the vector of machine type running costs and the vector of the number of each machine type running during the time slot.
The total hardware resource capacity available for time slot $t$ is then given by $bold(C) bold(z)_t$.
In order to be able to schedule and run all pending jobs, the following constraints must be satisfied.

$
  bold(C) bold(z)_t >= bold(R) bold(l)_t , forall t in cal(T)
$

This constraint compares total available capacity with total workload demand for each time slot.
The vector $bold(C) bold(z)_t$ gives the aggregate amount of each resource provided by the machines powered on during time slot $t$.
The vector $bold(R) bold(l)_t$ gives the aggregate amount of each resource required by all jobs that must run during the same time slot.
Thus, the constraint states that, for every resource dimension, the powered-on machines must provide at least as much total capacity as the jobs require.

Finally, we can state an optimization problem.

$
    "minimize" & quad bold(x)^(T)bold(c^p) + sum_(t=1)^T sum_(i=1)^M z_(t,i) c^r_i \
  "subject to" & quad bold(C) bold(z)_t >= bold(R) bold(l)_t , forall t in cal(T) \
               & quad bold(z)_t <= bold(x) ,forall t in cal(T) \
               & quad bold(x) in ZZnonneg^M quad bold(z)_t in ZZnonneg^M ,forall t in cal(T)
$

The objective function minimizes the total cost of the selected machine fleet.
The first term, $bold(x)^(T)bold(c^p)$, is the one-time purchase cost of the machines.
The second term is the total running cost over all time slots, obtained by multiplying the number of powered-on machines of each type by their per-slot running costs.
The first constraint enforces aggregate resource sufficiency in every time slot.
The second constraint states that we cannot power on more machines of a type than we have purchased.
The final constraint states that both the purchase decisions and the powered-on machine counts must be non-negative integers.

However, this is not an accurate model of the problem.
The solutions given by the simplified optimization problem above are not guaranteed to be valid allocations of jobs to machines.
In reality, jobs must be _packed_ into machines.
For each time slot and for each machine type, the sum of the resource requirements for all jobs allocated to the machine type must not exceed its resource capacities.
This is a form of _bin-packing_, in which the machine types are the bins, and the job types are the objects which must be placed in the bins.
Specifically, it is a _multi-dimensional heterogeneous bin-packing_ problem.
The problem is _multi-dimensional_ since the jobs have multiple dimensions in the form of resource requirements.
The problem is _heterogeneous_ since the bins have different resource capacities.

Because the stated problem does not have these packing constraints, it can only yield _lower bound_ solutions.
It may select a fleet whose total capacity is large enough when all machines are viewed as one combined resource pool, even though the individual jobs cannot be divided into a valid set of per-machine assignments.
Any solution that is feasible for the real scheduling problem must also satisfy the aggregate capacity constraints above, but the reverse is not necessarily true.
Therefore, the simplified model can underestimate the true minimum cost.

Let us now describe the variables and constraints required to state an optimization problem which will guarantee valid allocations of jobs to machines.
We introduce the vectors $bold(y)_t^((i)) in ZZnonneg^J$ to denote the number of each job type allocated per powered-on instance of machine type $i$ to time slot $t$.
Using these new variables, we define two new constraints.
First, the constraint
$
  sum_(i=1)^M z_(t,i) bold(y)_t^((i)) = bold(l)_t , forall t in cal(T)
$
ensures that exactly the jobs scheduled for each time slot will be run.
For a fixed time slot $t$, the term $z_(t,i) bold(y)_t^((i))$ is the number of jobs assigned to all powered-on machines of type $i$.
Summing over all machine types therefore gives the total number of scheduled jobs of each type.
The equality to $bold(l)_t$ means that every required job is assigned, and that no extra jobs are introduced.
Second, the constraint

$
  bold(R) bold(y)_t^((i)) <= bold(m)_i ,forall i in cal(M), t in cal(T)
$

ensures that the sum of the resource requirements for all jobs allocated to the machine type must not exceed its resource capacities at any time slot.
This is a per-machine packing constraint.
For one powered-on machine instance of type $i$, the vector $bold(y)_t^((i))$ describes the jobs placed on that machine during time slot $t$.
Multiplying by $bold(R)$ converts those job counts into resource demand, and the inequality requires that this demand fits within the capacity vector $bold(m)_i$.
To understand this constraint, note that element $r_(k,j)$ of $bold(R)$ is the requirement for resource $k$ for job type $j$.
Therefore, the row vector for row $k$ of $bold(R)$, call it $bold(q^((k)))$, gives the resource requirement of resource $k$ of each job type.
The scalar product of $bold(q^((k)))$ and $bold(y)_t^((i))$ is then the sum of the resource requirement of resource $k$ of each job type, scaled by the number of jobs of type $j$ allocated to machine type $i$ in time slot $t$.
This must hold for each resource type $k$, and machine type $i$.
Thus, we must have $bold(R) bold(y)_t^((i)) <= bold(m)_i ,forall i in cal(M), t in cal(T)$.
Now we may state a more realistic optimization problem.

// The vector $bold(y)_t^((i))$ gives the number of each job type which will run per powered-on instance of machine type $i$ during time slot $t$.
// For time slot $t$, there are $z_(t,i)$ instances of machine type $i$ powered on.

$
  "minimize" & quad bold(x)^(T)bold(c^p) + sum_(t=1)^T bold(z)_t^T bold(c^r) \
  "subject to" & quad sum_(i=1)^M z_(t,i) bold(y)_t^((i)) = bold(l)_t, quad forall t in cal(T) \
  & quad bold(R) bold(y)_t^((i)) <= bold(m)_i, quad forall i in cal(M), t in cal(T) \
  & quad bold(x) in ZZnonneg^M, quad bold(z)_t in ZZnonneg^M forall t in cal(T), quad bold(y)_t^((i)) in ZZnonneg^J, quad forall i in cal(M), t in cal(T)
$

The objective has the same interpretation as before: purchase cost plus running cost.
The first constraint assigns all required jobs in each time slot to powered-on machines.
The second constraint requires the per-machine job assignment to fit inside the capacity of one machine of the corresponding type.
The final constraint restricts all decision variables to non-negative integer values, since the model chooses counts of machines and jobs.

However, this formulation only allows for a single job packing configuration per machine type.
In reality, there will exist a large set of valid job packing configurations per machine type.
In order to express this, we require new notation.
Let $S_i$ be the set of all valid job packings for machine type $i$.

$
  S_i = {bold(y) in ZZnonneg^J | bold(R y) <= bold(m)_i}
$

The set $S_i$ contains every possible combination of job counts that can fit on one machine instance of type $i$.
Each vector $bold(y) in S_i$ is therefore one feasible way to pack jobs onto a single machine of that type.

Let $bold(n)_(i,t) in ZZnonneg^(abs(S_i))$ be a vector where element $n_(i,t,k)$ is the number of machine instances of type $i$ that are running job packing configuration $k$ during time slot $t$.
For each machine type $i$, let $bold(Y)_i in ZZnonneg^(J crossmark abs(S_i))$ be a matrix with column vectors from the set $S_i$.

$
  bold(Y)_i = mat(|, |, , |; bold(y)_(i,1), bold(y)_(i,2), dots.c, bold(y)_(i,abs(S_i)); |, |, , |)
$

The column vectors of $bold(Y)_i$ will be ordered by size: $forall i in cal(M), j,k in cal(abs(S_i)): j<k <=> bold(y)_(i,j) < bold(y)_(i,k)$.
We can now state our constraints.
As before, for each time slot, the powered-on machines must be able to run all pending jobs.
We express this constraint as following.

$
  sum_(i=1)^M bold(Y)_i bold(n)_(i,t) >= bold(l)_t quad forall t in cal(T)
$

Remember that the column vectors of $bold(Y)_i$ are elements of the set $S_i$.
For each vector $bold(y) in S_i$, we have $bold(R)bold(y)<=bold(m)_i$.
Each column vector of $bold(Y)_i$ represents a possible valid job packing configuration of jobs for a machine instance of type $i$.
The vector $bold(n)_(i,t)$ gives the number of machine instances of type $i$ running each job packing configuration during time slot $t$.
Therefore, row $j$ of $bold(Y)_i bold(n)_(i,t)$ gives the total number of jobs of type $j$ running on machine instances of type $i$ during time slot $t$.
Equivalently, $bold(Y)_i bold(n)_(i,t)$ is the vector of jobs served by all active machines of type $i$ during time slot $t$.
After summing this vector over all machine types, the resulting vector must cover the workload vector $bold(l)_t$.
Note that:
$ sum_(k=1)^(abs(S_i)) n_(i,t,k) = z_(t,i), quad forall i in cal(M), t in cal(T). $
We can now state our new optimization problem.

$
  "minimize" & quad bold(x)^T bold(c^p) + sum_(i=1)^(M) c^r_i sum_(t=1)^(T) sum_(k=1)^(abs(S_i)) n_(i,t,k) \
  //=bold(x)^T bold(c^p) + sum_(t=1)^(T) bold(z)_t^T bold(c^r) \
  "subject to" & quad S_i = {bold(y) in ZZnonneg^J | bold(R y) <= bold(m)_i}, quad forall i in cal(M) \
  & quad bold(Y)_i = mat(bold(y)_(i,1), ..., bold(y)_(i,abs(S_i))) \
  & quad bold(y)_(i,j) in S_i quad forall i in cal(M), j in cal(abs(S_i)) \
  & quad sum_(i=1)^M bold(Y)_i bold(n)_(i,t) >= bold(l)_t quad forall t in cal(T) \
  & quad sum_(k=1)^(abs(S_i)) n_(i,t,k) <= x_i quad forall i in cal(M), t in cal(T) \
  & quad bold(x) in ZZnonneg^M, quad bold(n)_(i,t) in ZZnonneg^(abs(S_i)) quad forall i in cal(M), t in cal(T)
$

In this final formulation, the objective again minimizes purchase cost plus running cost.
The first term, $bold(x)^T bold(c^p)$, is the cost of buying the selected machines.
The second term counts how many machine instances of each type are active across all time slots and packing configurations, and multiplies those counts by the corresponding per-slot running cost.
The first three constraints define the feasible packing configurations for each machine type and collect them in the matrices $bold(Y)_i$.
The fourth constraint requires the selected packing configurations to cover all jobs in every time slot.
The fifth constraint states that the number of active machine instances of type $i$ in any time slot cannot exceed the number $x_i$ purchased.
The final constraint enforces non-negative integer counts for purchased machines and active packing configurations.

== Symbol reference table

#figure(
  table(
    columns: 4,
    align: center,
    table.header([*Symbol*], [*Type*], [*Shape*], [*Description*]),
    [K], [Scalar], [-], [Number of resource types],
    [J], [Scalar], [-], [Number of job types],
    [M], [Scalar], [-], [Number of machine types],
    [T], [Scalar], [-], [Number of time slots],
    [$cal(n)$], [Set], [-], [Index set ${1,dots.h,n}$ for a positive integer $n$],
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
    [$bold(alpha)$], [Vector], [$K$], [Value of each resource],
    [$alpha_k$], [Scalar], [-], [Value of resource $k$],
    [$gamma$], [Scalar], [-], [Machine type running cost multiplier factor],
  ),
  caption: [Symbol reference table],
) <symbol_ref_table>

#pagebreak()
== Example

We will now show a small example of the problem.

$
  J=2, M=2, K=3, T=3 \
  bold(R) = mat(2, 1; 1, 1; 0, 1) quad bold(C) = mat(3, 1; 2, 3; 1, 0) quad bold(L) = mat(1, 2, 0; 1, 0, 1) \
  bold(alpha) = vec(1/2, 1/2, 1/2) quad gamma = 1/2 \
  bold(c^p) = bold(C)^T bold(alpha) = vec(3, 2) quad bold(c^r) = gamma bold(c^p) = vec(3/2, 1)
$

For machine type $1$, the feasible packing configurations are:

$
  S_1 = {vec(0, 0), vec(1, 0), vec(0, 1), vec(1, 1)}
$

For machine type $2$, the feasible packing configurations are:

$
  S_2 = {vec(0, 0)}
$

Thus, we can define the packing matrices:

$
  bold(Y)_1 = mat(0, 1, 0, 1; 0, 0, 1, 1) quad
  bold(Y)_2 = mat(0; 0)
$

Consider the following solution:

$
  bold(x) = vec(2, 0) \
  bold(n)_(1,1) = vec(0, 0, 0, 1) quad
  bold(n)_(1,2) = vec(0, 2, 0, 0) quad
  bold(n)_(1,3) = vec(0, 0, 1, 0) \
  bold(n)_(2,t) = vec(0) quad forall t in cal(T)
$

The solution buys two instances of machine type $1$ and no instances of machine type $2$.
In time slot $1$, one machine of type $1$ runs one job of each type.
In time slot $2$, two machines of type $1$ each run one job of type $1$.
In time slot $3$, one machine of type $1$ runs one job of type $2$.

We verify the solution by checking the same feasibility conditions used in the final optimization problem.
First, we verify that the used packing configurations belong to the corresponding sets $S_i$:

$
  bold(R) vec(0, 0) = vec(0, 0, 0) <= vec(3, 2, 1) \
  bold(R) vec(1, 0) = vec(2, 1, 0) <= vec(3, 2, 1) \
  bold(R) vec(0, 1) = vec(1, 1, 1) <= vec(3, 2, 1) \
  bold(R) vec(1, 1) = vec(3, 2, 1) <= vec(3, 2, 1) \
  bold(R) vec(0, 0) = vec(0, 0, 0) <= vec(1, 3, 0)
$

We then verify the workload coverage constraint, meaning that the selected packing configurations serve exactly the jobs required in each time slot:

$
  t=1: bold(Y)_1 vec(0, 0, 0, 1) + bold(Y)_2 vec(0) = vec(1, 1) = bold(l)_1 \
  t=2: bold(Y)_1 vec(0, 2, 0, 0) + bold(Y)_2 vec(0) = vec(2, 0) = bold(l)_2 \
  t=3: bold(Y)_1 vec(0, 0, 1, 0) + bold(Y)_2 vec(0) = vec(0, 1) = bold(l)_3
$

#block(breakable: false, [
  Finally, we verify the purchased-machine constraint, meaning that the number of powered-on machines does not exceed the number of purchased machines:

  $
    t=1: sum_(k=1)^(abs(S_1)) n_(1,1,k) = 1 <= x_1 \
    t=2: sum_(k=1)^(abs(S_1)) n_(1,2,k) = 2 <= x_1 \
    t=3: sum_(k=1)^(abs(S_1)) n_(1,3,k) = 1 <= x_1 \
    sum_(k=1)^(abs(S_2)) n_(2,t,k) = 0 <= x_2 quad forall t in cal(T)
  $
])

The purchase cost is:

$
  bold(x)^T bold(c^p) = 2 dot 3 + 0 dot 2 = 6
$

The running cost is:

$
  sum_(i=1)^M c^r_i sum_(t=1)^T sum_(k=1)^(abs(S_i)) n_(i,t,k)
  = (3/2) dot (1 + 2 + 1) + 1 dot 0 = 6
$

Therefore, the total cost of this solution is $6 + 6 = 12$.
