library(tidyverse)

# Load simulations -----------------------------------------------------

raw_results <- readRDS("cache/results_sens.rds")

results <- raw_results %>%
  unnest_wider(col = results) %>%
  mutate(symplus = outcome %in% c("symptomatic", "hospitalized", "fatal")) %>%
  select(iter, par, symplus) %>%
  # unnest_longer(col = par) %>%
  unnest_longer(
    col = par,
    values_to = "value",
    indices_to = "par"
  ) %>%
  filter(map_lgl(value, ~ class(.)[1] == "numeric")) %>%
  unnest(cols = c(value))

raw_results %>%
  unnest_wider(col = results) %>%
  count(outcome)

safe_wilcox <- function(x, g) {
  if (length(unique(g)) == 1) {
    list(
      slope = NA_real_,
      p_value = 1
    )
  } else {
    list(
      slope = median(x[g]) / median(x[!g]),
      p_value = wilcox.test(x ~ g)$p.value
    )
  }
}

results_table <- results %>%
  group_by(par) %>%
  summarize(
    x = list(value),
    g = list(symplus)
  ) %>%
  # remove fixed values
  filter(map_lgl(x, ~ length(unique(.)) > 1)) %>%
  mutate(
    test = map2(x, g, safe_wilcox),
    slope = map_dbl(test, ~ .$slope),
    p_value = map_dbl(test, ~ .$p_value),
    p_adj = p.adjust(p_value, "BH")
  ) %>%
  select(par, slope, p_value, p_adj)

results_table

write_tsv(results_table, "results/results_sens.tsv")
