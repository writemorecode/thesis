#import "@preview/fletcher:0.5.6" as fletcher: diagram, edge, node
#import "@preview/algorithmic:1.0.6"
#import algorithmic: algorithm-figure, style-algorithm

#let ZZnonneg = $ZZ_(>=0)$

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

== Algorithms

=== Adapting first-fit to heterogeneous bins with costs

// TODO: update with "marginal-cost" stuff

The first-fit algorithm described in @ff_algorithm is intended for the case of homogeneous bins with no costs.
This algorithm does not take bin type opening costs into account when opening a new bin.
This can lead to the algorithm selecting a more expensive bin type, when other less expensive bin types are available.
We can solve this problem by sorting the machine capacity vector $bold(m)_i$ of the machine capacity matrix $bold(C)$, in non-decreasing order of the opening costs $c^r_i$ of the machine types.
This can be achieved by multiplying the $bold(C)$ matrix with permutation matrix $bold(P)$, forming the new matrix $bold(C_s)=bold(C P)$.

$
  bold(C) = mat(|, |, , |; bold(m)_1, bold(m)_2, dots.c, bold(m)_M; |, |, , |), quad
  bold(P) = mat(|, |, , |; bold(e)_(alpha_1), bold(e)_(alpha_2), dots.c, bold(e)_(alpha_M); |, |, , |), quad
  bold(I) = mat(|, |, , |; bold(e)_(1), bold(e)_(2), dots.c, bold(e)_(M); |, |, , |) \
  bold(c^r) = mat(c^r_1, c^r_2, dots.c, c^r_M), quad
  c^r_(alpha_1) <= c^r_(alpha_2) <= dots.c <= c^r_(alpha_M) quad
  1<=alpha_k<=M, quad 1<=k<=M \
  bold(e)_1 = mat(1, 0, 0, dots.c, 0)^T, bold(e)_2 = mat(0, 1, 0, dots.c, 0)^T, ..., bold(e)_M = mat(0, 0, 0, dots.c, 1)^T.
$

Now, we can define the cost-optimal bin type $bold(gamma)_i$ for each item type $i$ as:

$
  bold(gamma) = mat(gamma_1, gamma_2, dots.c, gamma_J), quad
  bold(gamma)_i = min {j | C_s e_j >= bold(r)_i , 1<=j<=M}, quad 1<=i<=J.
$

We shall refer to this version of the first-fit decreasing algorithm as FFD in the rest of the report.
We can also use this bin selection method for the best-fit decreasing (BFD) algorithm.

=== Upper bound on machine types

Before we begin to search for an optimal machine vector $bold(x)$, we want to restrict the search space by finding an upper bound $bold(x)_U >= bold(x)$.

Any valid upper bound must be able to run the jobs given by $bold(l)_t$ for all time slots $t$.
Since we are searching for an upper bound, we only need to focus on the time slots with the most scheduled jobs.
We can also ignore all duplicate time slots.
We can do this by only considering time slots which are not Pareto dominated by some other time slot.
This gives us a smaller subset of time slots.
We shall continue here to refer to these time slot vectors as $bold(l)_t$.

Next, for each time slot vector $bold(l)_t$ and for each machine type $i$, we attempt to run FFD (First-Fit-Decreasing) on the jobs in $bold(l)_t$ using only machines of type $i$.
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
      "MachineTypesUpperBound",
      ($C$, $R$, $L$),
      {
        Comment[Iterate over each time slot]
        For($1<=t<=T$, {
          Comment[Let $bold(lambda)_t$ be $bold(l)_t$ with oversized jobs removed]
          Assign($bold(lambda)_t$, $bold(l)_t$)
          Comment[Iterate over each machine type]
          For($1<=m<=M$, {
            Comment[Iterate over each job type]
            For($1<=j<=J$, {
              Comment[Remove job types which do not fit on current machine type]
              For($1<=k<=K$, {
                If($r_(j,k) > C_(m,k)$, {
                  Assign($lambda_(t,j)$, $0$)
                })
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

=== A first solution algorithm

==== Introduction

At first glance, the problem of searching for both an optimal machine fleet to buy, and an optimal packing of jobs to these machines may seem quite difficult.
However, using the relation between the machine vector $bold(x)$ and the vector $bold(z)_t$ of powered-on machines at time $t$:

$
  bold(x)_i = max_t z_(t,i)
$ <eqn_x_z_vectors>

we can essentially remove the variable $bold(x)$ from the problem, and work only with $bold(z)_t$.
This simplifies the problem greatly.

We can divide this algorithm into two main stages: packing and re-packing.
We will use the FFD algorithm to pack jobs into machines.
FFD is guaranteed to yield a valid packing given a sufficiently large set of machines.
We can improve this packing by moving jobs from machines with lower utilization to machines with higher utilization.
If all jobs running on some machines can be moved to another machine, then the now-empty machine can be shut down for the time slot.

==== Job re-packing

We will now describe how the job re-packing algorithm works.
We begin with a few definitions.
Let $N=sum_i x_i$ be the number of bins.
Let $B = {(a_1,bold(b)_1),(a_2,bold(b)_2),dots.h,(a_N,bold(b)_N)}$ be the set of pairs of types $a_k$ and capacities $bold(b)_k$ of each bin, with $bold(b)_k in ZZ_(>= 0)^K$ and $1<=a_k<=M, forall k$.
Let $I = {I_1,I_2,dots.h,I_N}$ be the set of sets of items in each bin.
The set $I_j$ contains the items in bin $j$.

We define the load $bold(l)_j$ of bin $j$ as the sum of all items in bin $I_j$:
$
  bold(l)_j = sum_(bold(s) in I_j) bold(s).
$
For all bins, the load of the bin cannot exceed its capacity:

$
  bold(l)_j <= bold(b)_j, quad forall 1<=j<=N.
$

For each bin $i$, we define the _bin utilization_ for dimension $k$ as the load-to-capacity ratio for dimension $k$:

$
  U_(i,k) = cases(
    l_(i,k) \/ b_(i,k) quad "if" b_(i,k)>0,
    0 quad "else".
  )
$

Since we are re-packing a valid packing of items to bins, we know that no bins are over-packed.
This means that for each bin and for each dimension, the load does not exceed the capacity.
In other words, we have $U_(i,k) <= 1$ for all bins $i$ and dimensions $k$.

With this definition, we can define the total utilization for bin $bold(b)_i$ as the maximum bin utilization across all dimensions:

$
  U_i = max_k U_(i,k).
$

The goal of the job-repacking algorithm is reduce item fragmentation across all bins.
We can achieve this by moving items from bins with lower utilization, to bins with higher utilization.
This is easier to do if we first sort the bins by their utilization.

We shall begin the algorithm by sorting the bins, first in non-decreasing order of their bin utilization and then in non-increasing order of per-time slot running cost.
The second sort condition ensures that in the case where two bins have different capacities and running costs, but equal bin utilization, the bin with the highest running cost is first selected for re-packing.
If all of the jobs from this more expensive bin were to be moved, the cost savings would be larger than if the items from a less expensive bin were moved.

We initialize two index variables $i=0$ and $j=abs(B)$.
The $i$ index variable will start at the beginning of the bin list.
The $j$ index variable will start at the end of the bin list.
The $i$ index variable is then moved forward to the first non-empty bin.

Then, we sort the items in each bin in non-increasing order.
The reason for this is that we want to move the largest items first.
This makes better use of the free space in the receiving bins.
Here, we use ordinary element-wise comparison of vectors.
It may be worth investigating using other measures of item size here.

Next, we shall attempt to move items from bin $i$ to bin $j$.
Here, we shall refer to bin $i$ and $j$ as the source and destination bins, respectively.
If none of the items from bin $i$ can be moved to bin $j$, then the $j$ index is decremented (moved one step to the right).
Otherwise, items from bin $i$ are moved, in non-increasing order of size, to bin $j$.

The process of moving an item from bin $i$ to bin $j$ involves five steps.
First, remove the item from the list of items in bin $i$.
Second, add the item to the list of items in bin $j$.
Third, re-sort the items in bin $j$.
Fourth, add the item to the bin load of bin $j$.
Finally, remove the item from the bin load of bin $i$.
Items are only moved to bins with higher utilization than its origin bin.

Suppose now that all items from the source bin have been moved to other destination bins.
This means that the source bin is now empty.
In this case, we move to a new source bin by incrementing the source bin index (moving one step to the left).
We also reset the destination bin index $j$ to the end of the bin list, by setting $j <- abs(B)$.
Now, we will describe the most important step of this algorithm.
We were able to re-pack the items for this time slot in such a way that the source bin was emptied of all items.
Let $k$ be the bin type of the source bin, and let $z_k$ be the number of bins of type $k$ required to pack all items of this time slot.
Since the source bin was emptied, we will need one fewer bin of type $k$ to pack the items of this time slot.
This means setting $z_k <- z_k - 1$.

It is by this method that we reduce the number of required bins for each type.
We begin by computing a rough upper bound on the number of each bin type required to pack all items.
We then attempt to re-pack these items in a better way, aiming to reduce item fragmentation by moving items to bins with higher utilization.
If one more bins are emptied by this re-packing process, then we can remove these bins from the current bin configuration.
This in turn yields a smaller valid bin configuration.
We can then continue this packing-repacking process until we reach an optimal (or near-optimal) bin configuration.

Suppose now that the source bin is not empty, and that none of the remaining items from the source bin can be moved to the destination bin.
In this case, we want to attempt to find a new destination bin.
We also reset the destination bin index $j$ to the end of the bin list, by setting $j <- abs(B)$.

In any case, we re-sort the list of bins in non-decreasing order of utilization.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Job re-packing algorithm", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure(
      "RepackJobs",
      ($B$, $I$, $z$),
      {
        LineComment(Assign($B$, $"SortByUtilization"(I)$), "Sort bins by non-decreasing utilization")

        LineComment(Assign($i$, $1$), "Initialize indexes")
        Assign($j$, $abs(B)$)

        Comment[Sort items of each bin in non-increasing size order]
        For($1<=k<=abs(B)$, {
          Assign($I_k$, $"Sort"(I_k)$)
        })

        While($i < j$, {
          Comment[Find largest item $bold(lambda)$ in bin $i$ which fits in bin $j$]
          For($1<=k<=abs(I_i)$, {
            LineComment(Assign($bold(lambda)$, $I_(i)[k]$), $"Let" bold(lambda) "be item" k "of bin" j$)
            Comment[Check if item fits in bin $j$]
            If($bold(lambda) + bold(l)_j <= bold(b)_j$, {
              LineComment(
                Assign($bold(lambda)$, $"ListRemoveItem"(I_i, bold(lambda))$),
                $"Remove item" bold(lambda) "from source bin"$,
              )
              LineComment(
                Assign($I_j$, $"ListPush"(I_j, bold(lambda))$),
                $"Add item" bold(lambda) "to destination bin"$,
              )
              LineComment(Assign($I_j$, $"Sort"(I_j)$), "Re-sort destination bin")
              LineComment(Assign($bold(l)_j$, $bold(l)_j + bold(lambda)$), "Update load of destination bin")
              LineComment(Assign($bold(l)_i$, $bold(l)_i - bold(lambda)$), "Update load of source bin")
            })
          })
          Comment[Move to next bin if current bin was emptied]
          IfElseChain(
            $I_i = emptyset$,
            {
              LineComment(Assign($i$, $i+1$), "Increment source bin index")
              LineComment(Assign($j$, $abs(B)$), "Reset destination bin index")
              LineComment(Assign($k$, $a_i$), $"Bin i has bin type" k$)
              LineComment(Assign($z_k$, $z_k - 1$), "Decrement number of running instances")
            },
            {
              Comment[Some items in bin $i$ did not fit in bin $j$]
              LineComment(Assign($j$, $j-1$), "Move to next destination bin")
            },
          )

          Comment[Re-sort all non-source bins]
          For($i + 1<=k<=abs(B)$, {
            Assign($I_k$, $"Sort"(I_k)$)
          })
        })
        LineComment(Return[$(z,I)$], "Returned re-packed items")
      },
    )
  })
])


==== Algorithm description <first_alg>

An initial basic solution algorithm proceeds as following.


First, we compute an upper bound $bold(x_U)$ on the machine vector $bold(x)$.
Next, we select $bold(x_U)$ as our initial machine vector.
We compute the cost $c_p$ of selecting these machines.
Next, for each time slot $t$, we pack the jobs given by $bold(l)_t$ into the machines given by the initial machine vector.
Here we use the FFD algorithm, sorting jobs and machines as discussed previously.
This gives us an initial running cost $c_r^t$  and an initial solution $X_t$ for time slot $t$ in the form of the pair:
$
  //  X_0 = ({bold(z)_t}_t, {bold(Y)_(i,t)}_(i,t)).
  X_t = (bold(z)_t, {bold(Y)_(i,tau)}_(i,tau=t)).
$
Here, $bold(z)_t$ is the vector representing the number of powered-on machine instances for time slot $t$.
The second element of the solution pair, ${bold(Y)_(i,tau)}_(i,tau=t)$ is the set of tuples $(bold(y)_(i,j),n_(i,j))$, where the vector $bold(y)_(i,j)$ is a job-packing configuration for machine type $i$, and $n_(i,j)$ is the number of machine instances of type $i$ running the configuration $bold(y)_(i,j)$:

$
  bold(Y)_(i,t) = {dots.h, (bold(y)_(i,j), n_(i,j)), dots.h}.
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


If no such neighboring solution could be found, or if its cost was greater than the previous cost, then we stop the algorithm and return the current valid solution and cost since no improved solution could be found.
Otherwise, we let this improved solution be

$
  hat(X) = ({bold(hat(z))_t}_t, {bold(hat(Y))_(i,tau)}_(i,tau=t))
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

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Scheduler algorithm", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure(
      "Scheduler",
      ($C$, $R$, $L$),
      {
        // Comment[Using upper bound as initial machine vector]
        LineComment(Assign($bold(x)_U$, $"MachineTypesUpperBound"(C, R, L)$), "Compute upper bound")
        Assign($bold(x)$, $bold(x)_U$)

        Comment[Initial packing for each time slot]
        For($1<=t<=T$, {
          Assign($(bold(z)_t, {bold(Y)_(i,tau)}_(i,tau=t))$, $"MHBCFFD"(bold(x), bold(l)_t)$)
          Assign($X_t$, $(bold(z)_t, {bold(Y)_(i,tau)}_(i,tau=t))$)
        })
        LineComment(Assign($X$, ${X_t}_t$), "Collect solutions from all time slots")

        // Comment[Initial cost and seen solution]
        LineComment(Assign($c$, $"SolutionCost"({bold(z)}_t)$), "Compute cost of initial solution")
        LineComment(Assign($S$, ${X}$), "Initialize set of seen solutions with initial solution")
        LineComment(Assign($i$, $0$), "Initialize loop iteration variable")

        Comment[Iterative improvement loop]
        While($i < N_max$, {
          Comment[Generate neighboring solution via re-packing]
          For($1<=t<=T$, {
            Assign($(hat(bold(z))_t, {hat(bold(Y))_(i,t)}_(i))$, $"RepackJobs"(X_t)$)
            Assign($hat(X)_t$, $(hat(bold(z))_t, {hat(bold(Y))_(i,t)}_(i))$)
          })
          Assign($hat(X)$, ${hat(X)_t}_t$)

          Comment[Stop if configuration repeats]
          If($hat(X) in S$, {
            Return[$(c,X)$]
          })

          LineComment(Assign($hat(c)$, $"SolutionCost"({hat(bold(z))}_t)$), "Compute cost of neighbor solution")
          LineComment(Assign($hat(bold(x))$, $"MaxOverTime"({hat(bold(z))_t}_t)$), "Compute new machine vector")

          Comment[Abort if neighbor violates upper bound]
          If($hat(bold(x)) > bold(x)_U$, {
            Return[$(c,X)$]
          })

          Comment[Re-pack when fewer machines suffice]
          If($hat(bold(x)) != bold(x)$, {
            For($1<=t<=T$, {
              Assign($(hat(bold(z))_t, {hat(bold(Y))_(i,t)}_(i))$, $"FFD"(hat(bold(x)), bold(l)_t)$)
              Assign($hat(X)_t$, $(hat(bold(z))_t, {hat(bold(Y))_(i,t)}_(i))$)
            })
            Assign($hat(X)$, ${hat(X)_t}_t$)
            Assign($hat(c)$, $"SolutionCost"({hat(bold(z))}_t)$)
          })

          Comment[Accept improved neighbor; otherwise stop]
          IfElseChain(
            $hat(c) < c$,
            {
              LineComment(Assign($c$, $hat(c)$), "Set neighbor cost to current cost")
              LineComment(Assign($X$, $hat(X)$), "Set neighbor solution to current solution")
              LineComment(Assign($bold(x)$, $hat(bold(x))$), "Set neighbor machines to current machines")
              LineComment(Assign($S$, $S union {X}$), "Mark current solution as seen")
            },
            {
              LineComment(Return[$(c,X), "")$], "Return current solution if neighbor not improved")
            },
          )

          Assign($i$, $i + 1$)
        })

        LineComment(Return($(c,X)$), "Return best-found solution if max iterations reached")
      },
    )
  })
])

==== Alternate initial solution method <alt_initial_soln>

The previously described algorithm uses the upper-bound machine vector $bold(x)_U$ as its initial solution.
This is a valid choice, but often very far from optimal.
The goal is to minimize the total cost of ownership for all machines.
This means we should minimize the number of machines owned.
We can find a better initial solution by using a new version of FFD.
This new FFD version uses a different method for selecting the bin type to open for an item.
For a given item type, from the set of bin types with sufficient capacity, we select the bin type with the lowest marginal cost.
Here, we define the marginal cost of each bin type as the cost to add one more bin of the type to the current bin configuration.
If there exists at least one purchased unused bin of some bin type, then the marginal cost will be equal to the per-slot opening cost.
Otherwise, if there are no unused bins of the type remaining, then the marginal cost will be equal to the sum of the bin type's purchase and running costs.
For an item type, the cost-optimal bin type is then given by the bin type with the lowest marginal cost.
The running costs and purchase costs, respectively, are used as tie-breakers.
It is a good idea to use choose to order bin types by their per-slot cost, rather than their purchase cost.
This is especially true for problem instances with larger numbers of time slots.
The purchase costs are a one-time cost, but the per-slot costs represent the most of the total cost.

We can define a new version of the previously described algorithm, which uses this method for computing an initial solution.

=== A global search algorithm <rnr_alg>

The problem with the first job scheduler algorithm was that it was unable to move away from the neighborhood defined by the initial solution.
It was able to find a local minimum solution in this neighborhood, but was unable to move to other neighborhoods further away to find better solutions.
We need a new algorithm which can take large steps between neighborhood and explore larger regions of the search space.
One idea for how to do this is to destroy, or "ruin" a feasible solution, and then somehow fix, or "recreate" the ruined solution in a different way in order to find a new feasible and possibly superior solution.
What the "ruin and recreate" algorithm attempts to do is reduce costs by removing the most expensive bins with the lowest utilization.
This method is known as "recreate and ruin" and has previously been used successfully for problems such as vehicle routing @shaw_maher_lns_vrp and bin packing @gardeyn2022goal @EKICI20231007.

The algorithm proceeds as following.
We begin by computing an initial solution $x_0$ using FFD with the previously discussed "marginal cost"-based method for new bin selection.
Initialize the best solution $x_"best"$ as the initial solution $x_0$.
Initialize the best cost as the cost of the initial solution.
Next, we enter a loop of a fixed number of $N$ iterations.
Let the current iteration be $i$.
The main loop consists of two phases.
The first phase is a global search phase, which aims to move from the current neighborhood to an adjacent neighborhood.
We refer to this neighborhood transition as a "shaking" operation.
We order the bins in ascending order of their utilization.
As previously defined, the utilization bin is its maximum load to capacity ratio across all resource dimensions.
Let $alpha = min (abs(B), ceil(p abs(B)))$.
Here, $B$ is the set of all bins, and $p$, $0<=p<=1$, is a configurable parameter controlling the maximum percentage of bins which should be "ruined" in each iteration.
Let $beta$ be a random variable sampled from the uniform distribution on $[0, alpha]$.
We select the first $beta$ bins from this sorted list.
These bins are removed from the current solution, and the items packed in these bins are marked as unpacked.
Next, we move to the "recreate" phase of the algorithm.
Here, it is important that we do not create and recreate solutions in the same way.
Therefore, we use the best-fit decreasing (BFD) algorithm for recreating ruined solutions, rather than the first-fit decreasing (FFD) algorithm.
Let $x'$ be the solution given by the shake operation.

After the global search phase, we enter the local improvement phase.
In this phase, we aim to find an optimal or near-optimal solution in the neighborhood entered in the previous phase.
Here, we use the previously described job repack algorithm.
Let $x''$ be the solution given by the local search operation.

The algorithm will attempt to place the items in these bins in a better location, which can either be a in an existing open bin, or in a new bin.
Finally, we set the best solution $x_"best"$ to the best of $x_"best"$ and the current solution $x''$.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Global search algorithm", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure(
      "GlobalSearch",
      ($bold(C)$, $bold(R)$, $bold(L)$, $bold(c^p)$, $bold(c^r)$),
      {
        LineComment(
          Assign($x_0$, $"InitialSolution"(bold(C),bold(R),bold(L),bold(c^p),bold(c^r))$),
          $"Compute initial solution "x_0$,
        )
        LineComment(Assign($x_"best"$, $x_0$), $"Initialize current best solution "x_"best"$)
        LineComment(Assign($x$, $x_"best"$), $"Initialize current solution "x$)
        Assign($i$, $0$)
        While($i < N$, {
          LineComment(Assign($x'$, $"Shake"(x)$), "Run global search phase")
          LineComment(Assign($x''$, $"LocalSearch"(x')$), "Run local search phase")
          If($"Cost"(x'')<="Cost"(x_"best")$, {
            LineComment(Assign($x_"best"$, $x''$), "Update best solution")
          })
        })
        Return($x_"best"$)
      },
    )
  })])

== Experimental methodology

=== Problem instance generation

In order to evaluate these algorithms, we use randomly generated problem instances.
Each problem instance is generated as follows.

Each machine type resource capacity value $C_(i,k)$ is initialized according to a configurable positive base resource capacity parameter $c_0$.
Each job type resource demand value $R_(j,k)$ is initialized according to a configurable positive base resource demand parameter $d_0$.
Next, some variation is introduced to each element $C_(i,k)$ and $R_(j,k)$ with multiplicative jitter values sampled uniformly from the configurable ranges $[c_"min",c_"max"]$ and $[d_"min",d_"max"]$, respectively.

$
  C_(i,k) arrow.l ceil(c_0 U([c_"min", c_"max"])), quad
  R_(i,j) arrow.l ceil(d_0 U([d_"min", d_"max"])), quad forall i,j,k.
$

In order to generate more realistic problem instances, we want to avoid having nearly uniform machine types, job types, and time slots.
Instead, we want a fraction of all machine types, job types, and time slots to have a greater number of certain resource capacities, resource demands, and job types, respectively.
For example, certain machine types may be optimized, or specialized, for certain kinds of workloads.
These special machine types will have a larger amount of a certain resource type, such as memory, disk, etc.
This will make these machine types better suited to running job types with above average demands for these resource types.
This is also true for job time slots.
Above average numbers of certain job types may be scheduled to run during certain time slots.

Each machine type, job type, and time slot may be assigned a primary resource or job type.
The number of them which are assigned a primary resource is controlled by a configurable parameter $rho in [0,1]$.
This means that, for example, given $M$ different machine types, $ceil(rho M)$ machine types will be assigned a primary resource.

The primary resources of a machine type, job type, or time slot are computed using the $"CHOOSEPRIMARYRESOURCES"$ function, described below.
The function takes as arguments the number $n$ of primary resources to compute, the number of resources $K$,
the fraction $rho$ of resources to assign a primary resource to, and a probability vector $bold(q) in (0,1)^K$.
For each of the machine types, job types, or time slots assigned a primary resource, the resource index $k$ will be chosen with probability $q_k$, for $1<=k<=K$.
By setting each element $q_k$ of $bold(q)$ to $1\/K$, each primary resource index $k$ will be chosen with equal probability.
The values $q_k$ can instead be adjusted to increase or decrease the probability of resource $k$ being assigned to primary resources.
This will be used later in order to make the machine types have similar primary resources as the job types.
This means that, for example, if there are many job types with memory as a primary resource, then there should also be many machine types with memory as a primary resource.

#block(
  breakable: false,
  [
    #show: style-algorithm
    #algorithm-figure(
      "Choose primary resources",
      vstroke: .5pt + luma(200),
      {
        import algorithmic: *
        Procedure(
          "ChoosePrimaryResources",
          (
            $"count" n$,
            $"resource count" K$,
            $"specialization fraction" rho$,
            $"probability vector" bold(q)$,
            $"RNG" G$,
          ),
          {
            Assign($s$, $ceil(n rho)$)
            Comment[Sample set $S$ of size $s$ from set ${1,dots.h,n}$ without replacement, with RNG G]
            Assign($S$, $"UniformWithoutReplacement"({1,dots.h,n}, s ; G)$)
            Comment[Let $bold(p)$ be $n$-dimensional vector initialized to value $-1$]
            Assign($bold(p)$, $mat(-1, dots.h, -1)$)
            For($i in S$, {
              Comment[Sample $p_i$ from set ${1,dots.h,K}$ with probabilities ${q_1,dots.h,q_K}$, with RNG G]
              Assign($p_i$, $"Categorical"({1,dots.h,K}, bold(q) ; G)$)
            })
            Return($bold(p)$)
          },
        )
      },
    )],
)

Now that we have described how the primary resources are computed, we move on to describing how they are used in practice.
Let $u ~ "UniformInteger"([u_"min", u_"max"])$.
For each machine type $i$, if the machine type has been assigned primary resource $k^*$, then we set $C_(i,k^*) arrow.l u dot max(1, ceil(C_(i,k^*)))$, where.
For each job type $j$, if the job type has been assigned primary resource $k^*$, then we set $R_(j,k^*) arrow.l u dot max(1, ceil(R_(j,k^*)))$.
Note that $u$ is re-sampled for each element $C_(i,k)$ and $R_(j,k)$.
Here, it is the configurable range $[u_"min", u_"max"]$ which controls how much primary resource values shall be increased.

Next, we want to use the vector $p^"machine"$ returned by the $"CHOOSEPRIMARYRESOURCES"$ function for
computing a probability vector $bold(q)^"job"$ to use for computing the primary resources for the job types matrix $bold(R)$.
To do this, we begin by letting the vector $bold(u)$ be the $K$-dimensional uniform probability vector $bold(1)\/K$.
Next, we compute a histogram vector $bold(h)$ of the elements of $p^"machine"$.
The $bold(h)$ vector will have dimension $k$, and each element $h_k$ will be equal to the number of machine types which were assigned resource $k$ as a primary resource.
If no primary resources were assigned, then we set $bold(h)$ equal to $bold(u)$.
Finally, we can compute the probability vector $q^"job"$ as a weighted vector sum between the normalized histogram vector $bold(h)$ and the vector $bold(u)$.

$
  bold(q)^"job" = eta bold(h)/norm(bold(h)) + (1-eta) 1/K bold(1)
$

Here, $eta in (0,1)$ is a configurable correlation parameter.
For larger values of $eta$, $bold(q)^"job"$ will be more similar to the histogram vector $bold(h)$, and vice versa.
In other words, larger values of $eta$ increase the correlation between the primary resources of the machine and job types.
This means that, for example, if many job types were assigned CPU as a primary resource, then $eta$ will control how many machine types are assigned CPU as a primary resource.
With the vector $bold(q)^"job"$ computed, we can now compute the primary resources for the machine types.

The next step is to compute the machine capacity matrix $bold(C)$.
This is handled by the function $"GENERATECAPACITIESANDREQUIREMENTS"$.

#block(
  breakable: false,
  [
    #show: style-algorithm
    #algorithm-figure(
      "Generate capacities and requirements",
      vstroke: .5pt + luma(200),
      {
        import algorithmic: *
        Procedure(
          "GenerateCapacitiesAndRequirements",
          (
            $K$,
            $M$,
            $J$,
            $c_0$,
            $d_0$,
            $bold(p)^"machine"$,
            $bold(p)^"job"$,
            $"hyperparameters"$,
            $"RNG" G$,
          ),
          {
            Comment[Initialize $bold(C)$ with base capacity and variance]
            Assign($C_(i,k)$, $ceil(c_0 dot U(c_"min", c_"max"))$)
            Comment[Initialize $bold(R)$ with base demand and variation]
            Assign($R_(j,k)$, $ceil(d_0 dot U(d_"min", d_"max"))$)

            Comment[Amplify assigned primary resources for machine types]
            For($1<=i<=M$, {
              Comment[Check if machine type $i$ was assigned a primary resource]
              If($p^"machine"_i >= 0$, {
                LineComment(Assign($k^*$, $p^"machine"_i$), $"Let" k^* "be primary resource of machine type "i$)
                Assign($u$, $"UniformInteger"([u_"min", u_"max"])$)
                LineComment(Assign($C_(i,k^*)$, $u dot C_(i,k^*)$), "Scale the capacity of primary resource")
              })
            })

            Comment[Amplify assigned primary resources for job types]
            For($1<=j<=J$, {
              Comment[Check if job type $j$ was assigned a primary resource]
              If($p^"job"_j >= 0$, {
                LineComment(Assign($k^*$, $p^"job"_j$), $"Let" k^* "be primary resource of job type "j$)
                Assign($u$, $"UniformInteger"([u_"min", u_"max"])$)
                LineComment(Assign($R_(j,k^*)$, $u dot R_(j,k^*)$), "Scale the demand of primary resource")
              })
            })

            LineComment(Assign($C_(i,k)$, $max(1, C_(i,k))$), $"Ensure all capacity values" >=1$)
            LineComment(Assign($R_(j,k)$, $max(1, R_(j,k))$), $"Ensure all demand values" >=1$)

            Comment[Ensure all job types can be packed]
            For($1<=j<=J$, {
              Comment[If no machine type can store job type $j$]
              If($exists.not i: bold(m)_i >= bold(r)_j$, {
                LineComment(Assign($pi$, $p^"job"_j$), $"Let" pi "be primary resource of job type j"$)

                IfElseChain(
                  $pi>=0$,
                  {
                    LineComment(Assign($A$, ${i|p^"machine"_i=pi}$), $"Compute machine types with primary resource" pi$)
                    LineComment(
                      Assign($t$, $"Uniform"(A)$),
                      $"Select random machine type with primary resource" pi$,
                    )
                  },
                  {
                    LineComment(
                      Assign($t$, $arg max_m sum_k C_(m,k)$),
                      "Fallback to machine type with max capacity sum",
                    )
                  },
                )
                LineComment(Assign($bold(m)_t$, $bold(r)_j - bold(m)_t$), "Add deficit capacity to target machine type")
              })
            })

            Return($bold(C), bold(R)$)
          },
        )
      },
    )],
)

With the description of the generation of the machine capacity matrix $bold(C)$ and job demand matrix $bold(R)$ completed, we now move on to description of the job time slot matrix $bold(L)$.
The $bold(L)$ matrix generation is handled by the $"GENERATEJOBCOUNTS"$ function.
The function works as follows.

For each time slot, the job count matrix generation aims to select job types which have been assigned some primary resource.
Previously, the primary resource capacities of the machine types were selected with respect to the primary resource demands of the job types.
If some subset of the job types were each assigned some primary resource demand, then the machine types must be assigned matching resource capacities.
For example, memory-intensive job types are best assigned to memory-optimized machine types.
In this function, for a subset of all time slots, we select a primary resource $k^*$, where $0<=k^*<K$.
For each time slot in this subset, we can increase the number of jobs which also have primary resource $k^*$.

For each time slot $t$, the total time slot load value $N_t$ is assigned a base load value, which is $lambda_0$ in this case.
Next, some jitter is applied to $N_t$ by multiplying it by a jitter value $u$ sampled uniformly from a configurable interval $[lambda_"min", lambda_"max")$, after which $N_t$ is clamped to an integer $>=1$.
After this, we uniformly sample a $J$-dimensional job type weight vector $bold(w)$ from the interval $[0.5,1)$.
This vector will later be used to decide the number of each job type to select for time slot $t$.
Next, we compute a set $M$ of each job type $j$ assigned the same primary resource $k^*>0$ as time slot $t$.
For each of these matching job types, we sample a positive integer $v$ from the configurable interval $[v_"min", v_"max"]$.
Then, the weight vector element $w_j$ is multiplied by $v$.

Once we have completed this step for all time slots, we let $bold(pi)$ be the normalized $bold(w)$ vector.
Finally, we compute the job count vector $bold(l)_t$ for time slot $t$.
This is done by sampling the vector from multinomial distribution.
Here, $bold(l)_t$ is the total number of jobs scheduled for time slot $t$, across all job types.
The vector $bold(pi)$ is the probability vector controlling the probability of selecting each job type.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Generate job counts", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure(
      "GenerateJobCounts",
      (
        $K$,
        $J$,
        $T$,
        $lambda_0$,
        $(lambda_"min",lambda_"max")$,
        $rho^"slot"$,
        $eta$,
        $(v_"min", v_"max")$,
        $bold(p)^"job"$,
        $G$,
      ),
      {
        LineComment(Assign($bold(h)$, $"Histogram"(bold(p)^"job")$), "Compute histogram of job type primary resources")
        LineComment(Assign($bold(u)$, $bold(1)\/K$), $"Let "bold(u)" be uniform "K"-dim probability vector"$)
        LineComment(
          Assign($bold(q)^"slot"$, $eta bold(h)\/norm(bold(h))+(1-eta)bold(u)$),
          "Compute time slot primary job type probabilities",
        )
        Comment[Compute primary job types for time slots]
        Assign($p^"slot"$, $"COMPUTEPRIMARYRESOURCES"(T,K,rho^"slot", bold(q)^"slot",G)$)
        Assign($L_(j,t)$, $0$)
        For($1<=t<=T$, {
          LineComment(Assign($u$, $"Uniform"([lambda_"min", lambda_"max");G)$), "Sample jitter value")
          LineComment(Assign($N_t$, $max(1, ceil(lambda_0 u))$), "Multiply base load by jitter, clip")

          LineComment(Assign($bold(w)$, $"UniformVector"([0.5, 1), J ; G)$), "Sample job type weight vector")

          If($p^"slot"_t>=0$, {
            LineComment(Assign($k^*$, $p^"slot"_t$), $"Let" k^* "be primary job type for slot "t$)
            Comment[Compute set $M$ of job types with same primary resource as time slot $t$]
            Assign($M$, ${j | p^"job"_j = p^"slot"_t}$)
            If($M != emptyset$, {
              Comment[Sample a job type focus multiplier]
              Assign($v$, $"UniformInteger"([v_"min",v_"max"])$)
              For($i in M$, {
                Assign($w_i$, $w_i v$)
              })
            })
          })
          LineComment(Assign($bold(pi)$, $bold(w)\/norm(bold(w))$), "Normalize weight vector")
          Comment[Sample job types for slot $t$ from multinomial distribution]
          LineComment(Assign($L_(dot,t)$, $"Multinomial"(N_t, bold(pi))$), "")
        })
      },
    )
  })])


/*
#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure("", ($x$), {
    })
  })]))
*/

