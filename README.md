# Epic model

This model simulates the transmission of COVID-19 to an employee or their
household, transmission within the household, the health outcomes
experienced by members of the household, and the effects of those outcomes
on the employee's absenteeism.

## To do

- Clean up rates calculator

## White papers

- [Paper 1](https://docs.google.com/document/d/1w9Q1MKcgNG0mLcb0bwneyQNo8132W27ZcBNA4NCjRKU/edit)
- [Paper 2](https://docs.google.com/document/d/14IJ0ATm56NdBsJoGL0ofiA9_wM7rX7lH0Pzzg3lru4w/edit)

## File overview

- `model.R`: Main modeling functions
- `run.R`: Runs simulations and stores the results
- `analyze.R`: Loads stored results and produces plots and tables
- `cache/`: Stored simulation results
- `results/`: Output figures and tables
- `utils.R`: Functions utilized by multiple files

## Notes

- [COVID-19 Forecasting Hub](https://covid19forecasthub.org/data/) is used by CDC, 538, etc.
- [Zoltar](https://zoltardata.com/model/159) is the API for the Hub
- Relative risks [Nature paper](https://www.nature.com/articles/s41586-020-2521-4)
