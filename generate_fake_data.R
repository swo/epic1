library(tidyverse)
source("utils.R")

# Generate fake employee data

# 60% of being in North Carolina; equal prob. everywhere else
state_prob <- rep((1.0 - 0.6) / 49, 50)
state_prob[state.abb == "NC"] <- 0.6
stopifnot(sum(state_prob) == 1.0)

employees <- tibble(id = 1:2000) %>%
  mutate(
    # Ages centered on 37, down to about 20 and up to about 55
    age = round(rnorm(n(), 37, 5)),
    # States, distributed as above
    state = sample(state.abb, n(), replace = TRUE, prob = state_prob),
    # 80% of employees are male
    sex = sample(c("M", "F"), n(), replace = TRUE, prob = c(0.8, 0.2)),
    # No. of dependents is mostly zero (30%), up to 9
    n_dependents = rpois(n(), 0.9)
  )

verify_employees(employees)

write_tsv(employees, "employees.tsv")
