library(tidyverse)
library(lubridate)

download_data <- function() {
  # Download number of cases, by county and date (which includes county metadata)
  raw_data <- read_csv(
    "https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_confirmed_usafacts.csv",
    col_types = cols(countyFIPS = "c", stateFIPS = "c")
  ) %>%
    filter(countyFIPS != "0")

  # Tidy the cases data: each row is one county/date combination
  cases <- raw_data %>%
    select(-`County Name`, -State, -stateFIPS) %>%
    pivot_longer(cols = -c(countyFIPS), names_to = "date", values_to = "n_cases") %>%
    mutate_at("date", lubridate::mdy)

  # Download the county populations
  denom <- read_csv(
    "https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_county_population_usafacts.csv",
    col_types = cols(countyFIPS = "c")
  ) %>%
    select(countyFIPS, population) %>%
    filter(countyFIPS != "0")

  # Pull out the county metadata (name, FIPS code, state) into a separate object,
  # and add the denominator
  county_metadata <- raw_data %>%
    select(countyFIPS, `County Name`, State) %>%
    distinct() %>%
    left_join(denom, by = "countyFIPS")

  list(
    cases = cases,
    county_metadata = county_metadata
  )

    # left_join(denom, by = "countyFIPS") %>%
    # mutate(daily_rate = if_else(n_cases == 0, 0, n_cases / population)) %>%
    # left_join(county_data, by = "countyFIPS")
}

get_data <- function(fn = "cache/data.rds") {
  if (file.exists(fn)) {
    data <- readRDS(fn)
  } else {
    data <- download_data()
    saveRDS(data, fn, compress = FALSE)
  }

  data
}

get_rate <- function(data, county_name, date) {
  # Confirm there is only 1 county with that name
  county_metadata <- data$county_metadata %>%
    filter(`County Name` == county_name)

  n_counties <- nrow(county_metadata)
  if (n_counties == 0) stop("County name not found")
  if (n_counties > 1) stop("Non-unique county name")

  # Confirm that there are sequential dates
  county_data <- data$cases %>%
    filter(countyFIPS == county_metadata$countyFIPS)

  stopifnot(all(diff(county_data$date) == 1))

  # Get the number of *new* cases per date
  county_data %>%
    left_join(county_metadata, by = "countyFIPS") %>%
    mutate(
      new_cases = c(0, diff(n_cases)),
      incidence = new_cases / population,
      per_incidence = 1 / incidence
    )
}

# Get prevalence in Wake County on July 1
data <- get_data()

rate <- get_rate(
  data,
  "Wake County",
  mdy("07-01-2020")
)

rate %>%
  tail() %>%
  glimpse()
# 1 / rate
