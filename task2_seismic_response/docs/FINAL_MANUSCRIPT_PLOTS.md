# Final manuscript plotting workflow

The original author plotting style and manuscript-compatible filenames are
preserved. Displayed terminology has been updated to match the revised paper:

- P1--P10 are numerical response-extraction points;
- the horizontal axis of prediction grids is `FLAC2D reference`;
- the vertical axis is the applicable surrogate prediction;
- PGA plots refer to the `detected transition`, not physical failure;
- R1--R7 are displayed using the physical symbols and units used in the paper;
- `a_{10}` is used in mathematical labels.

## Aggregate final figures

After `setup_task2`, run:

```matlab
outDir = generate_final_manuscript_figures( ...
    'E:\path\to\task2_final_manuscript_handoff_20260816_141005.xlsx');
```

This reads saved final results only and does not retrain any model. It writes:

- `COMPARE_dashboard.png`;
- `COMPARE_wins_top2.png` and its audit CSV;
- `MODEL_summary_final.png`;
- `ELMIGWO_by_response_final.png`;
- `NEURON_sweep_final.png`.

## Complete result-figure set

To generate every active result figure cited in the main text and appendices,
including all `ALL70...` prediction grids and detected-transition plots, run:

```matlab
manifest = generate_all_final_manuscript_plots;
```

The runner reads the following files from the active Task 2 package:

- `data/task2_consolidated_dataset.mat`;
- `data/task2_failure_database.mat`;
- `data/task2_realization_split.mat`;
- the final selected model checkpoints; and
- the final manuscript-handoff workbook.

It does not use the obsolete `FAILURE_TIMES_v6.mat` or
`FULL_ALL_POINTS_ALL_RESPONSES_XY.mat` files. A lightweight sparse adapter is
created only to preserve compatibility with the author's established plot
layout functions and filenames.

The returned manifest verifies the eleven active result figures cited in the
paper. The flowchart and dam cross-section/mesh panels remain static. The IAA
spectral heatmaps are generated separately because they require the original
signed acceleration history rather than the cumulative PGA envelope used by
the surrogate workflow. The commented `COMPARE_delta_vs_ELM` figure is
intentionally excluded.

## IAA methodology figures (Figure 3)

Provide the signed IAA acceleration history and run:

```matlab
files = generate_iaa_methodology_figures('E:\path\to\IAA-20sec.xlsx');
```

This writes `a_PSA_heatmap.png` and `b_PSV_heatmap.png`, the two panels used
in Figure 3, plus the separate excitation illustration `IAA.png` and an
auditable MAT file containing the plotted arrays. The heatmaps are cumulative
5%-damped response spectra: every time column reports the maximum response up
to that instant. The retained manuscript settings use 120 periods from 0.05 to
2.0 s, ten contour levels, and the reversed period-axis orientation of the
accepted figures. Use `'MakeIAAPlot',false` to generate only the two Figure 3
heatmaps. `IAA.png` is not a third Figure 3 panel.

A monotonic PGA-envelope column cannot be used to reconstruct response
spectra. If an input workbook contains several numeric columns, specify
`'TimeColumn',N` and `'AccelerationColumn',M`; specify `'InputUnits','g'` or
`'InputUnits','m/s2'` when automatic unit detection is inappropriate.

## FLAC2D-reference-versus-predicted grids

The final selected checkpoints must contain saved test predictions. Run:

```matlab
summary = assemble_final_selected_results(false);
generate_original_task2_plots( ...
    fullfile(setup_task2,'results','final_selected_models'),1:10,1:7);
```

Use the resulting ELM, ELM--ABC, ELM--ACOR, and ELM--IGWO prediction grids in
the main text and Appendix B. The three constant-reference cases P8--R5,
P9--R5, and P10--R5 remain identified separately.

## Detected-transition plots

The updated legacy callers preserve the established heatmap and CDF style.
Their internal MAT-file field names and historical output filenames still use
`failure` for backward compatibility, but all visible labels use `detected
transition`. Do not interpret these operational transitions as calibrated
physical-collapse thresholds.

## Compatibility

The scripts use MATLAB R2020a-compatible plotting functions. Existing internal
field names, folders, and manuscript figure filenames are preserved so that
saved results do not need to be renamed or regenerated.
