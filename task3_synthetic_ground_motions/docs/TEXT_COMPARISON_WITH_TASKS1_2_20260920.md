# Historical Task 3 alignment with Tasks 1 and 2

This note predates the final multi-output response-evolution workflow. Use
`MANUSCRIPT_ALIGNMENT.md` for current manuscript claims and values.

This note records the final manuscript and repository decisions after using the
Task 1 published paper and Task 2 proof/repository as references.

## Scientific role

Task 1 supplies the numerical-model lineage, dam geometry, material-property
presentation, and mesh/cross-section style. Task 2 supplies the positive
increasing response-envelope concept, conservative response symbols, material
table style, all-output prediction layout, and separation of manuscript assets
from repository code. Task 3 applies those presentation and modeling ideas to
150 synthetic ground motions with unequal native durations.

## Final Task 3 prediction problem

- The dam model is fixed and the ground motion varies.
- Every FLAC2D history is retained only before a common simulation-level
  pre-runaway boundary.
- R1, R2, R6, and R7 use `cummax(abs(response))`.
- R3, R4, and R5 use `cummax(abs(response-response(1)))`.
- Every record contributes 100 equally weighted samples over its admissible
  native duration.
- The learning matrix contains 15,000 rows, 33 predictors, and 70 outputs.
- Complete records are separated between development and testing.

## Final estimator

The primary estimator is the exact run
`run_task3_time_resolved_residual_fmrvr(10,100)`. A ridge model with penalty 10
provides the trajectory backbone. A rank-5 mixed multiscale FMRVR is fitted to
the residual field using five representative rows per development record.
Seven nonnegative family weights are selected in three development-record
folds. The final prediction is clipped at zero and projected to a nondecreasing
path with a per-record cumulative maximum.

Across ten deterministic 105/45 outer splits, ridge reaches mean
$R^2=0.8267$. Residual FMRVR reaches $R^2=0.8321$ with SD 0.0185, nRMSE 0.0493,
and nMAE 0.0307. On an average split, 53 of 67 nonconstant outputs exceed
$R^2=0.8$. Scalar terminal-demand models, direct FMRVR, classifier variants,
and extra feature searches are development benchmarks rather than the final
approach.

## Paper and repository presentation

The manuscript includes the dam cross-section and mesh, material properties,
response and predictor symbols, screening definition, full final method,
split-level results, family results, output map, all-70 observed--predicted
figure, representative response paths, modal-period diagnostic, limitations,
and data/code statement. Captions use engineering response names rather than
internal task labels. Manuscript files remain in the separate paper folder;
the repository contains executable MATLAB code, compact reviewed CSV evidence,
documentation, tests, and generated-result recipes. This historical comparison
is retained alongside the final repository package.
