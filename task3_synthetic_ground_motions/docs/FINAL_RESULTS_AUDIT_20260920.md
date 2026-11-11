# Superseded Task 3 development-results audit (2026-09-20)

This document records the earlier ridge-plus-residual experiment for
traceability. It is not the final manuscript evidence. The accepted ridge-free
point-wise result is documented in `MANUSCRIPT_ALIGNMENT.md` and
`MANUSCRIPT_EVIDENCE_MAP.md`.

## Approach accepted at the time

The only primary model is the output of:

```matlab
run_task3_time_resolved_residual_fmrvr(10,100)
```

It uses 150 records, 100 samples per record, 33 predictors, 70 cumulative
response envelopes, a ridge trajectory backbone with penalty 10, a rank-5
mixed multiscale FMRVR residual correction trained at five rows per development
record, family-specific development-selected residual weights, and a final
nonnegative cumulative-maximum projection.

## Primary evidence files

- `time_resolved_residual_fmrvr_family_metrics_100points.csv`
- `time_resolved_residual_fmrvr_family_summary_100points.csv`
- `time_resolved_residual_fmrvr_family_selections_100points.csv`
- `time_resolved_residual_fmrvr_per_output_100points.csv`
- `time_resolved_residual_fmrvr_response_family_100points.csv`
- `time_resolved_residual_fmrvr_split1_100points.mat`
- `time_resolved_feature_dictionary.csv`

Files without the `100points` suffix and scalar-demand files are development
or benchmark evidence and do not supply primary manuscript results.

## Recomputed primary results

- Ridge mean R2: 0.8267427591
- Residual FMRVR mean R2: 0.8320741532
- Residual FMRVR split SD: 0.0185268082
- Mean R2 increase: 0.0053313941
- Mean nRMSE: 0.0493188449
- Mean nMAE: 0.0307446950
- Corrected split range: 0.8024187848--0.8602015821
- Corrected R2 exceeds ridge R2 in all 10 outer splits.
- Rounded mean output counts: 62 at R2 >= 0.7, 53 at R2 >= 0.8, and 14 at
  R2 >= 0.9.
- All seven response-family means exceed 0.78.
- The saved first split has 4,500 rows, 70 outputs, and 33 predictor names.
- Saved corrected predictions are finite, nonnegative, and nondecreasing within
  every held-out record.

## Manuscript consistency decisions

The manuscript reports nMAE as 0.0307. Counts of outputs above R2 thresholds
are reported as whole outputs (62, 53, and 14); the CSV retains exact averages.
The unsupported earlier statement that an unconstrained model attained mean
R2 = 0.8328 has been removed. Scalar terminal-demand FMRVR (0.6743) and ridge
(0.6808), direct time-resolved FMRVR (0.544), classifier variants, and feature
searches are labeled as development benchmarks.

`verify_task3_validated_artifacts.m` checks the primary summary against the ten
split rows, the nRMSE and nMAE means, positive improvement in all splits, seven
family rows, 67 nonconstant outputs per split, saved dimensions, 33 predictors,
and nonnegative monotonic predictions.
