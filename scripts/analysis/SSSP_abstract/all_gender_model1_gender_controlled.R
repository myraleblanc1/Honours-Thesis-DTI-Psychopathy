#------------------------------------------------------------------------------
# MODEL 1 (Exploratory): All Genders, Gender-Controlled
# FA_mean ~ PCL-R + Age + Gender
#------------------------------------------------------------------------------

library(tidyverse)
library(broom)
library(car)
library(ggplot2)

#------------------------------------------------------------------------------
# 1. Load raw data

dti_raw_all <- read_csv("data/raw/rawdata_prelimSSSP_abstract.csv")

#------------------------------------------------------------------------------
# 2. Prepare analysis dataset (all genders, complete cases only)

dti_fa_all_clean <- dti_raw_all |>
  rename(
    age  = Age...6,
    pclr = `PCL-R Total`
  ) |>
  filter(
    !is.na(pclr),
    !is.na(age),
    !is.na(FA_mean),
    !is.na(Gender)
  )

# Confirm final N
n_distinct(dti_fa_all_clean$subject_id)

#------------------------------------------------------------------------------
# 3. Fit Model 1 (Gender-adjusted, exploratory)

models_fa_m1_gender <- dti_fa_all_clean |>
  group_by(roi) |>
  group_map(
    ~ lm(FA_mean ~ pclr + age + Gender, data = .x),
    .keep = TRUE
  )

roi_names_all <- dti_fa_all_clean |>
  distinct(roi) |>
  pull(roi)

names(models_fa_m1_gender) <- roi_names_all

#------------------------------------------------------------------------------
# 4. Tidy regression results

results_fa_m1_gender <- map_dfr(
  names(models_fa_m1_gender),
  ~ tidy(models_fa_m1_gender[[.x]]) |>
    mutate(
      roi   = .x,
      model = "Model 1 (All Genders, Gender-Controlled)"
    )
)

#------------------------------------------------------------------------------
# 5. Extract PCL-R effects + FDR correction

results_fa_m1_gender_pclr <- results_fa_m1_gender |>
  filter(term == "pclr") |>
  mutate(p_fdr = p.adjust(p.value, method = "fdr"))

# Clean display table
results_fa_m1_gender_pclr |>
  select(
    roi,
    estimate,
    std.error,
    statistic,
    p.value,
    p_fdr
  ) |>
  arrange(p_fdr)

#------------------------------------------------------------------------------
# 6. Assumption checks

## Linearity
ggplot(dti_fa_all_clean, aes(x = pclr, y = FA_mean)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~ roi) +
  theme_minimal()

## Homoscedasticity
plot(models_fa_m1_gender$JHU_UF_L, which = 1)
plot(models_fa_m1_gender$JHU_UF_R, which = 1)
plot(models_fa_m1_gender$JHU_CgC_L, which = 1)
plot(models_fa_m1_gender$JHU_CgC_R, which = 1)

## Normality of residuals (Q–Q)
plot(models_fa_m1_gender$JHU_UF_L, which = 2)
plot(models_fa_m1_gender$JHU_UF_R, which = 2)
plot(models_fa_m1_gender$JHU_CgC_L, which = 2)
plot(models_fa_m1_gender$JHU_CgC_R, which = 2)

## Multicollinearity
vif(models_fa_m1_gender$JHU_UF_L)
vif(models_fa_m1_gender$JHU_UF_R)
vif(models_fa_m1_gender$JHU_CgC_L)
vif(models_fa_m1_gender$JHU_CgC_R)

#------------------------------------------------------------------------------
# 7. Preregistered outlier diagnostics (leverage + standardized residuals)

outlier_summary_fa_m1_gender <- map_dfr(
  names(models_fa_m1_gender),
  function(r) {
    
    model <- models_fa_m1_gender[[r]]
    
    std_resid <- rstandard(model)
    leverage  <- hatvalues(model)
    
    n <- nobs(model)
    p <- length(coef(model)) - 1
    
    lev_thresh <- 2 * (p + 1) / n
    
    outlier_flag <- abs(std_resid) > 2.5 & leverage > lev_thresh
    
    tibble(
      roi = r,
      n_flagged = sum(outlier_flag),
      flagged_indices = if (any(outlier_flag)) {
        paste(which(outlier_flag), collapse = ", ")
      } else {
        NA_character_
      }
    )
  }
)

outlier_summary_fa_m1_gender
