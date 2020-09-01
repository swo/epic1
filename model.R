library(tidyverse)

# Model utility functions ---------------------------------------------

check_pars <- function(pars) {
  with(pars, {
    # Hospitalized must be a subset of symptomatic
    stopifnot(p_hospitalized < 1 - p_asymptomatic)
  })
}

# Main function -------------------------------------------------------

model <- function(pars) {
  # Check parameter validity
  check_pars(pars)

  with(pars, {
    # Compute parameters for each household member
    family_size <- length(ages)
    age_categories <- case_when(
      ages < 18 ~ "child",
      TRUE ~ "adult"
    )

    # Daily prob. of infection for household
    daily_p <- case_when(
      age_categories == "adult" ~ incidence * r_adult,
      age_categories == "child" ~ incidence * r_child
    )

    # In the table of risks by age, which row does each household
    # member fall into?
    age_i <- map_int(ages, ~
      which(. >= risks_by_age$min_age & . <= risks_by_age$max_age)
    )

    # What are the risk ratios for male and female, compared to average?
    # (Change reference from male to average)
    r_sex <- case_when(
      sexes == "M" ~ 2 * r_male / (1 + r_male),
      sexes == "F" ~ 2 / (1 + r_male),
      sexes == "X" ~ 1
    )

    # Compute probability of hospitalization and fatality-if-hosp.
    # from reference risk and age-adjusted risk ratios
    p_hosp_if_symp <- p_hospitalized / (1 - p_asymptomatic) * risks_by_age$r_hosp[age_i] * r_sex
    p_fatal_if_hosp <- p_fatal_if_hosp * risks_by_age$r_fatal_if_hosp[age_i] * r_sex

    # Check lengths
    stopifnot(length(r_sex) == family_size)
    stopifnot(length(daily_p) == family_size)
    stopifnot(length(p_hosp_if_symp) == family_size)
    stopifnot(length(p_fatal_if_hosp) == family_size)

    # Check for infection from outside (earliest is day 1)
    # for each household member
    exposure_day <- rnbinom(family_size, 1, daily_p) + 1
    symptoms_day <- exposure_day + t_incubate

    # Determine (potentially hypothetical) outcomes
    is_symptomatic <- rbernoulli(family_size, 1 - p_asymptomatic)
    is_hospitalized <- is_symptomatic && rbernoulli(1, p_hosp_if_symp)
    is_fatal <- is_hospitalized && rbernoulli(1, p_fatal_if_hosp)

    # Intra-household infections --------------------------------------

    # Determine the index case
    index <- which.min(exposure_day)

    # Determine the attack rate for that person
    p_attack <- p_attack_adult *
      if_else(age_categories[index] == "child", r_attack_child, 1) *
      if_else(is_symptomatic[index], 1, r_asymp)

    # Determine if attacks are successful
    successful_attack <- rbernoulli(family_size, p_attack)

    # If attack successful, set exposure date to minimum of old exposure
    # date and index's symptom date
    exposure_day[successful_attack] <- pmin(
      exposure_day[successful_attack],
      symptoms_day[index]
    )

    # Update symptoms days based on new exposures
    symptoms_day <- exposure_day + t_incubate

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
      age_category = age_categories,
      outcome = outcomes
    )
  })
}
