#import "@preview/fletcher:0.5.6" as fletcher: diagram, edge, node
#import "@preview/algorithmic:1.0.6"
#import algorithmic: algorithm-figure, style-algorithm

#let ZZnonneg = $ZZ_(>=0)$

= Method <method_section>

This chapter summarizes our research questions and the scheduling algorithms that are evaluated.

== Research questions

With this research, we aim to answer the following research questions:

RQ1: How can we create a cost-efficient offline multi-resource cloud job scheduler? \
RQ2: How can we create a cloud job scheduler which is optimized for both scheduling quality and execution time?

== Algorithms

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

Finally, we will now describe a packing algorithm based on the best-fit heuristic.
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
      [$bold(lambda)$], [Total resource load of a bin],
      [$bold(rho)$], [Remaining resource capacity of a bin],
      [$Phi_b$], [Slack score for bin $b$],
      [$y_(t,j,b)$], [Number of items of type $j$ in bin $b$ in time slot $t$],
      [$Psi_i$], [Slack score for bin type $i$],
    ),
    caption: [Symbol table for BFD and FFDNew algorithms.],
  )
])


We begin by presenting a pseudocode description of the algorithm.
Thereafter, we describe each step of the algorithm in greater detail.

#pagebreak()

#block(breakable: true, [
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
                  Assign($q_b$, $min_(k: hat(r)_(j,k)>0) floor(rho_k\/hat(r)_(j,k))$),
                  "Num. of items which fit in bin",
                )
                If($q_b >= 1$, {
                  LineComment(Assign($n_b$, $min(q_b, eta)$), $"Number of type "j "items to place in bin" b$)

                  LineComment(
                    Assign($bold(u)$, $bold(rho) - n_b bold(hat(r))_j$),
                    $"Slack of bin " b "with" n_b "type" j "items"$,
                  )

                  LineComment(
                    Assign($Phi_b$, $sum_(k=1)^K alpha_k u_k^2$),
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
                  LineComment(Assign($eta$, $eta - n_(b^*)$), "Update packed jobs counter")
                  LineComment(
                    Assign($y_(t,j,b^*)$, $y_(t,j,b^*) + n_(b^*)$),
                    $"Pack" n_(b^*) "type" j "items into bin" b^*$,
                  )
                },
                {
                  For($1<=i<=M$, {
                    LineComment(
                      Assign($q_i$, $min_(k: hat(r)_(j,k)>0) floor(m_(i,k)\/hat(r)_(j,k))$),
                      "Num. of items which fit in empty bin of type i",
                    )
                    If($q_i >= 1$, {
                      LineComment(Assign($n_i$, $min(eta, q_i)$), $"Number of type "j "items to place in new bin"$)

                      LineComment(
                        Assign($bold(u)$, $bold(m)_i - n_i bold(hat(r))_j$),
                        $"Slack of bin type" i "with" n_i "type" j "items"$,
                      )

                      LineComment(
                        Assign($Psi_i$, $sum_(k=1)^K alpha_k u_k^2 \/c^p_i$),
                        $"Compute slack score for bin type "i$,
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
For each time slot $t$, the Python implementation starts with an empty set of open bins and packs the jobs of that time slot independently.
The algorithm uses the resource weight vector $bold(alpha)$ to compute the item size vector $bold(v)=bold(R)^T bold(alpha)$, where each item type $j$ has scalar size $v_j$.
This ordering gives higher priority to item types with a greater demand for scarce resources.
Item types are packed in non-increasing order of their priorities.

For each unpacked item type $j$ with remaining count $eta$ and demand vector $bold(r)_j$, we first evaluate the currently open bins.
For each open bin $b$, let $bold(rho)$ be the bin's remaining capacity vector.
We compute the maximum number $q_b$ of items of type $j$ which can be added to the bin.

$
  q_b = min_(k: hat(r)_(j,k)>0) floor(rho_(k)/hat(r)_(j,k))
$

Note here that each $hat(r)_(j,k)$ is an element of the job-demand matrix $bold(hat(R))$ formed by permuting the columns of $bold(R)$.
Only bins with $q_b >= 1$ are feasible.
If at least one feasible open bin exists, then for each such bin $b$ we compute $n_b=min(q_b, eta)$.
Next, we compute the remaining capacity (slack) $bold(u)=bold(rho) - n_b bold(hat(r))_j$ of bin $b$ after storing $n_b$ items of type $j$.
This is inspired by the L2 Norm-based Greedy heuristic, described in @Panigrahy2011HeuristicsFV.
Next, we compute a score $Phi_b$ representing the quality of the fit of the current item in bin $b$.

$
  Phi_b = sum_(k=1)^K alpha_k u_k^2
$

The implementation then compares feasible open bins using the lexicographic key

$
  k_b = (Phi_b, c^r_(tau_(t,b)), b)
$

that is, weighted squared slack first, then running cost of the bin type, and finally the bin index.
We select the feasible open bin $b^*$ with minimum key $k_(b^*)$.
Finally, we pack $n_(b^*)$ items of type $j$ into bin $b^*$, by incrementing $y_(t,j,b^*)$ by $n_(b^*)$.
We decrement the number of remaining unpacked items by $n_(b^*)$.

If no open bin is feasible, we must open a new bin.
As before, we use a score-based method for selecting the bin type.
For each bin type $i$ with sufficient capacity, we compute the maximum number $q_i$ of items of type $j$ which can be stored in an empty bin of type $i$.

$
  q_i = min_(k: hat(r)_(j,k)>0) floor(m_(i,k)/hat(r)_(j,k))
$

Only machine types with $q_i >= 1$ are feasible.
For each feasible machine type $i$, we compute $n_i=min(eta, q_i)$.
Next, we compute the remaining capacity (slack) vector $bold(u) = bold(m)_i - n_i bold(hat(r))_j$ of bin type $i$ after storing $n_i$ items of type $j$.
Next, we compute a bin selection score $Psi_i$ to use for selecting the optimal bin type to open.

$
  Psi_i = sum_(k=1)^K alpha_k u_(k)^2 /c^p_i
$

The Python implementation compares feasible new bin types using the lexicographic key

$
  k_i = (Psi_i, c^p_i + c^r_i, i)
$

that is, normalized slack first, then the marginal cost of opening that bin type in the current slot, and finally the type index.
Thus we select the feasible bin type $i^*$ with minimum key $k_(i^*)$.
The score $Psi_i$ is nearly identical to the previous $Phi_b$, except for the normalization factor $c^p_i$.
Recall that $c^p_i = bold(alpha)^T bold(m)_i$, so the implementation is normalizing by the weighted capacity of bin type $i$.
By dividing $u_k^2$, the squared slack in dimension $k$, by $c^p_i$, we are normalizing the slack by the bin size.
This gives us a measure of _"slack per unit of bin capacity"_, which favors bins which fit the required demand proportionally well, rather than simply selecting the bins with smaller overall remaining capacity.
Without this normalization, larger bins with greater raw capacity will be unfairly penalized, pushing the heuristic to instead selecting smaller-capacity bins.
This can in turn lead to item fragmentation and a overall inferior packing.

We then open one new bin of type $i^*$, increment $X_(i^*,t)$, assign a new bin index $b$, store $tau_(t,b)=i^*$, and add $b$ to the set $B$ of open bins for the current time slot.
Finally, we pack $n_(i^*)$ items of type $j$ into this new bin, by incrementing $y_(t,j,b)$ by $n_(i^*)$.
We decrement the number of remaining unpacked items by $n_(i^*)$.
If no feasible machine type exists, the Python implementation raises an error.
For the generated datasets used in this thesis, this case does not occur because instance generation guarantees that every job type fits on at least one machine type.

The implementation also contains a degenerate guard for the case in which a job type has zero demand in every resource dimension.
In that case, all remaining items of the type are placed in the first open bin if one exists; otherwise a new bin of the cheapest type is opened.
This case does not occur in our generated datasets because generated demands are clamped to be at least $1$ in every dimension.

As with other previously discussed packing algorithms, this process is repeated for all $T$ time slots.
For each bin type $i$, we let $x_i = max_t X_(i,t)$ be the maximum number of bins of type $i$ used across all time slots.
Finally, we return the bin-type vector $bold(x)$ and the item-bin-time slot packing variable $y$.

We can create a new FFD-based packing algorithm based on this algorithm.
We will call this algorithm _"FFDNew"_.
The algorithm will use the same job-ordering and new bin selection methods as this algorithm.
However, like first fit, it will place items in the first bin which accommodate it.

