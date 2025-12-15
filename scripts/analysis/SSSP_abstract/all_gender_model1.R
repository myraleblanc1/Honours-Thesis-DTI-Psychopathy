#ALL Genders Included

library(tidyverse)
library(broom)

roi_fa_raw <- read_csv("data/raw/rawdata_prelimSSSP_abstract.csv")

roi_fa <- roi_fa_raw |>
  rename(
    age = Age...6,
    pclr = 'PCL-R Total'
  ) |>
  filter(
    !is.na(pclr),
    !is.na(age),
    !is.na(FA_mean)
  )
n_distinct(roi_fa$subject_id)  
n_distinct(roi_fa_raw$subject_id) 
#------------------------------------------------------------------------------
# Model 1: FA_mean ~ pclr + age

roi_fa_model1 <- roi_fa |>
  group_by(roi) |>
    group_map(~ lm(FA_mean ~ pclr + age, data = .x), .keep = TRUE)

names(roi_fa_model1) <- unique(roi_fa$roi)

results_roi_fa_model1 <- map_dfr(
  names(roi_fa_model1),
  ~ tidy(roi_fa_model1[[.x]]) %>% mutate(roi = .x, model = "Model 1")
)

results_roi_fa_model1_pclr <- results_roi_fa_model1 %>%
  filter(term == "pclr") %>%
  mutate(p_fdr = p.adjust(p.value, method = "fdr"))


results_roi_fa_model1_pclr %>%
  select(
    roi,
    estimate,
    std.error,
    statistic,
    p.value,
    p_fdr
  ) %>%
  arrange(p_fdr)

#------------------------------------------------------------------------------
#Assumption Testing for Model 1: FA_mean ~ pclr + age

#Linearity
library(ggplot2)
ggplot(roi_fa, aes(x = pclr, y = FA_mean)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~ roi)

#Homoscedasticity
plot(roi_fa_model1$JHU_UF_L, which = 1)
plot(roi_fa_model1$JHU_UF_R, which = 1)
plot(roi_fa_model1$JHU_CgC_R, which = 1)
plot(roi_fa_model1$JHU_CgC_L, which = 1)

#Normality of Residuals
plot(roi_fa_model1$JHU_UF_L, which = 2)
plot(roi_fa_model1$JHU_UF_R, which = 2)
plot(roi_fa_model1$JHU_CgC_R, which = 2)
plot(roi_fa_model1$JHU_CgC_L, which = 2)
shapiro.test(residuals(roi_fa_model1$JHU_UF_L))
shapiro.test(residuals(roi_fa_model1$JHU_UF_R))
shapiro.test(residuals(roi_fa_model1$JHU_CgC_R))
shapiro.test(residuals(roi_fa_model1$JHU_CgC_L))

#Multicollinearity
library(car)
vif(roi_fa_model1$JHU_UF_L)
vif(roi_fa_model1$JHU_UF_R)
vif(roi_fa_model1$JHU_CgC_R)
vif(roi_fa_model1$JHU_CgC_L)

#Outliers
outlier_results <- map_dfr(
  names(roi_fa_model1),
  function(r) {
    
    model <- roi_fa_model1[[r]]
    
    # standardized residuals
    std_resid <- rstandard(model)
    
    # leverage (hat values)
    leverage <- hatvalues(model)
    
    # sample size and number of predictors
    n <- nobs(model)
    p <- length(coef(model)) - 1
    
    # leverage threshold
    lev_thresh <- 2 * (p + 1) / n
    
    # joint outlier criterion
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

outlier_results


