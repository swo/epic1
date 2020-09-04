library(tidyverse)
library(lubridate)
library(zoo)

# Function get_incidence() gets the 7-day averaged incidence for each
# state, downloading more recent data if required

# Get data, including an average windowed over 7 days by default
download_data <- function(avg_window = 7) {
  # Download the state populations
  denom <- read_csv(
    "https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_county_population_usafacts.csv"
  ) %>%
    select(state = State, population) %>%
    group_by(state) %>%
    summarize_at("population", sum)

  # Download number of cases, by county and date (which includes county metadata)
  raw_data <- read_csv(
    "https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_confirmed_usafacts.csv"
  )

  incidence <- raw_data %>%
    select(-countyFIPS, -`County Name`, -stateFIPS) %>%
    rename(state = State) %>%
    # Summarize counts over states (rather than counties)
    group_by(state) %>%
    summarize_if(is.numeric, sum) %>%
    # Tidy the cases data: each row is one state/date combination
    pivot_longer(cols = -state, names_to = "date", values_to = "total_cases") %>%
    mutate_at("date", mdy) %>%
    # Add the populations
    left_join(denom, by = "state") %>%
    # Count new cases by day
    arrange(state, date) %>%
    group_by(state) %>%
    mutate(
      new_cases = c(0, diff(total_cases)),
      avg_new_cases = rollmean(new_cases, avg_window, na.pad = TRUE, align = "right")
    ) %>%
    ungroup() %>%
    mutate(
      avg_incidence = avg_new_cases / population,
      avg_incidence_per = 1 / avg_incidence
    ) %>%
    select(state, population, date, avg_incidence, avg_incidence_per)

  incidence
}

get_incidence <- function(date = today() - ddays(2), fn = "cache/state_incidences.rds") {
  data <- NULL

  # If the file exists, load it, and check if it is up-to-date
  if (file.exists(fn)) {
    data <- readRDS(fn)

    # If the desired date isn't in the data, download again
    if (max(data$date) < date) {
      data <- NULL
    }
  }

  # If the file does not exist or was out of date, need to download it
  if (is.null(data)) {
    data <- download_data()

    if (max(data$date) < date) {
      stop(str_glue("Desired date {date} is beyond range of data, which has latest date {max(data$date)}"))
    }

    saveRDS(data, fn, compress = FALSE)
  }

  data %>%
    filter(date == !!date)
}
