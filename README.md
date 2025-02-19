# Policy Lab Project: Analyzing the Linkage Between Local Poverty and Governance Perceptions in Burkina Faso

### Repository Overview

This repository showcases an example of the work I independently completed as part of the Harris Policy Lab Project, where I, along with five teammates, served as policy consultants under faculty supervision for our client, the United Nations Development Programme (UNDP). The project's focus was on analyzing disparities in local poverty and its connections with governance perceptions in Burkina Faso to guide the UNDP's resource allocation decisions. 

Included here are R scripts for:

* **Cleaning and Preparing Living Standards Metrics** from household survey data, essential for constructing the Multidimensional Poverty Index (MPI).

* **Cleaning and Preparing Subjective Poverty** from household survey data, capturing individual household perceptions of poverty. This script complements the MPI by providing a nuanced view of poverty that considers personal experiences and perceptions, enhancing our holistic approach to the analysis.

These efforts supported the creation of our final deliverables: a comprehensive policy memo and a presentation tailored for a non-technical stakeholder audience.  

### Process for Cleaning Household Survey Data

Both the **Living Standards** and **Subjective Poverty** scripts follow a structured approach to provess household survey data. The key steps include:

**1. Indentifying Relevant Data Files**

Before processing, we conduct a background literature review to inform variable selection and ensure that variable matching aligns with established methodologies.

* **Living Standards:** Uses the **MPI** framework (Oxford Poverty and Human Development Initiative & UNDP) to assess household deprivations across living standards, health, and education.

* **Subjective Poverty**: Based on the UNECE Subjective Poverty Report, measuring households' perceptions of their economic situation, financial well-being, and deprivation levels.

**2. Creating Household Identifiers**

* I created a function (`create_household_variable`) to generate a unique household identifier by concatenating `grappe`, `menage`, and `vague`, ensuring consistency and generalizability across multiple datasets.

After these intitial steps, the scripts diverge in their specific processing tasks:

### Living Standards Script

