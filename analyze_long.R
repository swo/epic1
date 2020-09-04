library(tidyverse)

# Load simulations -----------------------------------------------------

raw_results <- readRDS("cache/results_long.rds")

results <- raw_results %>%
  unnest(cols = c(results))

results_table <- results %>%
  count(outcome) %>%
  mutate(f = scales::percent(n / sum(n), accuracy = 0.1))

results_table

write_tsv(results_table, "results/results_long.tsv")
