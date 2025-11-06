#import "@preview/fletcher:0.5.6" as fletcher: diagram, edge, node
#import "@preview/algorithmic:1.0.6"
#import algorithmic: algorithm-figure, style-algorithm

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
    $bold(x), bold(z)_t, bold(Y)_i, bold(n)_(i,t)$
  ]),
)


== Research questions

With this research, we aim to answer the following research questions:

RQ1: How can we create a cloud job scheduler which is efficient with respect to energy consumption? \
RQ2: How can we create a cloud job scheduler which is optimized for both scheduling quality and execution time?

== Upper bound on machine types

Before we begin to search for an optimal machine vector $bold(x)$, we want to restrict the search space by finding an upper bound $bold(x)_U >= bold(x)$.

Any valid upper bound must be able to run the jobs given by $bold(l)_t$ for all time slots $t$.
Since we are searching for an upper bound, we only need to focus on the time slots with the most scheduled jobs.
We can also ignore all duplicate time slots.
We can do this by only considering time slots which are not Pareto dominated by some other time slot.
This gives us a smaller subset of time slots.
We shall continue here to refer to these time slot vectors as $bold(l)_t$.

Next, for each time slot vector $bold(l)_i$ and for each machine type $j$, we attempt to run FFD (First-Fit-Decreasing) on the jobs in $bold(l)_i$ using only machines of type $j$.
This gives us an upper bound

$ u_(i,t)="FFD"(bold(m)_i,bold(l)_t) $

on the number of required machines of each type.
We get each component of the upper bound $bold(x)_U$ by taking the maximum of $u_(i,t)$ across all time slots.
$ (bold(x)_U)_i = max_t u_(i,t) $

We can do this because we are searching for an upper bound on the number of each machine type we will need to purchase.
This upper bound will include machines of different types.
We are assuming that each job type can run on at least one machine type.
This means that if some job type cannot run on some machine type, then it will be able to run on some other machine type.
Since the upper bound will be a valid selection of machines, we can guarantee that it will contain a sufficient number of this machine type.

It is possible that the resource requirements of certain job types exceed the resource capacities of certain machine types.
Suppose for example that for resource $k$, the demands of job type $j$ exceeds the capacity of machine type $i$.
In this case, we can skip this job type by setting $bold(l)_(t,j)=0$ where $r_(j,k) > C_(m,k)$.
Here, we are unscheduling all jobs of type $j$ from time slot $t$, if job type $j$ can not run on machine type $i$.

The algorithm can be described with the following pseudocode.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Machine types upper bound", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure(
      "MachinesUpperBound",
      (),
      {
        For($"time slot" t = 1,2,...,T$, {
          Comment[Let $bold(lambda)_t$ be $bold(l)_t$ with oversized jobs removed]
          Assign($bold(lambda)_t$, $bold(l)_t$)
          For($"machine type" m = 1,2,...,M$, {
            For($"job type" j = 1,2,...,J$, {
              Comment[Remove oversized job types]
              If($exists k: r_(j,k) > C_(m,k)$, {
                Assign($lambda_(t,j)$, $0$)
              })
              Comment[Pack jobs for time slot $t$ into machines of type $i$]
              Assign($u_(i,t)$, $"FFD"(bold(m)_i, bold(lambda)_t)$)
            })
            Comment[Take max number of machines needed across all time slots]
            Assign($(bold(x)_U)_i$, $max_t u_(i,t)$)
          })
        })
        Return($bold(x)_U$)
      },
    )
  })
])

== A first solution algorithm

At first glance, the problem of searching for both an optimal machine fleet to buy, and an optimal packing of jobs to these machines may seem quite difficult.
However, using the relation between the machine vector $bold(x)$ and the vector $bold(z)_t$ of powered-on machines at time $t$:

$
  bold(x)_i = max_t z_(t,i)
$ <eqn_x_z_vectors>

we can essentially remove the variable $bold(x)$ from the problem, and work only with $bold(z)_t$.
This simplifies the problem greatly.
An initial basic solution algorithm proceeds as following.

We sort items and bins using the $S_("SUM")(bold(u))$ size measure (see @eqn_l1_sum_size_measure) with weights $w_k=d_k$ for all items, and $w_k=b_k$ for all bins. 

// TODO:
// add discussion about keeping state of previous packing configurations
// add discussion about pruning search space by never moving job to an "empty" machine
// discuss how a state is represented
// discuss how a move between states is represented
//

First, we compute an upper bound $bold(x_U)$ on the machine vector $bold(x)$.
Next, we select $bold(x_U)$ as our initial machine vector.
We then pack the jobs into the machines given by the initial machine vector.
Here we use the FFD algorithm, sorting jobs and machines as discussed previously.
This gives us an initial cost $c_0$, and an initial solution $X_0$ in the form of the pair:
$
  X_0 = ({bold(z)_t}_t, {bold(Y)_(i,t)}_(i,t)).
$
Here, ${bold(z)_t}_t$ is the set of the vectors $bold(z)_t$ representing the number of powered-on machine instances of each type for each time slot $t$.
The second element of the solution pair, ${bold(Y)_(i,t)}_(i,t)$ is the set of tuples $(bold(y)_(i,j),n_(i,j))$, where the vector $bold(y)_(i,j)$ is a job-packing configuration for machine type $i$, and $n_(i j)$ is the number of machine instances of type $i$ running the configuration $bold(y)_(i,j)$.

$
  bold(Y)_(i,t) = {dots.h, (bold(y)_(i,j), n_j), dots.h}
$

We will store previously seen solutions $X_i$ in the set $S$, which will be initialized with the initial solution $X_0$.

Next, we enter a loop of some fixed number of iterations.

At the start of each iteration, let the current best solution be $X$.
We begin by selecting the best neighbor solution to the current solution.
For this algorithm, this means attempting to move one or more jobs from one machine instance to another.
We want to move jobs from machines with higher unused capacity, to machines with lower unused capacity.
In other words, we want to move jobs from machines with lower resource utilization to machines with higher utilization.
The FFD algorithm will always yield a valid allocation of jobs to machines.
By moving jobs between machines, we can improve these allocations.
More advanced versions of this solution algorithm could involve other operations, such as swapping two jobs between machines.
We execute some fixed number of these operations, and select the neighboring solution with the lowest cost.
If no such neighboring solution could be found, or if its cost was greater than the previous cost, then we stop the algorithm and return the current valid solution and cost since no improved solution could be found.
Otherwise, we let this improved solution be 

$
  hat(X) = ({bold(hat(z))_t}_t, {bold(hat(Y))_(i,t)}_(i,t))
$

and let $hat(c)$ be its cost.
If this neighbor solution $hat(X)$ has been seen previously (i.e. $hat(X) in S$), then we stop the algorithm.

Next, we compute the new machine vector $bold(hat(x))$, using @eqn_x_z_vectors.
If the new machine vector is greater than the upper bound, i.e. $bold(hat(x)) > bold(x_U)$, then we stop the algorithm and return the current valid solution $X$ and cost $c$.
Otherwise, if the new machine vector is not equal to the old, i.e. $bold(hat(x)) != bold(x)$, then we will attempt to re-pack the jobs into the machines given by $bold(hat(x))$.
Let $bold(hat(X))$ be this job-packing configuration, and let $hat(c)$ be its cost.
In any case, we will now compare the costs of the previous and neighboring solutions.
If $hat(c)<c$, then set $c$ to $hat(c)$ and let $X$ be the lowest-cost solution.
Next, we insert this solution $X$ into the set $S$ of previously seen solutions: $S arrow.l S union {X}$.
Finally, if the maximum number of iterations has been reached, we stop the algorithm and return the best cost and solution found, $(c, X)$.

This rather primitive algorithm may be enhanced using methods such as Simulated Annealing, Tabu search.
Since these methods can accept some inferior solutions, they can avoid those local minimums reached by only selecting superior solutions.

