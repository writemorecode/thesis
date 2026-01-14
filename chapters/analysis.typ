= Analysis and Discussion <analysis_section>

This chapter interprets the evaluation results and discusses their implications for offline scheduling in private clouds.

The results of the evaluation are clear.
We can divide the packing algorithms into two classes: the naive _FFDLex_, _FFDSum_, _FFDProd_, _FFDMax_, _FFDL2_, etc, and the more intelligent _BFD_ and _FFDNew_.
We can make two initial conclusions.
The performance of the naive algorithms are all comparable, with exception of one or two outliers with exceedingly poor performance.
The performance of _BFD_ and _FFDNew_ are nearly, but not completely identical.
These conclusions hold for all three datasets.

We shall study the evaluation results of the _BFD_ and _FFDNew_ algorithms.
The two algorithms have nearly identical average costs on each of the datasets.
For all three datasets, the confidence interval for the mean logarithmic cost ratio contains the value $1$.
This means that it is not likely that _BFD_ is superior to _FFDNew_.
This means that we must instead use the Dolan-Moré performance profiles to help us determine the superior algorithm.
We find that the _BFD_ algorithm has the higher _"win-rate"_ on the balanced and job-heavy dataset, but that the _FFDNew_ algorithm has the higher win-rate on the machine-heavy dataset.
However, let us assume that private cloud providers purchase their machines in bulk, preferring to keep large fleets consisting of relatively few machine types.
Then, the number of job types would be either nearly equal to or far greater than the number of machine types.
This would mean that the _BFD_ algorithm performs best on the more realistic datasets.

This result is not unexpected.
Recall the details of how the problem instances used for algorithm evaluation were generated.
A subset of the job types and machine types were assigned a primary resource.
For these job and machine types, the resource demands and capacities, respectively, were amplified.
The primary resources of the job types and machine types were also correlated to some degree.
Clearly, a job type with a certain primary resource would be best placed in a machine type with a matching primary resource.
This placement would make the best use of the machine's resource capacity, especially for the machine's primary resource capacity.
Since the _BFD_ packing algorithm is based on the best-fit heuristic, it is clear that the algorithm will be better able to find these optimal packings.
Compare this to the _FFDNew_ algorithm, which is based on the simpler first-fit heuristic.
This algorithm will instead place each item in the first bin which can accommodate it, regardless of how well the item fits in the bin.
