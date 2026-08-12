# Aggregate and split audit

## Verified modeling scope

- The split assigns 210 complete realizations to development and 90 complete
  realizations to testing.
- Admissibility is response- and location-specific.
- For a detected instability, the onset row and every later row in that
  realization are excluded. This is a cumulative pre-failure mask, not an
  isolated row filter.
- PGA-template reduction and map-min-max fitting operate on development rows
  only. Test realizations are apply-only and are not reduced.
- Reported metrics use only admissible rows from the fixed 90 test
  realizations.

Accordingly, the regression surrogate represents the mechanically admissible
pre-failure response domain. It is not a post-failure predictor.

## Aggregate overwrite repair

`run_all_models` previously wrote the rows from only its current invocation to
the two shared aggregate files. A staged call such as
`run_all_models('ELMABC')` could therefore replace an earlier ELM aggregate.

The runner now calls `rebuild_all_four_method_aggregates`, which reads every
available `MODEL/P#_R#.mat` checkpoint and regenerates:

- one CSV and one MAT aggregate for each of the four methods;
- the compatibility `task2_all_model_*` CSV/MAT pair; and
- the explicit `task2_all_four_methods_*` CSV/MAT pair.

The combined files may be partial during a staged run. Their `report` table
records the case count and completion status for each method. A complete run
contains 70 cases per method and 280 rows in total.
