source("model.R")

# Set baseline parameters ---------------------------------------------

base_pars <- list(
  t_max = 14, # duration of simulation
  n_adults = 0, # no. of adult cohabitants
  n_children = 0, # no. of child cohabitants
  p_immune = 0, # prob. of a priori immunity
  contacts_adult = 3 / 7, # daily no. of contacts
  contacts_child = 3 / 7,
  prevalence = 0.05, # prevalence
  p_transmit = 0.10, # prob. that exposure results in transmission
  p_attack_adult = 0.25, # prob. that index case infects adult
  r_attack_child = 0.50, # relative prob. that index infects child
  r_asymp = 0.50, # relative prob. of infection from asymp. index
  t_incubate = 6, # incubation period (days)
  p_asymptomatic = 0.40, # prob. asymptomatic
  p_hospitalized = 0.10, # prob. hospitalized (if infected)
  p_fatal_if_hosp_adult = 0.05, # prob. fatal if hospitalized
  p_fatal_if_hosp_child = 0.01 
)

family_pars <- list_modify(
  base_pars,
  n_adults = 1,
  n_children = 2
)

# Run simulations -----------------------------------------------------

tic <- Sys.time()

results <- tibble(
  family = c("employee_only", "family_of_4"),
  n_adults = c(0, 1),
  n_children = c(0, 2)
) %>%
  crossing(
    iter = 1:1e3,
    prevalence = c(0.01, 0.05, 0.10),
    daily_contacts = c(3, 15)
  ) %>%
  mutate(
    pars = map(iter, ~ base_pars),
    pars = map2(pars, n_adults, ~ list_modify(.x, n_adults = .y)),
    pars = map2(pars, n_children, ~ list_modify(.x, n_children = .y)),
    pars = map2(pars, prevalence, ~ list_modify(.x, prevalence = .y)),
    pars = map2(pars, daily_contacts, ~ list_modify(.x, contacts_adult = .y, contacts_child = .y))
  ) %>%
  mutate(results = map(pars, model))

toc <- Sys.time()

cat("Ran", nrow(results), "simulations in", toc - tic, "sec.\n")

saveRDS(results, "cache/results.rds")
