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

== Adapting first-fit to heterogeneous bins with costs

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

== A first solution algorithm

=== Introduction

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

=== Job re-packing

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


=== Algorithm description

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
          Assign($(bold(z)_t, {bold(Y)_(i,t)}_(i))$, $"FFD"(bold(x), bold(l)_t)$)
          Assign($X_t$, $(bold(z)_t, {bold(Y)_(i,t)}_(i))$)
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

