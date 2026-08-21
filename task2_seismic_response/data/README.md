# Data

Generated canonical files:

- `task2_consolidated_dataset.mat`
- `task2_failure_database.mat`
- `task2_realization_split.mat`

Large raw and generated files should normally be excluded from Git. Publish a representative example only when sharing rights and size permit.

The Figure 3 generator requires the original **signed IAA acceleration
history** (`IAAPGA20sec.xlsx`, `IAA-20sec.xlsx`, or a configured equivalent).
The monotonic cumulative PGA envelope used as a surrogate input is not enough
to calculate PSA or PSV. Keep the private motion outside Git when its sharing
rights are restricted and configure its path in `config/task2_user_paths.m`.
