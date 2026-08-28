# Published reference results

This directory contains only numerical results explicitly reported in the
published Computers and Geotechnics article:

B. Shakouri et al., "A collaborative numerical simulation-soft computing
approach for earth dams first impoundment modeling," *Computers and
Geotechnics*, 164, 105814, 2023.
https://doi.org/10.1016/j.compgeo.2023.105814

- `published_table7_response_metrics.csv` reproduces Table 7: metrics averaged
  over QoIs 1-10 for the selected sample size of 200 (140 training and 60
  testing realizations).
- `published_table8_fos_metrics.csv` reproduces Table 8: FoS model metrics for
  the same selected sample size and the reported FoS distribution statistics.

The values were transcribed at the precision printed in the article.

These CSVs are publication reference targets, not outputs from a new canonical
rerun. Raw FLAC2D data, trained checkpoints, detailed per-QoI metrics, and
sample-size sweep workspaces remain outside Git.
