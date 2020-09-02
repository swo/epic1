# Absenteeism model

This model simulates the transmission of COVID-19 to an employee or their
household, transmission within the household, the health outcomes
experienced by members of the household, and the effects of those outcomes
on the employee's absenteeism.

## To do

- Add notes here about how to run employee data

## Getting started

1. Download R
2. Install packages in R: `install.packages(c("tidyverse", "lubridate", "zoo"))`
3. Ensure the input employee data is in the right place (see below)
4. Run `make`
5. Interpret the output file `results/results.tsv`

## Input data

The scripts expect a file `employees.tsv` in this folder. This file should be tab-separated, with at least the following 4 columns:

- `state`: 2-letter abbreviations
- `sex`: either `M` or `F`
- `age`: an integer between 1 and 100
- `n_dependents` (number of dependents): a nonnegative integer

## White papers

- [Paper 1](https://docs.google.com/document/d/1w9Q1MKcgNG0mLcb0bwneyQNo8132W27ZcBNA4NCjRKU/edit)
- [Paper 2](https://docs.google.com/document/d/14IJ0ATm56NdBsJoGL0ofiA9_wM7rX7lH0Pzzg3lru4w/edit)
- [Paper 3](https://docs.google.com/document/d/1uZQOQvJJTNp7CgmsMwJJyToIA7tzr3QXETy6-kyXC9Y/edit)

## File overview

- `model.R`: Main modeling functions
- `run.R`: Runs simulations and stores the results
- `analyze.R`: Loads stored results and produces plots and tables
- `scrape_state_data.R`: Script to scrape incidences by state
- `compute_risks_by_age.R`: Derives certain risk ratios by age
- `generate_fake_data.R`: Generates fake employee data for debugging
- `utils.R`: Utility functions shared across scripts
- `Makefile`: Automated model running using `make`
- `cache/`: Stored simulation results
- `results/`: Output tables
