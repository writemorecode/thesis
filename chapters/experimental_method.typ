#import "@preview/algorithmic:1.0.6"
#import algorithmic: algorithm-figure, style-algorithm

#pagebreak()

== Experimental Methodology <exp_method_section>

This chapter describes how problem instances are generated, and how datasets are generated from these problem instances.
We also describe how our method for evaluating these algorithms using these datasets.

=== Problem instance generation <problem_instance_generation>

In order to evaluate these algorithms, we use randomly generated problem instances.
Each problem instance is generated as follows.
The generation of problem instances is controlled by a set of configurable parameters.
The table below describes each of these parameters.

#block(breakable: false, [
  #figure(
    table(
      columns: 3,
      [*Parameter*], [*Purpose*], [*Default value*],
      [$c_0^"cpu"$], [Base CPU capacity value], [$20$],
      [$c_0^"memory"$], [Base memory capacity value], [$40$],
      [$c_0^"disk"$], [Base disk capacity value], [$100$],
      [$c_0^"io"$], [Base I/O capacity value], [$30$],
      [$d_0^"cpu"$], [Base CPU demand value], [$8$],
      [$d_0^"memory"$], [Base memory demand value], [$16$],
      [$d_0^"disk"$], [Base disk demand value], [$40$],
      [$d_0^"io"$], [Base I/O demand value], [$12$],
      [$lambda_0$], [Base job type count value], [$12$],
      [$[c_"min",c_"max"]$], [Random machine capacity jitter interval], [$(0.8,1.3)$],
      [$[d_"min",d_"max"]$], [Random job demand jitter interval], [$(0.8,1.3)$],
      [$[lambda_"min",lambda_"max"]$], [Random job type count jitter interval], [$(0.6,1.4)$],
      [$[u_"min",u_"max"]$], [Primary resource amplification interval], [$(2,4)$],
      [$[v_"min",v_"max"]$], [Job type count amplification interval], [$(5,8)$],
      [$rho^"machine"$], [Machine resource specialization ratio], [$0.7$],
      [$rho^"job"$], [Job resource specialization ratio], [$0.7$],
      [$rho^"slot"$], [Time slot specialization ratio], [$0.6$],
      [$eta^"machine"$], [Machine-job primary resource correlation factor], [$0.7$],
      [$eta^"slot"$], [Time slot-job primary resource correlation factor], [$0.7$],
    ),
    caption: [Table of parameters used for problem instance generation],
  ) <dataset_parameter_table>
])

We fix the set of resource types to CPU, memory, disk, and I/O, so $K=4$ throughout.
The goal of the generator is not only to produce random instances, but to produce instances with enough structure to make the placement decisions non-trivial.
If machine types, job types, and time slots were sampled almost uniformly and independently, then most instances would consist only of small perturbations of the same workload.
Such instances would understate the heterogeneity that motivates the algorithms studied in this thesis.
We therefore generate each problem instance in several stages, introducing randomness at every step while also allowing specialization and correlations between supply and demand.

==== Step 1: Initialize baseline capacities and demands

Each resource type $k$ has its own base machine capacity $c_(0,k)$ and base job demand $d_(0,k)$, collected in the vectors
$bold(c)_0=(c_0^"cpu", c_0^"memory", c_0^"disk", c_0^"io")$ and
$bold(d)_0=(d_0^"cpu", d_0^"memory", d_0^"disk", d_0^"io")$.
Each machine type resource capacity value $C_(i,k)$ is initialized according to the corresponding base capacity $c_(0,k)$.
Each job type resource demand value $R_(j,k)$ is initialized according to the corresponding base demand $d_(0,k)$.
Next, a moderate amount of variation is introduced to each element $C_(i,k)$ and $R_(j,k)$ with multiplicative jitter values sampled uniformly from the configurable ranges $[c_"min",c_"max"]$ and $[d_"min",d_"max"]$, respectively.
This gives every machine type and job type a common baseline while still allowing them to differ slightly already before any specialization is introduced.

$
  C_(i,k) arrow.l ceil(c_(0,k) U([c_"min", c_"max"])), quad
  R_(j,k) arrow.l ceil(d_(0,k) U([d_"min", d_"max"])), quad forall i,j,k.
$

At this stage, however, the resulting matrices are still relatively close to uniform.
The next stages introduce the stronger heterogeneity which is needed to obtain more realistic and informative instances.

==== Step 2: Assign primary resources

To avoid nearly uniform machine types, job types, and time slots, we introduce the notion of a _primary resource_.
A primary resource indicates that a machine type or job type is specialized with respect to one resource dimension.
For time slots, the same mechanism is used to indicate which class of job types should be more common in that slot.
This is the main mechanism by which the generator creates concentrated supply, concentrated demand, and temporal shifts in the workload.

Only a fraction of all machine types, job types, and time slots are assigned a primary resource.
This fraction is controlled by a configurable parameter $rho in [0,1]$.
Thus, for example, given $M$ different machine types, $ceil(rho M)$ machine types will be assigned a primary resource, while the remaining machine types retain no explicit specialization.

The primary resources of machine types, job types, and time slots are computed using @alg_choose_primary_resources, described below.
The function takes as arguments the number $n$ of elements to consider, the fraction $rho$ of elements to assign a primary resource to, and a probability vector $bold(q) in (0,1)^K$.
For each selected element, the resource index $k$ is chosen with probability $q_k$, for $1<=k<=K$.
If $bold(q)=bold(1)\/K$, then all resource indices are chosen with equal probability.
By adjusting the entries of $bold(q)$, we can instead make some resource types more likely than others.
Elements not selected for specialization keep the value $-1$ in the output vector, meaning that no primary resource was assigned.

#block(
  breakable: false,
  [
    #show: style-algorithm
    #algorithm-figure(
      "Choose primary resources",
      vstroke: .5pt + luma(200),
      {
        import algorithmic: *
        Procedure(
          "ChoosePrimaryResources",
          (
            $n$,
            $rho$,
            $bold(q)$,
          ),
          {
            Assign($s$, $ceil(n rho)$)
            Comment[Sample set $S$ of size $s$ from set ${1,dots.h,n}$ without replacement]
            Assign($S$, $"UniformWithoutReplacement"({1,dots.h,n}, s ; G)$)
            Comment[Let $bold(p)$ be $n$-dimensional vector initialized to value $-1$]
            Assign($bold(p)$, $mat(-1, dots.h, -1)$)
            For($i in S$, {
              Comment[Sample $p_i$ from set ${1,dots.h,K}$ with probabilities ${q_1,dots.h,q_K}$]
              Assign($p_i$, $"Categorical"({1,dots.h,K}, bold(q) ; G)$)
            })
            Return($bold(p)$)
          },
        )
      },
    ) <alg_choose_primary_resources> ],
)

==== Step 3: Correlate machine specialization with job specialization

We first use @alg_choose_primary_resources to assign primary resources to the job types.
At this stage, the probability vector is taken to be uniform, so no resource type is preferred a priori.
This yields a random workload profile for the current instance.

Next, we use the resulting job-type assignments to construct the probability vector used for the machine types.
Let $bold(u)$ be the $K$-dimensional uniform probability vector $bold(1)\/K$, and let $bold(h)$ be the histogram vector of the elements of $bold(p)^"job"$.
The element $h_k$ is the number of job types assigned resource $k$ as their primary resource.
If no job types were assigned a primary resource, then we fall back to the uniform vector $bold(u)$.
The machine-type probability vector is then defined as the weighted vector sum

$
  bold(q)^"machine" = eta^"machine" bold(h)/norm(bold(h)) + (1-eta^"machine") 1/K bold(1).
$

Here, $eta^"machine" in (0,1)$ is a configurable correlation parameter.
For larger values of $eta^"machine"$, the machine-type primary resources become more similar to the sampled job-type primary resources, while smaller values keep the machine types closer to a uniform mix.
We choose this construction because it introduces a controlled correlation between supply and demand.
If many job types are, for example, memory-heavy, then it is reasonable that memory-oriented machine types should also be more common, but not necessarily dominate completely.
The blend with the uniform vector preserves randomness and prevents the generated instances from becoming overly deterministic.

==== Step 4: Generate machine and job type matrices

Once the primary resources have been assigned, they are converted into concrete capacities and demands.
Let $u ~ sans("UniformInteger")([u_"min", u_"max"])$.
For each machine type $i$, if the machine type has been assigned primary resource $k^*$, then we set $C_(i,k^*)$ to $u dot max(1, ceil(C_(i,k^*)))$.
For each job type $j$, if the job type has been assigned primary resource $k^*$, then we set $R_(j,k^*)$ to $u dot max(1, ceil(R_(j,k^*)))$.
Note that $u$ is re-sampled for each amplified entry.
The configurable interval $[u_"min", u_"max"]$ therefore controls how strongly specialization affects the generated capacities and demands.

This amplification step is important because it turns the abstract notion of a primary resource into an actual numerical imbalance in $bold(C)$ and $bold(R)$.
Without it, the primary-resource assignments would have only a limited effect on the final instance.
After amplification, all entries are clamped to be at least $1$.
Finally, if some job type cannot be packed on any machine type, we add the missing capacity to one selected machine type, preferring a machine type with a matching primary resource whenever such a machine type exists.
This last correction ensures that the resulting instance is feasible while retaining the intended structure of specialized machine and job types.

The generation of $bold(C)$ and $bold(R)$ is handled by @alg_machine_job_types.

#block(
  breakable: false,
  [
    #show: style-algorithm
    #algorithm-figure(
      "Generate job and machine types",
      vstroke: .5pt + luma(200),
      inset: 0.3em,
      {
        import algorithmic: *
        Procedure(
          "GenerateJobAndMachineTypes",
          (),
          {
            LineComment(
              Assign($C_(i,k)$, $ceil(c_(0,k) dot U(c_"min", c_"max"))$),
              $"Initialize" bold(C) "with base capacity and jitter"$,
            )

            LineComment(
              Assign($R_(j,k)$, $ceil(d_(0,k) dot U(d_"min", d_"max"))$),
              $"Initialize" bold(R) "with base demand and jitter"$,
            )

            Comment[Amplify assigned primary resources for machine types]
            For($1<=i<=M$, {
              Comment[Check if machine type $i$ was assigned a primary resource]
              If($p^"machine"_i >= 0$, {
                LineComment(Assign($k^*$, $p^"machine"_i$), $"Let" k^* "be primary resource of machine type "i$)
                LineComment(Assign($u$, $cal(U)([u_"min", u_"max"])$), "Sample capacity amplification factor")
                LineComment(Assign($C_(i,k^*)$, $u dot C_(i,k^*)$), "Scale the capacity of primary resource")
              })
            })

            Comment[Amplify assigned primary resources for job types]
            For($1<=j<=J$, {
              Comment[Check if job type $j$ was assigned a primary resource]
              If($p^"job"_j >= 0$, {
                LineComment(Assign($k^*$, $p^"job"_j$), $"Let" k^* "be primary resource of job type "j$)
                LineComment(Assign($u$, $cal(U)([u_"min", u_"max"])$), "Sample demand amplification factor")
                LineComment(Assign($R_(j,k^*)$, $u dot R_(j,k^*)$), "Scale the demand of primary resource")
              })
            })

            LineComment(Assign($C_(i,k)$, $max(1, C_(i,k))$), $"Ensure all capacity values" >=1$)
            LineComment(Assign($R_(j,k)$, $max(1, R_(j,k))$), $"Ensure all demand values" >=1$)

            Comment[Ensure all job types can be packed]
            For($1<=j<=J$, {
              Comment[Check if no machine type can store job type $j$]
              If($exists.not i: bold(m)_i >= bold(r)_j$, {
                LineComment(
                  Assign($A$, ${i|p^"machine"_i=p^"job"_j}$),
                  $"Compute machine types with primary resource" pi$,
                )
                IfElseChain(
                  $p^"job"_j>=0 "and" A != emptyset$,
                  {
                    LineComment(
                      Assign($i$, $"Uniform"(A)$),
                      $"Sample machine type with primary resource" pi$,
                    )
                  },
                  {
                    Assign($i$, $arg max_m sum_k C_(m,k)$)
                  },
                )
                LineComment(Assign($bold(m)_i$, $bold(r)_j - bold(m)_i$), "Add deficit capacity to target machine type")
              })
            })

            Return($bold(C), bold(R)$)
          },
        )
      },
    ) <alg_machine_job_types>],
)

#pagebreak()

==== Step 5: Generate time-slot job counts

With the generation of the machine capacity matrix $bold(C)$ and the job demand matrix $bold(R)$ completed, we now move on to the job time slot matrix $bold(L)$.
The matrix $bold(L)$ determines how many jobs of each type are present in each time slot.
If these counts were generated independently from an almost uniform distribution, then the workload would exhibit little temporal structure.
We instead want some time slots to be dominated by related job types, in the same way that real workloads often contain bursts of similar activity.

The generation of $bold(L)$ is handled by the $sans("GenerateTimeSlots")$ function.
As for machine types, we first compute a probability vector from the histogram of job-type primary resources.
Let $bold(h)$ be the histogram of $bold(p)^"job"$ and let $bold(u)=bold(1)\/K$.
We then define

$
  bold(q)^"slot" = eta^"slot" bold(h)/norm(bold(h)) + (1-eta^"slot") bold(u).
$

Here, $eta^"slot"$ controls how strongly the time-slot specializations follow the sampled job-type specializations.
The primary resources for the time slots are then sampled from this distribution.
Thus, if a particular resource type is common among the job types, then some time slots also become more likely to emphasize jobs associated with that resource type.

For each time slot $t$, let $N_t$ be the total number of jobs in the slot.
The value $N_t$ is initialized from the base load $lambda_0$ and then multiplied by a jitter value $u$ sampled uniformly from the configurable interval $[lambda_"min", lambda_"max")$, after which it is clamped to an integer $>=1$.
Next, we sample a $J$-dimensional job-type weight vector $bold(w)$ from the interval $[0.5,1)$.
If time slot $t$ has primary resource $k^*$, then we compute the set $M$ of job types whose primary resource is also $k^*$.
For these matching job types, we sample a positive integer $v$ from the configurable interval $[v_"min", v_"max"]$ and multiply the corresponding weights $w_j$ by $v$.
After normalizing $bold(w)$ to obtain a probability vector $bold(pi)$, the job count vector $bold(l)_t$ is sampled from the distribution $sans("Multinomial")(N_t,bold(pi))$.

This two-stage construction allows the total load and the composition of that load to vary separately across time slots.
It therefore creates temporal concentration without removing the stochastic variation between instances.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Generate time slots", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure(
      "GenerateTimeSlots",
      (
        $K$,
        $J$,
        $T$,
        $lambda_0$,
        $(lambda_"min",lambda_"max")$,
        $rho^"slot"$,
        $eta$,
        $(v_"min", v_"max")$,
        $bold(p)^"job"$,
        $G$,
      ),
      {
        LineComment(Assign($bold(h)$, $"Histogram"(bold(p)^"job")$), "Compute histogram of job type primary resources")
        LineComment(Assign($bold(u)$, $bold(1)\/K$), $"Let "bold(u)" be uniform "K"-dim probability vector"$)
        LineComment(
          Assign($bold(q)^"slot"$, $eta bold(h)\/norm(bold(h))+(1-eta)bold(u)$),
          "Compute time slot primary job type probabilities",
        )
        Comment[Compute primary job types for time slots]
        Assign($p^"slot"$, $"COMPUTEPRIMARYRESOURCES"(T,K,rho^"slot", bold(q)^"slot",G)$)
        Assign($L_(j,t)$, $0$)
        For($1<=t<=T$, {
          LineComment(Assign($u$, $"Uniform"([lambda_"min", lambda_"max");G)$), "Sample jitter value")
          LineComment(Assign($N_t$, $max(1, ceil(lambda_0 u))$), "Multiply base load by jitter, clip")

          LineComment(Assign($bold(w)$, $"UniformVector"([0.5, 1), J ; G)$), "Sample job type weight vector")

          If($p^"slot"_t>=0$, {
            LineComment(Assign($k^*$, $p^"slot"_t$), $"Let" k^* "be primary job type for slot "t$)
            Comment[Compute set $M$ of job types with same primary resource as time slot $t$]
            Assign($M$, ${j | p^"job"_j = p^"slot"_t}$)
            If($M != emptyset$, {
              Comment[Sample a job type focus multiplier]
              Assign($v$, $"UniformInteger"([v_"min",v_"max"])$)
              For($i in M$, {
                Assign($w_i$, $w_i v$)
              })
            })
          })
          LineComment(Assign($bold(pi)$, $bold(w)\/norm(bold(w))$), "Normalize weight vector")
          Comment[Sample job type count vector for slot $t$ from multinomial distribution]
          LineComment(Assign($L_(dot,t)$, $"Multinomial"(N_t, bold(pi))$), "")
        })
      },
    )
  })])

==== Step 6: Compute machine costs

Lastly, we describe the algorithm used for computing the machine type purchase and running cost vectors $bold(c^p)$ and $bold(c^r)$.
This is handled by the $"COMPUTECOSTS"$ function.
The purpose of this step is to tie the cost model directly to the machine capacities rather than sampling costs independently.
In this way, larger or more capable machine types also become more expensive to purchase and to run, which gives the evaluation a consistent cost trade-off.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Compute costs", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure("COMPUTECOSTS", ($C$, $bold(alpha)$, $gamma$, $G$), {
      Assign($bold(c^p)$, $C^T bold(alpha)$)
      Assign($bold(c^r)$, $gamma bold(c^p)$)
      Return($bold(c^p), bold(c^r)$)
    })
  })])

==== Step 7: Generate a complete problem instance

We can now describe the full algorithm for generating a single problem instance.
This is handled by the $"GENERATEPROBLEMINSTANCE"$ function.
Presented in this order, the dependency structure becomes explicit.
The sampled job-type specializations influence the machine-type specializations, and together they influence the temporal distribution of jobs.
The final output is therefore random, but not unstructured.

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Generate problem instance", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure(
      "GenerateProblemInstance",
      (),
      {
        Assign($bold(u)$, $bold(1)\/K$)
        Assign(
          $bold(p)^"job"$,
          $"ChoosePrimaryResources"(J,
            rho^"job",bold(u),G)$,
        )
        Assign($bold(h)$, $"Histogram"(bold(p)^"job")$)
        Assign($bold(q)^"machine"$, $zeta bold(h)\/norm(bold(h)) + (1-zeta) u$)
        Assign(
          $bold(p)^"machine"$,
          $"ChoosePrimaryResources"(M,rho^"machine",bold(q)^"machine",G)$,
        )
        Assign(
          $(C,R)$,
          $"GenerateCapacitiesAndRequirements"()$,
        )

        Assign(
          $L$,
          $"GenerateTimeSlots"()$,
        )

        Assign(
          $(bold(c^p),bold(c^r))$,
          $"ComputeCosts"(
             // C,
            // bold(alpha),
            // gamma
          )$,
        )
        Return($C, R, L, bold(c^p), bold(c^r)$)
      },
    )
  })])

To illustrate the effect of the primary-resource mechanism, we show two pairs of $bold(C)$ and $bold(R)$ matrices generated with the same seed value, with and without the primary-resource logic.
The two matrices below were generated using the primary-resource logic.
The primary-resource values are shown in bold.

$
  C=mat(
    25, bold(42), 17, 22;
    19, 25, bold(85), bold(49);
    19, 21, 28, 21;
  ),
  R=mat(
    6, 9, 7, bold(26), 7;
    9, 9, bold(27), 7, 9;
    9, bold(28), 9, 10, bold(20);
  )
$

The two matrices below were generated from the same seed value, but without the primary-resource logic.
Compared with the first pair, they are visibly more uniform.
This is precisely the effect that the primary-resource mechanism is intended to avoid.

$
  C=mat(
    25, 21, 17, 22;
    19, 25, 21, 16;
    19, 21, 21, 21;
  ),
  R=mat(
    6, 9, 7, 9, 7;
    9, 9, 7, 7, 9;
    9, 9, 9, 10, 7;
  ) quad
$

=== Dataset generation

With the description of the method for generating a single problem instance completed, we now move on to describing how a dataset of multiple problem instances is generated.

Each generated problem instance samples its dimensions $J$, $M$, and $T$ uniformly from configurable intervals $I_J$, $I_M$, $I_T$, respectively.
The number of resource types is fixed to $K=4$ (CPU, memory, disk, I/O).

#block(breakable: false, [
  #show: style-algorithm
  #algorithm-figure("Generate dataset", vstroke: .5pt + luma(200), {
    import algorithmic: *
    Procedure(
      "GENERATEDATASET",
      (
        $N$,
        $I_J$,
        $I_M$,
        $I_T$,
        $"hyperparameters"$,
        $G$,
      ),
      {
        Assign($S$, $emptyset$)
        Assign($K$, $4$)
        For($1<=i<=N$, {
          Assign($J$, $"UniformInteger"(I_J; G)$)
          Assign($M$, $"UniformInteger"(I_M; G)$)
          Assign($T$, $"UniformInteger"(I_T; G)$)
          Assign($(C,R,L,T,bold(c)^p, bold(c)^r)$, $"GenerateRandomInstance"(K, J, M, T, G)$)
          Assign($S$, $S union {(C,R,L,T,bold(c)^p, bold(c)^r)}$)
        })
        Return($S$)
      },
    )
  })])

=== Datasets

We evaluate the algorithms on three different datasets.
For evaluation, we developed a simulator in Python using the NumPy library @python_simulator_repo_github.
Each dataset was generated using the NumPy deterministic pseudorandom number generator, using the fixed seed value $5000$.
Each dataset contains 100 randomly generated problem instances.

The first dataset ("balanced") was generated with a balanced number of job types and machine types.
The second dataset ("job heavy") was generated with a greater number of job types than machine types.
The third dataset ("machine heavy") was generated with a greater number of machine types than job types.

The table below presents the parameters used to generate each dataset.

#let all_datasets_csv_file = csv("../data/all_datasets.csv")
#table(
  columns: 9,
  [*$"Name"$*], [*$K_min$*], [*$K_max$*], [*$J_min$*], [*$J_max$*], [*$M_min$*], [*$M_max$*], [*$T_min$*], [*$T_max$*],
  ..all_datasets_csv_file.flatten(),
)

=== Evaluation method

==== Paired comparison via cost ratios <cost_ratios>

Each dataset contains the same set of problem instances evaluated by every algorithm.
Therefore, comparisons between two algorithms are based on *paired* observations.

Let $c_(A,i)$ and $c_(B,i)$ be the total costs of algorithms $A$ and $B$ on instance $i$, and define the per-instance cost ratio

$
  r_i = c_(A,i) / c_(B,i).
$

If $r_i < 1$, then $c_(A,i) < c_(B,i)$ and $A$ is better on instance $i$ (lower cost).

We use the ratios $r_i$ to describe relative performance, but for statistical testing we compare paired *differences* in raw total cost:
$
  d_i = c_(A,i) - c_(B,i).
$
We test whether the algorithms differ using a paired Wilcoxon signed-rank test on the values $d_i$:
$cal(H_0): med(d) = 0$ and $cal(H_1): med(d) != 0$, with $alpha = 0.05$.
From this test, we report the $W$ statistic, the two-sided $p$-value, and summary statistics (mean/median difference and the number of non-zero pairs).

Here, $med(d) < 0$ indicates that $A$ has lower cost than $B$ on average, and $med(d) > 0$ indicates the opposite.

In addition to the comparison of the two best algorithms, we also run paired Wilcoxon signed-rank tests between _BFD_ and each remaining algorithm (excluding _FFDNew_).

==== Dolan-Moré performance profiles

Another method of comparing the performance of different algorithms on a set of problem instances is to use _performance profiles_, presented in 2004 by Elizabeth Dolan and Jorge Moré @dolan_more_performance_profiles_2004.
This method works as follows.

Let $S$ be the set of solvers, or algorithms to evaluate.
Let $P$ be the set of problem instances.
Let $t_(p,s)$ be the cost of the solution for problem $p in P$ returned by solver $s in S$.
Let
$
  t^*_p = min_(s in S) t_(p,s)
$
be the cost of the best solution for problem $p$ across all solvers in $S$.
Let the _performance ratio_ for solver $s$ on problem $p$ be
$
  r_(p,s) = t_(p,s) / t^*_p
$
be the ratio between the solver's cost for the problem and the optimal cost for the problem.
The _performance profile_ for solver $s$ is defined as the function

$
  rho_s (tau) = 1/abs(P) abs({p in P | r_(p,s) <= tau}).
$

The performance profile function $rho_s (tau)$ for a solver $s$ can be interpreted as the percentage of problem instances for which a performance ratio $r_(p,s)$ is within $tau$ of the optimal ratio across all problem instances.
Specifically, $rho_s (1)$ gives the percentage of problem instances for which solver $s$ achieved the optimal performance ratio, which can be interpreted as the solver's _"win rate"_.

We will use this performance profiles method as a second step in the process of determining which of the algorithms performs best on each of the datasets.
