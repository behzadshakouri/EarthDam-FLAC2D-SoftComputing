# Reference results

This directory contains compact, reviewed Task 3 results suitable for source
control. They document the cumulative response-envelope workflow reported in
the manuscript without redistributing the private MAT database, response
histories, trained checkpoints, or large intermediate target files.

Primary time-resolved evidence:

- `compact_pointwise_fmrvr_summary.csv`: aggregate ten-split result for the
  final ridge-free point-wise FMRVR workflow;
- `compact_pointwise_fmrvr_outer_metrics.csv`: one row per record-level outer
  split;
- `compact_pointwise_fmrvr_inner_selections.csv`: inner-selected response
  transforms for the ten point models;
- `compact_pointwise_fmrvr_per_output.csv`: all 70 outputs for every outer
  split;
- `compact_pointwise_fmrvr_point_summary.csv` and
  `compact_pointwise_fmrvr_response_summary.csv`: point and response-family
  summaries;
- `compact_pointwise_fmrvr_timing.csv`: measured training and prediction
  evidence using five warmups and 100 measured all-70 calls; its raw model-size
  column is retained only for traceability;
- `compact_pointwise_fmrvr_split_assignments.csv`: exact development/test
  membership for all 150 records in every outer split;

The validated database contains 15,000 rows (150 records times 100 normalized
time samples), 33 predictors, and 70 positive, nondecreasing response-envelope
outputs. Across ten deterministic 105/45 record-level splits, the final ten
point-wise FMRVR models reach mean R2 = 0.8574 +/- 0.0135 and mean median
R2 = 0.8896. On average, approximately 57 of the 67 nonconstant outputs exceed R2 = 0.8.
Mean a10 is 0.3648. The median of 100 measured predictions of all 70 outputs is
0.07095 s for 45 records, or about 0.00158 s per record, after five warmup calls
on the validation machine. Mean training time for the ten final point models is
0.820 s per outer split; inner selection time is excluded.

Superseded residual-correction evidence retained for traceability:

- `time_resolved_residual_fmrvr_family_summary_100points.csv`: aggregate
  ten-split result for the ridge backbone and residual FMRVR correction;
- `time_resolved_residual_fmrvr_family_metrics_100points.csv`: one row per
  record-level outer split;
- `time_resolved_residual_fmrvr_family_selections_100points.csv`: inner-selected
  family-specific residual weights;
- `time_resolved_residual_fmrvr_per_output_100points.csv`: all 70 outputs for
  every outer split, including the three constant outputs;
- `time_resolved_residual_fmrvr_response_family_100points.csv`: response-family
  accuracy;
- `time_resolved_feature_dictionary.csv`: definitions and units for the 33
  record-level and time-varying predictors.

The earlier ridge backbone reached mean R2 = 0.8267 and the residual FMRVR
workflow reached 0.8321 +/- 0.0185. These results remain reproducible but are
no longer the primary manuscript result.

Secondary terminal-demand benchmarks:

- `fmrvr_experts_nested_summary.csv`: aggregate ten-split result;
- `fmrvr_experts_nested_metrics.csv`: one row per outer split;
- `fmrvr_experts_nested_family_summary.csv`: response-family metrics;
- `fmrvr_experts_nested_per_output_summary.csv`: 67 nonconstant outputs;
- `fmrvr_experts_nested_selections.csv`: inner-selected blend weights;
- `fmrvr_experts_permutation_importance_summary.csv`: held-out one-feature
  permutation importance across the ten outer splits;
- `fmrvr_experts_difficult_outputs.csv`: ten lowest-scoring nonconstant outputs.
- `final_matched_comparator_summary.csv`: linear ridge with 16 predictors and random forest on
  the final FMRVR outer partitions;
- `final_matched_comparator_metrics.csv`: split-level matched comparator
  results.

Supporting evidence:

- detector and envelope-screening summaries;
- the nine-feature descriptive summary;
- development-only modal-period results;
- the rejected severity/family refinement summary.

Technical-review evidence:

- `reviewer_predictor_ablation_summary.csv` and its split-level companion compare
  the full 33-predictor set with complete-record, time-varying, and stricter
  prefix-only alternatives;
- `reviewer_multi_vs_single_summary.csv` documents the matched point-wise
  FMRVR versus 70 independent single-output RVR comparison;
- `reviewer_projection_ablation_summary.csv` and
  `reviewer_projection_correction_fraction.csv` audit the physical projection;
- `reviewer_terminal_metrics_by_family_summary.csv` and
  `reviewer_ranking_critical_point_by_family_summary.csv` document final-demand
  accuracy and engineering ranking behavior; and
- `screening_sensitivity.csv` compares the 10x and 20x boundaries with the
  adopted 5x numerical-runaway boundary;
- `development_reference_screening_summary.csv` and its split-level companion
  recompute the finite detector reference from the 105 development records in
  each outer split. All ten splits retain the same 48 screened simulations;
  seven reproduce every onset exactly and the maximum onset shift is 0.344 s.

The original Task 4 RBF basis was also tested unchanged on Task 3. On the fixed
development split it reached mean R2 = 0.0157; an additive record/dynamic
kernel variant reached -1.8075. These rejected diagnostics are generated under
the configured external analysis-results root and are intentionally excluded
from manuscript evidence.
The final Task 3 adaptation preserves the same ten point-wise, seven-output,
ridge-free FMRVR structure while using robust inputs and a compact global basis
suited to unseen ground motions.

The scalar peak-demand experiment gives mean $R^2=0.6743$ for the multiscale
FMRVR model. On the same partitions, linear ridge with 16 predictors reaches
0.6808 and random forest reaches 0.6744. These files are retained as an explicit
benchmark showing why response evolution, duration, and cumulative intensity
must be represented. The repeatedly inspected fixed 105/45 split is not treated
as an independent final test.

Regenerate the complete analysis from the private database with
`run_task3_validated_workflow("full")`. The larger prediction CSVs, generated
MAT files, and all raw histories remain ignored.
