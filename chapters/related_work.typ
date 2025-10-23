= Related work

== Job-scheduling

In 2010, Speitkamp and Bichler @speitkamp_bichler_2010 described a server consolidation problem.
The authors presented an LP-based formulation of the problem, and a solution using a heuristic based on LP-relaxation. 
They also showed that the problem is strongly NP-hard, by reducing the problem to the multidimensional bin-packing problem (MDBP).

In 2012, Setzer and Wolke @setzer_wolke_2018 formulated a mathematical model for scheduling virtual machines in data centers.
This model was optimized for minimizing the number of powered-on physical machines over time, while also attempting to minimize the overhead from virtual machine migration between physical machines.

In 2013, Ghribi et al. @ghribi_hadji_djamal_2013 presented two exact algorithms for energy-efficient cloud job scheduling.

In 2016, Mosa and Paton @mosa_paton_2016 developed an optimized energy- and SLA-aware virtual machine placement strategy based on genetic algorithms.

In 2018, Lei et al. @liu_li_li_2018 presented, analyzed, and benchmarked a randomized approximation algorithm for solving the minimal cost job-server configuration problem.

In 2010, Khuller et al. @khuller_scheduling_energy_partial_shutdown studied job scheduling problems with machine activation costs.
In this case, a subset of all available machines must be selected for use, and each machine type has a cost for selecting it.
This machine activation cost shall not be confused with a machine purchase cost.
Later in 2011, Khuller et al. @khuller_gma presented a generalization of their previous work.

== Bin-packing

In 1972, Gary, Graham, and Ullman analyzed the worst-case performance of heuristics-based methods for bin-packing @garey_worst_mem_alloc.
The authors viewed these algorithms from a more practical point of view, as algorithms for memory allocation. 

David Johnson was first to study approximation algorithms for the bin-packing problem, in his 1973 Ph.D. thesis @johnson_1973_phd.
He presented bounds for both the First-Fit and Best-fit algorithms.

In 1976, Gary, Graham Johnson, and Yao studied bin-packing applied to the problem of job scheduling with precedence constraints @Garey1976ResourceCS.
With precedence constraints, certain jobs may need to be scheduled before others.

In 2004, Chekuri and Khanna studied approximation algorithms for multidimensional versions of classic packing problems, including the bin-packing problem @chekuri_multidim_packing.

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

