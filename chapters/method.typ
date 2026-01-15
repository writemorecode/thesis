#import "@preview/fletcher:0.5.6" as fletcher: diagram, edge, node
#import "@preview/algorithmic:1.0.6"
#import algorithmic: algorithm-figure, style-algorithm

#let ZZnonneg = $ZZ_(>=0)$

= Method <method_section>

This chapter summarizes the research questions, the literature review scope, and the scheduling algorithms that are evaluated.

== Literature review

Since the literature on the bin-packing problem is so vast, we needed to reduce the number of search results by using a more precise search query.
We also decided to further reduce the number of search results by filtering out those articles which only applied existing bin-packing methods to problems, without presenting any new methods.

We used the Scopus search engine, with the search query $sans("( 'variable-sized' OR 'heterogeneous' ) ( 'vector' OR 'multidimensional' ) 'bin-packing'")$.
Article results were filtered to only return English language published journal and/or conference articles, excluding other kinds of articles such conference reviews and etc.
This search returned a total of $22$ results.
We filtered out $1$ duplicate article, and $7$ irrelevant articles.
We were forced to remove $1$ article due to not being able to access the article with institutional access.
After filtering, we had a total of $13$ articles.
From other articles cited by this set of articles, we found another $2$ articles.

== Research questions

With this research, we aim to answer the following research questions:

RQ1: How can we create a cloud job scheduler which is efficient with respect to energy consumption? \
// RQ2: How can we create a cloud job scheduler which is optimized for both scheduling quality and execution time?

== Algorithms

=== Adapting first-fit to heterogeneous bins with costs

The first-fit algorithm described in @ff_algorithm is intended for the case of homogeneous bins with no costs.
This algorithm does not take bin type opening costs into account when opening a new bin.
This can lead to the algorithm selecting a more expensive bin type, when other less expensive bin types are available.
A simple method for solving this problem is to always choose to open the cheapest feasible bin type.
However, this method turns out to not perform very well, and much better methods are available.
One such superior bin selection method will be discussed in @bfd_algo.


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

$ u_(i,t)="PackJobs"(bold(m)_i,bold(l)_t) $

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
              Assign($u_(i,t)$, $"PackJobs"(bold(m)_i, bold(lambda)_t)$)
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

This method for computing an upper-bound on the number of each machine type required is not practically interesting.
This is because a far superior packing can be found by directly using a packing method such as first-fit decreasing, without first computing any upper-bound.

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

For each bin $i$, we define the _bin utilization_ $U_i$ as:

$
  U_(i) = bold(alpha)^T (bold(b)_i - bold(l)_i)
$

where the vector $bold(alpha)$ is the resource weight vector.

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

This repacking algorithm turned out to only be able to yield improved solutions when given deliberately poor starting solutions.
When given solutions computed using more intelligent heuristics, the algorithm was unable to find improved solutions.
Therefore, this algorithm will not be evaluated or discussed any further.

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

Next, we compute the new machine vector $bold(hat(x)) = max_t bold(z)_t$.
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

This algorithm was greatly outperformed by much simpler algorithms, first-fit decreasing being one of them.
Therefore, we will not be evaluating this algorithm or discussing it any further.

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

Yet again, this more complex algorithm was greatly outperformed by much simpler algorithms, first-fit decreasing being one of them.
Therefore, we will not be evaluating this algorithm or discussing it any further.

== Peak demand scheduler

Here, we briefly describe a new packing algorithm we shall call _"PeakDemand"_.
This algorithm begins by finding the time-slot with _peak demand_.
This is done by computing the vector $bold(v)$ of total time-slot costs:

$
  bold(v) = bold(alpha)^T bold(R) bold(L)^T
$

Next, we select the peak demand time-slot $t^*$:

$
  t^* = arg max_t v_t
$

Next, we pack the jobs $bold(l)_(t^*)$ for this time-slot.
After this, we pack the remaining time slot, each time keeping the bins for the previous time-slot as open bins for packing the next time slot.
The idea here is that any solution to the problem will need to be able to run all jobs for the peak-demand time-slot.
Therefore, we should begin by packing this time-slot, and then attempt to pack all other time-slots using these open bins.

== Heuristics for FFD

Here, we shall describe a number of different variations of the first-fit decreasing algorithm, each using a different heuristic.
Many of these heuristics were first presented by in 2017 by Panigrahy et al. @Panigrahy2011HeuristicsFV.
Some of these heuristics are also discussed in @size_measures.

All of the algorithms described in this section always select the cheapest feasible bin when opening a new bin.
The algorithms do differ in how they sort the item types before they are packed.

The _FFDLex_ (also referred to in this report as just _FFD_) algorithm orders all item types at once using a single lexicographical sort.
The _FFDSum_ algorithm orders item types in decreasing order of the sum of their resource demand vector $sum_k r_(j,k)$.
The _FFDProd_ algorithm orders item types in decreasing order of the product of their resource demand vector $product_k r_(j,k)$.
This algorithm works best when all resource demand values are positive.
The _FFDMax_ algorithm orders item types in decreasing order of their maximum resource demand value $max_k r_(j,k)$.
The _FFDL2_ algorithm orders item types in decreasing order of the Euclidean (L2) vector norm of their resource demand vector $norm(bold(r)_j)_2$.

== Resource-weighted cost-aware best-fit algorithm <bfd_algo>

Finally, we will now describe a packing algorithm based on the best-fit heuristic.
This is a simpler algorithm, which does not make use of any of the previous _"ruin-and-recreate"_ or _"neighborhood search"_ methods used by the previously described algorithm.
As we shall later see in the coming Results section (@results_section), this algorithm yields excellent solutions, dominating all other packing algorithms previously described in this report.
The strength of this algorithm comes from how it selects the type of bin to open for a new item.
Previous algorithm have used naïve methods for this, such as simply selecting the cheapest feasible bin type.
This algorithm takes a more intelligent approach to the problem, instead attempting to place multiple items of the same type into a new open bin, and selecting the bin type which can accomplish this with minimum remaining slack.
Because of this, the algorithm could also be viewed as a best-fit-next-fit hybrid algorithm.
This new method encourages the selection of bin types which are neither too large or too small.
A similar slack-based method is used to select which of the already open bins should store a given item.

We begin by presenting a pseudocode description of the algorithm.
Thereafter, we describe each step of the algorithm in greater detail.
=== Pseudocode


#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("BestFit packing algorithm", vstroke: .5pt + luma(200), inset: 0.3em, {
    import algorithmic: *
    Procedure(
      "BestFitPackingAlgorithm",
      ($bold(C), bold(R), bold(L), bold(c^p), bold(c^r), bold(alpha)$),
      {
        LineComment(
          Assign($(bold(hat(R)),bold(hat(L)))$, $"ResourceWeightSort"(bold(R),bold(L),bold(alpha))$),
          $"Sort "bold(R) "and" bold(L) "by resource demand"$,
        )

        LineComment(Assign($B$, $emptyset$), "Initialize empty set of bins")
        LineComment(Assign($X_(i,t)$, $0, quad forall i,t$), "Initialize bin-type matrix to zero")

        For($1<=t<=T$, {
          For($1<=j<=J$, {
            LineComment(Assign($eta$, $hat(l)_(j,t)$), "Initialize remaining jobs counter")
            While($eta > 0$, {
              IfElseChain(
                $B != emptyset$,
                {
                  For($b in B$, {
                    LineComment(Assign($i$, $tau_(t,b)$), $"Bin type of bin "b$)
                    LineComment(
                      Assign($bold(lambda)$, $sum_(bold(nu) in b) bold(nu)$),
                      "Compute total load of items in current bin",
                    )
                    LineComment(
                      Assign($bold(rho)$, $bold(m)_i-bold(lambda)$),
                      "Compute remaining capacity of current bin",
                    )
                    LineComment(
                      Assign($q_b$, $min_(k: hat(r)_k>0) floor(rho_k\/hat(r)_(j,k))$),
                      $"Number of type "j" items which fit in bin" b$,
                    )
                    LineComment(Assign($n_b$, $min(q_b, eta)$), $"Number of type "j" items to place in bin" b$)

                    LineComment(
                      Assign($bold(u)$, $bold(rho) - n_b bold(hat(r))_j$),
                      $"Slack of bin " b "with" n_b "type" j "items"$,
                    )

                    LineComment(
                      Assign($Phi_b$, $sum_(k=1)^K alpha_k u_k^2$),
                      $"Compute weighted slack score for bin" b$,
                    )
                    LineComment(Assign($k_b$, $(Phi_i, c^r_i, i)$), "Use running cost and index for tie-break")
                  })
                  LineComment(Assign($b^*$, $arg min_b k_b$), "Select bin with minimum slack score")
                  LineComment(Assign($eta$, $eta - n_(b^*)$), "Update packed jobs counter")
                  LineComment(
                    Assign($y_(t,j,b^*)$, $y_(t,j,b^*) + n_(b^*)$),
                    $"Pack" n_(b^*) "type" j "items into bin" b^*$,
                  )
                },
                {
                  For($1<=i<=M$, {
                    LineComment(
                      Assign($q_i$, $min_(k: hat(r)_k>0) floor(m_(i,k)\/hat(r)_(j,k))$),
                      $"Num. of type" j "items which fit in bin type" i$,
                    )

                    LineComment(Assign($n_i$, $min(eta, max(1, q_i))$), "")

                    LineComment(
                      Assign($bold(u)$, $bold(m)_i - n_i bold(r)_j$),
                      $"Slack of bin type" i "with" q_i "type" j "items"$,
                    )

                    LineComment(
                      Assign($Psi_i$, $sum_(k=1)^K alpha_k u_k^2 \/c^r_i$),
                      $"Compute slack score for bin type "i$,
                    )
                    LineComment(Assign($k_i$, $(Psi_i, c^r_i, i)$), "Use running cost and index for tie-break")
                  })
                  LineComment(Assign($i^*$, $arg min_i k_i$), "Select bin type with minimum cost-slack score")
                  LineComment(Assign($eta$, $eta - n_(i^*)$), "Update packed jobs counter")
                  LineComment(Assign($X_(i^*,t)$, $X_(i^*,t) + 1$), $"Open new bin of type" i^*$)
                  LineComment(Assign($b$, $X_(i^*,t)$), $"Number of open bins of type" i^*$)
                  LineComment(
                    Assign($y_(t,j,b)$, $y_(t,j,b) + n_(i^*)$),
                    $"Pack" n_(b^*) "type" j "items into bin" b$,
                  )
                },
              )
            })
          })
          LineComment(Assign($bold(x)$, $max_t X_(i,t)$), "Take max machine type counts over time slots")
        })
        Return[$bold(x)$, $y$]
      },
    )
  })])

=== Algorithm description

The algorithm uses a weighted best-fit heuristic, with resource demand-aware job type ordering and cost-aware bin type selection.
The algorithm uses the resource weight vector $bold(alpha)$ to compute the item size vector $bold(v)=bold(R)^T bold(alpha)$, where each item type $j$ has scalar size $v_j$.
This ordering gives higher priority to item types with a greater demand for scarce resources.
Item types are packed in non-increasing order of their priorities.

For each unpacked item of type $j$ with demand vector $bold(r)_j$, we first check if there are any open bins with sufficient capacity.
If there are any such bins open, then we select the best bin to store the item.
The open bin selection works as follows.
For each open bin $b$, let $bold(rho)$ be the bin's remaining capacity vector.
We compute the maximum number $q_b$ of items of type $j$ which can be added to the bin.

$
  q_b = min_(k: hat(r)_(j,k)>0) floor(rho_(k)/hat(r)_(j,k))
$

Note here that each $hat(r)_(j,k)$ is an element of the job-demand matrix $bold(hat(R))$ formed by permuting the columns of $bold(R)$.
For each bin $b$ which can accommodate at least one type $j$ item (i.e. $q_b >= 1$), we compute $n_b=min(q_b, eta)$.
Next, we compute the remaining capacity (slack) $bold(u)=bold(rho) - n_b bold(hat(r))_j$ of bin $b$ after storing $n_b$ items of type $j$.
This is inspired by the L2 Norm-based Greedy heuristic, described in @Panigrahy2011HeuristicsFV.
Next, we compute a score $Phi_b$ representing the quality of the fit of the current item in bin $b$.

$
  Phi_b = sum_(k=1)^K alpha_k u_k^2
$

We select the open bin $b^*$ with minimum slack score $Phi_(b^*)$.
We use bin opening costs and bin indexes for tie breaking.
Finally, we pack $n_(b^*)$ items of type $j$ into bin $b^*$, by incrementing $y_(t,j,b^*)$ by $n_(b^*)$.
We decrement the number of remaining unpacked items by $n_(b^*)$.

In the other case in which there are no open bins with sufficient capacity, we must open a new bin.
Here, as before, we use a score-based method for selecting the optimal bin type.
For each bin type $i$ with sufficient capacity, we compute the maximum number $q_i$ of items of type $j$ which can be stored in an empty bin of type $i$.

$
  q_i = min_(k: hat(r)_(j,k)>0) floor(m_(i,k)/hat(r)_(j,k))
$

Next, as before, we compute the remaining capacity (slack) vector $bold(u) = bold(m)_i - q_i bold(r)_j$ of bin type $i$ after storing $q_i$ items of type $j$.
Next, we compute a bin selection score $Psi_i$ to use for selecting the optimal bin type to open.

$
  Psi_i = sum_(k=1)^K alpha_k u_(k)^2 /c^r_i
$

As before, we select the bin type $i^*$ with minimum score $Psi_(i^*)$, using bin opening costs and bin indexes for tie-breaking.
The score $Psi_i$ is nearly identical to the previous $Phi_b$, except for the normalization factor $c^r_i$.
Recall the definition $bold(c^r) = bold(C)^T bold(alpha)$.
By dividing $u_k^2$, the squared slack in dimension $k$, by $c^r_i$, the size (or cost) of bin type $i$, we are normalizing the slack by the bin size.
This gives us a measure of _"slack per unit of bin capacity"_, which favors bins which fit the required demand proportionally well, rather than simply selecting the bins with smaller overall remaining capacity.
Without this normalization, larger bins with greater raw capacity will be unfairly penalized, pushing the heuristic to instead selecting smaller-capacity bins.
This can in turn lead to item fragmentation and a overall inferior packing.

We open one new bin of type $i^*$, by incrementing $X_(i^*,t)$.
Let $b^* = X_(i^*,t)$.
Finally, we pack $n_(i^*)$ items of type $j$ into this new bin, by incrementing $y_(t,j,b^*)$ by $n_(i^*)$.
We decrement the number of remaining unpacked items by $n_(i^*)$.

As with other previously discussed packing algorithms, this process is repeated for all $T$ time slots.
For each bin type $i$, we let $x_i = max_t X_(i,t)$ be the maximum number of bins of type $i$ used across all time slots.
Finally, we return the bin-type vector $bold(x)$ and the item-bin-time slot packing variable $y$.

We can create a new FFD-based packing algorithm based on this algorithm.
We will call this algorithm _"FFDNew"_.
The algorithm will use the same job-ordering and new bin selection methods as this algorithm.
However, like first fit, it will place items in the first bin which accommodate it.
