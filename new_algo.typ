#import "@preview/fletcher:0.5.6" as fletcher: diagram, edge, node
#import "@preview/algorithmic:1.0.6"
#import algorithmic: algorithm-figure, style-algorithm

= Algorithm pseudocode

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Packing algorithm", vstroke: .5pt + luma(200), inset: 0.3em, {
    import algorithmic: *
    Procedure(
      "PackingAlgorithm",
      ($bold(C), bold(R), bold(L), bold(c^p), bold(c^r), bold(alpha)$),
      {
        LineComment(Assign($bold(v)$, $bold(R)^T bold(alpha)$), "Compute weighted size of each item type")
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
        LineComment(Assign($X_(m,t)$, $0, quad forall m,t$), "Initialize bin-type matrix to zero")

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
                  LineComment(Assign($m$, $arg min_i k_i$), "Select bin type with minimum cost-slack score")
                  LineComment(Assign($eta$, $eta - n_m$), "Update packed jobs counter")
                  LineComment(Assign($b$, $x_(m)$), $"Number of open bins of type" m$)
                  LineComment(Assign($X_(m,t)$, $X_(m,t) + 1$), $"Open new bin of type" b^*$)
                  LineComment(
                    Assign($y_(t,j,b)$, $y_(t,j,b) + n$),
                    $"Pack" n_(b^*) "type" j "items into bin" b^*$,
                  )
                },
              )
            })
          })
          LineComment(Assign($bold(x)$, $max_t X_(m,t)$), "Take max machine type counts over time slots")
        })
        Return[$bold(x)$, $y$]
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




