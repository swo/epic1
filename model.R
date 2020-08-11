library(tidyverse)

source("utils.R")

# Set baseline parameters ---------------------------------------------

base_pars <- list(
  verbose = TRUE,
  t_max = 14, # duration of simulation
  p_immune = 0, # prob. of a priori immunity
  contacts_adult = 3 / 7, # daily no. of contacts (for an adult)
  p_transmit = 0.10, # prob. that exposure results in transmission
  t_incubate = 6, # incubation period (days)
  p_asymptomatic = 0.40, # prob. asymptomatic
  p_hospitalized = 0.10, # prob. hospitalized (if infected)
  p_fatal_if_hosp = 0.02 # prob. fatal if hospitalized
)

rates <- get_rates()

base_pars$prevalence <- get_prevalence(
  rates,
  "Wake County",
  lubridate::mdy("07-01-2020"), # first date for prevalence determination
  base_pars$t_incubate
)

check_pars <- function(pars) {
  with(pars, {
    # Hospitalized must be a subset of symptomatic
    stopifnot(p_hospitalized < 1 - p_asymptomatic)
  })
}

model <- function(pars) {
  check_pars(pars)

  with(pars, {
    # Derived parameters
    # Probability of hospitalization given symptomaticity
    p_hosp_if_symp <- p_hospitalized / (1 - p_asymptomatic)
    # Daily probability of infection
    daily_infect_p <- 1 - (1 - p_transmit) ** (contacts_adult * prevalence)

    # Check for infection from outside (earliest is day 1)
    exposure_day <- rnbinom(1, 1, daily_infect_p) + 1
    symptoms_day <- exposure_day + t_incubate

    # Determine (potentially hypothetical) outcomes
    is_symptomatic <- rbernoulli(1, 1 - p_asymptomatic)
    is_hospitalized <- is_symptomatic && rbernoulli(1, p_hosp_if_symp)
    is_fatal <- is_hospitalized && rbernoulli(1, p_fatal_if_hosp)

    outcome <- case_when(
      exposure_day > t_max ~ "not_infected",
      symptoms_day > t_max ~ "presymptomatic",
      is_fatal ~ "fatal",
      is_hospitalized ~ "hospitalized",
      is_symptomatic ~ "symptomatic",
      !is_symptomatic ~ "asymptomatic"
    )

    outcome
  })
}

tibble(iter = 1:1e3) %>%
  mutate(outcome = map_chr(iter, ~ model(base_pars))) %>%
  count(outcome) %>%
  mutate(f = n / sum(n))
