verify_employees <- function(employees) {
  # Check that input has correct columns
  stopifnot(all(c("age", "state", "sex", "n_dependents") %in% names(employees)))

  with(employees, {
    # Ages should be reasonable
    stopifnot(all(between(age, 1, 100)))
    # States should be known 2-letter abbreviations
    stopifnot(all(state %in% state.abb))
    # Sex should be M or F
    stopifnot(all(sex %in% c("M", "F")))
    # No. dependents should be nonnegative integer
    stopifnot(all(n_dependents == round(n_dependents)))
    stopifnot(all(n_dependents >= 0))
  })
}
