# Canonical pipeline

1. Load and validate `outputs_gp.mat`.
2. Validate the 500-by-18 uncertain-input matrix.
3. Extract four scalar responses at each of ten QoIs.
4. Construct the 40 response-location cases.
5. Evaluate sample sizes 50, 100, 150, 200, 300, 400, and 500.
6. Create a realization-level 70/30 development/test split.
7. Fit `[-1,1]` scaling using development data only.
8. Perform the paper's ELM configuration trials.
9. Train ELM, ELM-ABC, ELM-ACOR, and ELM-IGWO using RMSE fitness.
10. Report R2, RMSE, MAE, and a10 for development and testing.
11. Repeat the modeling workflow for the independent FoS target.
12. Rebuild the paper figures and compare against reference results.

Task 1 does not use IAA, time histories, failure screening, safe-state masks,
or Task 2's fixed 210/90 split.
