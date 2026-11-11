# Task 4: Scaled-Dam IAA Simulations

This MATLAB package prepares and screens 450 scaled-dam IAA simulations and
combines them with the 300 Task 2 prototype simulations for scale-aware
multi-output response prediction. Raw databases and generated model files
remain private.

## Confirmed database

- Scale 0.25: Task 4 simulations 1--150
- Scale 0.50: Task 4 simulations 151--300
- Scale 1.50: Task 4 simulations 301--450
- Outputs: 10 points by 7 responses = 70 variable-length histories per simulation

## Run

```matlab
cd task4_scaled_dam_iaa
report = run_task4_validated_workflow("full");
```

Before the private audit, copy `config/task4_local_paths.m.example` to
`config/task4_local_paths.m`, set the private input paths, and select external
roots for full results and generated figures.

## History preparation and screening

The audit reads v7.3 MAT-file histories selectively to avoid loading the
entire database into memory. Older MAT formats use the in-memory adapter.

`prepare_task4_history` removes nonfinite time-response pairs, sorts and
deduplicates times, and interpolates onto 0.01:0.01:20 s using the Task 2
coverage checks. It constructs `cummax(abs(response))` and applies Task 2's
response-specific v4.2 detector. The onset row and all later rows are excluded.
An isolated initial NaN therefore does not automatically discard a history.

Finite values with magnitude >= 1e30 are bounded for numerical processing
after carrying the last finite sentinel forward over a missing/nonfinite
terminal tail to the supplied time vector's end (`padded_tail_samples`).
If the time vector itself ends early with a finite failure sentinel, that
sentinel is also carried forward on the canonical grid through 20 seconds.
Ordinary finite responses are never extended this way. Sentinel values
impose a hard exclusion, including interpolation samples that touch them.
They are not treated as admissible response values. Insufficient coverage is
reported explicitly in the audit, with no unrestricted extrapolation.

The history CSV retains raw-prefix diagnostics (`clean_length`,
`raw_prefix_usable`) separately from `admissible_samples`, `onset_time_s`,
`screening_status`, and `is_usable`. The latter means at least two canonical
samples survive screening, not a guarantee of physical validity. Preparation
errors are recorded in `screening_message`. Detector settings are in
`config/task4_config.m`. The same documented settings are applied at every
scale; transferring them across scales is identified as a study limitation.
The preparation function returns the envelope and its admissibility mask;
downstream modeling must use the mask.

## Scale-aware modeling

`analysis/build_task4_scale_aware_dataset.m` constructs the four-scale,
750-record data set. It samples each record at 100 locations on the common
20-s time grid, stores the response-specific admissibility masks, and keeps the
70 outputs in point-major order (`P1R1` through `P10R7`). Its 17 predictors are
14 material variables, water level, running PGA, and geometric scale in that
order. Model fitting at each monitoring point uses rows admissible for all
seven local responses, so a failed point does not remove valid rows at other
points.

The final architecture uses ten FMRVR models, one for each monitoring point;
each model predicts the seven local responses together. FMRVR is fitted
directly without a separate ridge-regression backbone. The earlier development
entry point is retained as `analysis/run_task4_pointwise_fmrvr_pilot.m`.
`src/modeling/predict_task4_pointwise_fmrvr.m`
runs all ten models in one call and returns all 70 responses. Comparator pilots
use the same record split and response masks.

`analysis/run_task4_pointwise_fmrvr_validation.m` reproduces the ten accepted
outer tests. `analysis/generate_task4_pointwise_fmrvr_figures.m` creates the
repeated-validation, point/response, output-map, scale-audit, and Task 2-style
all-70 figures directly from the saved production predictions and CSV files.
The point/response panels include one-standard-deviation error bars computed
from the ten scale-stratified outer splits. Manuscript metrics use three
decimals, while the saved CSV files retain full precision.
`analysis/generate_task4_geometry_scale_figure.m` creates the Task 4-specific
cross-section/mesh composite and the four discrete scale sketches from the
cited reference sources in `analysis/figure_sources/`.
The validation also exports every record's partition assignment, Task 2-style
`a10`, and prediction timing from five warmups followed by 100 measured calls
of the complete ten-model, 70-output predictor. Use
`run_task4_validated_workflow("artifacts")` to rebuild figures and
`run_task4_validated_workflow("verify")` to check saved evidence.

Ten repeated record-level, scale-stratified splits give mean R2 = 0.8842 +/-
0.0042 for the final constrained multi-output FMRVR system. Mean nRMSE and
nMAE are 0.0556 and 0.0371, mean a10 is 0.4698, and about 57 of 67 nonconstant
outputs exceed R2 = 0.8.
The reviewed numerical results are in `reference_results/`. The manuscript does not
claim superiority over ELM-IGWO, RF, or SVR because those methods have not been
rerun with identical masks, partitions, preprocessing, and tuning budgets.
Leave-one-scale-out evaluation is likewise reserved for a separate transfer
study. See `docs/IMPLEMENTATION_STATUS.md`.

The adapted FMRVR solver's BSD license is retained under `third_party/`; see
`THIRD_PARTY_NOTICES.md`.

The reusable workflow does not modify source histories. Simulation recovery
and raw-data checks remain with the private source data. See
`docs/VALIDATION_RUN_20260919.md`.

Raw MAT files, generated reports, and machine-specific paths are excluded.
