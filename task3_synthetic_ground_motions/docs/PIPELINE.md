# Task 3 validated workflow

`run_task3_validated_workflow.m` is the single entry point for the accepted
paper analysis. It preserves the supplied raw MAT-file and the external paper
archive. Generated products are written only to ignored `results/`,
`analysis/results/`, `output/figures/`, and `output/tables/` locations.

## End-to-end run

```matlab
cd task3_synthetic_ground_motions
report = run_task3_validated_workflow("full");
```

The full run performs these stages in order:

1. Check dependencies and run a public-data-free structural smoke test.
2. Load the private `Task3` variable, extract the original nine ground-motion
   measures, clean histories, and save the prepared 150-realization dataset.
3. Detect each simulation's common loss-of-validity onset from the FLAC2D
   sentinel/runaway pattern. Values at and after that onset are excluded.
4. Audit common-onset target equivalence and detector sensitivity. Alternative
   response-specific envelopes remain sensitivity evidence and are not the
   accepted target definition. Recompute the finite detector reference inside
   each development split as a leakage-sensitivity audit.
5. Build positive nondecreasing response envelopes and sample 100 equally
   weighted native-duration points per record. Build 33 predictors from 16
   record descriptors and 17 cumulative excitation descriptors, including six
   running spectral accelerations.
6. Run ten deterministic, sentinel-stratified 105/45 realization-level outer
   splits. Every time sample from a record remains in the same partition.
7. For every split, use three development-record folds to select the response
   transform independently for each response-extraction point. Fit ten
   ridge-free FMRVR models, each jointly predicting the seven responses at one
   point, and project held-out predictions onto the positive nondecreasing
   envelope space.
8. Run the matched technical-review audits: four predictor sets, point-wise
   multi-output versus 70 independent single-output RVR fits, unconstrained
   versus bounded/projected predictions, terminal-demand accuracy, motion
   ranking, and critical response-extraction-point identification.
9. Retain the original scalar-demand FMRVR, matched comparators, modal analysis,
   and detector alternatives as benchmark and sensitivity evidence. The final
   screening diagnostic compares the 10x and 20x boundaries with the adopted
   conservative 5x target definition.
10. Export the exact split assignments, per-output and grouped metrics,
   Task 2-style `a10`, prediction timing based on five warmups plus 100 measured
   all-70 calls, and split, family, spatial, representative-history, and all-70
   figures. The accepted figure set also includes a first-split normalized
   Taylor diagram, a characterization of the 150 unequal-duration motions,
   and a Task 3-specific monitoring/mesh/response-map composite generated from
   preserved cited source images.
11. Verify the expected artifact set, 10 outer splits, 67 nonconstant outputs,
    48 sentinel-bearing simulations, monotonic predictions, and mean held-out
    R2 above 0.8.

The primary estimator is the ten-split point-wise result. The original fixed
105/45 split and the later ridge-plus-residual experiment are retained as
development history and are not treated as independent final tests.

## Regenerating presentation artifacts

After the fitted results exist, figures and tables can be rebuilt without model
training:

```matlab
run_task3_validated_workflow("artifacts");
```

To check an existing run without changing fitted results or figures:

```matlab
run_task3_validated_workflow("verify");
```

## Code organization

- `src/preparation`: raw-data loading, cleaning, reduction, and validation.
- `src/features`: original ground-motion feature extraction.
- `src/modeling`: scaling, FMRVR fitting/prediction, kernels, and split tools.
- `src/evaluation`: metrics and compact exports.
- `analysis/build_*`: screened targets, augmented features, and time-resolved
  cumulative-envelope datasets.
- `analysis/run_*`: accepted validation, comparators, audits, modal
  analysis, and documented rejected refinements.
- `analysis/generate_*`: figures and tables from saved results.
- `reference_results`: compact reviewed evidence suitable for source control.

Exploratory `explore_*` scripts document model development but are not called by
the accepted workflow. Large predictions, checkpoints, private raw histories,
and trained models remain ignored and are not intended for GitHub.
