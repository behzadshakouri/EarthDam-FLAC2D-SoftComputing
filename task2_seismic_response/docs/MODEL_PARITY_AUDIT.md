# Model parity audit

The production workflow retains the supplied FULL70 model definition:

- ELM: 20 hidden neurons.
- ELM-ABC, ELM-ACOR, and ELM-IGWO: 10 hidden neurons.
- Sigmoid hidden activation and ridge coefficient `1e-4`.
- Metaheuristics optimize only hidden input weights and biases. Output weights
  are recomputed by ridge regression.
- Optimization bounds use `bound_scale=2` and `bound_cap=10`.
- The original `maxPGAperTemplate=10` reduction is applied within the fixed
  development realizations before scaling and fitting. Test rows are untouched.
- Fitness evaluation uses no more than 50,000 reduced development rows.
- ABC: 1,000 iterations, population 30, 20 onlookers, acceleration 0.4.
- ACOR: 1,000 iterations, population 40, 40 samples, q=0.1, zeta=1.
- IGWO: 1,000 iterations and population 30.

## Important implementation note

The supplied ABC and ACOR FULL70 scripts call third-party YPEA classes
`ypea_abc` and `ypea_acor`; the package calls those same classes directly.
Because the YPEA files were not included in the supplied archive, the same
YPEA installation used for the original runs must be on the MATLAB path.

The supplied `IGWO.m` is called directly. Its original `initialization` and
`boundConstraint` helpers and MATLAB distance functions must also be
available. Missing dependencies stop the run; no optimizer is substituted.

Progress printing and plotting are reporting layers only. They do not change
candidate generation, the objective function, bounds, or final model fitting.

## Reviewer-only adaptations

These changes surround the supplied methods without replacing them:

- response-specific pre-instability admissibility masking;
- one fixed 210/90 split by realization, shared across all methods;
- scaling fitted from reduced development data only;
- evaluation on all admissible rows from the untouched 90 test realizations;
- checkpoints, row/realization mappings, metrics, timing, and plots.

The earlier project-local ABC, ACOR, and IGWO adapters have been removed.
