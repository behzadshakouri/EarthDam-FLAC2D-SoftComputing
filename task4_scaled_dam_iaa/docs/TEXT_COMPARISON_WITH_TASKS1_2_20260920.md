# Task 4 text comparison with Tasks 1 and 2

> Historical audit (2026-09-20). This document describes the initial imported
> package before the final 17-predictor, 750-record multi-output FMRVR workflow
> was implemented. See `IMPLEMENTATION_STATUS.md` and `RELEASE_CHECKLIST.md`
> for the current validated status.

Date: 2026-09-20

## Sources reviewed

- Task 1 published article in the authors' publication archive;
- Task 2 final proof text in the authors' manuscript archive;
- Task 4 manuscript source in the authors' manuscript archive.
- Task 4 repository audits and data contract.

The external Task 4 ZIP was read without modification.

## Main conclusion

Task 4 is not ready for a performance-results manuscript. The current paper describes a completed 750-simulation, scale-aware surrogate and benchmark comparison, but the verified Task 4 dataset contains 450 scaled-dam response sets without a predictor matrix. No Task 4 surrogate has been trained. The claimed cross-scale generalization, benchmark superiority, and 70/30 performance evaluation therefore have no supporting outputs.

Task 1 supplies the broad FLAC2D-to-surrogate research context, while Task 2 supplies the prototype IAA data, failure-screening method, realization-level split, numerical model results, and limitations. Task 4 must add independently verified scale information and a scientifically justified link to Task 2 before it can claim a 750-case combined model.

## Quantitative text comparison

| Comparison | Observation |
|---|---:|
| Task 4 normalized word count | 5,737 |
| Task 2 normalized word count | 14,878 |
| Task 4 vs Task 2 exact sentences of at least 10 words | 9 |
| Task 4 vs Task 3 sequence similarity | 0.88 |
| Task 4 vs Task 3 shared 10-word sequences | 4,133 |
| Task 4 vs Task 3 exact sentences of at least 10 words | 162 |

The overlap with Task 3 is excessive for distinct papers. The Task 4 paper needs a scale-specific scientific question, methods, results, and discussion rather than a Task 3 text with ground-motion terms replaced by IAA and geometric scaling.

## What can be carried forward from Tasks 1 and 2

### Task 1 published paper

- Research-series context for collaborative FLAC2D and soft-computing models.
- Clear definition of the dam problem, inputs, outputs, sample-size study, and engineering limits.
- Concrete quantitative conclusions rather than unsupported performance adjectives.

Task 1 first-impoundment results are background only.

### Task 2 final proof

- Prototype scale 1.0 IAA methodology and 300-realization data source.
- Response-specific numerical-instability screening and pre-instability prediction domain.
- Realization-level 210/90 partition, 67 nonconstant outputs, numerical model metrics, difficult cases, and explicit post-failure limitations.

Task 2 can supply a documented prototype reference only if its variables, excitation definitions, response reductions, and realization relationship are shown to be compatible with Task 4.

## Verified Task 4 facts

- 450 scaled-dam simulations: 150 at scale 0.25, 150 at 0.50, and 150 at 1.50.
- 70 histories per simulation, giving 31,500 audited histories.
- 26,933 raw prefixes were truncated at an invalid value.
- 30,612 histories retain usable screened samples.
- 2,612 histories were extended only through an existing failure sentinel.
- 888 histories still lack adequate time coverage.
- The validated MAT-file stores responses and simulation count, but no predictor matrix.
- Equal within-scale row numbers are not yet proven to be paired realizations.
- Task 2's detector was applied operationally; scale-specific physical validity remains unconfirmed.
- No Task 4 surrogate, cross-scale split, or combined Task 2/Task 4 model has been trained.

## Unsupported or premature statements in the current text

1. The abstract claims successful scale-aware learning and improved accuracy without a trained model or numerical result.
2. The manuscript calls the database 750 simulations by combining 300 Task 2 prototype cases with 450 Task 4 scaled cases before compatibility and pairing are established.
3. The input vector is generic; the predictor variables and their source are not defined.
4. The claimed random 70/30 split and cross-validation have not been executed.
5. Claims that the model transfers knowledge across scales or generalizes beyond one geometry are untested.
6. Claims of consistent superiority over ELM, SVR, and random forest have no result files.
7. Statements about robust accuracy at each scale, fragility analysis, digital twins, and engineering applicability exceed the current audit evidence.
8. Eight figures and three tables are referenced but undefined: `fig:dam_geometry`, `fig:workflow`, `fig:response_distributions`, `fig:corr_matrix`, `fig:scatter_outputs`, `fig:point_performance`, `fig:model_comparison`, `fig:scale_effects`, `tab:response_stats`, `tab:overall_metrics`, and `tab:response_metrics`.

## Work required before a results-paper rewrite

1. Recover and verify the predictor/source-generation contract for all 450 scaled simulations.
2. Determine whether within-scale rows are paired and whether they correspond to Task 2 prototype realizations.
3. Verify consistent IAA definitions, input distributions, units, durations, response reductions, and point locations across Tasks 2 and 4.
4. Validate instability-screening settings at each scale and resolve or explicitly exclude the remaining 888 incomplete histories.
5. Choose a grouped split that prevents paired motions or parameter realizations from crossing development and test sets.
6. Establish baselines that separate the value of scale factor from the value of other predictors.
7. Test within-scale interpolation, leave-one-scale-out extrapolation, and combined-scale prediction separately.
8. Report numerical uncertainty across repeated grouped splits and response families.
9. Generate the referenced figures and tables from saved results.

## Recommended Task 4 scientific focus

The paper should ask whether a common surrogate can interpolate across verified dam scales and whether it improves over scale-specific models. That question requires three distinct evaluations:

- within-scale prediction;
- pooled interpolation among observed scales;
- held-out-scale transfer or extrapolation.

The last evaluation is necessary before using terms such as transferability or generalized scale-aware prediction.

## Safe interim manuscript position

Until the predictor contract and modeling results are available, Task 4 can support only a data-quality and numerical-instability audit. Its current quantitative statements should be limited to the 450 simulations, three confirmed scale blocks, 31,500 histories, screening outcomes, incomplete-coverage count, and unresolved provenance questions.

## Decision

Keep the original ZIP unchanged. Do not revise its results prose by inserting provisional adjectives or Task 2 metrics. Complete the predictor and cross-scale data contract first, execute the grouped validation, and then replace the abstract, results, discussion, and conclusions with Task 4-specific evidence. The introduction and methods must also be rewritten sufficiently to remove the present near-duplication with Task 3.
