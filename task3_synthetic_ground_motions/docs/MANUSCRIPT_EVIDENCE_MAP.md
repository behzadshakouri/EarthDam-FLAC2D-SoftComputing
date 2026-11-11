# Manuscript evidence map

This file maps the principal Task 3 manuscript claims to reproducible code and
compact reference results.

| Claim | Code | Reviewed result |
|---|---|---|
| 48 sentinel-bearing simulations; common onset at 5x | `analysis/build_task3_screened_targets.m` | `reference_results/detector_screening_summary.csv` |
| Common-onset peak equals the cumulative-envelope endpoint | `analysis/verify_task3_common_onset_envelope_equivalence.m` | `reference_results/common_onset_envelope_equivalence.csv` |
| 33 cumulative-path predictors and 100 samples per record | `analysis/build_task3_time_resolved_dataset.m` | `reference_results/time_resolved_feature_dictionary.csv` |
| Ten ridge-free point-wise FMRVR models and development-only transform selection | `analysis/run_task3_compact_pointwise_fmrvr_validation.m` | `reference_results/compact_pointwise_fmrvr_inner_selections.csv` |
| Mean $R^2=0.8574$ (SD 0.0135), nRMSE 0.0450, and nMAE 0.0257 | same final validation script | `reference_results/compact_pointwise_fmrvr_summary.csv`; `reference_results/compact_pointwise_fmrvr_outer_metrics.csv` |
| About 57/67 outputs exceed $R^2=0.8$ and 27/67 exceed 0.9 | same final validation script | same summary and `reference_results/compact_pointwise_fmrvr_per_output.csv` |
| Response-family and extraction-point performance | same final validation script | `reference_results/compact_pointwise_fmrvr_response_summary.csv`; `reference_results/compact_pointwise_fmrvr_point_summary.csv` |
| Exact record membership for all ten 105/45 splits | same final validation script | `reference_results/compact_pointwise_fmrvr_split_assignments.csv` |
| `a10` and full all-70 prediction timing | same final validation script | final summary, outer metrics, grouped metrics, and `reference_results/compact_pointwise_fmrvr_timing.csv` |
| Scalar peak benchmark reaches $R^2=0.6743$ for FMRVR | `analysis/run_task3_fmrvr_experts_nested_validation.m` | `reference_results/fmrvr_experts_nested_summary.csv` |
| Modal candidates at 1.700, 0.802, and 0.476 s | `analysis/run_task3_modal_period_analysis.m` | `reference_results/modal_periods_development_only.csv` |
| The 14-predictor prefix-only set retains mean $R^2=0.8591$, whereas the 16 complete-record predictors alone give 0.0571 | `analysis/run_task3_reviewer_ablation.m` | `reference_results/reviewer_predictor_ablation_summary.csv` |
| Point-wise FMRVR and 70 matched single-output RVR models have effectively equal accuracy, while the point-wise formulation uses less training and prediction time | same reviewer-ablation script | `reference_results/reviewer_multi_vs_single_summary.csv` |
| Nonnegative bounding and monotonic projection preserve aggregate accuracy | same reviewer-ablation script | `reference_results/reviewer_projection_ablation_summary.csv`; `reference_results/reviewer_projection_correction_fraction.csv` |
| Terminal-demand, motion-ranking, and critical-point audits | same reviewer-ablation script | `reference_results/reviewer_terminal_metrics_by_family_summary.csv`; `reference_results/reviewer_ranking_critical_point_by_family_summary.csv` |
| The 10x and 20x runaway thresholds identify the same 48 simulations but alter terminal targets relative to the adopted 5x boundary | `analysis/run_task3_screening_sensitivity_final.m` | `reference_results/screening_sensitivity.csv` |
| Development-only finite references identify the same 48 simulations in every outer split; maximum onset shift is 0.344 s | `analysis/run_task3_development_reference_sensitivity.m` and optional reference IDs in `analysis/build_task3_screened_targets.m` | `reference_results/development_reference_screening_summary.csv`; `reference_results/development_reference_screening_by_split.csv` |
| Full-width cross-section/monitoring-point and mesh composition | `analysis/generate_task3_monitoring_response_figure.m` | source assets and provenance note in `analysis/figure_sources/` |
| Response-family error bars report variability over ten outer splits | `analysis/generate_task3_compact_fmrvr_figures.m` | generated `time_resolved_family_performance` figure |
| Modal-period plots increase from left to right | `analysis/run_task3_modal_period_analysis.m`; `analysis/generate_task3_final_presentation.m` | generated `modal_period_transfer_analysis` figure |

The original precommit ZIP establishes the scalar-demand contract, response
dictionary, Gaussian FMRVR baseline, and fixed split. The accepted workflow
adds cumulative response envelopes, cumulative excitation descriptors,
record-separated repeated validation, and point-wise multi-output FMRVR. The
older ridge-plus-residual result ($R^2=0.8321$) is retained only for development
traceability and is not a manuscript performance result.

Run `run_task3_validated_workflow("full")` to reproduce the complete chain or
`run_task3_validated_workflow("verify")` to check an existing artifact set.
