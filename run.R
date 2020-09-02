source("model.R") # for running the model
source("scrape_state_data.R") # for pulling incidence
source("utils.R") # for verifying employee data

# Set baseline parameters ---------------------------------------------

n_iter <- 10 # no. of iterations to run for all employees

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

# Read in employee data
raw_employees <- read_tsv("employees.tsv")
verify_employees(raw_employees)

# Turn employee age and no. dependents into a list of household ages
ages_f <- function(age, n_dependents) {
  # first dependents is assumed adult, 2nd is assumed child
  n_adult <- min(1, n_dependents)
  n_child <- max(0, n_dependents - 1)
  c(rep(age, 1 + n_adult), rep(5, n_child))
}

# Turn employee sex and no. dependents into a list of household sexes
sexes_f <- function(sex, n_dependents) {
  # assume first (adult) dependents is opposite sex
  sexes <- c(sex)

  if (n_dependents > 0 && sex == "M") {
    sexes <- c(sexes, "F")
  } else if (n_dependents > 0 && sex == "F") {
    sexes <- c(sexes, "M")
  }

  # assume all children are male; doesn't matter
  if (n_dependents > 1) {
    sexes <- c(sexes, rep("M", n_dependents - 1))
  }

  sexes
}

employees <- raw_employees %>%
  left_join(incidence, by = "state") %>%
  mutate(
    ages = map2(age, n_dependents, ages_f),
    sexes = map2(sex, n_dependents, sexes_f)
  )

# Run simulations -----------------------------------------------------

tic <- proc.time()

results <- employees %>%
  mutate(
    pars = map(id, ~ base_pars),
    pars = map2(pars, ages, ~ list_modify(.x, ages = .y)),
    pars = map2(pars, sexes, ~ list_modify(.x, sexes = .y)),
    pars = map2(pars, avg_incidence, ~ list_modify(.x, incidence = .y))
  ) %>%
  crossing(iter = 1:n_iter) %>%
  mutate(results = map(pars, model))

results

toc <- proc.time()

cat("Ran", nrow(results), "simulations in:\n")
print(toc - tic)

saveRDS(results, "cache/results.rds")
