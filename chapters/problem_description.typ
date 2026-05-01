= Problem Description <problem_description_section>

This chapter formalizes the offline job scheduling problem and introduces the notation used throughout the thesis.

#let ZZnonneg = $ZZ_(>=0)$
#let ZZpos = $ZZ_(>0)$

There are $J$ different types of jobs.
Each job type has certain hardware resource requirements.
There are $K$ different types of hardware resources, e.g. CPU, memory, disk, GPU, etc.
The resource demands of job type $j$, for $1<=j<=J$, is described with a $K$-dimensional vector $bold(r)_j in ZZnonneg^K$ with non-negative integer elements.
We assume that every job type has non-zero total demand, i.e. $sum_(k=1)^K r_(k,j) > 0$ for all $1<=j<=J$.
We collect these job resource requirements as column vectors in a job resource demand matrix $bold(R)$ with dimensions $(K,J)$.

$
  bold(R) = mat(|, |, , |; bold(r)_1, bold(r)_2, dots.c, bold(r)_J; |, |, , |)
$

There are $M$ different kinds of machines available to buy.
Each machine type has a certain hardware resource capacity.
The resource capacity of machine type $i$, for $1<=i<=M$, is described with a $K$-dimensional vector $bold(m)_i in ZZnonneg^K$ with non-negative integer elements.
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
We will not allow a single job to be split across multiple machines.
Machines incur no running cost while powered off.
Let the $M$-dimensional vector $bold(x) in ZZnonneg^M$ be the decision variable representing our selection of machine types.
The vector element $x_i$ equals the number of machines of type $i$ we choose to buy.
The total initial cost of buying our selected machines will then be given by the scalar product $bold(x)^(T)bold(c^p)$.
To calculate our total running cost, we introduce the variables $bold(z)_t in ZZnonneg^M$, where $z_(t,i)$ denotes the number of instances of machine type $i$ which are powered on during time slot $t$.
Since the number of powered on instances of any machine type can not exceed the number of purchased instances of the given type, we must add the constraints $bold(z)_t<=bold(x) ,forall t$.
The cost of running our selected machine instances will be given by the following expression.
$
  sum_(t=1)^T sum_(i=1)^M z_(t,i) c^r_i
$
This is the sum over all time slots of the scalar product of the vector of machine type running costs and the vector of the number of each machine type running during the time slot.
The total hardware resource capacity available for time slot $t$ is then given by $bold(C) bold(z)_t$.
In order to be able to schedule and run all pending jobs, the following constraints must be satisfied.

$
  bold(C) bold(z)_t >= bold(R) bold(l)_t , forall t
$

Finally, we can state an optimization problem.

$
    "minimize" & quad bold(x)^(T)bold(c^p) + sum_(t=1)^T sum_(i=1)^M z_(t,i) c^r_i \
  "subject to" & quad bold(C) bold(z)_t >= bold(R) bold(l)_t , forall t \
               & quad bold(z)_t <= bold(x) ,forall t \
               & quad bold(x) in ZZnonneg^M quad bold(z)_t in ZZnonneg^M ,forall t
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
  sum_(i=1)^M z_(t,i) bold(y)_t^((i)) = bold(l)_t , forall 1<=t<=T
$
ensures that exactly the jobs scheduled for each time slot will be run.
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

// The vector $bold(y)_t^((i))$ gives the number of each job type which will run per powered-on instance of machine type $i$ during time slot $t$.
// For time slot $t$, there are $z_(t,i)$ instances of machine type $i$ powered on.

$
  "minimize" & quad bold(x)^(T)bold(c^p) + sum_(t=1)^T bold(z)_t^T bold(c^r) \
  "subject to" & quad sum_(i=1)^M z_(t,i) bold(y)_t^((i)) = bold(l)_t, quad forall t \
  & quad bold(R) bold(y)_t^((i)) <= bold(m)_i, quad forall i,t \
  & quad bold(x) in ZZnonneg^M, quad bold(z)_t in ZZnonneg^M forall t, quad bold(y)_t^((i)) in ZZnonneg^J, quad forall i,t
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
$ sum_(k=1)^(abs(S_i)) n_(i,t,k) = z_(t,i), quad forall i,t. $
We can now state our new optimization problem.

$
    "minimize" & quad bold(x)^T bold(c^p) + sum_(i=1)^(M) c^r_i sum_(t=1)^(T) sum_(k=1)^(abs(S_i)) n_(i,t,k) \
  //=bold(x)^T bold(c^p) + sum_(t=1)^(T) bold(z)_t^T bold(c^r) \
  "subject to" & quad S_i = {bold(y) in ZZnonneg^J | bold(R y) <= bold(m)_i}, quad forall i \
               & quad bold(Y)_i = mat(bold(y)_(i,1), ..., bold(y)_(i,abs(S_i))) \
               & quad bold(y)_(i,j) in S_i quad forall i, j \
               & quad sum_(i=1)^M bold(Y)_i bold(n)_(i,t) >= bold(l)_t quad forall t \
               & quad sum_(k=1)^(abs(S_i)) n_(i,t,k) <= x_i quad forall i,t \
               & quad bold(x) in ZZnonneg^M, quad bold(n)_(i,t) in ZZnonneg^(abs(S_i)) quad forall i,t
$

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
  bold(n)_(2,t) = vec(0) quad forall t
$

The solution buys two instances of machine type $1$ and no instances of machine type $2$.
In time slot $1$, one machine of type $1$ runs one job of each type.
In time slot $2$, two machines of type $1$ each run one job of type $1$.
In time slot $3$, one machine of type $1$ runs one job of type $2$.

We first verify that the used packing configurations are feasible:

$
  bold(R) vec(0, 0) = vec(0, 0, 0) <= vec(3, 2, 1) \
  bold(R) vec(1, 0) = vec(2, 1, 0) <= vec(3, 2, 1) \
  bold(R) vec(0, 1) = vec(1, 1, 1) <= vec(3, 2, 1) \
  bold(R) vec(1, 1) = vec(3, 2, 1) <= vec(3, 2, 1) \
  bold(R) vec(0, 0) = vec(0, 0, 0) <= vec(1, 3, 0)
$

We then verify that the scheduled jobs match the workload exactly:

$
  t=1: bold(Y)_1 vec(0, 0, 0, 1) + bold(Y)_2 vec(0) = vec(1, 1) = bold(l)_1 \
  t=2: bold(Y)_1 vec(0, 2, 0, 0) + bold(Y)_2 vec(0) = vec(2, 0) = bold(l)_2 \
  t=3: bold(Y)_1 vec(0, 0, 1, 0) + bold(Y)_2 vec(0) = vec(0, 1) = bold(l)_3
$

The number of powered-on machines does not exceed the number of purchased machines:

$
  t=1: sum_(k=1)^(abs(S_1)) n_(1,1,k) = 1 <= x_1 \
  t=2: sum_(k=1)^(abs(S_1)) n_(1,2,k) = 2 <= x_1 \
  t=3: sum_(k=1)^(abs(S_1)) n_(1,3,k) = 1 <= x_1 \
  sum_(k=1)^(abs(S_2)) n_(2,t,k) = 0 <= x_2 quad forall t
$

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
