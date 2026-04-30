# Script setup ------------------------------------------------------------

list.of.packages <- c("data.table", "openxlsx")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
suppressPackageStartupMessages(lapply(list.of.packages, require, character.only=T))
rm(list.of.packages, new.packages)

# Set working directory to folder the level above the code location
script_path <- rstudioapi::getActiveDocumentContext()$path
parent_dir <- dirname(dirname(script_path))
setwd(parent_dir)
rm(parent_dir, script_path)

# Read in reference helper files
iso_lookup <- setDT(read.xlsx("input/ref/names_and_iso_lookups.xlsx", sheet = 1))
deflators <- fread("input/ref/deflators_2023usd.csv")
dac_deflators <- deflators[ISO == "DAC"]
recip_org_type_map <- setDT(read.xlsx("input/ref/org_type_map.xlsx", sheet = 1))
donor_org_type_map <- setDT(read.xlsx("input/ref/org_type_map.xlsx", sheet = 2))
rcrc_map <- fread("input/ref/rcrc_map.csv")
govt_fts <- fread("input/ref/govt_fts.csv")
recip_org_unique <- fread("input/ref/recip_org_unique.csv")

# Master dataset structure ------------------------------------------------

# Create blank master dataset structure

master_dt <- data.table(
  year = integer(),
  amount_usd = numeric(),
  amount_usd_defl = numeric(),
  project_title_description = character(),
  donor_org = character(),
  donor_org_type = character(),
  recipient_org = character(),
  recipient_org_type = character(),
  lnha_flag = logical(),
  funding_level = character(),
  recipient_location = character(),
  recipient_location_iso3 = character(),
  source = character(),
  source_id = character()
)

# Create a key for master dataset data type structure and a way to apply it

master_dt_type_key <- list(
  year = as.integer,
  amount_usd = as.numeric,
  amount_usd_defl = as.numeric,
  project_title_description = as.character,
  donor_org = as.character,
  donor_org_type = as.character,
  recipient_org = as.character,
  recipient_org_type = as.character,
  lnha_flag = as.logical,
  funding_level = as.character,
  recipient_location = as.character,
  recipient_location_iso3 = as.character,
  source = as.character,
  source_id = as.character
)

apply_types <- function(DT, master_dt_type_key) {
  cols <- intersect(names(master_dt_type_key), names(DT))
  DT[, (cols) := Map(function(col, fun) fun(col),
                     .SD,
                     master_dt_type_key[cols]),
     .SDcols = cols]
}

char_cols <- c("project_title_description", "donor_org", "donor_org_type", "recipient_org",
               "recipient_org_type", "funding_level", "recipient_location",
               "recipient_location_iso3", "source", "source_id")

# FTS ---------------------------------------------------------------------

# Read in FTS and merge into master
fts <- fread("input/fts/fts_2016_2024.csv", encoding = "UTF-8")

fts[, `:=`(
  lnha_flag = logical(),
  source = "FTS",
  funding_level = fifelse(
    newMoney == TRUE,
    "Direct",
    "Indirect")
)]

col_map_fts <- c(
  year = "year",
  amount_usd = "amountUSD",
  amount_usd_defl = "amountUSD_defl",
  project_title_description = "description",
  donor_org = "source_org_grouped",
  donor_org_type = "source_orgtype",
  recipient_org = "destination_org_grouped",
  recipient_org_type = "destination_orgtype",
  lnha_flag = "lnha_flag",
  funding_level = "funding_level",
  recipient_location = "destination_org_country",
  recipient_location_iso3 = "destination_org_iso3",
  source = "source",
  source_id = "id"
)

aligned_fts <- fts[year >= 2016 & domestic_response == FALSE, ..col_map_fts]
setnames(aligned_fts, old = col_map_fts, new = names(col_map_fts))
apply_types(aligned_fts, master_dt_type_key)
aligned_fts[, (char_cols) := lapply(.SD, trimws), .SDcols = char_cols]

# Re-assign incorrect recipient org types
aligned_fts[
  recipient_org == "Al-Ameen for Humanitarian Support" & recipient_location_iso3 != "TUR",
  recipient_org_type := "NGOs: International"
]

aligned_fts[
  recipient_org == "Rural Water and Sanitation Support Agency",
  recipient_org_type := "NGOs: National"
]

aligned_fts[
  recipient_org == "Social Fund for Development",
  recipient_org_type := "Governments: Local/National"
]

aligned_fts[
  recipient_org == "International Organization for Migration",
  recipient_org_type := "Multilateral: UN"
]


# Map standardised org types and local actor flag onto FTS data
aligned_fts[recip_org_type_map,
            on = "recipient_org_type",
            `:=`(
              lnha_flag = i.lnha_flag,
              recipient_org_type = i.master_recipient_org_type
)]
aligned_fts[donor_org_type_map,
            on = "donor_org_type",
            donor_org_type := i.master_donor_org_type
]

# Re-code government actors only as local/national actors when receiving funding for their own country

aligned_fts[govt_fts,
            on = .(recipient_org),
            `:=`(
              recipient_org_type = fifelse(recipient_location_iso3 == i.iso3, "Governments: Local/National", "Governments: International"),
              lnha_flag = fifelse(recipient_location_iso3 == i.iso3, TRUE, FALSE)
            )]

# Fix FTS coding errors
aligned_fts[recipient_location_iso3 == "Global" |
              recipient_location_iso3 == "MULTI" |
              recipient_location_iso3 == "",
            lnha_flag := FALSE
            ]

aligned_fts[grepl("Region", recipient_location), recipient_location_iso3 := "MULTI"]

# Drop duplicate FTS rows (stemming from duplicates in source file)
aligned_fts <- unique(aligned_fts)

# Remove negative FTS funding flows (often the product of incorrect multi-year funding reports)
aligned_fts <- aligned_fts[!(amount_usd < 0)]

# Fix deflator assignment for multilateral donor organisations
aligned_fts[
  dac_deflators,
  on = "year",
  dac_defl := i.gdp_defl
]

aligned_fts[
  donor_org_type %in% c("Multilateral: UN", "Multilateral: Other"),
  amount_usd_defl := amount_usd / dac_defl
]

aligned_fts[, dac_defl := NULL]

# Check for missing columns and merge into master dataset

missing_cols <- setdiff(names(master_dt), names(aligned_fts))
for (col in missing_cols) {
  aligned_fts[, (col) := master_dt[[col]][0]]
}

master_dt <- rbind(master_dt, aligned_fts, use.names = TRUE)

rm(fts, col_map_fts, govt_fts)

# CBPFs -------------------------------------------------------------------

# Read in CBPF allocations and sub-grants and merge in master while avoiding double-counting

cbpf_alloc <- fread("input/cbpf/cbpf_projects.csv", encoding = "UTF-8")
cbpf_subgrants <- setDT(read.xlsx("input/cbpf/cbpf_subgrants.xlsx", sheet = "Subgrants_RAW"))

cbpf_alloc[, `:=`(
  lnha_flag = logical(),
  amount_usd_defl = integer(),
  funding_level = "Indirect",
  donor_org_type = "Pooled Funds: Country",
  source = "CBPF_datahub"
)]

cbpf_alloc[!grepl("RhPF", PooledFundName),
           PooledFundName := paste0(PooledFundName, " CBPF")]

cbpf_subgrants[, `:=`(
  lnha_flag = logical(),
  amount_usd_defl = integer(),
  funding_level = "Indirect",
  project_title_description = character(),
  recipient_org = character(),
  source = "CBPF_email"
)]

cbpf_subgrants[cbpf_alloc,
  on = "ChfProjectCode",`:=`(
      OrganizationName = i.OrganizationName,
      project_title_description = i.ProjectTitle)]

col_map_cbpf_alloc <- c(
  year = "AllocationYear",
  amount_usd = "Budget",
  amount_usd_defl = "amount_usd_defl",
  project_title_description = "ProjectTitle",
  donor_org = "PooledFundName",
  donor_org_type = "donor_org_type",
  recipient_org = "OrganizationName",
  recipient_org_type = "OrganizationType",
  lnha_flag = "lnha_flag",
  funding_level = "funding_level",
  recipient_location = "recipient_location",
  recipient_location_iso3 = "recipient_location_iso3",
  source = "source",
  source_id = "ChfProjectCode"
)

col_map_cbpf_subgrants <- c(
  year = "AllocationYear",
  amount_usd = "SubOrgBudget",
  amount_usd_defl = "amount_usd_defl",
  project_title_description = "project_title_description",
  donor_org = "OrganizationName",
  donor_org_type = "OrganizationType",
  recipient_org = "recipient_org",
  recipient_org_type = "SubOrgType",
  lnha_flag = "lnha_flag",
  funding_level = "funding_level",
  recipient_location = "recipient_location",
  recipient_location_iso3 = "recipient_location_iso3",
  source = "source",
  source_id = "ChfProjectCode"
)

aligned_cbpf_alloc <- cbpf_alloc[, ..col_map_cbpf_alloc]
aligned_cbpf_subgrants <- cbpf_subgrants[
  !is.na(SubOrgBudget) & nzchar(SubOrgBudget) & SubOrgBudget != 0,
  ..col_map_cbpf_subgrants
]

setnames(aligned_cbpf_alloc, old = col_map_cbpf_alloc, new = names(col_map_cbpf_alloc))
setnames(aligned_cbpf_subgrants, old = col_map_cbpf_subgrants, new = names(col_map_cbpf_subgrants))
apply_types(aligned_cbpf_alloc, master_dt_type_key)
apply_types(aligned_cbpf_subgrants, master_dt_type_key)
aligned_cbpf_alloc[, (char_cols) := lapply(.SD, trimws), .SDcols = char_cols]
aligned_cbpf_subgrants[, (char_cols) := lapply(.SD, trimws), .SDcols = char_cols]

aligned_cbpf_alloc <- aligned_cbpf_alloc[year >= 2016 & year <= 2024]
aligned_cbpf_subgrants <- aligned_cbpf_subgrants[year >= 2016 & year <= 2024]

# Carry out remaining data manipulations and merge into master dataset

aligned_cbpf_alloc[dac_deflators,
           on = "year",
           amount_usd_defl := amount_usd / i.gdp_defl]

aligned_cbpf_subgrants[dac_deflators,
           on = "year",
           amount_usd_defl := amount_usd / i.gdp_defl]

aligned_cbpf_alloc[recip_org_type_map,
                   on = "recipient_org_type",
                   `:=` (
                     recipient_org_type = i.master_recipient_org_type,
                     lnha_flag = i.lnha_flag
                   )]

aligned_cbpf_alloc[donor_org_type_map,
            on = "donor_org_type",
            donor_org_type := i.master_donor_org_type
]

aligned_cbpf_subgrants[recip_org_type_map,
                   on = "recipient_org_type",
                   `:=` (
                     recipient_org_type = i.master_recipient_org_type,
                     lnha_flag = i.lnha_flag
                   )]

aligned_cbpf_subgrants[donor_org_type_map,
                   on = "donor_org_type",
                   donor_org_type := i.master_donor_org_type
]

missing_cols <- setdiff(names(master_dt), names(aligned_cbpf_alloc))
for (col in missing_cols) {
  aligned_cbpf_alloc[, (col) := master_dt[[col]][0]]
}

missing_cols <- setdiff(names(master_dt), names(aligned_cbpf_subgrants))
for (col in missing_cols) {
  aligned_cbpf_subgrants[, (col) := master_dt[[col]][0]]
}

master_dt <- rbind(master_dt, aligned_cbpf_alloc, use.names = TRUE)
master_dt <- rbind(master_dt, aligned_cbpf_subgrants, use.names = TRUE)

rm(cbpf_alloc, cbpf_subgrants, col_map_cbpf_alloc, col_map_cbpf_subgrants,
   aligned_cbpf_alloc, aligned_cbpf_subgrants)

# Delete FTS CBPF (including RHF) allocations from master dataset to remove double-counting

master_dt <- master_dt[
  !(source == "FTS" & donor_org_type %in% c("Pooled Funds: Regional", "Pooled Funds: Country"))
]

# UNICEF ------------------------------------------------------------------

# Read in UNICEF humanitarian partner sub-grants

unicef <- fread("input/un_agencies/unicef.csv")
unicef[, `:=` (
  lnha_flag = logical(),
  amount_usd_defl = integer(),
  source = "UNICEF",
  donor_org = "UNICEF",
  funding_level = "Indirect",
  donor_org_type = "Multilateral: UN",
  TRANSFERS_TO_IP = as.integer(gsub(",", "", TRANSFERS_TO_IP))
)]

# Add UNICEF humanitarian funding classification column (based on DAC humanitarian sector codes and keyword search)

unicef[, unicef_hum_class := {
  checks <- c(
    sector = hum_dac_perc > 50,
    kws    = Cases_that_pass == "Yes"
  )
  out <- names(checks)[checks]
  if (length(out)) paste(out, collapse = ", ") else NA_character_
}, by = .I]

unicef <- unicef[!(unicef_hum_class == "NA")]

# Carry out remaining data manipulations and merge into master dataset

col_map_unicef <- c(
  year = "Year",
  amount_usd = "TRANSFERS_TO_IP",
  amount_usd_defl = "amount_usd_defl",
  project_title_description = "CP_RESULT_STATEMENT_cleaned",
  donor_org = "donor_org",
  donor_org_type = "donor_org_type",
  recipient_org = "PARTNER",
  recipient_org_type = "Org_type_GB",
  lnha_flag = "lnha_flag",
  funding_level = "funding_level",
  recipient_location = "BUSINESS_AREA",
  recipient_location_iso3 = "recipient_location_iso3",
  source = "source",
  source_id = "WBS_ELEMENT_EX"
)

aligned_unicef <- unicef[, ..col_map_unicef]
setnames(aligned_unicef, old = col_map_unicef, new = names(col_map_unicef))
apply_types(aligned_unicef, master_dt_type_key)
aligned_unicef[, (char_cols) := lapply(.SD, trimws), .SDcols = char_cols]

aligned_unicef[dac_deflators,
                   on = "year",
                   amount_usd_defl := amount_usd / i.gdp_defl]

aligned_unicef[recip_org_type_map,
                   on = "recipient_org_type",
                   `:=` (
                     recipient_org_type = i.master_recipient_org_type,
                     lnha_flag = i.lnha_flag
                   )]

aligned_unicef[iso_lookup,
                  on = .(recipient_location = CountryName),
                  recipient_location_iso3 := i.ISO3]

master_dt <- rbind(master_dt, aligned_unicef, use.names = TRUE)

# Remove any existing funding from UNICEF to sub-grantees from master dataset to prevent double-counting
master_dt <- master_dt[
  !(source == "FTS" & donor_org == "UNICEF")
]

master_dt <- master_dt[
  !(source == "CBPF_email" & donor_org == "United Nations Children's Fund")
]

rm(unicef, col_map_unicef, aligned_unicef)


# UNHCR ---------------------------------------------------------------------

# Read in UNHCR humanitarian partner sub-grants

unhcr <- fread("input/un_agencies/unhcr.csv")
unhcr[, `:=` (
  lnha_flag = logical(),
  amount_usd_defl = integer(),
  funding_level = "Indirect",
  donor_org_type = "Multilateral: UN",
  source_id = NA
)]

col_map_unhcr <- c(
  year = "year",
  amount_usd = "amountUSD",
  amount_usd_defl = "amount_usd_defl",
  project_title_description = "description",
  donor_org = "source_org",
  donor_org_type = "donor_org_type",
  recipient_org = "destination_org",
  recipient_org_type = "destination_org_type",
  lnha_flag = "lnha_flag",
  funding_level = "funding_level",
  recipient_location = "country",
  recipient_location_iso3 = "iso3",
  source = "data_source",
  source_id = "source_id"
)

aligned_unhcr <- unhcr[, ..col_map_unhcr]
setnames(aligned_unhcr, old = col_map_unhcr, new = names(col_map_unhcr))
apply_types(aligned_unhcr, master_dt_type_key)
aligned_unhcr[, (char_cols) := lapply(.SD, trimws), .SDcols = char_cols]

aligned_unhcr[dac_deflators,
               on = "year",
               amount_usd_defl := amount_usd / i.gdp_defl]

aligned_unhcr[recip_org_type_map,
               on = "recipient_org_type",
               `:=` (
                 recipient_org_type = i.master_recipient_org_type,
                 lnha_flag = i.lnha_flag
               )]

master_dt <- rbind(master_dt, aligned_unhcr, use.names = TRUE)

# Remove any existing funding from UNHCR to sub-grantees from master dataset to prevent double-counting

master_dt <- master_dt[
  !(source == "FTS" & donor_org == "United Nations High Commissioner for Refugees")
]

master_dt <- master_dt[
  !(source == "CBPF_email" & donor_org == "United Nations High Commissioner for Refugees")
]

rm(unhcr, col_map_unhcr, aligned_unhcr)

# WFP ---------------------------------------------------------------------

wfp <- fread("input/un_agencies/wfp.csv")
wfp[, `:=` (
  lnha_flag = logical(),
  amount_usd_defl = integer(),
  donor_org_type = "Multilateral: UN",
  funding_level = "Indirect",
  recipient_location_iso3 = character(),
  source_id = NA
)]

col_map_wfp <- c(
  year = "year",
  amount_usd = "amountUSD",
  amount_usd_defl = "amount_usd_defl",
  project_title_description = "activity_description",
  donor_org = "source_org",
  donor_org_type = "donor_org_type",
  recipient_org = "destination_org",
  recipient_org_type = "destination_org_type",
  lnha_flag = "lnha_flag",
  funding_level = "funding_level",
  recipient_location = "country",
  recipient_location_iso3 = "recipient_location_iso3",
  source = "data_source",
  source_id = "source_id"
)

aligned_wfp <- wfp[, ..col_map_wfp]
setnames(aligned_wfp, old = col_map_wfp, new = names(col_map_wfp))
apply_types(aligned_wfp, master_dt_type_key)
aligned_wfp[, (char_cols) := lapply(.SD, trimws), .SDcols = char_cols]

aligned_wfp[dac_deflators,
              on = "year",
              amount_usd_defl := amount_usd / i.gdp_defl]

aligned_wfp[iso_lookup,
               on = .(recipient_location = CountryName),
               recipient_location_iso3 := i.ISO3]

aligned_wfp[recip_org_type_map,
              on = "recipient_org_type",
              `:=` (
                recipient_org_type = i.master_recipient_org_type,
                lnha_flag = i.lnha_flag
              )]

master_dt <- rbind(master_dt, aligned_wfp, use.names = TRUE)

# Remove any existing funding from wfp to sub-grantees from master dataset to prevent double-counting

master_dt <- master_dt[
  !(source == "FTS" & donor_org == "WFP")
]

master_dt <- master_dt[
  !(source == "CBPF_email" & donor_org == "World Food Programme")
]

rm(wfp, col_map_wfp, aligned_wfp)


# IOM ---------------------------------------------------------------------

iom <- fread("input/un_agencies/iom.csv")
iom[, `:=` (
  lnha_flag = logical(),
  funding_level = "Indirect",
  amount_usd_defl = integer()
)]

col_map_iom <- c(
  year = "year",
  amount_usd = "amount_USD",
  amount_usd_defl = "amount_usd_defl",
  project_title_description = "project_title_description",
  donor_org = "donor_org",
  donor_org_type = "donor_org_type",
  recipient_org = "recipient_org",
  recipient_org_type = "recipient_org_type",
  lnha_flag = "lnha_flag",
  funding_level = "funding_level",
  recipient_location = "recipient_location",
  recipient_location_iso3 = "recipient_location_iso3",
  source = "source",
  source_id = "source_id"
)

aligned_iom <- iom[, ..col_map_iom]
setnames(aligned_iom, old = col_map_iom, new = names(col_map_iom))
apply_types(aligned_iom, master_dt_type_key)
aligned_iom[, (char_cols) := lapply(.SD, trimws), .SDcols = char_cols]

aligned_iom[dac_deflators,
            on = "year",
            amount_usd_defl := amount_usd / i.gdp_defl]

aligned_iom[
  recip_org_type_map,
  on = "recipient_org_type",
  `:=` (recipient_org_type = i.master_recipient_org_type,
        lnha_flag = i.lnha_flag
)]

aligned_iom[
  recip_org_type_map,
  on = "recipient_org_type",
  recipient_org_type := i.master_recipient_org_type
]

master_dt <- rbind(master_dt, aligned_iom, use.names = TRUE)

# Remove any existing funding from iom to sub-grantees from master dataset to prevent double-counting

master_dt <- master_dt[
  !(source == "FTS" & donor_org == "International Organization for Migration")
]

master_dt <- master_dt[
  !(source == "CBPF_email" & donor_org == "International Organization for Migration")
]

rm(iom, col_map_iom, aligned_iom)

# Standardise UN org names as recipient organisations

master_dt[
  recip_org_unique,
  on = .(recipient_org),
  recipient_org := i.recipient_org_unique
]

rm(recip_org_unique)

# RCRC National Societies --------------------------------------------------------------------

rcrc_ns <- fread("input/rcrc/rcrc_ns.csv")
rcrc_ns[, `:=` (
  lnha_flag = TRUE,
  amount_usd_defl = integer(),
  project_title_description = character(),
  donor_org = character(),
  recipient_org_type = "RCRC: National",
  source_id = NA
)]

col_map_rcrc_ns <- c(
  year = "year",
  amount_usd = "amountUSD",
  amount_usd_defl = "amount_usd_defl",
  project_title_description = "project_title_description",
  donor_org = "donor_org",
  donor_org_type = "source_org_type",
  recipient_org = "destination_org",
  recipient_org_type = "recipient_org_type",
  lnha_flag = "lnha_flag",
  funding_level = "funding_level",
  recipient_location = "country",
  recipient_location_iso3 = "iso3",
  source = "data_source",
  source_id = "source_id"
)

aligned_rcrc_ns <- rcrc_ns[year >= 2016, ..col_map_rcrc_ns]
setnames(aligned_rcrc_ns, old = col_map_rcrc_ns, new = names(col_map_rcrc_ns))
apply_types(aligned_rcrc_ns, master_dt_type_key)
aligned_rcrc_ns[, (char_cols) := lapply(.SD, trimws), .SDcols = char_cols]

aligned_rcrc_ns[dac_deflators,
            on = "year",
            amount_usd_defl := amount_usd / i.gdp_defl]

aligned_rcrc_ns[donor_org_type_map,
                on = "donor_org_type",
                donor_org_type := i.master_donor_org_type
]

# Check whether FTS or IFRC Network data are more comprehensive for national societies to decide source
rcrc_ns_sum <- aligned_rcrc_ns[, .(
  rcrc_sum = sum(amount_usd_defl, ra.rm = TRUE)
), by = recipient_org]

fts_ns_sum <- aligned_fts[
  recipient_org_type == "RCRC: National",
  .(fts_sum = sum(amount_usd_defl, ra.rm = TRUE)),
  by = recipient_org]

rcrc_map <- rcrc_map[
  fts_ns_sum,
  on = .(fts_rcrc_ns_name = recipient_org),
  fts_sum := i.fts_sum
]

rcrc_map <- rcrc_map[
  rcrc_ns_sum,
  on = .(rcrc_ns_name = recipient_org),
  rcrc_sum := i.rcrc_sum
]

rcrc_map <- rcrc_map[, source_decision := character()]
rcrc_map[,
  source_decision := 
  fifelse(
    !is.na(rcrc_sum) & !is.na(fts_sum) & rcrc_sum > fts_sum,
    "IFRC Network Databank", "FTS"
)]

rcrc_map[is.na(fts_rcrc_ns_name), source_decision := "IFRC Network Databank"]
rcrc_map[is.na(rcrc_ns_name), source_decision := "FTS"]

rcrc_to_remove <- rbindlist(list(
  rcrc_map[source_decision == "FTS", .(
    recipient_org = rcrc_ns_name,
    source = "IFRC Network Databank")],
  rcrc_map[source_decision == "IFRC Network Databank", .(
    recipient_org = fts_rcrc_ns_name,
    source = "FTS")]
))
rcrc_to_remove <- rcrc_to_remove[!(recipient_org == "#N/A")]
rcrc_to_remove <- rbind(
  rcrc_to_remove,
  data.table(recipient_org = "Red Cross/Red Crescent Societies (Confidential)", 
             source = "FTS")
)

# Merge IFRC Network data into master dataset

master_dt <- rbind(master_dt, aligned_rcrc_ns, use.names = TRUE)

# Retain CBPF allocations for countries that are not in the RCRC dataset
# Retain funding to RCRC national societies from either FTS or IFRC Network Database depending on comprehensiveness check

master_dt <- master_dt[!rcrc_to_remove,
 on = .(recipient_org, source)
]

# Remove double-counting between IFRC Network Database and UN partner datasets

master_dt <- master_dt[
  !(source == "CBPF_email" & 
      recipient_org_type == "RCRC: National" &
      recipient_location_iso3 %in% c("BFA", "NGA", "YEM"))
]

rcrc_source_overlap <- c("IOM", "UNHCR partner info", "UNICEF", "WFP FLA data")
rcrc_map_long <- rcrc_map[
  !is.na(rcrc_ns_name) & trimws(rcrc_ns_name) != "" &
    !is.na(other_rcrc_ns_name) & trimws(other_rcrc_ns_name) != "",
  .(other_rcrc_ns_name = trimws(unlist(strsplit(other_rcrc_ns_name, ";")))),
  by = rcrc_ns_name]
  
master_dt[rcrc_map_long,
  on = .(recipient_org = other_rcrc_ns_name),
  rcrc_key := i.rcrc_ns_name
]
master_dt[source == "IFRC Network Databank", rcrc_key := recipient_org]

subtract_rcrc_dt <- master_dt[
  source %in% rcrc_source_overlap &
    !is.na(rcrc_key),
  .(subtract_usd = sum(amount_usd, na.rm = TRUE),
    subtract_usd_defl = sum(amount_usd_defl, na.rm = TRUE)),
  by = .(rcrc_key, year)
]

master_dt[subtract_rcrc_dt,
 on = .(rcrc_key, year),
 `:=`(
   amount_usd = fifelse(
     source == "IFRC Network Databank" & donor_org_type == "Multilateral: UN",
     pmax(amount_usd - i.subtract_usd, 0),
     amount_usd),
   amount_usd_defl = fifelse(
     source == "IFRC Network Databank" & donor_org_type == "Multilateral: UN",
     pmax(amount_usd_defl - i.subtract_usd_defl, 0),
     amount_usd_defl
   ))
]

master_dt[, rcrc_key := NULL]
master_dt <- master_dt[!amount_usd == 0]


rm(rcrc_ns, col_map_rcrc_ns, aligned_rcrc_ns, subtract_rcrc_dt, rcrc_map_long,
   rcrc_ns_sum, fts_ns_sum, rcrc_to_remove, char_cols, rcrc_source_overlap)

# Sort and write master dataset ----------------------------------------------------

setorder(master_dt, year, source, recipient_location)
fwrite(master_dt, file = "output/master_local_funding_flows.csv", encoding = "UTF-8")

