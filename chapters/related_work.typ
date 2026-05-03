= Related Work <chp-relatedwork>

This chapter surveys prior research on energy-aware scheduling and multidimensional bin-packing, and positions this thesis within that landscape.

== Job-scheduling

In 2012, Beloglazov et al. @beloglazov_energy-aware_2012 proposed energy-aware VM allocation heuristics for provisioning physical machines while satisfying service-level agreements (SLAs).
These SLAs were related to metrics such as total data center energy consumption, overloaded physical machines, the number of VM migrations, and the unmet resource demands from VMs.
The authors presented heuristics for both placement of VMs and migration of VMs between physical machines.
The authors used the CloudSim toolkit @cloudsim_2011 for evaluating their heuristics.
One of the heuristics presented by the authors resulted in significantly lower number of VM migrations and SLA violations.
The results showed that dynamic migration of VMs between physical machines resulted a substantial reduction in total data center energy consumption.
The authors also discussed a number of open challenges in the field of energy-efficient data centers.
Among these was the optimization of VM placement according to utilization of multiple system resources.

In 2016, Mosa and Paton @mosa_paton_2016 presented similar work, applying genetic algorithm to the problem of finding an optimal VM placement strategy minimizing costs of both energy and SLA violations.
The genetic algorithms are used to find a VM placement with maximum utility.
The utility of a VM placement during a time period is defined by the authors as its future financial return after total costs over that period.
Here, the cost of a VM placement is defined as the sum of costs from energy, SLA violations, and performance degradation from VM overallocation.
The authors' proposed solution was evaluated using the CloudSim simulator, and compared to a heuristics-based solution presented by Beloglazov et al. @beloglazov_energy-aware_2012.
Evaluation results showed that the proposed solution outperformed other existing heuristics-based solution, in terms of energy savings and SLA violations.

In 2015, Mann @mann_allocation_2015 presented a survey article on the subject of virtual machine allocation in cloud data centers.
The survey considered different problem models and optimization algorithms.
The same year, Mann presented another article discussing how well the VM allocation problem could be approximated as a bin-packing problem @mann_approximability_2015.
Mann discussed various cases of the problem, such as multi-dimensionality, VM migration, heterogeneous physical machines, etc.
The author found that the VM allocation problem is in many cases more complex than the bin-packing problem.

In 2010, Speitkamp and Bichler @speitkamp_bichler_2010 described a server consolidation problem.
The authors presented an LP-based formulation of the problem, and a solution using a heuristic based on LP-relaxation.
They also showed that the problem is strongly NP-hard, by reducing the problem to the multidimensional bin-packing problem (MDBP).
Evaluation on real-world data showed that the authors' solution could result in up to 31\% of hardware resource savings.

In 2012, Setzer and Wolke @setzer_wolke_2018 formulated a mathematical model for scheduling virtual machines in data centers.
This model, which had the form of an integer program, was optimized for minimizing the number of powered-on physical machines over time, while also attempting to minimize the overhead from virtual machine migration between physical machines.
Numerical experiments on real-world workload traces showed that nearly 50\% of operational server hours could be saved using this model.
However, since solving integer programs is an NP-complete problems, this model could only be used for smaller problem instances.

In 2013, Ghribi et al. @ghribi_hadji_djamal_2013 presented an algorithm for energy-efficient cloud VM scheduling.
This algorithm decomposed the scheduling problem into sub-problems of allocation and migration.
The authors presented a separate algorithm for each of these sub-problems.
The first algorithm handled VM allocation and was based on a bin-packing algorithm with a minimum power consumption objective.
Specifically, this algorithm used the best-fit heuristic for bin-packing.
The second algorithm VM migration and consolidation, and was based on solving an integer linear problem (ILP).
The authors found that their proposed algorithm could achieve significant energy savings at low resource load, and lower savings at higher load.

In 2018, Lei et al. @liu_li_li_2018 presented, analyzed, and benchmarked a randomized approximation algorithm for solving the minimal cost job-server configuration problem.
This problem involves finding a heterogeneous set of servers with minimal cost such that for a given set of time slots, the resources of the servers can meet the total resource demand of the workloads in the time slot.
This is an NP-hard problem, since it can be reduced to the multidimensional knapsack problem (MKP).
The authors solve the problem with a randomized rounding algorithm.

In 2010, Khuller et al. @khuller_scheduling_energy_partial_shutdown studied job scheduling problems with machine activation costs.
In this case, a subset of all available machines must be selected for use, and each machine type has a cost for selecting it.
This machine activation cost shall not be confused with a machine purchase cost.
Later in 2011, Khuller et al. @khuller_gma presented a generalization of their previous work.

In 2015, Gabay and Zaourar @gabay_vector_2016 introduced a generalization for the vector bin-packing problem for variable-sized bins.
The authors propose a number of greedy heuristics for the problem.
They describe the machine reassignment problem, which involves assigning or re-assigning a set of processes to a set of machines while minimizing total cost of the new assignments.
Next, the authors show how their proposed heuristics can be used to solve this problem.
Finally, the authors' solutions to the variable-sized vector bin-packing problem and the machine reassignment problem are evaluated on a randomly generated and a real-world benchmark, respectively.
For further work on the machine reassignment problem, see @mrp_multineighborhood_local_search.

== Bin-packing

In 1972, Garey, Graham, and Ullman analyzed the worst-case performance of heuristics-based methods for bin-packing @garey_worst_mem_alloc.
The authors viewed these algorithms from a more practical point of view, as algorithms for memory allocation.

David Johnson was first to study approximation algorithms for the bin-packing problem, in his 1973 Ph.D. thesis @johnson_1973_phd.
He presented bounds for both the First-Fit and Best-fit algorithms.

In 1976, Garey, Graham, Johnson, and Yao studied bin-packing applied to the problem of job scheduling with precedence constraints @Garey1976ResourceCS.
With precedence constraints, certain jobs may need to be scheduled before others.

In 2004, Chekuri and Khanna studied approximation algorithms for multidimensional versions of classic packing problems, including the bin-packing problem @chekuri_multidim_packing.

In 2025, Mommessin, Erlebach, Sahkhlevich studied the vector bin packing problem (VBP) with homogeneous bins @MOMMESSIN2025106860.
The authors present a systematic classification of heuristics for the problem.
Existing VBP algorithms are combined, and new algorithms are proposed.

In 2021, Stakić et al. @stakic2021reduced presented a solution to the two-dimensional heterogeneous vector bin-packing problem (2DHet-VBPP).
This solution to this NP-hard problem used a metaheuristic approach based on Reduced variable neighborhood search (RVNS).
RVNS is based on the variable neighborhood search method, which was proposed by in 2010 by Hansen et al. @Hansen_vns_2010.
In general, these kinds of solutions work in three phases.
First, we generate an initial solution $S_0$, and let the current solution $S$ and best solution $S^*$ be $S_0$.
Next, we apply a shaking operator to $S$ to attempt to move $S$ to a different neighborhood of the solution space.
This gives us a new shaken solution $S'$.
Next, we run a local search procedure to find the local optimal solution in the new neighborhood of $S'$.
This gives us a new solution $S''$.
Finally, we decide if $S''$ is a better solution than the current best solution $S^*$.
If so, we set $S^*$ to $S''$.
This process then continues for some number of iterations.

In 2011, Hemmelmayr, Schmid and Blum @hemmelmayr_variable_2012 presented a similar to the variable-sized bin-packing problem, also based on the variable-sized neighhborhood search method.
This work was similar to the Stakić's later work @stakic2021reduced, but for the one-dimensional variable-sized case.
The authors' solution made use of multiple different shaking operators for moving between different neighborhoods of the solution space.
The solution also used multiple different local search methods for searching for local optima in a given neighborhood.


== Research gap

Previous work in this area have focused on solving job scheduling problems where the collection of available machines were given as an input.
This is not the case for the problem we aim to solve with this research.
For our problem, the collection of available machines is a decision variable and not a given problem input.
This is an important distinction, since it creates a problem which requires optimization in two stages.
First, one must select a suitable collection of available machines.
Second, the jobs scheduled across all time slots must then be allocated to these machines.
Finding a good solution to the problem will require weighing the amount of time spent solving each of the two subproblems.
We want to create a scheduler which can return a good result within a reasonable amount of execution time.
If we spend too much time searching for a good collection of available machines, then we will have little time remaining for job scheduling, and vice versa.
