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
Each resource type $k$ has its own base machine capacity $c_(0,k)$ and base job demand $d_(0,k)$, collected in the vectors
$bold(c)_0=(c_0^"cpu", c_0^"memory", c_0^"disk", c_0^"io")$ and
$bold(d)_0=(d_0^"cpu", d_0^"memory", d_0^"disk", d_0^"io")$.
Each machine type resource capacity value $C_(i,k)$ is initialized according to the corresponding base capacity $c_(0,k)$.
Each job type resource demand value $R_(j,k)$ is initialized according to the corresponding base demand $d_(0,k)$.
Next, some variation is introduced to each element $C_(i,k)$ and $R_(j,k)$ with multiplicative jitter values sampled uniformly from the configurable ranges $[c_"min",c_"max"]$ and $[d_"min",d_"max"]$, respectively.

$
  C_(i,k) arrow.l ceil(c_(0,k) U([c_"min", c_"max"])), quad
  R_(j,k) arrow.l ceil(d_(0,k) U([d_"min", d_"max"])), quad forall i,j,k.
$

In order to generate more realistic problem instances, we want to avoid having nearly uniform machine types, job types, and time slots.
Instead, we want a fraction of all machine types, job types, and time slots to have a greater number of certain resource capacities, resource demands, and job types, respectively.
For example, certain machine types may be optimized, or specialized, for certain kinds of workloads.
These special machine types will have a larger amount of a certain resource type, such as memory, disk, etc.
This will make these machine types better suited to running job types with above average demands for these resource types.
This is also true for job time slots.
Above average numbers of certain job types may be scheduled to run during certain time slots.

Each machine type, job type, and time slot may be assigned a primary resource or job type.
The number of them which are assigned a primary resource is controlled by a configurable parameter $rho in [0,1]$.
This means that, for example, given $M$ different machine types, $ceil(rho M)$ machine types will be assigned a primary resource.

The primary resources of a machine type, job type, or time slot are computed using @alg_choose_primary_resources, described below.
The function takes as arguments the number $n$ of primary resources to compute, the number of resources $K$,
the fraction $rho$ of resources to assign a primary resource to, and a probability vector $bold(q) in (0,1)^K$.
For each of the machine types, job types, or time slots assigned a primary resource, the resource index $k$ will be chosen with probability $q_k$, for $1<=k<=K$.
By setting each element $q_k$ of $bold(q)$ to $1\/K$, each primary resource index $k$ will be chosen with equal probability.
The values $q_k$ can instead be adjusted to increase or decrease the probability of resource $k$ being assigned to primary resources.
This will be used later in order to make the machine types have similar primary resources as the job types.
This means that, for example, if there are many job types with memory as a primary resource, then there should also be many machine types with memory as a primary resource.

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

Now that we have described how the primary resources are computed, we move on to describing how they are used in practice.
Let $u ~ sans("UniformInteger")([u_"min", u_"max"])$.
For each machine type $i$, if the machine type has been assigned primary resource $k^*$, then we set $C_(i,k^*)$ to $u dot max(1, ceil(C_(i,k^*)))$.
For each job type $j$, if the job type has been assigned primary resource $k^*$, then we set $R_(j,k^*)$ to $u dot max(1, ceil(R_(j,k^*)))$.
Note that $u$ is re-sampled for each element $C_(i,k)$ and $R_(j,k)$.
Here, it is the configurable interval $[u_"min", u_"max"]$ which controls how much primary resource values shall be increased.

Next, we want to use the vector $bold(p)^"machine"$ returned by @alg_choose_primary_resources for
computing a probability vector $bold(q)^"job"$ to use for computing the primary resources for the job types.
To do this, we begin by letting the vector $bold(u)$ be the $K$-dimensional uniform probability vector $bold(1)\/K$, where $bold(1)$ is the all-ones vector.
Next, we compute a histogram vector $bold(h)$ of the elements of $bold(p)^"machine"$.
The histogram vector $bold(h)$ will have dimension $k$, and each element $h_k$ will be equal to the number of machine types which were assigned resource $k$ as a primary resource.
If no primary resources were assigned, then we set $bold(h)$ equal to $bold(u)$.
Finally, we can compute the probability vector $bold(q)^"job"$ as a weighted vector sum between the normalized histogram vector $bold(h)$ and the vector $bold(u)$.

$
  bold(q)^"job" = eta bold(h)/norm(bold(h)) + (1-eta) 1/K bold(1)
$

Here, $eta in (0,1)$ is a configurable correlation parameter.
For larger values of $eta$, $bold(q)^"job"$ will be more similar to the histogram vector $bold(h)$, and vice versa.
In other words, larger values of $eta$ increase the correlation between the primary resources of the machine and job types.
This means that, for example, if many job types were assigned CPU as a primary resource, then $eta$ will control how many machine types are assigned CPU as a primary resource.
With the vector $bold(q)^"job"$ computed, we can now compute the primary resources for the machine types.

The next step is to compute the machine capacity matrix $bold(C)$.
This is handled by @alg_machine_job_types.

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

desc here

With the description of the generation of the machine capacity matrix $bold(C)$ and job demand matrix $bold(R)$ completed, we now move on to description of the job time slot matrix $bold(L)$.
The $bold(L)$ matrix generation is handled by the $sans("GenerateJobCounts")$ function.
The function works as follows.

For each time slot, the job count matrix generation aims to select job types which have been assigned some primary resource.
Previously, the primary resource capacities of the machine types were selected with respect to the primary resource demands of the job types.
If some subset of the job types were each assigned some primary resource demand, then the machine types must be assigned matching resource capacities.
For example, memory-intensive job types are best assigned to memory-optimized machine types.
In this function, for a subset of all time slots, we select a primary resource $k^*$, where $0<=k^*<K$.
For each time slot in this subset, we increase the number of jobs which also have primary resource $k^*$.

For each time slot $t$, $N_t$ is the total time slot job count, across all job types.
$N_t$ is initialized with a base load value $lambda_0$.
Next, some jitter is applied to $N_t$ by multiplying it by a jitter value $u$ sampled uniformly from a configurable interval $[lambda_"min", lambda_"max")$, after which $N_t$ is clamped to an integer $>=1$.
After this, we uniformly sample a $J$-dimensional job type weight vector $bold(w)$ from the interval $[0.5,1)$.
This vector will later be used to decide the number of each job type to select for time slot $t$.
Next, we compute a set $M$ of each job type $j$ assigned the same primary resource $k^*$ as time slot $t$.
For each of these matching job types, we sample a positive integer $v$ from the configurable interval $[v_"min", v_"max"]$.
Then, the weight vector element $w_j$ is multiplied by $v$.

Once we have completed this step for all time slots, we let $bold(pi)$ be the normalized $bold(w)$ vector.
Finally, we compute the job count vector $bold(l)_t$ for time slot $t$.
This is done by sampling the vector from the $sans("Multinomial")(N_t,bold(pi))$ distribution.

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

Lastly, we will again describe the algorithm used for computing the machine type purchase and running cost vectors $bold(c^p)$ and $bold(c^r)$.
This is handled by the $"COMPUTECOSTS"$ function.

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

Finally, we can describe the full algorithm for generating a single problem instance.
This is handled by the $"GENERATEPROBLEMINSTANCE"$ function.

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

We will now show two $bold(C)$ and $bold(R)$ matrices generated with the same seed value, with and without the primary resource logic.
The two matrices below were generated using the primary resource logic.
The primary resource values are in bold.

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

The two matrices here below were generated from the same seed value, but without the primary resource logic.

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
