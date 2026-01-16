#------------------------------------------------------------------------------
# Hierarchical Regression: Male-Only
# Model 1: FA ~ PCL-R + Age
# Model 2: FA ~ PCL-R + Age + IQ + SUS
#------------------------------------------------------------------------------

library(tidyverse)

#------------------------------------------------------------------------------
# 1. Load and prepare data (single clean dataset)

male_controlled_hier_data <- read_csv("data/raw/rawdata_prelimSSSP_abstract.csv") |>
  filter(Gender == 0) |>
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

roi_names <- male_controlled_hier_data |>
  distinct(roi) |>
  pull(roi)

#------------------------------------------------------------------------------
# 3. Hierarchical model comparison (ROI-wise)

male_controlled_hierarchical_results <- map_dfr(
  roi_names,
  function(r) {
    
    data_r <- male_controlled_hier_data |> filter(roi == r)
    
    # Base model
    model_1 <- lm(FA_mean ~ pclr + age, data = data_r)
    
    # Extended model
    model_2 <- lm(FA_mean ~ pclr + age + iq + sus, data = data_r)
    
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

male_controlled_hierarchical_results <- 
  male_controlled_hierarchical_results |>
  mutate(
    p_fdr = p.adjust(p_change, method = "fdr")
  )

male_controlled_hierarchical_results
