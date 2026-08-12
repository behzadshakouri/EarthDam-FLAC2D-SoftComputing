# Canonical pipeline

1. Load and validate the historical `Task2Data.mat` response histories.
2. Interpolate every realization to 0.01-20.00 s.
3. Build cumulative absolute response and PGA envelopes.
4. Assemble the 70 cases directly in one consolidated dataset.
5. Detect instability onset separately for every case and realization.
6. Review diagnostic plots and approve detector parameters.
7. Create one fixed 210/90 realization split.
8. Apply response-specific masks; exclude onset and later values.
9. Fit normalization on development observations only.
10. Train ELM, ELM-ABC, ELM-ACOR, and ELM-IGWO.
11. Evaluate only held-out admissible observations.
12. Export auditable tables, figures, masks, seeds, timing, and metadata.

Historical development files may be retained outside the canonical package,
but they are not dependencies of this workflow. Code history belongs in Git.
