# Policy Lab Project: Analyzing the Linkage Between Local Poverty and Governance Perceptions in Burkina Faso

## Repository Overview

This repository showcases an example of the work I independently completed as part of the Harris Policy Lab Project, where I, along with five teammates, served as policy consultants under faculty supervision for our client, the United Nations Development Programme (UNDP). The project's focus was on analyzing disparities in local poverty and its connections with governance perceptions in Burkina Faso to guide the UNDP's resource allocation decisions. 

Included here is an R script for cleaning and preparing **Living Standards Metrics**, which is one of the three key components of the **Multidimensional Poverty Index (MPI)** along with health and education. These metrics are crucial for a comprehensive understanding of poverty at the household level. This process helped construct the final MPI metrics for our analysis, which supported the creation of our final deliverables: a comprehensive policy memo and a presentation tailored for a non-technical stakeholder audience.

## Process for Cleaning Household Survey Data

The **Living Standards** script follow a structured approach to processing household survey data. The key steps include:

### Indentifying Relevant Data Files and Fields

I conducted a background literature review to inform variable selection and ensure that variable matching aligns with established methodologies. This script systematically classifies household deprivations across dimensions such as fuel, water, sanitation, electricity, and housing, following the MPI framework established by the Oxford Poverty and Human Development Initiative (OPHI) and UNDP.


### Creating Household Identifiers

* I created the `create_household_variable` function to generate a unique household identifier by concatenating `grappe`, `menage`, and `vague`, which are geographical identifiers at different administrative levels. This enables seamless merging with cleaned health and education tables for constructing the final household MPI metrics. The function is designed for scalability and generalizability and was also used in cleaning other poverty metrics (not shown in this repo).


### Handling Missing Values (NAs)

  * **Using Available Seasonal Data:** I pragmatically handled missing time cost data by using available time costs from either the dry or wet season to determine overall deprivation status, preventing unnecessary data loss. This approach recognizes that good access in one season might offset poorer access in another. Without this handling, any NA in either season could default to deprivation, potentially overestimating the number of households considered deprived.
    
  * **Imputing Missing Time Cost as 0:** I imputed missing time costs as 0s for household accessing water in-house, from their yard, or from a neighbor to ensure that these cases were not mistakenly classified as deprived due to missing travel time data and to significantly reduce data loss. This step accounted for 90% of the NAs in the dataset.

### Sequencing Transformations

I carefully ordered `mutate()` operations to prevent incorrect classifications by prioritizing and placing stronger conditions at the end, ensuring that it overrides the weaker conditions. For instance, even if the round-trip time to access water is less than 30 minutes, a household is still considered deprived if their water source is unclean.


