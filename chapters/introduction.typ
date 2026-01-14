= Introduction <chp-introduction>

== Background

Due to privacy concerns, many organizations are today choosing to migrate away from public clouds to their own private cloud environments.
Such a migration requires an initial investment in a fleet of machines.
The organizations which want to run these private clouds also want to minimize its energy consumption.
This can be because of both environmental and financial reasons.
It is possible that organizations can, with some degree of certainty, predict the kinds of workloads which will run on their private cloud environment, and the resource demands of these workloads.
Given this prediction information, organizations would then want to be able to optimize their machine fleet with respect to both its total required capital and operational expenditures.

== Problem statement and approach

In this thesis, we describe a number of different algorithms for solving this optimization problem.
We model the problem as an offline job scheduling problem, which we then approach as an offline variable-sized multidimensional bin-packing problem with bin selection and opening costs.
This is an offline problem, since we have access to the predicted workload data ahead of time.
Due to the lack of an existing realistic dataset for this exact problem, we describe how to generate a dataset of random problem instances.
Finally, we evaluate these algorithms and discuss their strengths and weaknesses.

== Outline

The thesis is structured as follows.
In @theory_section, we present some of the existing theory related to the bin-packing problem, and some of its generalizations.
In @problem_description_section, we present a mathematical model of the job scheduling problem.
In @method_section, we describe the details of each job scheduling algorithm, including both pseudocode and more detailed descriptions.
In @exp_method_section, we describe our experimental methodology for generating problem instances and our dataset.
In @results_section, we present our algorithm evaluation data.
Finally, in @analysis_section, we analyze and discuss the evaluation data.
