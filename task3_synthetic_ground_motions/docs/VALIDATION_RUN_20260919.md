# Task 3 local production run — 2026-09-19

Executed with MATLAB R2020a and the private Task3Data.mat. Data preparation
produced 150 x 9 features and 150 x 70 targets. The fixed seed is 20260830,
with 105 development and 45 held-out realizations. Acceleration was interpreted
as g, using the package's supplied response reductions.

## Implementation and validation

- Cross-validation fits standardizers and median-distance scales separately
  inside each training fold; five width factors are evaluated in five folds.
- A training-only SVD and whitening wrapper handles dependent outputs. The
  final 67 nonconstant outputs have numerical rank 36. Predictions are mapped
  back to the original response columns; constant outputs use development means.
- The local FMRVR adaptation initializes the zero-basis model's outputs. The
  original third-party file is unchanged.
- Synthetic tests passed for end-to-end prediction, dependent outputs,
  zero-basis early exit, sentinel cleanup, and response reduction.
- Reloading the saved model reproduced all 3,150 exported test predictions
  to relative tolerance 1e-12 (with absolute tolerance 1e-12 near zero).

## Numerical results

| Quantity | Value |
|---|---:|
| Selected width factor | 1 |
| Final standardized kernel width | 3.17599173175384 |
| Mean cross-validation nRMSE | 0.311059441394345 |
| Relevance bases | 44 |
| Final iterations | 639 / 1000 |
| Mean test R2, 67 nonconstant outputs | 0.561028929870769 |
| Mean test nRMSE, 67 nonconstant outputs | 0.271660455605937 |
| Mean test nMAE, 67 nonconstant outputs | 0.185975330778171 |
| Mean test a10, 67 nonconstant outputs | 0.0431177446102819 |

## Interpretation limits

This is a completed computational run, not a validated physical-response
surrogate or finalized manuscript result. The supplied reductions retained
pre-sentinel targets as large as 9.9995e29; 3,216 histories were truncated.
P8R5, P9R5, and P10R5 are constant. Response admissibility and reduction rules
must be reviewed before interpreting these metrics as dam-response accuracy.
Some cross-validation fits reached the iteration cap or emitted covariance
conditioning warnings. The final fit completed below its iteration cap.
The SVD and empty-model adaptations also require disclosure in the methodology.

## Local artifacts

The ignored `results/final_production/` directory contains the prepared data,
saved model, input and response QC, test predictions, output metrics, width
selection, and run summary. The realization split is in `splits/`.
To resume modeling from the already prepared data explicitly:

```matlab
result = run_task3_production('results/final_production/task3_prepared_dataset.mat');
```

Omitting this argument regenerates the dataset from the private MAT-file.
