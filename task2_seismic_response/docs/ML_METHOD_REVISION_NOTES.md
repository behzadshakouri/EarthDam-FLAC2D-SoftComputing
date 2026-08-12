# ML method revision notes (reviewer-valid mapminmax v2)

This workflow is designed to improve reproducibility and generalization while
preserving a strict held-out evaluation.

## Preserved reviewer safeguards

- The 300 ground-motion realizations are split once into 210 development and
  90 held-out test realizations.
- Rows from a realization cannot occur in both sets.
- Response-specific instability/admissibility masking is applied before model
  fitting and evaluation.
- PGA-template reduction is applied to development data only.
- Scaling is fitted on development data only. Test data are transformed with
  the saved development settings.
- The reported metrics use only the 90 held-out realizations.

## Restored author-method behavior

- Inputs and targets use MATLAB `mapminmax`, as in the supplied FULL70 files.
- The hidden-layer equations are the supplied sigmoid ELM equations.
- Output weights use the supplied ridge solution with lambda = 1e-4.
- ABC and ACOR call YPEA; IGWO calls the supplied `IGWO.m` and its original
  dependencies. There is no fallback optimizer.
- The supplied model-specific hidden-neuron counts and 1,000 optimizer
  iterations remain unchanged.

## Stable plain ELM selection

Plain ELM evaluates 30 random hidden-layer initializations. Candidates are
ranked on an inner validation subset containing complete development
realizations. After selection, ridge output weights are refitted on all reduced
development rows. The 90 final test realizations are never used for candidate
selection.

This may improve ELM stability but does not guarantee that every response will
achieve a high R2. Any reported performance remains an honest held-out result.
