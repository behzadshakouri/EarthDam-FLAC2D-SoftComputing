# Model parity audit

The canonical workflow retains the paper's four method families, sigmoid
activation, hidden-neuron counts recorded in the final supplied scripts,
`[-1,1]` bounds, RMSE fitness, optimizer populations, and 1000 iterations.

For reproducibility and leakage control, canonical splits and random seeds are
recorded and scaling is fitted on development data only. The historical
scripts normalized before splitting and called `randperm` without saving a
seed. The original files remain unchanged under `legacy` so both behaviors are
auditable.

As in Task 2, the canonical metaheuristic adapters optimize hidden-layer input
weights and biases and solve output weights by ridge regression. Third-party
ABC, ACOR, and I-GWO implementations are not replaced by local substitutes.
