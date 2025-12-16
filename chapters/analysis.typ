= Analysis

== Algorithm discussion

=== Naive local search algorithm

As demonstrated by the results of the first described algorithm in @results_section, this algorithm can perform poorly for certain problem instances.
Specifically, we saw that the chose buy machines of only a single type, despite the fact that this machine type was the most expensive of all.
The reason for this was the rudimentary algorithms for selecting a new bin type and packing jobs into open bins.

The first cause of the poor performance of the algorithm is related to the First-Fit (FF) bin-packing algorithm.
The FF algorithm does not specify which bin type shall be opened in the case of heterogeneous bins.
Nor does the algorithm specify how to handle the case where there are costs related to opening a new bin.
The FF algorithm used by the current algorithm does not take costs into account.
When selecting a bin type to store a new item, it will choose the first bin type with sufficient capacity to store the item regardless of its costs.

In order to develop an improved algorithm with superior performance, we must begin by developing a version of the First-Fit algorithm more suitable to our problem.
Specifically, this new bin-packing heuristic algorithm must be developed with the multidimensional heterogeneous case of the bin-packing problem in mind.
First, we shall consider which bin type shall be selected to store a given item which could not be placed in any of the already opened bins.
There are several directions to take here.
First, we shall define the feasible bin types for an item type to be the bin types with sufficient capacity to store item type.
We could choose to always open the most inexpensive, or the largest, or the smallest feasible bin type.
Or, we could attempt two combine two of the approaches, by e.g. sorting the feasible bin types first by increasing cost, and then by decreasing or increasing capacity.
Opening larger bins works well when many other items can be packed or re-packed into the bin.
Likewise, opening smaller bins works well when there will not be many other items packed into the bin.
In practice, it will be difficult to predict how many other items will be packed into a newly opened bin.

Now, given that we have developed an improved algorithm for selecting the optimal bin type to open for a new item, we can focus on the next problem.
This problem is how to improve the packing of items into open bins.
The current algorithm uses First-Fit Descending for bin-packing.
While packing jobs into machines, we want to avoid the stranded resource problem.
We shall explain the problem with an example.
Consider a job with high memory requirements and medium-high CPU requirements.
The job is placed on a machine with large resources for CPU and memory.
In this case, the memory resource of the machine will be well-utilized, but the CPU resource will not usable by other jobs which also require memory.
Because of this, the CPU resource of the machine will be stranded.
A solution to this problem is to find a better machine for the job, with high memory resource but only medium-high CPU resources.
By placing the job on this other machine, its CPU resources will not be wasted.

=== Improved local search algorithm

By modifying the naive local search algorithm discussed above, we get a much improved algorithm which is able to correctly pack items into bins of different types.
However, this is still only a local search algorithm, with no ability to search for solutions outside of the initial solution neighborhood.

=== Global search algorithm

This algorithm has the capacity to search for solutions in multiple neighborhoods.
However, the algorithm is unable to outperform the simple first-fit decreasing algorithm.
In fact, the algorithm is rarely able to find any other solution superior to the initial solution computed with FFD.
It is possible that the algorithm can be improved using more intelligent methods for moving between adjacent neighborhoods.
However, the complexity of the algorithm must match its performance.
Increased algorithmic complexity must yield superior performance.
