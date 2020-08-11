library(lubridate)

download_rates <- function() {
  cases <- read_csv(
    "https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_confirmed_usafacts.csv",
    col_types = cols(countyFIPS = "c", stateFIPS = "c")
  ) %>%
    filter(countyFIPS != "0")

  county_data <- cases %>%
    select(countyFIPS, `County Name`, State)

  cases <- cases %>%
    select(-`County Name`, -State, -stateFIPS)

  denom <- read_csv(
    "https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_county_population_usafacts.csv",
    col_types = cols(countyFIPS = "c")
  ) %>%
    select(countyFIPS, population) %>%
    filter(countyFIPS != "0")

  rates <- cases %>%
    pivot_longer(cols = -c(countyFIPS), names_to = "date", values_to = "n_cases") %>%
    mutate_at("date", lubridate::mdy) %>%
    left_join(denom, by = "countyFIPS") %>%
    mutate(daily_rate = if_else(n_cases == 0, 0, n_cases / population)) %>%
    left_join(county_data, by = "countyFIPS")

  rates
}

get_rates <- function(fn = "cache/rates.rds") {
  if (file.exists(fn)) {
    rates <- readRDS(fn)
  } else {
    rates <- download_rates()
    saveRDS(rates, fn, compress = FALSE)
  }

  rates
}

get_prevalence <- function(rates, county_name, date, infectious_period) {
  county_rates <- rates %>%
    filter(
      `County Name` == county_name,
      between(date, !!date - ddays(infectious_period), !!date)
    )

  n_fips <- length(unique(county_rates$countyFIPS))

  if (n_fips == 0) stop("County name not found")
  if (n_fips > 1) stop("Non-unique county name")

  sum(county_rates$daily_rate)
}
