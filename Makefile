.PHONY: clean

MODEL_DEPENDENCIES = model.R scrape_state_data.R utils.R cache/risks_by_age.rds

all: results/results.tsv results/results_long.tsv results/results_sens.tsv

# Regular results -----------------------------------------------------

results/results.tsv: analyze.R cache/results.rds
	Rscript $<

cache/results.rds: run_employees.R employees.tsv $(MODEL_DEPENDENCIES)
	Rscript $<

cache/risks_by_age.rds: compute_risks_by_age.R
	Rscript $<

# "Long" simulation results -------------------------------------------

results/results_long.tsv: analyze_long.R cache/results_long.rds
	Rscript $<

cache/results_long.rds: run_long.R $(MODEL_DEPENDENCIES)
	Rscript $<

# Sensitivity analysis ------------------------------------------------

results/results_sens.tsv: analyze_sens.R cache/results_sens.rds
	Rscript $<

cache/results_sens.rds: run_sens.R $(MODEL_DEPENDENCIES)
	Rscript $<

clean:
	rm -rf cache/* results/*
