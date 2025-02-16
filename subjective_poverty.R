# My Vuong
# UNDP Policy Lab
# Subjective Poverty

library(haven)
library(tidyverse)
library(dplyr)
library(knitr)
library(ggplot2)
library(corrplot)
library(foreign)

setwd('~/Documents/Policy Lab/2021 Data')

### Loading in datasets
ehcvm_individu_bfa2021 <- read_dta("~/Documents/Policy Lab/2021 Data/ehcvm_individu_bfa2021.dta")

s20 <-read_dta('s20a_me_bfa2021.dta')
s00 <- read_dta("s00_me_bfa2021.dta")
s01 <- read_dta("s01_me_bfa2021.dta")

# Employment (main and secondary)
s04b <- read_dta("s04b_me_BFA2021.dta")
s04c <- read_dta("s04c_me_BFA2021.dta")

# Non-employment income
s05 <- read_dta("s05_me_BFA2021.dta")

# Creating unique household identification numbers 
create_household_variable <- function(df) {
  df <- df %>%
    mutate(household = paste(grappe, menage, vague, sep = '_')) %>%
    select(-grappe, -menage, -vague)
  return(df)
}

# Only selecting relevant variables from each dataframes
# Assuming all 9999 values are coded NAs, we only know for sure in s04bc
s00 <- create_household_variable(s00) %>% 
  rename(region = s00q01, province = s00q02, commune = s00q03) %>%
  select(household, region, province, commune)

s01 <- create_household_variable(s01) %>%
  select(household, s01q01, s01q04a) %>%
  rename(gender = s01q01, age = s01q04a)

s04b <- create_household_variable(s04b) %>%
  select(household, s04q43, s04q43_unite, s04q45, s04q45_unite, s04q47, s04q47_unite, s04q49, s04q49_unite) %>%
  mutate_all(~ifelse(. == 9999, NA, .))

s04c <- create_household_variable(s04c) %>%
  select(household, s04q58, s04q58_unite, s04q60, s04q60_unite ,s04q62, s04q62_unite, s04q64, s04q64_unite) %>%
  mutate_all(~ifelse(. == 9999, NA, .))

# s05 is annual income  
s05 <- create_household_variable(s05) %>%
  select(household, s05q02, s05q04, s05q06, s05q08, s05q10, s05q12, s05q14) %>%
  mutate_all(~ifelse(. == 9999, NA, .))

s20 <- create_household_variable(s20) %>%
  mutate_all(~ifelse(. == 9999, NA, .))


# Merging dataframes
merged_s00_s20 <- merge(s00, s20, by = "household", all = TRUE)
merged_all <- merge(merged_s00_s20, s01, by = 'household', all = TRUE)

# Number of household survey responses by regions
hhld_response_by_region <- merged_s00_s20 %>%
  group_by(region) %>%
  summarise(household_survey_response = n())
mean(hhld_response_by_region$household_survey_response)
sd(hhld_response_by_region$household_survey_response)

# Number of individual respondents by regions
indiv_response_by_region <- merged_all %>%
  group_by(region) %>%
  summarise(indiv_survey_response = n())
mean(indiv_response_by_region$indiv_survey_response)
sd(indiv_response_by_region$indiv_survey_response)

# Demographics by Region
gender_distribution <- merged_all %>%
  group_by(region, gender) %>%
  summarise(survey_response = n()) %>%
  group_by(region) %>%
  mutate(percentage = (survey_response / sum(survey_response)) * 100) %>%
  print(n = 26)

age_distribution <- merged_all %>%
  group_by(region) %>%
  summarise(mean_age = mean(age, na.rm = TRUE))

ggplot(merged_all, aes(x = factor(region), y = age)) +
  geom_boxplot() +
  ggtitle("Boxplot of Age by Region") +
  xlab("Region") +
  ylab("Age")


######## Getting household income
## We need to aggregate income in sections 4bc and 20 to annual level

col_to_process_4b <- c('s04q43_unite', 's04q45_unite', 's04q47_unite', 's04q49_unite')

s04b <- s04b %>% 
  mutate(across(all_of(col_to_process_4b), 
                ~ case_when(
                  . == 1 ~ 52,
                  . == 2 ~ 12,
                  . == 3 ~ 4,
                  . == 4 ~ 1,
                  TRUE ~ NA_real_
                ),
                .names = "{col}_frequency"))

s04b <- s04b %>%
  mutate(total_annual_q43 = s04q43_unite_frequency * s04q43,
         total_annual_q45 = s04q45_unite_frequency * s04q45,
         total_annual_q47 = s04q47_unite_frequency * s04q47,
         total_annual_q49 = s04q49_unite_frequency * s04q49) %>%
  select(household, total_annual_q43, total_annual_q45, total_annual_q47, total_annual_q49)

s04b <- s04b %>%
  group_by(household) %>%
  summarise_all(sum, na.rm = TRUE) %>%
  rowwise() %>%
  mutate(total_main_inc = sum(c_across(-household), na.rm = TRUE)) 

s04b <- s04b %>%
  select(household, total_main_inc)


# These variables capture different time units
col_to_process_4c <- c('s04q58_unite', 's04q60_unite', 's04q62_unite', 's04q64_unite')

s04c <- s04c %>% 
  mutate(across(all_of(col_to_process_4c), 
                ~ case_when(
                  . == 1 ~ 52,
                  . == 2 ~ 12,
                  . == 3 ~ 4,
                  . == 4 ~ 1,
                  TRUE ~ NA_real_
                ),
                .names = "{col}_frequency"))

s04c <- s04c %>%
  mutate(total_annual_q58 = s04q58_unite_frequency * s04q58,
         total_annual_q60 = s04q60_unite_frequency * s04q60,
         total_annual_q62 = s04q62_unite_frequency * s04q62,
         total_annual_q64 = s04q64_unite_frequency * s04q64) %>%
  select(household, total_annual_q58, total_annual_q60, total_annual_q62, total_annual_q64)

s04c <- s04c %>%
  group_by(household) %>%
  summarise_all(sum, na.rm = TRUE) %>%
  rowwise() %>%
  mutate(total_2nd_inc = sum(c_across(-household), na.rm = TRUE)) 

s04c <- s04c %>%
  select(household, total_2nd_inc)


# 0s are NAs
s05 <- s05 %>% 
  group_by(household) %>%
  summarise_all(sum, na.rm = TRUE) %>%
  rowwise() %>%
  mutate(total_non_empl_inc = sum(c_across(-household), na.rm = TRUE))

s05 <- s05 %>%
  select(household, total_non_empl_inc)

# Income 
df_empl_inc <- merge(s04b, s04c, by='household', all = TRUE)
df_total_inc <- merge(df_empl_inc, s05, by='household', all = TRUE)

df_total_inc <- df_total_inc %>%
  rowwise() %>%
  mutate(total_income = sum(c_across(-household))) %>%
  select(household, total_income) %>%
  mutate(across(everything(), ~ replace(., . == 0, NA)))

s20_min_inc <- s20 %>% 
  mutate(min_annual_inc = s20aq06 * 12) %>%
  select(household, min_annual_inc)

df_final <- merge(df_total_inc, s20_min_inc, by='household')

# subj_poverty is 0 for poor (total income is less than minimum level), 1 for not poor
df_final <- df_final %>%
  mutate(subj_poor = case_when(
    total_income >= min_annual_inc ~ 1,
    total_income < min_annual_inc ~ 0
  ))

### Some analysis
df_final <- merge(df_final, s00, by='household')

## Show distribution of indexes by region
df_final %>% 
  group_by(region, subj_poor) %>%
  summarise(count = n()) %>%
  mutate(percentage = count / sum(count) * 100) %>%
  print(n=39)

df_final %>%
  group_by(region) %>%
  summarise(mean_subj_poor = mean(subj_poor, na.rm = TRUE)) %>%
  ggplot(aes(x = region, y = mean_subj_poor)) +
  geom_bar(stat = "identity", fill = "skyblue", color = "black") +
  ggtitle("Simple Mean of Subjective Poverty Index (SPI) by Region") +
  xlab("Region") +
  ylab("Mean SPI")

# Stacked bar plot of distribution
df_final$region <- factor(df_final$region)

ggplot(df_final, aes(x = region, fill = factor(subj_poor))) +
  geom_bar(position = "stack", alpha = 0.7) +
  ggtitle("Stacked Bar Plot of Subjective Poverty Distribution by Region") +
  xlab("Region") +
  ylab("Count") +
  scale_fill_manual(values = c("lightblue", "lightgreen"), labels = c("0", "1"))

### Testing different correlations
s20_descriptive <- s20 %>%
  select(household, s20aq02, s20aq03, s20aq04, s20aq05) 

## Recoded multiple-scaled questions
# s20aq05: If you were asked to rank your own household on a welfare scale from poor to rich, how would you rank it
# 1. Rich, 2.Medium, 3. Poor, 4. Very poor, 5. Don't know
# Rescale for question 5 so that a score that is closer to 0 means more subjective poverty

s20_test <- s20_descriptive %>%
  mutate(s20aq05 = replace(s20aq05, s20aq05 == 5, NA)) %>%
  mutate(across(-household, ~replace(., . == 6, NA))) %>% # 6. Not concerned 
  mutate(across(-c(household, s20aq05), ~recode(., `1` = 5, `2` = 4, `3` = 3, `4` = 2, `5` = 1))) %>%
  mutate(s20aq05 = recode(s20aq05, `1` = 4, `2` = 3, `3` = 2, `4` = 1)) %>% # Being rich ~ higher score
  mutate(subj_poor_s20aq05 = (s20aq05-1) / (4 - 1))

df_corr <- merge(df_final, s20_test, by='household')

# Pairwise heatmap
df_corr <- df_corr %>% select(subj_poor, s20aq02, s20aq03, s20aq04, s20aq05, subj_poor_s20aq05)
cor_matrix <- cor(df_corr, use = 'pairwise.complete.obs')
corrplot(cor_matrix, method = 'color', type = 'upper', addCoef.col = TRUE, tl.cex = 0.8)

# Final Dataframe
df_subj_poor_q05 <- s20_test %>%
  select(household, subj_poor_s20aq05)

subjective_poverty <- merge(df_final, df_subj_poor_q05, by='household')

basic_id <- ehcvm_individu_bfa2021 %>%
  mutate(household_ID = paste(grappe, menage, vague, sep = "_")) %>%
  select(household_ID, region, province, commune) %>%
  distinct()

subjective_poverty <- subjective_poverty %>%
  rename(household_ID = household,
         subj_poor_miq = subj_poor,
         subj_poor_scale = subj_poor_s20aq05) %>%
  select(-region, -province, -commune)



subjective_poverty <- merge(subjective_poverty, basic_id, by='household_ID')
write.dta(subjective_poverty, 'Subj_Poverty.dta')
