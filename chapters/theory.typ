#import "@preview/algorithmic:1.0.6"
#import algorithmic: algorithm-figure, style-algorithm

#let ZZnonneg = $ZZ_(>=0)$

= Theory <theory_section>

This chapter introduces the bin-packing formulations and algorithmic bounds that underpin the scheduler design.
Throughout this thesis, for a positive integer $n$, let $cal(n) = {1,dots.h,n}$ denote the index set from $1$ to $n$.

== Bin-packing problem definition

=== One-dimensional bin-packing problem

The book _Computers and Intractability_ @book_computers_intractability gives the following definition of the bin-packing problem.
We are given a finite set $U={u_1,dots.h,u_n}$ of items where item $u in U$ has item size $s_u$, where $0 < s_u <= c$.
The problem is to find a partition of $U$ into $k$ disjoint subsets $U_1,dots.h,U_k$ such that the sum of the size of the items in each subset $U_i$ is no more than $c$ and such that $k$ is as small as possible.
Each subset $U_i$ is as a _bin_, and the elements of $U_i$ are the items in the bin.

The bin-packing problem is NP-hard @karp_1972_reducibility @book_computers_intractability.
Informally, this means that there is no known algorithm that always finds an optimal solution efficiently for every possible input.
If an efficient general algorithm for an NP-hard optimization problem were found, then it would imply efficient solutions for a large class of other difficult combinatorial problems.
For this reason, practical work on bin-packing often uses approximation algorithms and heuristics, which aim to find good solutions quickly rather than guaranteeing an optimal solution for every instance.

The problem can be formulated as an integer LP problem:

$
    "minimize" & quad sum_(j=1)^n y_j \
  "subject to" & quad sum_(j=1)^n x_(i j) = 1, quad forall i in cal(n) \
               & quad sum_(i=1)^n s_i x_(i j) <= c y_j, quad forall j in cal(n) \
               & x_(i j) in {0,1}, quad y_j in {0,1} quad forall i,j in cal(n) \
$

Here, $n$ is the number of items.
The model uses $n$ candidate bins, since no feasible solution requires more bins than there are items.
The capacity of all bins is $c$.
The variable $y_j$ is equal to 1 if bin $j$ is used, and $0$ otherwise.
The variable $x_(i j)$ is equal to 1 if item $i$ is placed in bin $j$, and $0$ otherwise.
The objective is to minimize the number of bins used.
The first constraint ensures that each item $i$ is placed in exactly one bin.
The second constraint ensures that no bin capacity is exceeded by the items placed in it.

=== Multidimensional heterogeneous bin-packing problem

We now consider a more general case of the problem, where both items and bins have different sizes and capacities in multiple dimensions.
For this case, items and bins both have $K$ dimensions.
The size of item $i$ is given by the $K$-dimensional vector $bold(s)_i in ZZnonneg^K$.
The capacity of bin $j$ is given by the $K$-dimensional vector $bold(c)_j in ZZnonneg^K$.
The set $ZZnonneg^K$ is the set of all $K$-dimensional vectors with non-negative integer elements.

The problem can be formulated as an integer LP problem:

$
    "minimize" & quad sum_(j=1)^m y_j \
  "subject to" & quad sum_(j=1)^m x_(i j) = 1, quad forall i in cal(n) \
               & quad sum_(i=1)^n bold(s)_i x_(i j) <= bold(c)_j y_j, quad forall j in cal(m) \
               & x_(i j) in {0,1}, quad y_j in {0,1} quad forall i in cal(n), j in cal(m) \
$

Here, $n$ is the number of items and $m$ is the number of candidate bins.

== Online bin-packing algorithms

=== (FF) First fit <ff_algorithm>
The _first-fit_ algorithm assigns an item to the bin $U_j$ with sufficient capacity and the smallest index $j$.
If an item does not fit in any open bin, a new bin is opened, and the item is placed in it @garey_graham_ullman_1972.

#show: style-algorithm
#algorithm-figure("First fit", vstroke: .5pt + luma(200), {
  import algorithmic: *
  Procedure(
    "FirstFit",
    ("bins", "items"),
    {
      For($"object" i = 1,2,...,n$, {
        For($"open bin" j = 1,2,...,m$, {
          If($"object "i" fits in bin" j$, {
            Comment[Place object $i$ in bin $j$]
            Break
          })
        })
        If($"object "i" did not fit in any open bin"$, {
          Comment[Open and place object $i$ in a new bin]
        })
      })
    },
  )
})

Here, $m$ is the current number of open bins.
In the worst case, a new bin must be opened for each of the $n$ items.
This means that placing the $k$-th item will require $k$ bin size checks.
This gives this implementation of the algorithm the time complexity $Omicron (n^2)$.
Better time complexities may be achievable using better implementations.

=== (BF) Best fit
Place each item into the bin with the smallest remaining capacity which is at least as large as the size of item.
If an item does not fit in any open bin, a new bin is opened, and the item is placed in it @garey_graham_ullman_1972.

#show: style-algorithm
#block(breakable: false, {
  algorithm-figure("Best fit", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure(
      "BestFit",
      ("bins", "items"),
      {
        For($"object" i = 1,2,...,n$, {
          Comment($"Let S be the set of open bins which fit object" i$)
          Assign($S$, ${b | b in "bins" , r(b) >= s(i)}$)
          IfElseChain(
            $S = emptyset$,
            {
              Comment[Open and place object $i$ in a new bin]
            },
            {
              Comment($"Let bin "j" be the bin which fits object "i" with minimum remaining capacity"$)
              Assign($j$, $arg min_(b in S) r(b)$)
              Comment[Place object $i$ in bin $j$]
            },
          )
        })
      },
    )
  })
})

Here, $r(b)$ is the remaining capacity of bin $b$.
For the worst case, we must check each of the $m$ open bins for each of the $n$ items.
This gives the algorithm the time complexity $Omicron (n^2)$.

== Offline bin-packing algorithms

In offline scheduling, the relevant job data are assumed to be known before the schedule is constructed.
For online scheduling requires decisions under incomplete knowledge of future jobs or releases @pinedo_single_machine_2016 @lee_leung_pinedo_2013_online_scheduling.

For the offline case, we can improve the previous online algorithms by sorting the items in decreasing order.
This gives us the First-Fit-Decreasing algorithm @garey_graham_ullman_1972.

We can extend the first-fit decreasing algorithm for multidimensional heterogeneous bin-packing.
In order to do this, we must first define how items and bins shall be sorted.


== Algorithmic bounds for bin-packing algorithms

Much research has been done on finding tight bounds for approximation algorithms for bin-packing.
Due to this, we shall only discuss some of the latest relevant results.
By bounds, we mean the ratio between the number of bins used by the approximation algorithms, and the optimal number of bins possible for the input.
For some given problem $L$, we denote by $A(L)$ the number of bins opened by algorithm $A$ for problem $L$.
By $"OPT"(L)$ we denote the theoretical minimum number of opened bins required for problem $L$.
Note that these bounds hold only for the classical one-dimensional unit-capacity bin-packing problem.

We shall now present a few important theoretical bounds for bin-packing algorithms.
In 2007, Dósa @dosa_2007_ffd_bounds showed new bounds for First-Fit-Decreasing:
$
  "FFD"(L) ≤ 11/9 "OPT"(L) + 6/9.
$

In 2013, Dósa and Sgall @dosa_sgall_2013_ff_bounds showed new bounds for First-Fit:

$
  "FF"(L) <= floor(1.7 "OPT"(L)).
$

This means that if the optimal number of required bins for the input $L$ is $"OPT"(L)$, then the First-Fit algorithm uses at most $floor(1.7 "OPT"(L))$ bins.

In 2014, Dósa and Sgall @dosa_sgall_2014_bounds_bf showed that the same absolute bound for First-Fit also holds for Best-Fit:
$
  "BF"(L) <= floor(1.7 "OPT"(L)).
$
