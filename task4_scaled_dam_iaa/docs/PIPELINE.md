# Canonical pipeline

`run_task4_validated_workflow.m` is the single entry point for the accepted
Task 4 FMRVR analysis.

1. Validate dependencies and run the public-data-free synthetic test.
2. Audit the 450 private scaled-dam simulations without modifying the source
   MAT files.
3. Apply the Task 2 response-specific instability detector. Exclude the onset
   sample and all later samples; carry only an explicit terminal failure
   sentinel to the 20 s boundary before screening.
4. Combine the 450 Task 4 records with the 300 Task 2 records, giving 750
   records at scale factors 0.25, 0.50, 1.00, and 1.50.
5. Sample each response envelope at 100 locations on the 20 s grid and assemble
   17 predictors: 14 material properties, water level, running PGA, and scale.
6. Run ten deterministic, scale-stratified 600/150 record-level outer splits.
   Every row from a record stays in one partition.
7. At each monitoring point, fit one multi-output FMRVR model to the seven
   locally admissible response envelopes. These are direct FMRVR models without
   a separate ridge-regression stage. One wrapper evaluates all ten models and
   returns the 70 outputs.
8. Project predictions onto the nonnegative nondecreasing envelope space.
9. Export exact split assignments, per-output and scale-specific metrics,
   Task 2-compatible `a10`, and timing from five warmups plus 100 measured
   all-70 prediction calls.
10. Generate the repeated-validation, point/response, output-map, discrete
    scale-audit, Task 2-style all-70, IAA spectral, Taylor, and Task 4-specific
    geometry/scale figures, then verify the complete artifact set.

Run the complete workflow with:

```matlab
cd task4_scaled_dam_iaa
report = run_task4_validated_workflow("full");
```

Use `"artifacts"` to rebuild figures from fitted results and `"verify"` for
read-only consistency checks. Matched ELM-IGWO, RF, and SVR comparisons and
leave-one-scale-out transfer tests remain separate until their repeated
validation is complete.
