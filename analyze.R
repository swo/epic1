library(tidyverse)
library(cowplot)

# Load simulations -----------------------------------------------------

results <- readRDS("cache/results.rds") %>%
  unnest(cols = c(results))

# Add absences --------------------------------------------------------

add_absences <- function(df) {
  mutate(df, absence_time = case_when(
      outcome %in% c("not_infected", "presymptomatic", "asymptomatic") ~ 0,
      is_employee & outcome == "fatal" ~ Inf,
      is_employee & outcome == "hospitalized" ~ 30,
      is_employee & outcome == "symptomatic" ~ 14,
      !is_employee & outcome == "fatal" ~ 30,
      !is_employee & outcome == "hospitalized" ~ 14,
      !is_employee & outcome == "symptomatic" ~ 0
  ))
}

# Get absence by scenario ---------------------------------------------

absences <- results %>%
  add_absences() %>%
  group_by(family, incidence, r_infect, iter) %>%
  summarize_at("absence_time", max) %>%
  ungroup() %>%
  count(family, incidence, r_infect, absence_time)

absences

absences_plot <- absences %>%
  ggplot(aes(factor(absence_time), n, fill = family)) +
  facet_grid(
    rows = vars(incidence),
    cols = vars(r_infect),
    labeller = label_both
  ) +
  geom_col(position = "dodge") +
  labs(
    x = "No. days absent",
    y = "No. simulations",
    title = "Absence by family size, incidence, and relative risk",
    caption = "Over 2 wk period"
  ) +
  theme_cowplot() +
  theme(
    legend.title = element_blank(),
    legend.position = c(0.85, 0.9)
  )

ggsave("results/absences.png", plot = absences_plot, width = 5, height = 4)

# Get outcomes by scenario --------------------------------------------

outcomes <- results %>%
  filter(is_employee) %>%
  count(family, incidence, r_infect, outcome)

outcomes

outcomes_plot <- outcomes %>%
  mutate(outcome = factor(outcome,
      levels = c("not_infected", "presymptomatic", "asymptomatic", "symptomatic", "hospitalized", "fatal"),
      labels = c("N.I.", "pre.", "asy.", "sym.", "hosp.", "fatal")
  )) %>%
  ggplot(aes(outcome, n, fill = family)) +
  facet_grid(rows = vars(incidence), cols = vars(r_infect), labeller = label_both) +
  geom_col(position = "dodge") +
  labs(
    x = "Employee health outcome",
    y = "No. simulations",
    title = "Outcomes by family size, incidence, and relative risk",
    caption = "Over 2 wk period. N.I. = not infected. pre. = presymptomatic/incubating."
  ) +
  theme_cowplot() +
  theme(
    legend.title = element_blank(),
    legend.position = c(0.85, 0.9)
  )

ggsave("results/outcomes.png", plot = outcomes_plot, width = 5, height = 4)

# Make a table of outcomes

outcomes_table <- outcomes %>%
  mutate(sympto_plus = outcome %in% c("symptomatic", "hospitalized", "fatal")) %>%
  group_by(family, incidence, r_infect, sympto_plus) %>%
  summarize_at("n", sum) %>%
  mutate(f = n / sum(n)) %>%
  ungroup() %>%
  filter(sympto_plus) %>%
  select(family, incidence, r_infect, f) %>%
  mutate_at("f", ~ scales::percent(., accuracy = 1)) %>%
  pivot_wider(names_from = family, values_from = f) %>%
  arrange(r_infect, incidence)

write_tsv(outcomes_table, "results/outcomes.tsv")
