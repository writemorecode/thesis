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

== Algorithm description

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

