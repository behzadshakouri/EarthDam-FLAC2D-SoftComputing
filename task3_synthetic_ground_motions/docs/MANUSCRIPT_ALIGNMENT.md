# Manuscript Alignment Checklist

The manuscript must agree with the final cumulative response-envelope
implementation on the following:

- 150 synthetic ground motions with unequal native durations;
- common simulation-level pre-runaway screening, with all 48 affected
  simulations retained up to the common boundary;
- 100 equally weighted samples per record, producing 15,000 rows;
- 10 extraction points, seven response families, 70 outputs in P-major order,
  67 nonconstant outputs, and three constant pore-pressure outputs;
- positive nondecreasing envelope definitions for displacement, stress,
  pore-water pressure, and strain;
- 16 complete-record plus 17 time-varying predictors;
- ten ridge-free point-wise FMRVR models, each jointly predicting seven
  responses;
- response transform selected independently for each point in three
  development-record folds;
- final nonnegative cumulative-maximum projection;
- ten deterministic 105/45 record-level outer splits;
- exported assignments for every record and outer split;
- primary mean $R^2=0.8574$, SD 0.0135, nRMSE 0.0450, nMAE 0.0257, and
  $a_{10}=0.3648$;
- about 57 of 67 nonconstant outputs above $R^2=0.8$ and 27 above 0.9;
- scalar-demand and ridge-plus-residual results labeled only as development
  benchmarks;
- Task 2-compatible `a10` and timing based on five warmups and 100 measured
  full all-70 predictions;
- Ha and Zhang (2019) attribution and third-party license; and
- exclusion of raw FLAC2D files and proprietary dependencies from GitHub.

Numerical claims must agree with the `compact_pointwise_fmrvr_*.csv` files in
`reference_results` and pass `run_task3_validated_workflow("verify")` before
release.
