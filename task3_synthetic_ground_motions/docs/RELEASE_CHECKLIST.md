# Release checklist

The authors marked the manuscript and its evidence package final for repository
preparation on 2026-11-10. Tag the immutable paper release after submission.

- [x] Original precommit ZIP retained unchanged outside Git.
- [x] Private `Task3Data.mat` excluded.
- [x] Local paths and user settings excluded.
- [x] Raw/intermediate response targets and trained models excluded.
- [x] Ha--Zhang solver provenance and license retained.
- [x] Synthetic smoke test retained.
- [x] Common-onset screening and target definitions documented.
- [x] Realization-level leakage controls documented.
- [x] Task 2-style cumulative-envelope workflow validated on ten record splits.
- [x] Positive nondecreasing prediction constraint verified.
- [x] Scalar-demand analysis retained and labeled as a benchmark.
- [x] Compact nested-validation reference results selected.
- [x] Direct multi-output FMRVR system (one model per monitoring point)
  designated as the sole final estimator.
- [x] Export and review exact assignments for all ten outer splits.
- [x] Export Task 2-compatible `a10` and 5-warmup/100-run timing evidence.
- [x] Manuscript claims mapped to code and CSV evidence.
- [x] Original Overleaf export preserved separately from the validated draft.
- [x] Document the supplied synthetic-motion database as an external input,
  interpret acceleration explicitly in `g`, and keep the deterministic model
  split seed in `task3_config.m`; no unverified motion-generation claim is made.
- [x] Add the available dam cross-section with P1--P10 extraction points.
- [x] Confirm that numerical P1--P10 coordinates are not required for the
  submission; the documented locations and reproducible DWG-to-raster mapping
  are retained in the geometry figure script.
- [x] Confirm final author, funding, acknowledgement, and AI-use statements in
  the manuscript package maintained outside Git.
- [x] Complete author review of the expanded manuscript package.
- [x] Freeze the accepted ten-split evidence; any further performance tuning
  requires a separately identified external test set.
- [x] Run dependency check, synthetic self-test, and saved-result verification in
  the release MATLAB environment (passed 2026-11-10).
- [x] Prepare the first repository commit after final author review.

Before release:

```matlab
setup_task3;
check_task3_dependencies;
run_task3_smoke_test;
run_task3_validated_workflow("verify");
```
