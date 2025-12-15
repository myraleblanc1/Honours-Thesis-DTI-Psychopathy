#------------------------------------------------------------------------------
# MALES ONLY (Primary Analysis)

library(tidyverse)
library(broom)
library(car)
library(ggplot2)


roi_fa_male_raw <- read_csv("data/raw/rawdata_prelimSSSP_abstract.csv") 

roi_fa_male_n <- roi_fa_male_raw|>
  filter(Gender == 0)

roi_fa_male <- roi_fa_male_raw|>
  filter(Gender == 0) |>                     # <-- male-only filter
  rename(
    age  = Age...6,
    pclr = 'PCL-R Total'
  ) |>
  filter(
    !is.na(pclr),
    !is.na(age),
    !is.na(FA_mean)
  )

n_distinct(roi_fa_male$subject_id)  
n_distinct(roi_fa_male_n$subject_id) 
#------------------------------------------------------------------------------
# Model 1: FA_mean ~ pclr + age (males only)

roi_fa_model1_male <- roi_fa_male |>
  group_by(roi) |>
  group_map(~ lm(FA_mean ~ pclr + age, data = .x), .keep = TRUE)

roi_names_male <- roi_fa_male |>
  distinct(roi) |>
  pull(roi)

names(roi_fa_model1_male) <- roi_names_male

results_roi_fa_model1_male <- map_dfr(
  names(roi_fa_model1_male),
  ~ tidy(roi_fa_model1_male[[.x]]) |>
    mutate(roi = .x, model = "Model 1 (Males Only)")
)

results_roi_fa_model1_pclr_male <- results_roi_fa_model1_male |>
  filter(term == "pclr") |>
  mutate(p_fdr = p.adjust(p.value, method = "fdr"))

# View clean results table
results_roi_fa_model1_pclr_male |>
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
#------------------------------------------------------------------------------
# ASSUMPTION TESTING
# Model 1: FA_mean ~ pclr + age
# Sample: Males only
#------------------------------------------------------------------------------

library(ggplot2)
library(car)

#------------------------------------------------------------------------------
# 1. Linearity
# Visual inspection of FA vs PCL-R relationship by ROI

ggplot(roi_fa_male, aes(x = pclr, y = FA_mean)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~ roi) +
  theme_minimal()

#------------------------------------------------------------------------------
# 2. Homoscedasticity
# Residuals vs fitted values

plot(roi_fa_model1_male$JHU_UF_L, which = 1)
plot(roi_fa_model1_male$JHU_UF_R, which = 1)
plot(roi_fa_model1_male$JHU_CgC_L, which = 1)
plot(roi_fa_model1_male$JHU_CgC_R, which = 1)

#------------------------------------------------------------------------------
# 3. Normality of residuals
# Q–Q plots (primary diagnostic)

plot(roi_fa_model1_male$JHU_UF_L, which = 2)
plot(roi_fa_model1_male$JHU_UF_R, which = 2)
plot(roi_fa_model1_male$JHU_CgC_L, which = 2)
plot(roi_fa_model1_male$JHU_CgC_R, which = 2)

# Optional: Shapiro–Wilk tests (run but not emphasized in reporting)
shapiro.test(residuals(roi_fa_model1_male$JHU_UF_L))
shapiro.test(residuals(roi_fa_model1_male$JHU_UF_R))
shapiro.test(residuals(roi_fa_model1_male$JHU_CgC_L))
shapiro.test(residuals(roi_fa_model1_male$JHU_CgC_R))

#------------------------------------------------------------------------------
# 4. Multicollinearity
# Variance Inflation Factors (VIF)

vif(roi_fa_model1_male$JHU_UF_L)
vif(roi_fa_model1_male$JHU_UF_R)
vif(roi_fa_model1_male$JHU_CgC_L)
vif(roi_fa_model1_male$JHU_CgC_R)

#------------------------------------------------------------------------------
# 5. Influential observations (preregistered outlier diagnostics)

outlier_results_male <- map_dfr(
  names(roi_fa_model1_male),
  function(r) {
    
    model <- roi_fa_model1_male[[r]]
    
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

outlier_results_male


