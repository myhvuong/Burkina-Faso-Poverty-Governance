# My Vuong
## DATA CLEANING FOR CONSTRUCTING HOUSEHOLD MPI LIVING STANDARDS

library(tidyverse)
library(haven)
library(foreign)
setwd('~/Documents/Policy Lab/2021 Data')

### Loading in datasets and constructing IDs
ehcvm_individu_bfa2021 <- read_dta("~/Documents/Policy Lab/2021 Data/ehcvm_individu_bfa2021.dta")

basic_id <- ehcvm_individu_bfa2021 %>%
  mutate(household_ID = paste(grappe, menage, vague, sep = "_")) %>%
  select(household_ID, region, province, commune) %>%
  distinct()

s11 <- read_dta("s11_me_bfa2021.dta")

create_household_variable <- function(df) {
  df <- df %>%
    mutate(household_ID = paste(grappe, menage, vague, sep = '_')) %>%
    select(-grappe, -menage, -vague)
  return(df)
}

s11 <- create_household_variable(s11) 

s11_selected <- s11 %>% 
  select(household_ID, s11q52__1, s11q52__2, s11q52__3, s11q52__4, s11q52__5, s11q52__6, s11q52__7, s11q52__8, s11q52_autre, s11q54, s11q54_autre, s11q55, s11q28a, s11q30a, s11q26a, s11q26a_autre, s11q26b, s11q33, s11q18, s11q18_autre, s11q19, s11q19_autre, s11q20, s11q20_autre)

# ==============================================================================
## Deprived if the household cook with dung, wood and charcoal.
# 1. Collected wood 2. Wood purchased 3. Charcoal 4. Gas 5. Electricity 6. Oil
# 7. Animal Waste 8. Other
s11_selected <- s11_selected %>%
  mutate(fuel_deprived = if_else(s11q52__1 != 0 | 
                                 s11q52__2 != 0 | 
                                 s11q52__3 != 0 |
                                 s11q52__7 != 0 |
                                 s11q52__8 != 0, 1, 0)) # Everything in Others is considered deprived

## The household's sanitation facility is not improved or it is improved but shared with other household
# A person is considered to have access to improved sanitation if the
# household has some type of flush toilet or latrine, or ventilated improved pit or composting toilet, provided that they are not shared. If the household does not satisfy these conditions, then it is considered deprived in sanitation
# For question 54, considering options 8, 9, 10, 11, 12 to be unimproved.
# s11q55: Does the household share these toilets with other households? 1. Yes 2.No

s11_selected$s11q54_autre <- tolower(s11_selected$s11q54_autre)

s11_selected <- s11_selected %>% 
  mutate(sanitation_deprived = ifelse(s11q54 %in% 8:12, 1, 0))

s11_selected$sanitation_deprived[s11_selected$s11q54_autre %in% c('latrine biodigesteur', 'latrine vip une fosse', 'latrines vip double fosse')] <- 0

s11_selected$sanitation_deprived[s11_selected$s11q55 == 1] <- 1

# ==============================================================================
## Deprived if the household's source of drinking water is not safe (clean water - piped water, public tap, borehole or pump, protected well, protected spring or rainwater) and it is not within a distance of 30 minutes (round-trip)
# s11q26: What is the household's main source of drinking water?
# s11q30: What is the time taken (in minutes) to get to the source of drinking water during the rainy season?
# s11q28: dry season?

s11_selected$s11q28a <- s11_selected$s11q28a*2 # Multiplying to get round-trip time
s11_selected$s11q30a <- s11_selected$s11q30a*2

# Assigning time cost of 0 if households get water in-house/yard/from neighbor
s11_selected[s11_selected$s11q26a %in% c(1:3, 5, 7, 9), c('s11q28a', 's11q30a')] <- 0

## Deprived if time cost is > 30 minutes
s11_selected <- s11_selected %>%
  mutate(water_deprived = ifelse(s11q28a > 30 |
                                 s11q30a > 30, 1, 0))

# In 28a and 30a (time costs in dry and wet season), if one column is NA and the other is <= 30 --> non-deprived
s11_selected <- s11_selected %>%
  mutate(
    water_deprived = case_when(
      is.na(s11q28a) & !is.na(s11q30a) & s11q30a <= 30 ~ 0,
      !is.na(s11q28a) & is.na(s11q30a) & s11q28a <= 30 ~ 0,
      TRUE ~ water_deprived
    )
  )

# Even if t < 30, deprived if water is unclean -- considering this as the stronger condition
s11_selected <- s11_selected %>%
  mutate(water_deprived = ifelse(s11q26a %in% c(6, 9, 10, 12, 13, 18), 1, water_deprived))

# ==============================================================================
## Deprived if household not connected to an electricity network
s11_selected <- s11_selected %>% 
  mutate(electricity_deprived = ifelse(s11q33 == 4, 1, 0)) 

# ==============================================================================
## Deprived if the household has inadequate housing materials (dirt, sand, or dung) in any of the three components: floor, roof, or walls

s11_selected$s11q18_autre <- tolower(s11_selected$s11q18_autre)

######### Walls
# Replacing values that are irrelevant
q18_replace <- c('cecco', 'pompe', 'pas de mrs pour le moment')
s11_selected$s11q18_autre[s11_selected$s11q18_autre %in% q18_replace] <- NA

s11_selected <- s11_selected %>%
  mutate(wall_deprived = if_else(s11q18 %in% c(6, 7, 8), 1, 0))
# values in c() are considered non-deprived
s11_selected$wall_deprived[s11_selected$s11q18_autre %in% c('grillage')] <- 0

######### Flooring
s11_selected <- s11_selected %>%
  mutate(floor_deprived = if_else(s11q20 %in% 3:5, 1, 0))

######### Roof
s11_selected <- s11_selected %>%
  mutate(roof_deprived = if_else(s11q19 %in% c(4:6, 8), 1, 0))

s11_selected$roof_deprived[s11_selected$s11q19_autre == 'Tôles, pailles'] <- 0

living_standards <- s11_selected %>%
  select(household_ID, ends_with('deprived'))

living_standards <- living_standards %>%
  mutate(housing_deprived = if_else(rowSums(select(., c(wall_deprived, floor_deprived, roof_deprived))) > 0, 1, 0))

living_standards <- living_standards %>%
  select(-wall_deprived, -floor_deprived, -roof_deprived)

# ==============================================================================
# Getting living standards MPI for each household
# We are missing assets indicator. Each of the other indicator has a 1/5 weight

living_standards <- living_standards %>%
  mutate(mpi_living_standards = rowSums(across(-household_ID)) * 0.2)

# Final variable/indicator for living standards is Living_Standards
# Closer to 0 means more poor
living_standards <- living_standards %>%
  mutate(Living_Standards = 1 - mpi_living_standards) # mpi_living_standards is the traditional MPI score (closer to 1 means more deprived)

living_standards <- merge(living_standards, basic_id, by='household_ID')

write.dta(living_standards, 'MPI_Living_Standards.dta')