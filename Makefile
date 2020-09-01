results/outcomes.tsv: analyze.R cache/results.rds
	Rscript $<

cache/results.rds: run.R model.R cache/risks_by_age.rds
	Rscript $<

cache/risks_by_age.rds: compute_risks_by_age.R
	Rscript $<
