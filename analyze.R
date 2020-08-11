library(tidyverse)

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

# Get absence by scenario
absences <- results %>%
  add_absences() %>%
  group_by(family, prevalence, daily_contacts, iter) %>%
  summarize_at("absence_time", max) %>%
  ungroup() %>%
  count(family, prevalence, daily_contacts, absence_time)

absences

absences_plot <- absences %>%
  ggplot(aes(factor(absence_time), n, fill = family)) +
  facet_grid(rows = vars(prevalence), cols = vars(daily_contacts), labeller = label_both) +
  geom_col(position = "dodge") +
  labs(
    x = "No. days absent", y = "No. simulations",
    title = "Absence by family size, prevalence, and no. daily contacts",
    caption = "Over 2 wk period"
  ) +
  theme_minimal()

ggsave("results/absences.png", plot = absences_plot)

# Get outcomes by scenario
outcomes <- results %>%
  filter(is_employee) %>%
  count(family, prevalence, daily_contacts, outcome)

outcomes

outcomes_plot <- outcomes %>%
  mutate(outcome = factor(outcome,
      levels = c("not_infected", "presymptomatic", "asymptomatic", "symptomatic", "hospitalized", "fatal"),
      labels = c("N.I.", "pre.", "asymp.", "symp.", "hosp.", "fatal")
  )) %>%
  ggplot(aes(outcome, n, fill = family)) +
  facet_grid(rows = vars(prevalence), cols = vars(daily_contacts), labeller = label_both) +
  geom_col(position = "dodge") +
  labs(
    x = "Employee health outcome", y = "No. simulations",
    title = "Outcomes by family size, prevalence, and no. daily contacts",
    caption = "Over 2 wk period. N.I. = not infected. pre. = presymptomatic/incubating."
  ) +
  theme_minimal()

ggsave("results/outcomes.png", plot = outcomes_plot)
