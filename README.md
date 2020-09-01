# Absenteeism model

This model simulates the transmission of COVID-19 to an employee or their
household, transmission within the household, the health outcomes
experienced by members of the household, and the effects of those outcomes
on the employee's absenteeism.

## To do

- Understand inputs from Epic
- Clean up incidence scraper
    - Change name from `utils.R` to something more accurate

## White papers

- [Paper 1](https://docs.google.com/document/d/1w9Q1MKcgNG0mLcb0bwneyQNo8132W27ZcBNA4NCjRKU/edit)
- [Paper 2](https://docs.google.com/document/d/14IJ0ATm56NdBsJoGL0ofiA9_wM7rX7lH0Pzzg3lru4w/edit)
- [Paper 3](https://docs.google.com/document/d/1uZQOQvJJTNp7CgmsMwJJyToIA7tzr3QXETy6-kyXC9Y/edit)

## File overview

- `model.R`: Main modeling functions
- `run.R`: Runs simulations and stores the results
- `analyze.R`: Loads stored results and produces plots and tables
- `utils.R`: Script to scrape incidences in different counties
- `compute_risks_by_age.R`: Derives certain risk ratios by age
- `Makefile`: Automated model running using `make`
- `cache/`: Stored simulation results
- `results/`: Output figures and tables
