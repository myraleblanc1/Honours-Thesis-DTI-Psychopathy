#------------------------------------------------------------------------------
# ALL GENDER (Primary Analysis) — Model 2

library(tidyverse)
library(broom)
library(car)
library(ggplot2)

roi_fa_allgender_raw <- read_csv("data/raw/rawdata_prelimSSSP_abstract.csv")

roi_fa_allgender <- roi_fa_allgender_raw |>
  rename(
    age  = Age...6,
    pclr = 'PCL-R Total',
    iq   = IQ,
    sus  = 'Total Drug Use'
  ) |>
  filter(
    !is.na(pclr),
    !is.na(age),
    !is.na(iq),
    !is.na(sus),
    !is.na(FA_mean)
  )

n_distinct(roi_fa_allgender$subject_id)
#------------------------------------------------------------------------------
# Model 2: FA_mean ~ pclr + age + IQ + SUS (males only)

roi_fa_model2_allgender <- roi_fa_allgender |>
  group_by(roi) |>
  group_map(
    ~ lm(FA_mean ~ pclr + age + iq + sus, data = .x),
    .keep = TRUE
  )

roi_names_allgender <- roi_fa_allgender |>
  distinct(roi) |>
  pull(roi)

names(roi_fa_model2_allgender) <- roi_names_allgender

results_roi_fa_model2_allgender <- map_dfr(
  names(roi_fa_model2_allgender),
  ~ tidy(roi_fa_model2_allgender[[.x]]) |>
    mutate(
      roi = .x,
      model = "Model 2 (Males Only: +IQ +SUS)"
    )
)

results_roi_fa_model2_pclr_allgender <- results_roi_fa_model2_allgender |>
  filter(term == "pclr") |>
  mutate(p_fdr = p.adjust(p.value, method = "fdr"))

results_roi_fa_model2_pclr_allgender |>
  select(
    roi,
    estimate,
    std.error,
    statistic,
    p.value,
    p_fdr
  ) |>
  arrange(p_fdr)

