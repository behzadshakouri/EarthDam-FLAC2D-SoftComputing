# Reviewer-readiness map

| Requirement | Implementation |
|---|---|
| Realization-level separation | Fixed 210-development/90-test split |
| Leakage prevention | Development-only scaling and PGA reduction |
| Stable-domain definition | Response/location-specific pre-onset mask |
| Metrics | R2, nRMSE, nMAE, and a10 on admissible test rows |
| Reproducibility | Fixed seeds, saved split, configuration-tagged checkpoints |
| Four-method parity | ELM, ELM-ABC, ELM-ACOR, and ELM-IGWO |
| Hyperparameter sensitivity | Twelve neuron-count configurations |
| Final selected models | ELM-30, ABC-15, ACOR-15, IGWO-5 |
| Computational reporting | Per-case measured training seconds |
| Figures | Saved-prediction and failure-report regeneration entry points |

FLAC2D constitutive, damping, boundary-condition, and mesh-verification
evidence belongs to the numerical-model repository/manuscript and is not
created by this surrogate-model package.
