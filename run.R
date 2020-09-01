source("model.R")

# Set baseline parameters ---------------------------------------------

# Load relative risks of hospitalization and death by age
risks_by_age <- readRDS("cache/risks_by_age.rds")

base_pars <- list(
  ages = c(35), # ages of household, with employee first
  sexes = c("M"), # sex of household members
  t_max = 21, # duration of simulation
  p_immune = 0, # prob. of a priori immunity
  r_adult = 0.25, # rel. risk of infection for adult
  r_child = 0.25, # rel. risk of infection for child
  p_attack_adult = 0.25, # prob. that index case infects adult
  r_attack_child = 0.50, # rel. risk that index case infects child
  r_asymp = 0.50, # rel. risk of infection from asymp. index case
  t_incubate = 6, # incubation period (days)
  p_asymptomatic = 0.40, # prob. asymptomatic
  p_hospitalized = 0.10, # prob. hospitalized (if infected)
  p_fatal_if_hosp = 0.05, # prob. fatal if hospitalized
  r_male = 1.6, # rel. risk of hosp/fatal for male (ref. female)
  risks_by_age = risks_by_age
)

# Run simulations -----------------------------------------------------

tic <- Sys.time()

results <- tibble(
  family = c("employee_only", "family_of_4"),
  ages = list(c(35), c(35, 35, 5, 8)),
  sexes = list(c("M"), c("M", "F", "X", "X"))
) %>%
  crossing(
    iter = 1:1e3,
    incidence = c(1 / 2500, 1 / 10000),
    r_infect = c(0.25, 1.0)
  ) %>%
  mutate(
    pars = map(iter, ~ base_pars),
    pars = map2(pars, incidence, ~ list_modify(.x, incidence = .y)),
    pars = map2(pars, ages,      ~ list_modify(.x, ages =      .y)),
    pars = map2(pars, sexes,     ~ list_modify(.x, sexes =     .y)),
    pars = map2(pars, r_infect,  ~ list_modify(.x, r_adult =   .y)),
    pars = map2(pars, r_infect,  ~ list_modify(.x, r_child =   .y))
  ) %>%
  mutate(results = map(pars, model))

results

toc <- Sys.time()

cat("Ran", nrow(results), "simulations in", toc - tic, "sec.\n")

saveRDS(results, "cache/results.rds")
