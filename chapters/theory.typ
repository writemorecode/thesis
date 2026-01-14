#import "@preview/algorithmic:1.0.6"
#import algorithmic: algorithm-figure, style-algorithm

#let ZZnonneg = $ZZ_(>=0)$

= Theory <theory_section>

This chapter introduces the bin-packing formulations and algorithmic bounds that underpin the scheduler design.

== Bin-packing problem definition

=== One-dimensional bin-packing problem

The book _Computers and Intractability_ @book_computers_intractability gives the following definition of the bin-packing problem.
Given a finite set $U={u_1,dots.h,u_n}$ of _items_ and a rational _size_ $s(u) in [0,1)$ for each item $u in U$, find a partition of $U$ into disjoint subsets $U_1,dots.h,U_k$ such that the sum of the size of the items in each $U_i$ is no more than $1$ and such that $k$ is as small as possible.

The problem can be formulated as an integer LP problem:

$
  "minimize" quad sum_(i=1)^k y_i \
  "subject to" quad \
  sum_(j=1)^k x_(i j) = 1 quad forall 1 <= i <= n \
  sum_(i=1)^n s(i) x_(i j) <= c y_j quad forall 1 <= j <= k \
  x_(i j) in {0,1}, quad y_j in {0,1} quad forall i,j \
$

Here, $k$ and $n$ are the number of bins and items, respectively.
The capacity of all bins is $c$.
The variable $y_j$ is equal to 1 if bin $j$ is used, and $0$ otherwise.
The variable $x_(i j)$ is equal to 1 if item $i$ is placed in bin $j$, and $0$ otherwise.
As before, the objective is to minimize the number of bins used.
The first constraint ensures that each item $i$ is placed in exactly one bin.
The second constraint ensures that no bin capacity is exceeded by the items placed in it.

=== Multidimensional heterogeneous bin-packing problem

We now consider a more general case, where both items and bins have different sizes and capacities in multiple dimensions.
Items and bins have $D$ dimensions.
The size of item $i$ is given by $bold(s)(i) in ZZnonneg^D$.
The capacity of bin $j$ is given by $bold(c)(j) in ZZnonneg^D$.

The problem can be formulated as an integer LP problem:

$
  "minimize" quad sum_(i=1)^k y_k \
  "subject to" quad \
  sum_(j=1)^k x_(i j) = 1 quad forall 1 <= i <= n \
  sum_(i=1)^n bold(s)(i) x_(i j) <= bold(c)(i) y_j quad forall 1 <= j <= k \
  x_(i j) in {0,1}, quad y_j in {0,1} quad forall i,j \
$

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
        For($"bin" j = 1,2,...,m$, {
          If($"object i fits in bin j"$, {
            Comment[Place object i in bin j]
            // Assign($"bin j"$, $"object i"$)
            Break
          })
        })
        If($"object i did not fit in any open bin"$, {
          Comment[Open and place object i in a new bin]
          // Assign($"new bin"$, $"object i"$)
        })
      })
    },
  )
})

In the worst case, a new bin must be opened for each of the $n$ items.
This means that placing the $k$:th item will require $k$ bin size checks.
This gives the algorithm the quadratic time complexity $Omicron (m n)$.

=== (BF) Best fit
Place each item into the bin with the smallest remaining capacity which is at least as large as the size of item.
If an item does not fit in any open bin, a new bin is opened, and the item is placed in it @garey_graham_ullman_1972.

#show: style-algorithm
#algorithm-figure("Best fit", vstroke: .5pt + luma(200), {
  import algorithmic: *
  Procedure(
    "BestFit",
    ("bins", "items"),
    {
      For($"object" i = 1,2,...,n$, {
        Comment($"Let S be the set of capacities of all bins which fit object i"$)
        Assign($S$, ${c(b) | b in "bins" , c(b) >= s(i)}$)
        IfElseChain(
          $S = nothing$,
          {
            Comment[Open and place object i in a new bin]
          },
          {
            Comment($"Let bin j be the bin which fits object i with minimum remaining capacity"$)
            Assign($j$, FnInline([min], [S]))
            Comment[Place object i in bin j]
          },
        )
      })
    },
  )
})

For the worst case, we must check each of the $m$ bins for each of the $n$ items.
This gives the algorithm the time complexity $Omicron (m n)$.
The algorithm can be improved by storing the bin capacities in a sorted data structure, such as a binary heap.
Binary heaps allow us to retrieve the smallest element from a heap of $m$ elements in $Omicron (log m)$ time.
This gives the algorithm an improved time complexity of $Omicron (n log m)$.

=== (WF) Worst fit
A variation of best-fit, where we instead select the bin with the largest remaining capacity @garey_graham_ullman_1972.

#show: style-algorithm
#algorithm-figure("Worst fit", vstroke: .5pt + luma(200), {
  import algorithmic: *
  Procedure(
    "WorstFit",
    ("bins", "items"),
    {
      For($"object" i = 1,2,...,n$, {
        Comment($"Let S be the set of capacities of all bins which fit object i"$)
        Assign($S$, ${c(b) | b in "bins" , c(b) >= s(i)}$)
        IfElseChain(
          $S = nothing$,
          {
            Comment[Open and place object i in a new bin]
          },
          {
            Comment($"Let bin j be the bin which fits object i with maximum remaining capacity"$)
            Assign($j$, FnInline([max], [S]))
            Comment[Place object i in bin j]
          },
        )
      })
    },
  )
})

Same time complexity as best fit.

=== (NF) Next-fit
First, open a single bin.
Let this bin be the current bin.
Place items into this bin until an item does not fit into the bin.
When this happens, close this bin, open a new bin, and make the new bin the current bin @garey_graham_ullman_1972.

#show: style-algorithm
#algorithm-figure("Next fit", vstroke: .5pt + luma(200), {
  import algorithmic: *
  Procedure(
    "NextFit",
    ("bins", "items"),
    {
      Assign([Current bin], [First bin])
      For($"object" i = 1,2,...,n$, {
        IfElseChain(
          $"object i fits in current bin"$,
          {
            Comment[Place object i in current bin]
          },
          {
            Comment[Open and place object i in a new bin, make this the current bin]
          },
        )
      })
    },
  )
})

Each item only checks the current bin, opening a new bin if needed.
This gives the algorithm the time complexity $Theta (n)$.

== Offline bin-packing algorithms

For the offline case, we can improve the previous online algorithms by sorting the items in decreasing order.
This gives us the First-Fit-Decreasing and Next-Fit-Decreasing algorithms @garey_graham_ullman_1972.

We can extend the first-fit decreasing algorithm for multidimensional heterogeneous bin-packing.
In order to do this, we must first define how items and bins shall be sorted.


== Algorithmic bounds for bin-packing algorithms

Much research has been done on finding tight bounds for approximation algorithms for bin-packing.
Due to this, we shall only discuss the latest results.
By _bounds_, we mean the ratio between the number of bins used by the approximation algorithms, and the optimal number of bins possible for the input.

In 2013, Dósa and Sgall @dosa_sgall_2013_ff_bounds showed new bounds for First-Fit: $"FF"(L) <= floor(1.7 "OPT"(L))$.
This means that if the optimal number of required bins for the input $L$ is $"OPT"(L)$, then the First-Fit algorithm will require $floor(1.7 "OPT"(L))$ bins.

In 2007, Dósa @dosa_2007_ffd_bounds showed new bounds for First-Fit-Decreasing: $"FFD"(L) ≤ 11/9 "OPT"(L) + 6/9$.
In 2014, Dósa and Gyorgy @dosa_gyorgy_2014_bounds_bf showed that these same bounds also hold for Best-Fit.

In David Johnson's 1973 Ph.D. thesis @johnson_1973_phd, the bounds $A(L) ≤ 2 "OPT"(L) - 1$ for the Next-Fit and Worst-Fit algorithms were presented.

== Size measures for items and bins <size_measures>

=== Size measures

In order to be able to use heuristics-based bin-packing algorithm such as First-Fit Descending, we must be able to order machine types and job types in order of size.
In this section, we shall take a more abstract approach and refer to jobs and machines as items and bins, respectively.
Mommessin et al. @MOMMESSIN2025106860 has evaluated and classified a number of different algorithms for vector bin packing with homogeneous bins.
These algorithms may be classified as either item-centric or bin-centric.
Item-centric algorithms pack items into bins one item at a time.
Bin-centric algorithms pack items into a single current bin until it is full, before opening a new current bin.

The size measures for the item-centric algorithms can be divided into three different classes.
First, there is the dominant resource measure, given by maximum resource demand or capacity for an item or bin, respectively.
This measure, among others, was introduced in @Maruyama_Chang_Tang_1977.
With this measure, the size of an item or bin $bold(u)$ is given by:
$
  S_("MAX")(bold(u)) = max_k u_k.
$

For the last two measures, there is a weight parameter $w_k$ for each dimension $k$.
Second, there is the weighted sum measure @Maruyama_Chang_Tang_1977.
With this measure, the size of an item or bin $bold(u)$ is given by:
$
  S_("SUM")(bold(u)) = sum_(k=1)^K w_k u_k
$ <eqn_l1_sum_size_measure>

Third, there is the weighted sum of squares measure @Maruyama_Chang_Tang_1977.
With this measure, the size of an item or bin $bold(u)$ is given by:
$
  S_("SQSUM")(bold(u)) = sum_(k=1)^K w_k u_k^2
$

For the bin-centric algorithms, we can use the remaining capacity of the current open bin to define other size measures.
Let this capacity vector be $bold(q)$.

The first size measure is a normalized weighted dot product between an item $bold(u)$ and the remaining capacity of the current open bin $bold(q)$.
With this measure, the size of an item $bold(u)$ is given by:

$
  S_("DP1")(bold(u)) = 1 / (norm(bold(u)) norm(bold(q))) sum_(k=1)^K w_k u_k q_k.
$
For this measure, the size of the item will be determined by how well it fits into the remaining capacity of the current open bin.

//We can define a different dot product-based size measure, introduced in @MOMMESSIN2025106860, by using a different form of normalization.
//$
//  S_("DP2")(bold(u)) = sum_(k=1)^K w_k u_k/D_k q_k/R_k
//$
//
//Let $I$ and $B$ be the set of all items and bins, respectively.
//Here, $D_k$ is the total size of each item in dimension $k$. $R_k$ is the total remaining capacity in dimension $k$ across all bins, opened or unopened.
//The value $D_k$ is computed once and remains constant, but $R_k$ is re-computed after each item placement decision is made.
//This makes this size measure more adaptive than other measures.

Finally, we can define a size measure from the negative weighted sum of squared Euclidean distance between an item vector $bold(u)$ and the remaining capacity $bold(q)$ of the current open bin.
This measure was introduced by @Panigrahy2011HeuristicsFV.
With this measure, the size of an item is given by:
$
  S_("L2")(bold(u)) = -sum_(k=1)^K w_k (u_k - q_k)^2.
$

=== Weights for size measures

In Mommessin et al. @MOMMESSIN2025106860, the authors discuss different options for the weights $w_k$ used for the previously discussed item/bin size measures.
These weights are based on the total size (demand) and capacity of items and bins, respectively.
For the simplest case, we can set $w_k=1$ for all dimensions $k$.
This gives each dimension/resource equal weight.
Next, we shall discuss more advanced weights.

Let $I$ and $B$ be the set of all items and bins, respectively.
Previously, we have divided items and bins (jobs and machines) into different types.
However, for bin-packing algorithms the items and bins will be stored in a list with possible duplicates.
Therefore, in this case it makes more sense to consider lists rather than sets.

Let $d_k$ be the average size in dimension $k$ of all items, and let $b_k$ be the average capacity in dimension $k$ of all activated bins:

$
  d_k = 1/abs(I) sum_(i in I) r_(i,k), quad b_k = 1/abs(B) sum_(b in B) q_(b,k).
$

Here, $q_(b,k)$ is the remaining (residual) capacity in dimension $k$ of bin $b$.
Let $I^* subset.eq I$ be the set of all unallocated items, and define $d^*_k$ as the average size in dimension $k$ of all unallocated items:

$
  d^*_k = 1/abs(I^*) sum_(i in I^*) r_(i,k).
$

Depending on whether the packing algorithm we are using is item-centric or bin-centric, we shall use different weights.
For item-based algorithms such as FFD, we shall want to use weights based on the average size of all items in each dimension, such as $w_k=d_k$ @caprara_lower_2001.
We can also choose to update these weights after each time we place an item in a bin.
In this case, we will want to use weights $w_k=d^*_k$ where we only consider the items which have not yet been placed in some bin.

Similarly, if we are using bin-centric algorithms such as Next Fit Decreasing, we shall want to use weights based on bin capacities, such as $w_k=b_k$.
These weights shall then also be updated after each time an item is placed in a bin.

=== Alternative method for item & bin size normalization

We can normalize the sizes of items and bins by, for each resource dimension $k$, dividing each item type $bold(r)_i$ and machine type $bold(m)_j$ by a scale $M_k$.
Here, we define $M_k$ as the maximum resource demand or capacity across all item and machine types.

$
  M_k = max_(i,j) {bold(r)_i, bold(m)_j}.
$

With this definition, we can define the normalized item and bin type vectors as

$ hat(bold(r))_i=(r_(i,1) \/ M_1,dots.h,r_(i,K) \/ M_K) $
and
$ hat(bold(m))_j=(m_(j,1) \/ M_1,dots.h,m_(j,K) \/ M_K) $
respectively.
