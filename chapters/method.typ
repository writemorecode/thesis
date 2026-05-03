#import "@preview/fletcher:0.5.6" as fletcher: diagram, edge, node
#import "@preview/algorithmic:1.0.6"
#import algorithmic: algorithm-figure, style-algorithm

#let ZZnonneg = $ZZ_(>=0)$

= Method <method_section>

This chapter summarizes our research questions and the scheduling algorithms that are evaluated.

== Research questions

With this research, we aim to answer the following research questions:

RQ1: How can we create a cost-efficient algorithm for offline multi-resource cloud procurement planning and job scheduling? \

RQ2: How can we create a procurement planner and cloud job scheduler which is optimized for both scheduling quality and execution time?

== Algorithms

In this chapter, we will use the terms item and job interchangeably.
The same goes for the terms bin and machine.

=== Heuristics for FFD

Here, we shall describe a number of different variations of the first-fit decreasing algorithm, each using a different heuristic.
Many of these heuristics were first presented by in 2017 by Panigrahy et al. @Panigrahy2011HeuristicsFV.

All of the algorithms described in this section always select the cheapest feasible bin when opening a new bin.
The algorithms do differ in how they sort the item types before they are packed.

The _FFDLex_ (also referred to in this report as just _FFD_) algorithm orders all item types at once using a single lexicographical sort.
The _FFDSum_ algorithm orders item types in decreasing order of the sum of their resource demand vector $sum_k r_(j,k)$.
The _FFDProd_ algorithm orders item types in decreasing order of the product of their resource demand vector $product_k r_(j,k)$.
This algorithm works best when all resource demand values are positive.
The _FFDMax_ algorithm orders item types in decreasing order of their maximum resource demand value $max_k r_(j,k)$.
The _FFDL2_ algorithm orders item types in decreasing order of the Euclidean (L2) vector norm of their resource demand vector $norm(bold(r)_j)_2$.

=== Resource-weighted cost-aware best-fit algorithm <bfd_algo>

Next, we will describe a new packing algorithm based on the best-fit heuristic.
As we shall later see in the coming Results section (@results_section), this algorithm yields excellent solutions, dominating all other packing algorithms previously described in this report.
The strength of this algorithm comes from how it selects the type of bin to open for a new item.
Previous algorithm have used naïve methods for this, such as simply selecting the cheapest feasible bin type.
This algorithm takes a more intelligent approach to the problem, instead attempting to place multiple items of the same type into a new open bin, and selecting the bin type which can accomplish this with minimum remaining slack.
Because of this, the algorithm could also be viewed as a best-fit-next-fit hybrid algorithm.
This new method encourages the selection of bin types which are neither too large or too small.
A similar slack-based method is used to select which of the already open bins should store a given item.
Below, we present a table of symbols used by this algorithm.

#block(breakable: false, [
  #figure(
    table(
      columns: 2,
      [*Symbol*], [*Description*],
      [$B$], [Set of open bins for the current time slot],
      [$X_(i,t)$], [Number of bins of type $i$ open for time slot $t$],
      [$eta$], [Number of remaining unpacked items of current type],
      [$tau_(t,b)$], [Bin type of bin $b$ for time slot $t$],
      [$Phi_b$], [Slack score for bin $b$],
      [$y_(t,j,b)$], [Number of items of type $j$ in bin $b$ in time slot $t$],
      [$Psi_i$], [Slack score for bin type $i$],
    ),
    caption: [Symbol table for BFD and FFDNew algorithms.],
  )
])


We begin by presenting a pseudocode description of the algorithm.
Thereafter, we describe each step of the algorithm in greater detail.

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
          "Sort items",
        )

        LineComment(Assign($X_(i,t)$, $0, quad forall i,t$), "Initialize bin-type matrix to zero")

        For($1<=t<=T$, {
          LineComment(Assign($B$, $emptyset$), "Initialize empty set of bins for time slot")
          For($1<=j<=J$, {
            LineComment(Assign($eta$, $hat(l)_(j,t)$), "Initialize remaining jobs counter")
            While($eta > 0$, {
              LineComment(Assign($p$, $"SelectOpenBin"(t, j, eta, B)$), "Try feasible open bins first")
              IfElseChain(
                $p != "none"$,
                {
                  LineComment(Assign($(b^*, n^*)$, $p$), "Unpack helper result")
                  LineComment(Assign($eta$, $eta - n_(b^*)$), "Update packed jobs counter")
                  LineComment(
                    Assign($y_(t,j,b^*)$, $y_(t,j,b^*) + n_(b^*)$),
                    $"Pack" n_(b^*) "type" j "items into bin" b^*$,
                  )
                },
                {
                  LineComment(Assign($p$, $"SelectNewBinType"(j, eta)$), "No feasible open bin found")
                  IfElseChain(
                    $p != "none"$,
                    {
                      LineComment(Assign($(i^*, n^*)$, $p$), "Unpack helper result")
                      LineComment(Assign($eta$, $eta - n_(i^*)$), "Update packed jobs counter")
                      LineComment(Assign($X_(i^*,t)$, $X_(i^*,t) + 1$), $"Open new bin of type" i^*$)
                      LineComment(Assign($b$, $abs(B) + 1$), "Assign new bin index")
                      LineComment(Assign($tau_(t,b)$, $i^*$), $"Store type of new bin " b$)
                      LineComment(Assign($B$, $B union {b}$), "Add new bin to set of open bins")
                      LineComment(
                        Assign($y_(t,j,b)$, $y_(t,j,b) + n_(i^*)$),
                        $"Pack" n_(i^*) "type" j "items into bin" b$,
                      )
                    },
                    {
                      Return[$"infeasible input"$]
                    },
                  )
                },
              )
            })
          })
        })
        LineComment(Assign($bold(x)$, $max_t X_(i,t)$), "Take max machine type counts over time slots")
        Return[$bold(x)$, $y$]
      },
    )
  })])

The algorithm uses a weighted best-fit heuristic, with resource demand-aware job type ordering and cost-aware bin type selection.
For each time slot $t$, the algorithm starts with an empty set of open bins and packs the jobs of that time slot independently.
The algorithm uses the $K$-dimensional resource weight vector $bold(alpha)$ to compute the $J$-dimensional item size vector $bold(v)=bold(R)^T bold(alpha)$, where each item type $j$ has scalar size $v_j$.
Let
$
  bold(I)_J = mat(|, |, , |; bold(e)_1, bold(e)_2, dots.c, bold(e)_J; |, |, , |)
$
be the identity matrix of dimension $J$.
Let $pi$ be a permutation function on the set ${1,dots.h,J}$ where the following holds:
$
  v_(pi(1)) > v_(pi(2)) > v_(pi(3)) > dots.h > v_(pi(J)).
$

The permutation $pi$ permutes the indices ${1,dots.h,J}$ of the $bold(v)$ vector to be in decreasing order of their respective vector elements ${v_1,dots.h,v_J}$.
In other words, we are sorting the elements of the $bold(v)$ vector in decreasing order.
Using this permutation, we form the permutation matrix:

$
  bold(P) = mat(|, |, , |; bold(e)_(pi(1)), bold(e)_(pi(2)), dots.c, bold(e)_(pi(J)); |, |, , |).
$

Using this permutation matrix, we can re-order the columns $bold(r)_j$ of the matrix $bold(R)$, forming the new permuted matrix $bold(hat(R)) = bold(R) bold(P)$.

$
  bold(hat(R)) = mat(|, |, , |; bold(r)_(pi(1)), bold(r)_(pi(2)), dots.c, bold(r)_(pi(J)); |, |, , |)
  = mat(|, |, , |; bold(hat(r))_(1), bold(hat(r))_(2), dots.c, bold(hat(r))_(J); |, |, , |)
$

Likewise, we can re-order the time slots in decreasing order of their total resource demand.
This gives us the permuted time slot matrix $bold(hat(L)) = bold(P)^T bold(L)$.

$
  bold(hat(L)) = mat(|, |, , |; bold(l)_(pi(1)), bold(l)_(pi(2)), dots.c, bold(l)_(pi(T)); |, |, , |)
  = mat(|, |, , |; bold(hat(l))_(1), bold(hat(l))_(2), dots.c, bold(hat(l))_(T); |, |, , |)
$

This ordering gives higher priority to item types with a greater demand for scarce resources.
Item types are packed in non-increasing order of their priorities.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Resource weight sort", vstroke: .5pt + luma(200), inset: 0.3em, {
    import algorithmic: *
    Procedure("ResourceWeightSort", ($bold(R)$, $bold(L)$, $bold(alpha)$), {
      LineComment(Assign($bold(v)$, $bold(R)^T bold(alpha)$), "Compute weighted size of each item type")
      Comment($pi(q)" is index of "q"-th largest entry of "bold(v)$)
      Assign($pi$, $"SortIndicesDescending"(bold(v))$)
      LineComment(Assign($bold(P)$, $0$), $"Initialize a "(J,J)" zero matrix"$)
      For($1 <= q <= J$, {
        LineComment(Assign($bold(P)_(pi(q), q)$, $1$), $"Put "1" at row "pi(q)", column "q$)
      })
      LineComment(Assign($bold(hat(R))$, $bold(R) bold(P)$), $"Reorder item-type columns using "pi$)
      LineComment(Assign($bold(hat(L))$, $bold(P)^T bold(L)$), $"Apply the same permutation to "L$)
      Return(($bold(hat(R)), bold(hat(L))$))
    })
  })
])

The main loop is intentionally short because the repeated scoring logic has been extracted into two helper procedures.
Both helpers follow the same pattern.
Given an available capacity vector $bold(z)$, we compute

$
  q = min_(k: hat(r)_(j,k)>0) floor(z_k / hat(r)_(j,k)), quad
  n = min(q, eta), quad
  bold(u) = bold(z) - n bold(hat(r))_j
$

Only candidates with $q >= 1$ are feasible.
Note here that each $hat(r)_(j,k)$ is an element of the job-demand matrix $bold(hat(R))$ formed by permuting the columns of $bold(R)$.
The slack vector $bold(u)$ is the remaining capacity after placing as many items of type $j$ as possible, up to the current remaining count $eta$.
This scoring method is inspired by the L2 Norm-based Greedy heuristic described in @Panigrahy2011HeuristicsFV.

Let $i = tau_(t,b)$ be the bin type for each open bin $b$ and time slot $t$.
The available capacity vector $bold(z)$ is the remaining capacity

$
  bold(z) = bold(rho)_b = bold(m)_i - sum_(j'=1)^J y_(t,j',b) bold(hat(r))_(j')
$

and the helper procedure evaluates the key

$
  Phi_b = sum_(k=1)^K alpha_k u_k^2, quad
  k_b = (Phi_b, c^r_(tau_(t,b)), b)
$

Thus, feasible open bins are ranked first by weighted squared slack, then by the running cost of their type, and finally by bin index.
The helper $"SelectOpenBin"$ returns the feasible open bin $b^*$ with minimum key, together with the corresponding placement count $n_(b^*)$.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Select feasible open bin", vstroke: .5pt + luma(200), inset: 0.3em, {
    import algorithmic: *
    Procedure("SelectOpenBin", ($t, j, eta, B$), {
      For($b in B$, {
        LineComment(Assign($i$, $tau_(t,b)$), $"Bin type of bin "b$)
        LineComment(
          Assign($bold(rho)_b$, $bold(m)_i - sum_(j'=1)^J y_(t,j',b) bold(hat(r))_(j')$),
          "Compute remaining capacity of current bin",
        )
        LineComment(
          Assign($q_b$, $min_(k: hat(r)_(j,k)>0) floor(rho_(b,k)\/hat(r)_(j,k))$),
          "Num. of items which fit in bin",
        )
        If($q_b >= 1$, {
          LineComment(Assign($n_b$, $min(q_b, eta)$), $"Number of type "j "items to place in bin" b$)
          LineComment(
            Assign($Phi_b$, $sum_(k=1)^K alpha_k (rho_(b,k) - n_b hat(r)_(j,k))^2$),
            $"Compute weighted slack score for bin" b$,
          )
          LineComment(Assign($k_b$, $(Phi_b, c^r_i, b)$), "Use running cost and bin index for tie-break")
        })
      })
      IfElseChain(
        $exists b in B: q_b >= 1$,
        {
          LineComment(
            Assign($b^*$, $arg min_(b in B: q_b >= 1) k_b$),
            "Select feasible open bin with minimum slack score",
          )
          Return[$(b^*, n_(b^*))$]
        },
        {
          Return[$"none"$]
        },
      )
    })
  })])

If no open bin is feasible, we must open a new bin.
For new bin types, the available capacity vector is simply $bold(z) = bold(m)_i$, and the helper procedure evaluates

$
  Psi_i = sum_(k=1)^K alpha_k u_k^2 /c^p_i, quad
  k_i = (Psi_i, c^p_i + c^r_i, i)
$

That is, feasible new bin types are ranked by normalized slack, then by the marginal cost of opening the bin in the current slot, and finally by type index.
The helper $"SelectNewBinType"$ returns the feasible type $i^*$ with minimum key, together with the corresponding placement count $n_(i^*)$.
Here $c^p_i = bold(alpha)^T bold(m)_i$, so the normalization divides weighted squared slack by the weighted capacity of the bin type.
This gives us a measure of _"slack per unit of bin capacity"_, which favors bins which fit the required demand proportionally well, rather than simply selecting the bins with smaller overall remaining capacity.
Without this normalization, larger bins with greater raw capacity will be unfairly penalized, pushing the heuristic to instead selecting smaller-capacity bins.
This can in turn lead to item fragmentation and a overall inferior packing.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Select new bin type", vstroke: .5pt + luma(200), inset: 0.3em, {
    import algorithmic: *
    Procedure("SelectNewBinType", ($j, eta$), {
      For($1<=i<=M$, {
        LineComment(
          Assign($q_i$, $min_(k: hat(r)_(j,k)>0) floor(m_(i,k)\/hat(r)_(j,k))$),
          "Num. of items which fit in empty bin of type i",
        )
        If($q_i >= 1$, {
          LineComment(Assign($n_i$, $min(eta, q_i)$), $"Number of type "j "items to place in new bin"$)
          LineComment(
            Assign($Psi_i$, $sum_(k=1)^K alpha_k (m_(i,k) - n_i hat(r)_(j,k))^2 \/c^p_i$),
            $"Compute normalized slack score for bin type "i$,
          )
          LineComment(
            Assign($k_i$, $(Psi_i, c^p_i + c^r_i, i)$),
            "Use marginal cost and type index for tie-break",
          )
        })
      })
      IfElseChain(
        $exists i: q_i >= 1$,
        {
          LineComment(
            Assign($i^*$, $arg min_(i: q_i >= 1) k_i$),
            "Select feasible bin type with minimum cost-slack score",
          )
          Return[$(i^*, n_(i^*))$]
        },
        {
          Return[$"none"$]
        },
      )
    })
  })])

The main algorithm first calls $"SelectOpenBin"$.
If that returns $"none"$, then it calls $"SelectNewBinType"$.
If the second helper also returns $"none"$, the input is infeasible.
Otherwise, the algorithm opens one new bin of type $i^*$, increments $X_(i^*,t)$, assigns a new bin index $b$, stores $tau_(t,b)=i^*$, adds $b$ to the set $B$ of open bins for the current time slot, and packs $n_(i^*)$ items of type $j$ into this new bin.
For the generated datasets used in this thesis, this case does not occur because instance generation guarantees that every job type fits on at least one machine type.

The implementation also contains a degenerate guard for the case in which a job type has zero demand in every resource dimension.
In that case, all remaining items of the type are placed in the first open bin if one exists; otherwise a new bin of the cheapest type is opened.
This case does not occur in our generated datasets because generated demands are clamped to be at least $1$ in every dimension.

As with other previously discussed packing algorithms, this process is repeated for all $T$ time slots.
For each bin type $i$, we let $x_i = max_t X_(i,t)$ be the maximum number of bins of type $i$ used across all time slots.
Finally, we return the bin-type vector $bold(x)$ and the item-bin-time slot packing variable $y$.

Let $N$ be the total number of jobs to pack across all time slots and job types.
The _BFD_ algorithm has worst-case time complexity:
$
  Omicron(J K N^2 + M K N).
$

=== Resource-weighted cost-aware first-fit algorithm

We can now construct a new FFD-based packing algorithm by modifying the open-bin selection rule of the previous algorithm.
We will call this algorithm _"FFDNew"_.
This algorithm uses exactly the same resource-weighted job ordering and the same cost-aware $"SelectNewBinType"$ helper as _BFD_.
The algorithm has the same worst-case time complexity as the previous _BFD_ algorithm.
Thus, both algorithms open new bins according to the same normalized weighted slack score.
The only difference lies in how already open bins are selected.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("FFDNew packing algorithm", vstroke: .5pt + luma(200), inset: 0.3em, {
    import algorithmic: *
    Procedure(
      "FFDNewPackingAlgorithm",
      ($bold(C), bold(R), bold(L), bold(c^p), bold(c^r), bold(alpha)$),
      {
        LineComment(
          Assign($(bold(hat(R)),bold(hat(L)))$, $"ResourceWeightSort"(bold(R),bold(L),bold(alpha))$),
          "Sort items",
        )

        LineComment(Assign($X_(i,t)$, $0, quad forall i,t$), "Initialize bin-type matrix to zero")

        For($1<=t<=T$, {
          LineComment(Assign($B$, $emptyset$), "Initialize empty set of bins for time slot")
          For($1<=j<=J$, {
            LineComment(Assign($eta$, $hat(l)_(j,t)$), "Initialize remaining jobs counter")
            While($eta > 0$, {
              LineComment(
                Assign($p$, $"SelectFirstOpenBin"(t, j, eta, B)$),
                "Try feasible open bins in first-fit order",
              )
              IfElseChain(
                $p != "none"$,
                {
                  LineComment(Assign($(b^*, n^*)$, $p$), "Unpack helper result")
                  LineComment(Assign($eta$, $eta - n_(b^*)$), "Update packed jobs counter")
                  LineComment(
                    Assign($y_(t,j,b^*)$, $y_(t,j,b^*) + n_(b^*)$),
                    $"Pack" n_(b^*) "type" j "items into bin" b^*$,
                  )
                },
                {
                  LineComment(Assign($p$, $"SelectNewBinType"(j, eta)$), "No feasible open bin found")
                  IfElseChain(
                    $p != "none"$,
                    {
                      LineComment(Assign($(i^*, n^*)$, $p$), "Unpack helper result")
                      LineComment(Assign($eta$, $eta - n_(i^*)$), "Update packed jobs counter")
                      LineComment(Assign($X_(i^*,t)$, $X_(i^*,t) + 1$), $"Open new bin of type" i^*$)
                      LineComment(Assign($b$, $abs(B) + 1$), "Assign new bin index")
                      LineComment(Assign($tau_(t,b)$, $i^*$), $"Store type of new bin " b$)
                      LineComment(Assign($B$, $B union {b}$), "Add new bin to set of open bins")
                      LineComment(
                        Assign($y_(t,j,b)$, $y_(t,j,b) + n_(i^*)$),
                        $"Pack" n_(i^*) "type" j "items into bin" b$,
                      )
                    },
                    {
                      Return[$"infeasible input"$]
                    },
                  )
                },
              )
            })
          })
        })
        LineComment(Assign($bold(x)$, $max_t X_(i,t)$), "Take max machine type counts over time slots")
        Return[$bold(x)$, $y$]
      },
    )
  })])

For a current item type $j$ and time slot $t$, let the set of open bins again be denoted by $B$.
For each $b in B$, we compute the remaining capacity vector $bold(rho)_b$ and the feasible placement count $q_b$ exactly as in the _BFD_ algorithm.
However, rather than computing the slack score $Phi_b$ for every feasible open bin and selecting the one with minimum score, _FFDNew_ follows the first-fit rule.
That is, it scans the open bins in their current order, which in the algorithm is the order in which the bins were opened, and selects the first bin which satisfies $q_b >= 1$.
Equivalently, if the feasible set is non-empty, the selected bin is

$
  b^* = arg min_(b in B: q_b >= 1) b
$

and the algorithm places

$
  n_(b^*) = min(q_(b^*), eta)
$

items of type $j$ into that bin.
If no open bin is feasible, then _FFDNew_ behaves exactly like _BFD_ and calls $"SelectNewBinType"$ to open a new bin type.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Select first feasible open bin", vstroke: .5pt + luma(200), inset: 0.3em, {
    import algorithmic: *
    Procedure("SelectFirstOpenBin", ($t, j, eta, B$), {
      For($b in B$, {
        LineComment(Assign($i$, $tau_(t,b)$), $"Bin type of bin "b$)
        LineComment(
          Assign($bold(rho)_b$, $bold(m)_i - sum_(j'=1)^J y_(t,j',b) bold(hat(r))_(j')$),
          "Compute remaining capacity of current bin",
        )
        LineComment(
          Assign($q_b$, $min_(k: hat(r)_(j,k)>0) floor(rho_(b,k)\/hat(r)_(j,k))$),
          "Num. of items which fit in bin",
        )
        If($q_b >= 1$, {
          LineComment(Assign($n_b$, $min(q_b, eta)$), $"Number of type "j "items to place in bin" b$)
          Return[$(b, n_b)$]
        })
      })
      Return[$"none"$]
    })
  })])

This means that _FFDNew_ may be viewed as a hybrid algorithm.
It combines the more sophisticated ordering and new-bin selection logic of _BFD_ with the simpler first-fit rule for already open bins.
In this sense, it keeps the cost-aware mechanism for deciding _which kind_ of bin to open, while replacing the best-fit scoring of open bins with a deterministic left-to-right scan through the bins that are already open.

The algorithm applies this rule in a vectorized way when several jobs of the same type remain to be packed.
In effect, it fills earlier feasible bins before later ones, which is equivalent to repeatedly applying first fit to identical items of the current type.
As before, the algorithm is run independently for each time slot, and the final machine vector is obtained by taking $x_i = max_t X_(i,t)$ for each machine type $i$.
