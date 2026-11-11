# Task 3 Overleaf export audit (2026-09-19)

Source archive:
The original Task 3 Overleaf export was reviewed from the authors' manuscript
archive outside Git.

## Package and build

- The archive contains `paper.tex`, `dump.tex`, and `cas-refs.bib`.
- `latexmk -pdf -interaction=nonstopmode -halt-on-error paper.tex` completes and
  produces a 14-page PDF.
- All cited bibliography keys exist.
- The manuscript references seven figures and three tables that are absent from
  `paper.tex` and the ZIP: `fig:dam_geometry`, `fig:workflow`,
  `fig:response_distributions`, `fig:corr_matrix`, `fig:scatter_outputs`,
  `fig:point_performance`, `fig:model_comparison`, `tab:response_stats`,
  `tab:overall_metrics`, and `tab:response_metrics`.

## Scientific and reproducibility gaps

- The abstract, results, and conclusions state that comparative multi-output
  modeling is complete and that FMRVR outperforms ELM, SVR, and Random Forest.
  The completed local production run evaluates FMRVR; those benchmark
  comparisons have not been executed by the Task 3 package.
- The manuscript describes all 70 outputs as learned jointly. The data audit
  found three constant outputs (P8R5, P9R5, and P10R5), leaving 67 nonconstant
  outputs. Their centered training matrix has rank 36, so the production model
  uses a 36-dimensional output subspace and restores the three constants in the
  final 70-output prediction. This treatment must be disclosed in Methods.
- The text says the 150 cases were split approximately 70/30. The implemented
  split is exactly 105 development and 45 held-out test cases, with preprocessing
  fitted independently inside each cross-validation fold.
- The results section contains qualitative claims but no actual numerical tables
  or figures. Current provisional held-out averages are mean R2 0.5610, mean
  nRMSE 0.2717, mean nMAE 0.1860, and mean a10 0.0431. These values do not
  support blanket statements of high accuracy across all responses.
- Data and Code Availability names `task3_recorded_ground_motions`, while the
  local implementation directory is `task3_synthetic_ground_motions`.

The manuscript should be revised around the executed FMRVR workflow and its
actual outputs, or the missing benchmark workflows and manuscript figures must
be implemented and validated before the comparative claims are retained.
