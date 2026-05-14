# Global data on humanitarian funding to local actors
This repository contains the analysis process and humanitarian funding data underlying the analysis in chapter 1 of the 2026 ODI HPG report ['The state of international humanitarian funding to local and national actors'](https://odi.org/en/publications/the-state-of-international-humanitarian-funding-to-local-and-national-actors/). The disaggregated funding dataset is accessible in [English](https://github.com/niklasrie/local_hum_funding/blob/ce76e9d30eb6cb7918da004cb09231487da8fb93/output/master_local_funding_flows.csv), [French](https://github.com/niklasrie/local_hum_funding/blob/ce76e9d30eb6cb7918da004cb09231487da8fb93/output/master_local_funding_flows_fr.csv), [Spanish](https://github.com/niklasrie/local_hum_funding/tree/ce76e9d30eb6cb7918da004cb09231487da8fb93/output) and [Arabic](https://github.com/niklasrie/local_hum_funding/blob/ce76e9d30eb6cb7918da004cb09231487da8fb93/output/master_local_funding_flows_ar.csv). Similarly, this explanation is available in [English](https://github.com/niklasrie/local_hum_funding/blob/ce76e9d30eb6cb7918da004cb09231487da8fb93/README.md), [French](https://github.com/niklasrie/local_hum_funding/blob/ce76e9d30eb6cb7918da004cb09231487da8fb93/README_FR.md), [Spanish](https://github.com/niklasrie/local_hum_funding/blob/ce76e9d30eb6cb7918da004cb09231487da8fb93/README_ES.md) and [Arabic](https://github.com/niklasrie/local_hum_funding/blob/ce76e9d30eb6cb7918da004cb09231487da8fb93/README_AR.md). This repository also contains the raw data for all figures in said report [here](https://github.com/niklasrie/local_hum_funding/tree/ce76e9d30eb6cb7918da004cb09231487da8fb93/analyses).

This dataset is intended to serve as open resource for the humanitarian policy and data user community. We welcome feedback on the process behind it and its contents. 

# Analysis methodology

The analysis process involved the following steps:

1. Sourcing disconnected, different datasets on humanitarian funding
2. Cleaning those datasets
3. Merging those datasets into one global, comprehensive dataset on humanitarian funding
4. Identifying within that funding to local and national actors (LNAs) while avoiding double-counting

Links to the various sources are included [below](#data-sources). The cleaning of each dataset was done manually in the first iteration of this analysis and is not currently included in this repository. Steps three and four are explained below. 

## Data sources

The methodology section of the corresponding 2026 ODI HPG report 'The state of international humanitarian funding to local and national actors' includes more detail for each source on what additional, manual steps were required for each dataset so that they could be merged into one global dataset.

### FTS

The bulk of data on direct humanitarian funding from mostly government donors to international, national and local actors is based on historical funding data from UN OCHA's [Financial Tracking Service](https://fts.unocha.org/).
The FTS data included in this repository only includes a reduced amount of columns and already contains USD values that were adjusted for inflation (USD values were deflated to constant 2023 prices). The script that downloaded this dataset from the FTS API and deflated to 2023 prices can be found in the corresponding [repository for ALNAP's GHA 2025 report](https://github.com/ALNAP-Comms/gha_2025/tree/main/scripts).

### Country-based pooled funds

Funding data on allocations from country-based pooled funds (CBPFs) was downloaded from the [CBPF Data Explorer](https://cbpf.data.unocha.org/dataexplorer.html).

Funding data on sub-grants from implementers of CBPF projects to other partner organisations is currently not publicly available with granular, project-level breakdown. The CBPF office however did share this data with the authors and it is included in the aggregate analysis results in the [output](https://github.com/niklasrie/local_hum_funding/tree/main/output) folder, though ommitted from the granular [master dataset](https://github.com/niklasrie/local_hum_funding/blob/main/output/master_local_funding_flows.csv) and the [data inputs](https://github.com/niklasrie/local_hum_funding/tree/main/input). **This means that there currently is a discrepancy when adding up the values from the disaggregated master local funding flow dataset to reproduce some of the aggregate results in the output folder.**

### UNICEF

Data on UNICEF's implementing partners was downloaded from its [online transparency portal](https://open.unicef.org/documents-and-resources?topic_id=&text_id=implementing%20partners).

### UNHCR

Data on UNHCR's implementing partners was downloaded from the [UN partner portal](https://supportcso.unpartnerportal.org/hc/en-us/articles/13420656571671-Collaboration-with-Funded-Partners).

### WFP

Data on WFP's partnerships with NGOs was downloaded from the [WFP website](https://www.wfp.org/non-governmental-organizations).

### IOM

IOM data is sourced from the PowerBI dashboards on the dedicated webpage.

### IFRC Network

Data on funding to Red Cross and Red Crescent (RCRC) Societies is based on income data from the [IFRC Network Databank](https://data.ifrc.org/) for countries with interagency humanitarian response plans.

## Merging of funding datasets

The automated merging of funding data takes the following steps for each source dataset:
1. Mapping the source dataset's columns onto the structure of the masterdaset
2. Adding shared columns to indicate whether funding is received by LNAs or not, and whether funding is direct (usually meaning from government or private donors) or indirect (through intermediaries, e.g., UN, pooled funds or NGOs)
2. Standardising country names, and classifications of donor and recipient organisations by type
4. If necessary, performing dataset-specific changes to align with master dataset structure (e.g., adjusting USD values for inflation)
5. Merging the 'aligned' source dataset into the master dataset
6. If necessary, removing double-counting of funding across the pre-existing and newly added funding data

Note that the removal of double-counting means here that the same funding flow is not counted twice (or more) from different sources. The same funding might however be included multiple times at different steps in the funding chain (e.g., first when provided from a government donor to a UN agency, and again when provided from that UN agency to an NGO). Given the limited amount of data shared publicly by intermediaries, it is not currently possible to track funding through the humanitarian system from one actor to another. The exception to this are CBPFs, even though they also currently do not publish sub-grants data within CBPF projects [see above](#country-based-pooled-funds).

## Analysis process

The [merging process](#merging-of-funding-datasets) yields a granular and global dataset of humanitarian funding flows by country, donor and recipient organisation. This dataset can then be used to analyse how much international humanitarian funding reached LNAs according to publicly available data. Note that the data availability by year varies by source, with only 2022 to 2024 including data from all sources listed above.

The [analysis script](https://github.com/niklasrie/local_hum_funding/blob/main/code/2_loc_analysis.R) in this repository performs four different analyses:
1. The volumes of international humanitarian funding received by different types of LNAs. This is a straightforward sum by each type and year.
2. The percentage of international humanitarian funding reaching LNAs each year, directly and indirectly. For this we impute the humanitarian funding received by the four UN agencies for which we have partner data (IOM, UNICEF, UNHCR and WFP) as per their own annual reports as opposed to FTS data. We then use as denominator the total, direct international humanitarian funding from FTS only prior to 2022 and from FTS and those four UN agencies' data for 2022 to 2024. We remove the CBPF sub-grants data from the numerator to correspond to the Grand Bargain definition of funding to LNAs that is as direct as possbile (i.e., through up to one intermediary).
3. The amount and share of international humanitarian funding reaching LNAs each year by country. We use FTS data on total humanitarian funding by country as denominator for the percentage calculation.
4. The volumes of international humanitarian funding provided to LNAs by donor. This is a straightforward sum by donor and year.
