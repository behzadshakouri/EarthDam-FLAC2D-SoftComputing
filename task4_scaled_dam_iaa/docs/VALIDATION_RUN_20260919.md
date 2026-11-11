# Task 4 local audit — 2026-09-19

MATLAB R2020a processed all 450 simulations and 31,500 response histories.
The v7.3 reader loads histories individually. Preparation uses Task 2's
canonical grid, paired finite-sample cleanup, cumulative absolute envelope,
and response-specific v4.2 instability detector.

## Final audit results

| Quantity | Count |
|---|---:|
| Histories audited | 31,500 |
| Raw prefixes truncated at an invalid value | 26,933 |
| Response/time length mismatches | 0 |
| Histories with usable screened samples | 30,612 |
| Histories still failing time coverage | 888 |
| Histories extended using an existing failure sentinel | 2,612 |

The initial full run found 3,501 coverage failures. After adding extension
through 20 seconds for histories ending in a finite failure sentinel, those
records were selectively rechecked and the complete CSVs regenerated. The
remaining 888 records have incomplete coverage. Ordinary finite responses are
not extrapolated to repair early termination. Sentinel-supported and post-onset
samples remain excluded. The audit uses a validated private MAT-file;
case-specific data provenance and repair artifacts are stored with that private
dataset rather than in the reusable repository.

## Tests and artifacts

Synthetic tests passed for initial-NaN cleanup, sentinel exclusion, nonfinite
tail padding, short-vector padding, early-ended time-vector padding, and
insufficient coverage without a failure sentinel. Final CSV consistency
checks enforce 31,500 records and agreement between usability and the number
of retained samples.

Ignored `results/` contains history QC, grouped case summaries, simulation
metadata, audit configuration, and execution logs.
`run_task4_data_audit` regenerates the final behavior in one complete run.

## Modeling and rerun prerequisites

Direct inspection confirms that Task4Data.mat contains only `Simulations`
under `Task4.Inputs`, with no predictor subgroups. External RV/FISH source
files were subsequently found in the original Maku_PT4 folder. Their mapping
and actual use must be verified against the archived run: the available
scale-0.25 template comments out both the RV input and RV calculation calls.
No Task 4 surrogate has been trained. Cross-scale relationships and
scale-specific screening validity remain unconfirmed. No commits or pushes
were made.
