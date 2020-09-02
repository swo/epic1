results/results.tsv: analyze.R cache/results.rds
	Rscript $<

cache/results.rds: run.R employees.tsv model.R scrape_state_data.R utils.R cache/risks_by_age.rds
	Rscript $<

cache/risks_by_age.rds: compute_risks_by_age.R
	Rscript $<
