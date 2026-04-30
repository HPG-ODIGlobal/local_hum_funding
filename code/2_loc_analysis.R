###Localisation script
#Required local files in 'input' folder:
#master_local_funding_flows.csv

#Load required packages
required.packages <- c("data.table", "rstudioapi", "openxlsx")
install.packages(required.packages[!(required.packages %in% installed.packages())])
lapply(required.packages, require, character.only=T)
rm(required.packages)

#Set working directory
setwd(dirname(dirname(getActiveDocumentContext()$path)))

#Load datasets
master_dt <- fread("output/master_local_funding_flows.csv")

# Funding volumes to LNHAs ------------------------------------------------

# Combine LNHA types with small funding volumes into one 'Other' category

master_dt[
  recipient_org_type %in% c("Private Organisations: Local/National", "Other: Local/National"),
  recipient_org_type := "Other: Local/National"
]

# Create table with aggregated, deflated funding volumes by year and LNHA type

volumes_table <- master_dt[
  lnha_flag == TRUE,
  .(total_usd_defl_m = sum(amount_usd_defl, na.rm = TRUE)/1000000),
  by = .(year, recipient_org_type)
]

volumes_table_wide <- dcast(
  volumes_table,
  recipient_org_type ~ year,
  value.var = "total_usd_defl_m",
  fill = 0
)

fwrite(volumes_table_wide, "output/lnha_volumes.csv")

# Funding percentages to LNHAs --------------------------------------------

# Impute UN's own hum. funding figures for 2022 and onwards 
UN_funding_to_remove <- c("IOM", "UNHCR", "UNICEF", "WFP")

funding_denominator_no_impute <- master_dt[
  funding_level == "Direct",
  .(total_usd_defl_m = sum(amount_usd_defl, na.rm = TRUE)/1000000),
  by = year
]
  
funding_denominator <- master_dt[
  funding_level == "Direct" & !(recipient_org %in% UN_funding_to_remove & year >= 2022),
  .(total_usd_defl_m = sum(amount_usd_defl, na.rm = TRUE)/1000000,
    funding_type = "Total direct humanitarian funding"),
  by = year
]

UN_own_funding_data <- setDT(read.xlsx("input/un_agencies/un_hum_funding.xlsx", sheet = 1))

funding_denominator[
  UN_own_funding_data[,
    .(total_usd_defl_m = sum(total_usd_defl, na.rm = TRUE)/1000000),
    by = year],
  on = .(year),
  total_usd_defl_m := total_usd_defl_m + i.total_usd_defl_m
]

# Remove CBPF sub-grants from local funding numerator as more than one intermediary
local_numerator_direct <- master_dt[
  lnha_flag == TRUE & funding_level == "Direct" & source != "CBPF_email",
  .(total_usd_defl_m = sum(amount_usd_defl, na.rm = TRUE)/1000000,
    funding_type = "Direct local"),
  by = year
]

local_numerator_all <- master_dt[
  lnha_flag == TRUE & source != "CBPF_email",
  .(total_usd_defl_m = sum(amount_usd_defl, na.rm = TRUE)/1000000,
    funding_type = "Direct and indirect local"),
  by = year
]

local_numerator_no_un_data <- master_dt[
  lnha_flag == TRUE & !(source %in% c("CBPF_email", "IOM", "UNICEF", "WFP FLA data", "UNHCR partner info")),
  .(total_usd_defl_m = sum(amount_usd_defl, na.rm = TRUE)/1000000,
    funding_type = "Direct and indirect local (without UN partner data)"),
  by = year
]

local_numerator_no_un_data[year < 2022, total_usd_defl_m := NA_integer_]

lnha_perc_amounts <- rbindlist(list(
  funding_denominator, local_numerator_all, local_numerator_direct, local_numerator_no_un_data
  )
)
  
setorder(lnha_perc_amounts, year, funding_type)

lnha_perc_amounts_wide <- dcast(
  lnha_perc_amounts,
  funding_type ~ year,
  value.var = "total_usd_defl_m",
  fill = 0
)

local_numerator_no_un_data_disagg <- master_dt[
  lnha_flag == TRUE & !(source %in% c("CBPF_email", "IOM", "UNICEF", "WFP FLA data", "UNHCR partner info")),
  .(total_usd_defl_m = sum(amount_usd_defl, na.rm = TRUE)/1000000),
  by = .(year, source)
]

fwrite(lnha_perc_amounts_wide, "output/lnha_perc_amounts.csv")


# Recipient country analysis ----------------------------------------------

# Read in fts and produce funding by country
fts <- fread("input/fts/fts_2016_2024.csv", encoding = "UTF-8")

fts_by_country <- fts[
  year >= 2016 & domestic_response == FALSE & new_to_country == TRUE,
  .(total_usd_defl_m = sum(amountUSD_defl_millions, na.rm = TRUE)),
  by = .(year, destination_org_country, destination_org_iso3)
]

lnha_by_country <- master_dt[
  lnha_flag == TRUE,
  .(total_usd_defl_m_lnha = sum(amount_usd_defl, na.rm = TRUE)/1000000),
  by = .(year, recipient_location_iso3)
]

lnha_by_country <- lnha_by_country[
  fts_by_country,
  on =.(year, recipient_location_iso3 = destination_org_iso3)
]

lnha_by_country[,
  lnha_funding_perc := total_usd_defl_m_lnha / total_usd_defl_m                 
]

fwrite(lnha_by_country, "output/lnha_by_country.csv")


# Donor analysis ----------------------------------------------------------

lnha_donors <- master_dt[
  lnha_flag == TRUE,
  .(total_usd_defl_m_lnha = sum(amount_usd_defl, na.rm = TRUE)/1000000),
  by = .(year, donor_org, donor_org_type)
]

fwrite(lnha_donors, "output/lnha_donors.csv")

# Clean up environment
rm(local_numerator_all, local_numerator_direct, local_numerator_no_un_data,
   UN_funding_to_remove, funding_denominator, funding_denominator_no_impute,
   UN_own_funding_data, volumes_table)
