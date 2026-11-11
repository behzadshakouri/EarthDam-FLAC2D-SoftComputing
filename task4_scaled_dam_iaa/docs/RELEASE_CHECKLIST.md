# Release checklist

The authors marked the manuscript and its evidence package final for repository
preparation on 2026-11-10. Tag the immutable paper release after submission.

- [x] Private Task 2 and Task 4 databases excluded.
- [x] Machine-specific paths excluded.
- [x] Task 2 screening behavior and the sentinel-tail rule documented.
- [x] Combined four-scale data contract and 17 predictors documented.
- [x] Ten direct multi-output FMRVR models, one per monitoring point,
  designated as the final estimator.
- [x] Record-level and scale-stratified leakage controls implemented.
- [x] Nonnegative nondecreasing predictions implemented.
- [x] Adapted Ha FMRVR solver provenance and BSD license retained.
- [x] Export and review exact assignments for all ten outer splits.
- [x] Export Task 2-compatible `a10` and 5-warmup/100-run timing evidence.
- [x] State conservatively that unmatched ELM-IGWO, RF, and SVR results do not
  establish an algorithm ranking.
- [x] Limit scale claims to interpolation among the four represented factors;
  reserve leave-one-scale-out testing for future transfer work.
- [x] Regenerate the scale audit as discrete bars and provide a reproducible
  Task 4-specific geometry/scale composite.
- [x] Reconcile manuscript performance numbers with the final canonical CSVs.
- [x] Confirm final author, funding, acknowledgement, and AI-use statements in
  the manuscript package maintained outside Git.
- [x] Convert the primary submission draft to the Infrastructures template.
- [x] Run dependency check, synthetic self-test, and saved-result verification in
  the release MATLAB environment (passed 2026-11-10).
- [x] Prepare the first repository commit after final author review.

Before release:

```matlab
setup_task4;
check_task4_dependencies;
run_synthetic_self_test;
run_task4_validated_workflow("verify");
```
