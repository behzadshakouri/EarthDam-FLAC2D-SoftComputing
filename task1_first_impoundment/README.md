# Task 1: first-impoundment response and factor-of-safety surrogates

This package reproduces the soft-computing workflow reported for the first
impoundment analysis of Maku earth dam. It follows the repository conventions
used by `task2_seismic_response` while retaining Task 1's distinct static
response, sample-size, and factor-of-safety experiments.

## Published configuration

- 500 FLAC2D realizations generated from 18 retained uncertain inputs.
- Ten quantities of interest (QoIs).
- Four scalar responses at each QoI: horizontal displacement, vertical
  displacement, horizontal stress, and vertical stress (40 cases).
- Factor of safety as a separate target.
- Sample sizes 50, 100, 150, 200, 300, 400, and 500.
- A 70/30 development/test split; at 200 samples this is 140/60.
- ELM, ELM-ABC, ELM-ACOR, and ELM-IGWO.
- Sigmoid activation, `[-1,1]` scaling, and RMSE fitness.
- Evaluation with R2, RMSE, MAE, and a10.

## Quick start

1. Set local input paths in `config/task1_user_paths.m`.
2. Run `setup_task1`.
3. Run `check_task1_dependencies`.
4. Run `run_task1_smoke_test` before a production experiment.
5. Run `run_task1_production` after confirming the configuration.

Large numerical datasets, generated results, FLAC2D case-study files, FISH
files, and machine-specific paths are not distributed in the canonical
package. Original MATLAB scripts are preserved under `legacy` for provenance
and are not canonical runtime dependencies.

## Data availability

The required private inputs are `outputs_gp.mat` and `PT1_FoS_SCT.xlsx`.
Their contracts are documented in `docs/RAW_DATA_CONTRACT.md`. The complete
database is available from the corresponding author upon reasonable request.

## Related automation

General MATLAB-FLAC2D batch automation is maintained separately at
https://github.com/behzadshakouri/Dam_Model_FLAC2D_Runner.

## Publication

B. Shakouri et al., "A collaborative numerical simulation-soft computing
approach for earth dams first impoundment modeling," *Computers and
Geotechnics*, 164, 105814, 2023.
https://doi.org/10.1016/j.compgeo.2023.105814
