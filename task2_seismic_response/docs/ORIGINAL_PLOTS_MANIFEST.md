# Original plotting manifest

All files below were copied from the supplied/recovered code archive. They
remain separate from the two simplified compatibility wrappers.

## Latest predictive-result plots wired to the default workflow

- `plot_grid_obs_vs_pred_7x10.m` and updated variants
- `plot_all70_metric_heatmaps_pretty.m`
- `plot_grid_timeseries_obs_pred_7x10.m`
- `plot_grid_scatter_at_t_7x10.m`
- `plot_all70_median_timeseries.m` (FULL70/multiple-case runs only)
- `plot_heatmap_all70_over_time.m`
- `plot_compare_models_metrics.m` and updated variant
- `compute_aggregated_metrics_table.m`
- `compute_aggregated_metrics_normalized.m`

The older `plot_grid_metrics_heatmaps_7x10.m` remains available in
`scripts/original_plots`, but is not called automatically because it repeats
the newer pretty metric heatmaps. Median time-series plots are skipped for a
one-case P1-R1 smoke test, where they duplicate the ordinary time series.
Curated automatic outputs are written under `plots/original/latest`, so legacy
figures from an earlier run are not mixed with the current set.

## Failure-result plots retained unchanged

- failure-summary heatmaps (original and updated)
- median failure-time heatmaps (original and updated)
- median failure-PGA heatmaps (original and updated)
- PGA-at-failure CDF plots and 7x10 grids (original and updated)

These failure plots continue to accept the original `FAILURE_TIMES_v6.mat` and
`FULL_ALL_POINTS_ALL_RESPONSES_XY.mat` inputs. They are not silently redirected
to a different data structure.

## Supporting/export scripts retained

- `save_full_predictions_time_major.m`
- `save_full_predictions_block_major.m`
- `plot_block.m`
- `plot_block_safe.m`
- every original `call_plot_*.m` caller
- `run_aggregated_metrics_all_models.m`

`export_original_plot_inputs.m` is the only new bridge. It converts saved
held-out predictions to the CSV columns expected by the original functions.
