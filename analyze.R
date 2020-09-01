library(tidyverse)
library(cowplot)

# Load simulations -----------------------------------------------------

results <- readRDS("cache/results.rds")

# Add absences --------------------------------------------------------

compute_absence <- function(results) {
  with(results, {
    case_when(
      # employee dies
      outcome[1] == "fatal" ~ Inf,
      # employee hospitalized, or cohabitant dies
      outcome[1] == "hospitalized" ~ 30,
      "fatal" %in% outcome ~ 30,
      # employee symptomatic, cohabitant hospitalized, or
      # adult cohabitant is symptomatic and there are children
      outcome[1] == "symptomatic" ~ 14,
      "hospitalized" %in% outcome ~ 14,
      any(age == "adult" & outcome == "symptomatic") &
        "child" %in% age ~ 14,
      # any other outcome has no absence
      TRUE ~ 0
    )
  })
}

# Get absence by scenario ---------------------------------------------

absences <- results %>%
  mutate(absence = map_dbl(results, compute_absence)) %>%
  count(family, incidence, r_infect, absence)

absences

absences_plot <- absences %>%
  ggplot(aes(factor(absence), n, fill = family)) +
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
  # get the employee outcome
  mutate(employee_outcome = map_chr(results, ~ .$outcome[1])) %>%
  count(family, incidence, r_infect, employee_outcome)

outcomes

outcomes_plot <- outcomes %>%
  mutate(employee_outcome = factor(employee_outcome,
      levels = c("not_infected", "presymptomatic", "asymptomatic", "symptomatic", "hospitalized", "fatal"),
      labels = c("N.I.", "pre.", "asy.", "sym.", "hosp.", "fatal")
  )) %>%
  ggplot(aes(employee_outcome, n, fill = family)) +
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
  mutate(sympto_plus = employee_outcome %in% c("symptomatic", "hospitalized", "fatal")) %>%
  group_by(family, incidence, r_infect, sympto_plus) %>%
  summarize_at("n", sum) %>%
  mutate(f = n / sum(n)) %>%
  ungroup() %>%
  filter(sympto_plus) %>%
  select(family, incidence, r_infect, f) %>%
  mutate_at("f", ~ scales::percent(., accuracy = 0.01)) %>%
  pivot_wider(names_from = family, values_from = f) %>%
  arrange(r_infect, incidence)

write_tsv(outcomes_table, "results/outcomes.tsv")
