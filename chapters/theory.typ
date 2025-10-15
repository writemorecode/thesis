#import "@preview/algorithmic:1.0.6"
#import algorithmic: style-algorithm, algorithm-figure

#let ZZnonneg = $ZZ_(>=0)$

= Theory

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

=== (FF) First fit
The _first-fit_ algorithm assigns an item to the bin $U_j$ with sufficient capacity and the smallest index $j$.
If an item does not fit in any open bin, a new bin is opened, and the item is placed in it @garey_graham_ullman_1972.

#show: style-algorithm
#algorithm-figure("First fit",
vstroke: .5pt + luma(200),
{
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
    }
  )
}
)

In the worst case, a new bin must be opened for each of the $n$ items.
This means that placing the $k$:th item will require $k$ bin size checks.
This gives the algorithm the quadratic time complexity $Omicron (m n)$.

=== (BF) Best fit
Place each item into the bin with the smallest remaining capacity which is at least as large as the size of item.
If an item does not fit in any open bin, a new bin is opened, and the item is placed in it @garey_graham_ullman_1972.

#show: style-algorithm
#algorithm-figure("Best fit",
vstroke: .5pt + luma(200),
{
  import algorithmic: *
  Procedure(
    "BestFit",
    ("bins", "items"),
    {
      For($"object" i = 1,2,...,n$, {
        Comment($"Let S be the set of capacities of all bins which fit object i"$)      
        Assign($S$, ${c(b) | b in "bins" , c(b) >= s(i)}$)
        IfElseChain($S = nothing$, {
          Comment[Open and place object i in a new bin]
        },
        {
          Comment($"Let bin j be the bin which fits object i with minimum remaining capacity"$)      
          Assign($j$, FnInline([min], [S]))
          Comment[Place object i in bin j]
        }
      )
      })      
    }
  )
}
)

For the worst case, we must check each of the $m$ bins for each of the $n$ items.
This gives the algorithm the time complexity $Omicron (m n)$. 
The algorithm can be improved by storing the bin capacities in a sorted data structure, such as a binary heap.
Binary heaps allow us to retrieve the smallest element from a heap of $m$ elements in $Omicron (log m)$ time.
This gives the algorithm an improved time complexity of $Omicron (n log m)$.

=== (WF) Worst fit
A variation of best-fit, where we instead select the bin with the largest remaining capacity @garey_graham_ullman_1972.

#show: style-algorithm
#algorithm-figure("Worst fit",
vstroke: .5pt + luma(200),
{
  import algorithmic: *
  Procedure(
    "WorstFit",
    ("bins", "items"),
    {
      For($"object" i = 1,2,...,n$, {
        Comment($"Let S be the set of capacities of all bins which fit object i"$)      
        Assign($S$, ${c(b) | b in "bins" , c(b) >= s(i)}$)
        IfElseChain($S = nothing$, {
          Comment[Open and place object i in a new bin]
        },
        {
          Comment($"Let bin j be the bin which fits object i with maximum remaining capacity"$)      
          Assign($j$, FnInline([max], [S]))
          Comment[Place object i in bin j]
        }
      )
      })      
    }
  )
}
)

Same time complexity as best fit.

=== (NF) Next-fit
First, open a single bin.
Let this bin be the current bin.
Place items into this bin until an item does not fit into the bin.
When this happens, close this bin, open a new bin, and make the new bin the current bin @garey_graham_ullman_1972.

#show: style-algorithm
#algorithm-figure("Next fit",
vstroke: .5pt + luma(200),
{
  import algorithmic: *
  Procedure(
    "NextFit",
    ("bins", "items"),
    {
      Assign([Current bin], [First bin])
      For($"object" i = 1,2,...,n$, {
        IfElseChain($"object i fits in current bin"$, {
          Comment[Place object i in current bin]
        }, {
          Comment[Open and place object i in a new bin, make this the current bin]
        })
      })      
    }
  )
}
)

Each item only checks the current bin, opening a new bin if needed.
This gives the algorithm the time complexity $Theta (n)$.

== Offline bin-packing algorithms
For the offline case, we can improve the previous online algorithms by sorting the items in decreasing order.
This gives us the FirstFitDecreasing and NextFitDecreasing algorithms @garey_graham_ullman_1972.
