# Repository status

Last structural and execution audit: 2026-11-10

## Task 1: first impoundment

- Paper-derived portable MATLAB workflow is present.
- Response production covers 10 QoIs, four responses, four methods, and sample
  sizes 50, 100, 150, 200, 300, 400, and 500.
- FoS production covers four methods across the same seven sample sizes.
- Published Tables 7 and 8 are included as restrained CSV reference targets.
- Seventy original MATLAB scripts are retained under `legacy` for provenance.
- Raw datasets, generated checkpoints, FLAC2D case files, FISH files, and
  machine-specific operational paths are excluded from the canonical package.
- MATLAB execution and published-value parity validation remain pending and
  are tracked in the Task 1 release checklist.

## Task 2: seismic response

- Complete paper-specific MATLAB workflow, safe-domain screening, fixed split,
  four production methods, twelve neuron-sweep configurations, plotting,
  tests, and reference metrics are present.
- Version-pinned YPEA and I-GWO dependencies and their licenses are included.
- Raw FLAC2D histories and generated checkpoints are excluded.
- Before tagging a release, rerun the documented dependency, synthetic, and
  private-data validation commands in the target MATLAB environment.

## Task 3 validated workflow

- The accepted analysis uses 150 unequal-duration synthetic motions, 100
  samples per record, 33 predictors, and 70 positive nondecreasing response
  envelopes.
- Ten ridge-free point-wise FMRVR models jointly predict the seven responses
  at each extraction point. Across ten deterministic 105/45 record splits,
  mean held-out R2 is 0.8574 (SD 0.0135), nRMSE is 0.0450, and nMAE is 0.0257.
- Exact split assignments, Task 2-compatible a10, 5-warmup/100-run prediction
  timing, compact CSV evidence, and deterministic figure generators are part
  of the canonical workflow.
- The earlier ridge-plus-residual result is retained only as development
  history. The accepted runner no longer regenerates its presentation files.

## Task 4 validated workflow

- The combined data set contains 750 records at scale factors 0.25, 0.50,
  1.00, and 1.50, with 17 predictors and 70 response envelopes.
- Ten ridge-free point-wise FMRVR models currently reach mean held-out R2 of
  0.8842 (SD 0.0042) over ten scale-stratified 600/150 record splits.
- A canonical full/artifact/verify runner, exact split export, Task 2-compatible
  metrics and timing, figure generators, and strict artifact checks are present.
- Comparator pilots produced with superseded predictors are excluded from
  algorithm-ranking claims. Leave-one-scale-out testing remains useful future
  work for extrapolation beyond the represented scale factors, but it is not
  part of the present interpolation claim.
- On 2026-11-10, the dependency check, synthetic self-test, and canonical
  artifact verification all passed in MATLAB. Verification reproduced ten
  splits, 67 nonconstant outputs, and mean held-out R2 of 0.8842.

The corresponding Task 3 checks also passed on 2026-11-10 and reproduced ten
splits, 67 nonconstant outputs, and mean held-out R2 of 0.8574.

## Historical Task 3 and Task 4 integration record (2026-09-19)

The observations below record the initial imported packages and are retained
for provenance. Later validated workflows and evidence above supersede the
early statements that modeling or predictor construction was pending.

- Imported `Task3_FMRVR_precommit_20260830.zip` and
  `Task4_scaled_dam_IAA_preliminary_20260830.zip` into their task directories.
- Configured ignored local path overrides for the external private MAT-files.
- Task 3 synthetic FMRVR smoke test passed in MATLAB R2020a (30 samples,
  six outputs). Several solver fits reached the smoke-test iteration cap;
  this verifies execution, not convergence or predictive performance.
- Task 4 synthetic metadata and sentinel-cleaning test passed in MATLAB R2020a.
- Task 3 private-data preparation passed: 150-by-9 features and 150-by-70
  finite targets. QC identified 3,216 truncated histories and three constant
  outputs (P8R5, P9R5, P10R5); computed and stored PGA agreed for all inputs.
  These results use the supplied reduction rules and do not validate them.
- Task 4 private-data audit completed for 450 simulations and 31,500
  histories: 26,933 truncated histories, one unusable history, and zero
  response/time length mismatches. QC tables are exported to local ignored
  results directories. At that initial stage, no production performance claim
  had yet been established.
- At import, Task 3 acceleration units and response reductions required review;
  the final workflow explicitly interprets acceleration in `g` and implements
  fold-specific preprocessing.
- At import, Task 4 modeling awaited its predictor contract and cross-scale
  data linkage. The validated 17-predictor, 750-record workflow supersedes that
  initial limitation.

### Task 4 screening update

- Added Task 2-derived paired-sample interpolation, cumulative response
  envelopes, and per-response v4.2 onset masking.
- Added terminal padding with the last finite failure sentinel when a failed
  response is shorter than its supplied time vector or ends in nonfinite values.
  Sentinel-supported samples remain excluded from the admissible mask.
- MATLAB R2020a synthetic checks passed for initial-NaN recovery, sentinel
  exclusion, NaN-tail padding, short-vector padding, and insufficient coverage.
- Updated screening and failed-tail extension are complete: 30,612 histories
  have usable screened samples, 888 fail coverage, and 2,612 were extended
  using existing finite failure sentinels. The repository consumes a validated
  private MAT-file and contains no case-specific data-repair behavior.
  The earlier counts above describe raw-prefix QC, not this assessment.
- Task 3 production completed after fold-local scaling, output-subspace
  preprocessing, and a zero-basis solver fix. The saved model reproduces all
  exported test predictions. The provisional September result was later
  superseded by the accepted point-wise workflow documented above. See each
  task's `docs/VALIDATION_RUN_20260919.md` for the historical execution record.

## Previously recorded repository-wide audit checks

- Both tasks contain README, citation, license, version, setup, dependency,
  production, test, data-contract, legacy, and reference-result components.
- No `.mat`, `.xlsx`, `.xls`, `.dat`, or `.fis` data/model files are committed
  within either task package.
- Published reference results are stored as auditable CSV files.
- Task-specific code and historical scripts remain separated.
- General FLAC2D batch execution remains in `Dam_Model_FLAC2D_Runner`.

The 2026-11-10 audit includes execution of both validated artifact verifiers
with the configured private datasets. Raw data remain outside Git.
