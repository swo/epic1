source("model.R") # for running the model
source("scrape_state_data.R") # for pulling incidence
source("utils.R") # for verifying employee data

# Set baseline parameters ---------------------------------------------

n_iter <- 1e4 # no. of iterations to run for all employees

# Load relative risks of hospitalization and death by age
risks_by_age <- readRDS("cache/risks_by_age.rds")

# Specify epidemiological/simulation parameters
base_pars <- list(
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

# Get disease incidence by state
incidence <- get_incidence() %>%
  select(state, avg_incidence)

pars <- list_modify(
  base_pars,
  t_max = 30 * 6, # six months
  ages = c(37),
  sexes = "M",
  incidence = incidence$avg_incidence[incidence$state == "NC"]
)

# Run simulations -----------------------------------------------------

tic <- proc.time()

results <- tibble(
  iter = 1:n_iter,
  results = map(iter, ~ model(pars))
)

results

toc <- proc.time()

cat("Ran", nrow(results), "simulations in:\n")
print(toc - tic)

saveRDS(results, "cache/results_long.rds")
