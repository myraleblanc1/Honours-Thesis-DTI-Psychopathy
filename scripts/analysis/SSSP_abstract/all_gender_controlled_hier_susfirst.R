#------------------------------------------------------------------------------
# Hierarchical Regression: All Genders SUS First
# Model 1: FA ~ SUS + Age + Gender + IQ
# Model 2: FA ~ SUS + PCL-R + Age + Gender + IQ
#------------------------------------------------------------------------------

library(tidyverse)

#------------------------------------------------------------------------------
# 1. Load and prepare data (single clean dataset)

all_gender_controlled_hier_sus__data <- read_csv("data/raw/rawdata_prelimSSSP_abstract.csv") |>
  rename(
    age  = Age...6,
    pclr = `PCL-R Total`,
    iq   = IQ,
    sus  = `Total Drug Use`
  ) |>
  filter(
    !is.na(pclr),
    !is.na(FA_mean),
  )

#------------------------------------------------------------------------------
# 2. Identify ROIs

roi_names <- all_gender_controlled_hier_sus__data |>
  distinct(roi) |>
  pull(roi)

#------------------------------------------------------------------------------
# 3. Hierarchical model comparison (ROI-wise)

all_gender_controlled_hierarchical_sus_results <- map_dfr(
  roi_names,
  function(r) {
    
    data_r <- all_gender_controlled_hier_sus__data |> filter(roi == r)
    
    # Base model
    model_1 <- lm(FA_mean ~ sus + age + Gender, data = data_r)
    
    # Extended model
    model_2 <- lm(FA_mean ~ sus + pclr + age + Gender + iq, data = data_r)
    
    # Extract R²
    r2_m1 <- summary(model_1)$r.squared
    r2_m2 <- summary(model_2)$r.squared
    
    # ΔR² and F-test
    anova_res <- anova(model_1, model_2)
    
    tibble(
      roi        = r,
      r2_model1  = r2_m1,
      r2_model2  = r2_m2,
      delta_r2   = r2_m2 - r2_m1,
      f_change   = anova_res$F[2],
      p_change   = anova_res$`Pr(>F)`[2]
    )
  }
)

all_gender_controlled_hierarchical_sus_results


