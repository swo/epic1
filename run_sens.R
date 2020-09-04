source("model.R") # for running the model
source("scrape_state_data.R") # for pulling incidence
source("utils.R") # for verifying employee data

# Set baseline parameters ---------------------------------------------

n_iter <- 1e4 # no. of iterations to run for all employees

# Load relative risks of hospitalization and death by age
risks_by_age <- readRDS("cache/risks_by_age.rds")

# Set up function to draw parameter values at random
par_ranges <- tribble(
  ~name, ~lower, ~upper,
  "t_max", 21, 21,
  "p_immune", 0.0, 0.10,
  "r_adult", 0.1, 1.0,
  "r_child", 0.1, 1.0,
  "p_attack_adult", 0.15, 0.30,
  "r_attack_child", 0.25, 0.75,
  "r_asymp", 0.25, 0.75,
  "p_asymptomatic", 0.1, 0.7,
  "p_hospitalized", 0.05, 0.20,
  "p_fatal_if_hosp", 0.03, 0.07,
  "r_male", 1.2, 2.0,
  "t_incubate", 4, 8,
  "incidence", 1 / 10000, 1 / 2500
)

integer_vars <- c("t_max", "t_incubate")
integer_idx <- which(par_ranges$name %in% integer_vars)

draw_par <- function() {
  # draw value for each var from its range
  values <- par_ranges %>%
    { runif(nrow(.), .$lower, .$upper) }

  # round the integer values
  values[integer_idx] <- round(values[integer_idx])

  values %>%
    # assign names
    set_names(par_ranges$name) %>%
    as.list() %>%
    # add in the remaining values
    list_modify(
      risks_by_age = risks_by_age,
      ages = c(37),
      sexes = c("M")
    )
}

# Run simulations -----------------------------------------------------

tic <- proc.time()

results <- tibble(
  iter = 1:n_iter,
  par = map(iter, ~ draw_par()),
  results = map(par, model)
)

results

toc <- proc.time()

cat("Ran", nrow(results), "simulations in:\n")
print(toc - tic)

saveRDS(results, "cache/results_sens.rds")
