#import "@preview/algorithmic:1.0.6"
#import algorithmic: style-algorithm, algorithm-figure

= Theory

Suppose we have bins $U_1,dots.h,U_n$.
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

== Offline bin-packing algorithms
For the offline case, we can improve the previous online algorithms by sorting the items in decreasing order.
This gives us the FirstFitDecreasing and NextFitDecreasing algorithms @garey_graham_ullman_1972.
