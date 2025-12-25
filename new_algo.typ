#import "@preview/fletcher:0.5.6" as fletcher: diagram, edge, node
#import "@preview/algorithmic:1.0.6"
#import algorithmic: algorithm-figure, style-algorithm

= Algorithm pseudocode

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Packing algorithm", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure(
      "PackingAlgorithm",
      ($bold(C), bold(R), bold(L), bold(c^p), bold(c^r), bold(alpha)$),
      {
        LineComment(Assign($bold(s)$, $bold(R)^T bold(alpha)$), "Compute weighted size of each item type")
        LineComment(Assign($bold(w)$, $bold(C)^T bold(alpha)$), "Compute weighted capacity of each bin type")

        //Assign($bold(v)$, $"SortIndicesDescending"(bold(s))$)
        //Assign($bold(hat(R))$, $"Permute"(bold(R), bold(v))$)

        LineComment(
          Assign(
            $bold(P)$,
            $"diag"(bold(e)_(v_1),dots.h,bold(e)_(v_J))$,
          ),
          "Compute permutation matrix",
        )

        LineComment(
          Assign($bold(hat(R))$, $bold(R) bold(P)$),
          "Permute job type column vectors in order of weighted size",
        )

        LineComment(
          Assign($bold(hat(L))$, $bold(P)^T bold(L)$),
          "Permute time slot column vectors",
        )

        LineComment(Assign($B$, $emptyset$), "Initialize empty set of bins")
        LineComment(Assign($bold(x)$, $bold(0)$), "Initialize bin-type vector to zero")

        For($1<=t<=T$, {
          For($1<=j<=J$, {
            LineComment(Assign($eta$, $0$), "Initialize packed jobs counter")
            While($eta < hat(l)_(j,t)$, {
              IfElseChain(
                $B != emptyset$,
                {
                  For($b in B$, {
                    LineComment(Assign($i$, $"BinType"(b)$), $"Let" i_b "be the bin type of bin" b$)
                    LineComment(
                      Assign($bold(lambda)$, $sum_(bold(nu) in b) bold(nu)$),
                      "Compute total load of items in current bin",
                    )
                    LineComment(
                      Assign($bold(rho)_b$, $bold(m)_i-bold(lambda)$),
                      "Compute remaining capacity of current bin",
                    )
                    LineComment(
                      Assign($m_b$, $min_(k: hat(r)_k>0) floor(rho_(b,k)\/hat(r)_(j,k))$),
                      $"Number of type "j" items which fit in bin" b$,
                    )
                    LineComment(Assign($n_b$, $max(m_b, hat(l)_(t,j))$), $"Number of type "j" items to place in bin" b$)

                    LineComment(
                      Assign($Phi_b$, $sum_(k=1)^K alpha_k (rho_(b,k) - n_b hat(r)_(j,k))^2$),
                      $"Compute weighted slack score for bin" b$,
                    )
                  })
                  Comment[TODO: Add logic for tie-breaking with opening cost and bin index]
                  LineComment(Assign($b^*$, $arg min_b Phi_b$), "Select bin type with minimum slack score")
                  LineComment(Assign($eta$, $eta + n_(b^*)$), "Update packed jobs counter")
                  For($1<=i<=n_(b^*)$, {
                    LineComment(Assign($b$, $b union {bold(hat(r))_j}$), $"Pack" n_(b^*) "type" j "items into bin" b^*$)
                  })
                },
                {
                  Comment[Open a new bin to store the item]
                  For($1<=i<=M$, {
                    LineComment(
                      Assign($q_i$, $min_(k: hat(r)_k>0) floor(m_(i,k)\/hat(r)_(j,k))$),
                      $"Num. of type" j "items which fit in bin type" i$,
                    )

                    LineComment(
                      Assign($bold(u)_i$, $bold(m)_i - q_i bold(r)_j$),
                      $"Slack of bin type" i "with" q_i "type" j "items"$,
                    )

                    LineComment(
                      Assign($Psi_i$, $c^r_i\/w_i + sum_(k=1)^K alpha_k u_(i,k)^2 \/w_i$),
                      $"Compute cost-slack score for bin type "i$,
                    )
                  })
                  LineComment(Assign($i^*$, $arg min_i Psi_i$), "Select bin type with minimum cost-slack score")
                  LineComment(Assign($x_(i^*)$, $x_(i^*) + 1$), $"Open new bin of type" b^*$)
                  LineComment(Assign($n_(i^*)$, $max(q_(i^*), hat(l)_(j,t))$), "")
                  LineComment(Assign($eta$, $eta + q_(i^*)$), "Update packed jobs counter")
                },
              )
            })
          })
        })
      },
    )
  })])

== Algorithm description

The algorithm uses a weighted best-fit heuristic, with demand-aware job type ordering and cost-aware bin type selection.
The algorithm uses the resource weight vector $bold(alpha)$ to compute a weighted size $s_j$ for each item type $j$.
This ordering gives higher priority to item types with a greater demand for scarce resources.
Item types are packed in non-increasing order of their priorities.

For each unpacked item $bold(r)_j$, we first check if there are any open bins with sufficient capacity.
If there are any such bins open, then we select the best bin to store the item.
The open bin selection works as follows.
For each open bin $b$, let $bold(rho)_b$ be the bin's remaining capacity vector.
We compute the maximum number $m_b$ of items of type $j$ which can be added to the bin.

$
  m_b = min_(k: hat(r)_k>0) floor(rho_(b,k)/hat(r)_(j,k))
$

For each bin $b$ with $m_b >= 1$, we compute $x_b=min(m_b, l_(j,t))$.
Next, we compute a score $Phi_b$ representing the quality of the fit of the current item $bold(r)_j$ in bin $b$.

$
  Phi_b = sum_(k=1)^K alpha_k (rho_(b,k) - n_b hat(r)_(j,k))^2
$

We select the open bin $b^*$ with minimum slack score $Phi_(b^*)$.
In case of a tie, we first select the bin with the lowest opening cost, and second the bin with the lowest index.

In the case where there are no open bins with sufficient capacity, we must open a new bin.
Here, we use a similar score-based method for selecting the optimal bin type.
For each bin type $i$ with sufficient capacity, we compute the maximum number $m_i$ of items of type $j$ which can be stored in an empty bin of type $i$.

$
  q_i = min_(k: hat(r)_k>0) floor(m_(i,k)/hat(r)_(j,k))
$

Next, we compute the remaining capacity vector $bold(u)_i = bold(m)_i - q_i bold(r)_j$ of bin type $i$ after storing $q_i$ items of type $j$.

Next, we compute a bin selection score $Psi_i$ to use for selecting the optimal bin type to open.

$
  Psi_i = c^r_i/w_i + sum_(k=1)^K alpha_k u_(i,k)^2 /w_i
$




