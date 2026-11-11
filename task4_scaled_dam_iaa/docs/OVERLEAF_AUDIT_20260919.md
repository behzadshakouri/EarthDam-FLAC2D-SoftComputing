# Task 4 Overleaf export audit (2026-09-19)

> Historical audit. Its statements about missing predictors and untrained
> surrogates predate the validated 17-predictor, 750-record workflow.

Source archive:
The original Task 4 Overleaf export was reviewed from the authors' manuscript
archive outside Git.

## Package and build

- The archive contains only `paper.tex` and `cas-refs.bib`.
- `latexmk -pdf -interaction=nonstopmode -halt-on-error paper.tex` completes and
  produces a 16-page PDF.
- All cited bibliography keys exist. BibTeX reports empty page fields for two
  entries but no missing citation keys after the full build.
- The manuscript references eight figures and three tables that are absent from
  both the TeX source and the ZIP: `fig:dam_geometry`, `fig:workflow`,
  `fig:response_distributions`, `fig:corr_matrix`, `fig:scatter_outputs`,
  `fig:point_performance`, `fig:model_comparison`, `fig:scale_effects`,
  `tab:response_stats`, `tab:overall_metrics`, and `tab:response_metrics`.

## Scientific and reproducibility gaps

- The abstract, results, and conclusions describe a completed 750-simulation
  scale-aware model and completed comparisons with ELM, SVR, and Random Forest.
  The current Task 4 package has completed response-history QC but has no
  predictor matrix and therefore has not trained or evaluated those models.
- The input vector is left as generic `x_1,...,x_p`; neither the predictors nor
  `p` are defined. The supplied Task 4 MAT-file contains response histories but
  no predictor matrix.
- The manuscript says the 750 cases were randomly split 70/30 and tuned with
  cross-validation. No corresponding combined split, trained model, predictions,
  or metric tables currently exist in the repository.
- The results text makes qualitative accuracy and model-superiority claims but
  provides no numerical results. The referenced result figures and tables are
  also missing.
- Data and Code Availability names `task4_scale_aware_modeling`, while the local
  implementation directory is `task4_scaled_dam_iaa`.

The manuscript should not retain completed-model or comparative-performance
claims until the missing predictor contract is recovered and the combined
Task 2--Task 4 workflow is actually executed.
