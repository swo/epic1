library(tidyverse)

# https://www.cdc.gov/coronavirus/2019-ncov/covid-data/investigations-discovery/hospitalization-death-by-age.html
# https://www.cdc.gov/coronavirus/2019-ncov/covid-data/covidview/index.html

risks <- tribble(
  ~min_age, ~max_age, ~rr_hosp, ~rr_death,
  0, 4, 1 / 4, 1 / 9,
  5, 17, 1 / 9, 1 / 16,
  18, 29, 1, 1,
  30, 39, 2, 4,
  40, 49, 3, 10,
  50, 64, 4, 30,
  65, 74, 5, 90,
  75, 84, 8, 220,
  85, Inf, 13, 630
) %>%
  # Adjust to that 30-39 is the reference class
  mutate(
    rr_hosp = rr_hosp / rr_hosp[min_age == 30],
    rr_death = rr_death / rr_death[min_age == 30],
  ) %>%
  # Add rel. risk of death given hospitalization
  mutate(rr_death_hosp = rr_death / rr_hosp)

risks

saveRDS(risks, "cache/risks_by_age.rds", compress = FALSE)
