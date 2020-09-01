library(tidyverse)

# Load simulations -----------------------------------------------------

raw_results <- readRDS("cache/results.rds")

# Add absences and employee outcomes ----------------------------------

compute_absence <- function(results) {
  with(results, {
    case_when(
      # employee dies
      outcome[1] == "fatal" ~ Inf,
      # employee hospitalized, or cohabitant dies
      outcome[1] == "hospitalized" ~ 30,
      "fatal" %in% outcome ~ 30,
      # employee symptomatic, cohabitant hospitalized, or
      # adult cohabitant is symptomatic and there are children
      outcome[1] == "symptomatic" ~ 14,
      "hospitalized" %in% outcome ~ 14,
      any(age == "adult" & outcome == "symptomatic") &
        "child" %in% age ~ 14,
      # any other outcome has no absence
      TRUE ~ 0
    )
  })
}

compute_employee_outcome <- function(results) results$outcome[1]

results <- raw_results %>%
  mutate(
    incidence_1_per = 1 / incidence,
    absence = map_dbl(results, compute_absence),
    employee_outcome = map_chr(results, compute_employee_outcome),
    any_absence = absence > 0,
    sympto_plus = employee_outcome %in% c("symptomatic", "hospitalized", "fatal")
  )

results_table <- results %>%
  select(incidence_1_per, r_infect, family, any_absence, sympto_plus) %>%
  group_by(incidence_1_per, r_infect, family) %>%
  summarize_at(c("any_absence", "sympto_plus"), sum)

write_tsv(results_table, "results/results.tsv")
