library(tidyverse)

# Model utility functions ---------------------------------------------

check_pars <- function(pars) {
  with(pars, {
    # Hospitalized must be a subset of symptomatic
    stopifnot(p_hospitalized < 1 - p_asymptomatic)
  })
}

# Compute derived parameters and add them to the parameter list
derive_pars <- function(pars) {
  with(pars, {
    list_modify(
      pars,
      # Prob. hospitalized if symptomatic
      p_hosp_if_symp = p_hospitalized / (1 - p_asymptomatic)
    )
  })
}

# Main function -------------------------------------------------------

model <- function(pars) {
  # Check parameter validity
  check_pars(pars)
  # Add derived parameters
  pars <- derive_pars(pars)

  with(pars, {
    # Compute parameters for each household member
    family_size = 1 + n_adults + n_children
    ages <- c(rep("adult", 1 + n_adults), rep("child", n_children))
    stopifnot(length(ages) == family_size)

    # Daily prob. of infection for household
    daily_p <- case_when(
      ages == "adult" ~ incidence * r_adult,
      ages == "child" ~ incidence * r_child
    )

    p_fatal_if_hosp <- case_when(
      ages == "adult" ~ p_fatal_if_hosp_adult,
      ages == "child" ~ p_fatal_if_hosp_child
    )

    # Check for infection from outside (earliest is day 1)
    # for each household member
    exposure_day <- rnbinom(family_size, 1, daily_p) + 1
    symptoms_day <- exposure_day + t_incubate

    # Determine (potentially hypothetical) outcomes
    is_symptomatic <- rbernoulli(family_size, 1 - p_asymptomatic)
    is_hospitalized <- is_symptomatic && rbernoulli(1, p_hosp_if_symp)
    is_fatal <- is_hospitalized && rbernoulli(1, p_fatal_if_hosp)

    # Determine the household index case (if any)
    if (min(symptoms_day) <= t_max) {
      index <- which.min(symptoms_day)

      # Index case has the chance to infect all other members
      p_attack <- case_when(
        ages == "adult" ~ p_attack_adult,
        ages == "child" ~ p_attack_adult * r_attack_child
      )

      # If asymptomatic, downgrade transmissivity
      if (!is_symptomatic[index]) p_attack <- p_attack * r_asymp

      # Index case can't infect themselves
      p_attack[index] <- 0

      # Determine if attacks "successful"
      attacks <- rbernoulli(family_size, p_attack)

      # If successful, set exposure day to earlier of existing exposure
      # day and index's symptoms day
      exposure_day[attacks] <- pmin(
        exposure_day[attacks],
        symptoms_day[index]
      )

      symptoms_day <- exposure_day + t_incubate
    }

    outcomes <- case_when(
      exposure_day > t_max ~ "not_infected",
      symptoms_day > t_max ~ "presymptomatic",
      is_fatal ~ "fatal",
      is_hospitalized ~ "hospitalized",
      is_symptomatic ~ "symptomatic",
      !is_symptomatic ~ "asymptomatic"
    )

    tibble(
      id = 1:family_size,
      is_employee = c(TRUE, rep(FALSE, family_size - 1)),
      age = ages,
      outcome = outcomes
    )
  })
}
