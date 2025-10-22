#import "@preview/fletcher:0.5.6" as fletcher: diagram, edge, node
#import "@preview/algorithmic:1.0.6"
#import algorithmic: style-algorithm, algorithm-figure

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

Before we begin to search for an optimal machine vector $bold(x)$, we want to restrict the search space by finding an upper bound $bold(x)_U >= bold(x)$.

Any valid upper bound must be able to run the jobs given by $bold(l)_t$ for all time slots $t$.
Since we are searching for an upper bound, we only need to focus on the time slots with the most scheduled jobs.
We can also ignore all duplicate time slots.
We can do this by only considering time slots which are not Pareto dominated by some other time slot.
This gives us a smaller subset of time slots.
We shall continue here to refer to these time slot vectors as $bold(l)_t$.

Next, for each time slot vector $bold(l)_i in P$ and for each machine type $j$, we attempt to run FFD (First-Fit-Decreasing) on the jobs in $bold(l)_i$ using only machines of type $j$.
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

#block(breakable: false,[
#show: style-algorithm
#algorithm-figure("Machine types upper bound",
  vstroke: .5pt + luma(200),
  {
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
              Assign($u_(i,t)$, $max_t "FFD"(bold(m)_i, bold(lambda)_t)$)
            }) 
          Comment[Take max number of machines needed across all time slots]
          Assign($(bold(x)_U)_i$, $max_t u_(i,t)$)
          })      
        }) 
        Return($bold(x)_U$)
      }
    )
  }
  )
])
