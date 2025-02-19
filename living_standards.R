# My Vuong
## DATA CLEANING FOR CONSTRUCTING HOUSEHOLD MPI LIVING STANDARDS

library(tidyverse)
library(haven)
library(foreign)

base_path <- "/Users/macbook/Documents/GitHub/Burkina-Faso-Poverty-Governance/2021 Data"
output_path <- "/Users/macbook/Documents/GitHub/Burkina-Faso-Poverty-Governance/Cleaned Data"

### Load datasets and construct IDs ###
# Individual data with unique household identifiers
ehcvm_individu_bfa2021 <- read_dta(file.path(base_path, "ehcvm_individu_bfa2021.dta"))
basic_id <- ehcvm_individu_bfa2021 %>%
  mutate(household_ID = paste(grappe, menage, vague, sep = "_")) %>%
  select(household_ID, region, province, commune) %>%
  distinct()

# Survey data
s11 <- read_dta(file.path(base_path, "s11_me_bfa2021.dta"))

# Function to create a household variable
create_household_variable <- function(df) {
  df <- df %>%
    mutate(household_ID = paste(grappe, menage, vague, sep = '_')) %>%
    select(-grappe, -menage, -vague)
  return(df)
}

s11 <- create_household_variable(s11) 

# Select relevant columns from s11
s11_selected <- s11 %>% 
  select(household_ID, s11q52__1, s11q52__2, s11q52__3, s11q52__4, s11q52__5, s11q52__6, s11q52__7, s11q52__8, s11q52_autre, s11q54, s11q54_autre, s11q55, s11q28a, s11q30a, s11q26a, s11q26a_autre, s11q26b, s11q33, s11q18, s11q18_autre, s11q19, s11q19_autre, s11q20, s11q20_autre
         )


### Deprivation indicators ###
# Fuel Deprivation
s11_selected <- s11_selected %>%
  mutate(fuel_deprived = if_else(s11q52__1 != 0 | 
                                 s11q52__2 != 0 | 
                                 s11q52__3 != 0 |
                                 s11q52__7 != 0 |
                                 s11q52__8 != 0, 1, 0) # Everything in Others is considered deprived
         ) 

# Sanitation Deprivation
s11_selected$s11q54_autre <- tolower(s11_selected$s11q54_autre)
s11_selected <- s11_selected %>% 
  mutate(sanitation_deprived = ifelse(s11q54 %in% 8:12, 1, 0),
         sanitation_deprived = ifelse(s11q54_autre %in% c('latrine biodigesteur', 'latrine vip une fosse', 'latrines vip double fosse'), 0, sanitation_deprived),
         sanitation_deprived = ifelse(s11q55 == 1, 1, sanitation_deprived)
         )


# Water Deprivation
s11_selected <- s11_selected %>%
  mutate(
    # Double the time to reflect round-trip
    s11q28a = s11q28a*2, 
    s11q30a = s11q30a*2,
    # Handle NA - Assigning time cost of 0 if households get water in-house/yard/from neighbor
    s11q28a = ifelse(s11q26a %in% c(1:3, 5, 7, 9), 0, s11q28a),
    s11q30a = ifelse(s11q26a %in% c(1:3, 5, 7, 9), 0, s11q30a),
    # Determine water deprivation based on the round-trip time exceeding 30 minutes
    water_deprived = ifelse(s11q28a > 30 | s11q30a > 30, 1, 0),
    # Handle NA - non-deprived if either season's round-trip is <= 30 minutes
    water_deprived = case_when(
      is.na(s11q28a) & !is.na(s11q30a) & s11q30a <= 30 ~ 0,
      !is.na(s11q28a) & is.na(s11q30a) & s11q28a <= 30 ~ 0,
      TRUE ~ water_deprived),
    # Even if time cost is < 30, deprived if water is unclean
    water_deprived = ifelse(s11q26a %in% c(6, 9, 10, 12, 13, 18), 1, water_deprived)
    )


# Electricity Deprivation
s11_selected <- s11_selected %>% 
  mutate(electricity_deprived = ifelse(s11q33 == 4, 1, 0)) 

# Housing Material Deprivation
s11_selected <- s11_selected %>%
  mutate(s11q18_autre = tolower(s11_selected$s11q18_autre),
         # Replace irrelevant wall values with NA
         s11q18_autre = ifelse(s11q18_autre %in% c('cecco', 'pompe', 'pas de mrs pour le moment'), NA_character_, s11q18_autre),
         # Wall
         wall_deprived = if_else(s11q18 %in% c(6, 7, 8), 1, 0),
         wall_deprived = if_else(s11q18_autre == 'grillage', 0, wall_deprived),
         # Floor
         floor_deprived = if_else(s11q20 %in% 3:5, 1, 0),
         # Roof
         roof_deprived = if_else(s11q19 %in% c(4, 5, 6, 8), 1, 0),
         roof_deprived = if_else(s11q19_autre == 'Tôles, pailles', 0, wall_deprived)
  )

# Aggregate deprivation across housing components to determine overall housing deprivation
living_standards <- s11_selected %>%
  select(household_ID, ends_with('deprived')) %>%
  mutate(housing_deprived = if_else(rowSums(select(., c(wall_deprived, floor_deprived, roof_deprived))) > 0, 1, 0)) %>%
  select(-wall_deprived, -floor_deprived, -roof_deprived)

### Calculate Multidimensional Poverty Index (MPI) for living standards ###
# We are missing assets indicator. Each of the other indicator has a 1/5 weight
living_standards <- living_standards %>%
  mutate(
    # mpi_living_standards is the traditional MPI score (closer to 1 means more deprived)
    mpi_living_standards = rowSums(across(-household_ID)) * 0.2,
    # Final variable/indicator for living standards is Living_Standards
    # Closer to 0 means more poor
    Living_Standards = 1 - mpi_living_standards
    )

### Merge with basic ID data and save ###
living_standards <- merge(basic_id, living_standards, by='household_ID')
# write.dta(living_standards, file.path(output_path, 'MPI_Living_Standards.dta'))
# Convert to csv for easy viewing on Github repo
write.csv(living_standards, file.path(output_path, 'MPI_Living_Standards.csv'), row.names = FALSE)
