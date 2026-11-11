# Task 3 machine-learning validation findings

## Accepted response-evolution formulation (2026-09-20)

The scalar-demand study below remains a benchmark of the original precommit
formulation. The accepted workflow now follows the Task 2 response-envelope
approach while respecting Task 3's 150 distinct ground motions and native
durations.

- Each signed FLAC2D history is converted to a positive nondecreasing envelope.
  Displacement and strain use `cummax(abs(response))`; stress and pore pressure
  use `cummax(abs(response-response(1)))`.
- Samples at and after the same common simulation-level runaway onset are
  excluded. No sentinel or repeated failure magnitude enters a target.
- Every record contributes 100 equally weighted samples over its admissible
  native-duration interval. All samples from a record remain in the same outer
  partition.
- Sixteen full-record descriptors are augmented by 17 time-varying cumulative
  descriptors: elapsed and normalized time, absolute acceleration, running
  PGA/PGV/PGD, running Arias intensity and fraction, running CAV and fraction,
  running RMS, and running Sa at 0.1, 0.2, 0.5, 1.0, 2.0, and 3.0 s.
- A regularized cumulative ridge model supplies a stable trajectory backbone.
  Rank-5 multiscale FMRVR learns the coupled residual field from five
  representative samples per development record. A nonnegative residual weight
  is selected separately for each response family using development-only record
  folds. Final predictions are projected onto the positive nondecreasing space.

Across ten stratified 105/45 record-level outer splits, monotonic cumulative
ridge attains mean R2 = 0.8267. The family-wise residual FMRVR correction raises
the mean to R2 = 0.8321 (SD 0.0185). The split range is 0.802--0.860. On an
average split, 62 of 67 nonconstant outputs exceed R2 = 0.7, 53 exceed 0.8,
and 14 exceed 0.9. Family means are 0.862 for X displacement, 0.826 for Y
displacement, 0.871 for horizontal stress, 0.786 for vertical stress, 0.874 for
pore pressure, 0.805 for shear strain, and 0.813 for volumetric strain.

The improvement is caused primarily by the change from terminal scalar peaks
to response evolution, not by changing the physical target definition. The
terminal value of each accepted envelope is the scalar peak used in the
benchmark. Raw total stress/pore-pressure targets and response-specific failure
onsets were both rejected in matched validation. Time-frequency PCA features,
nonlinear failure classifiers, direct all-output FMRVR, and direct family FMRVR
were also rejected. The accepted model enforces positive nondecreasing paths
after combining the ridge backbone and family-weighted FMRVR residuals.

## Data and target definition

- The raw FLAC2D histories remain signed. They are not forced to be positive
  or monotonically increasing.
- Displacement and strain targets are the maximum absolute response before
  numerical failure. Stress and pore-pressure targets are the maximum absolute
  change from the initial value before failure.
- Forty-eight of 150 simulations contain a FLAC invalid-value sentinel. Every
  one of those simulations shows runaway behavior in all 67 nonconstant
  outputs, supporting one simulation-level onset time.
- The repeated failure value is carried to each record's native endpoint only
  as a failure marker. It is excluded from the learning target.
- A threshold of 5 times the largest corresponding magnitude among histories
  without a sentinel detects the same 48 simulations and 3,216 histories as
  the 10- and 20-times thresholds. It triggers a median 1.566 s before the
  first sentinel and is the most conservative tested definition.

### Adaptation of the Task 2 response-envelope workflow

Task 2 constructs positive nondecreasing response envelopes and uses
time-resolved learning. Task 3 now follows the same response-evolution concept,
but adopts the earliest simulation-level onset because all 70 outputs form one
coupled target vector. Displacement and strain use
`cummax(abs(response))`; stress and pore pressure use
`cummax(abs(response-response(1)))`. Each record contributes 100 equally
weighted samples from its admissible interval.

The 150 Task 3 ground motions have different native durations. Task 3 envelope
screening and sampling therefore retain each record's native time vector and
endpoint; ordinary responses are not padded or extrapolated to a common
duration. Total record duration remains a predictor.

An initial direct-transfer audit also showed that the Task 2 v4.2 detector
parameters cannot be reused unchanged: they marked all 150 Task 3 simulations
and 9,233 of 10,500 histories, including simulations without sentinels. Those
targets were rejected before model fitting. The next experiment uses the
Task 3-calibrated 5-times reference threshold with response-specific envelope
onsets.

The calibrated response-specific audit identified exactly the 48 sentinel
simulations and 3,216 sentinel histories, with no detection in the other 102
simulations. Within an affected simulation, however, response-specific onsets
span a median 0.694 s (maximum 0.811 s). Because responses grow rapidly in
that interval, retaining each response until its own onset materially inflates
some targets relative to the earliest common onset. For the coupled 70-output
FMRVR target, the earliest simulation-level onset remains the primary common
validity boundary; the response-specific construction is retained as a
sensitivity analysis.

## Leakage controls

- Every fixed or repeated split separates realizations, not rows.
- Scaling, feature transforms, feature-set selection, ridge penalties, blend
  weights, and failure classifiers are fitted from development data only.
- Nested repeated validation reselects model settings inside each outer split.
- Constant outputs P8R5, P9R5, and P10R5 are restored separately and excluded
  from mean regression metrics.

## Model research

The evaluated approaches included FMRVR, linear and quadratic ridge, PLS,
ELM, Gaussian SVR, random forest, LSBoost, exact ARD Matérn Gaussian processes,
full kernel ridge, transformed targets, transformed inputs, development-selected
blends, output-specific feature and penalty selection, and failure-gated
mixtures.

An FMRVR-specific study retained the Ha--Zhang sparse Bayesian solver and
tested changes supported by the relevance-vector literature: physically
informed inputs, supervised input length scales, linear/Gaussian mixed bases,
response-family fits, and reduced-rank output representations. Three-fold
development validation selected a mixed linear/Gaussian kernel with a
five-dimensional output subspace. The rank-5 representation was selected in
all ten nested outer splits; the selected linear contribution was 0.50 or
0.75. The resulting models used only 9--16 relevance bases in the examined
fits.

Six 5%-damped pseudo-spectral acceleration ordinates at periods 0.1, 0.2, 0.5,
1.0, 2.0, and 3.0 s were added to the original nine intensity measures along
with total record duration. Development-only cross-validation selected this
16-feature set. This is physically motivated because spectral acceleration
represents oscillator response near a structure's vibration periods, whereas
PGA alone describes only peak ground-particle acceleration.

## Main results

### Fixed 105/45 split

| Model | Failure threshold | Mean R2 | Median R2 | Mean nRMSE | Mean nMAE | Mean a10 |
|---|---:|---:|---:|---:|---:|---:|
| FMRVR | 10x | 0.440 | 0.456 | 0.181 | 0.118 | 0.178 |
| Linear ridge | 10x | 0.665 | 0.738 | 0.137 | 0.093 | 0.241 |
| Transformed-input ridge | 10x | 0.673 | 0.724 | 0.136 | 0.091 | 0.253 |
| Spectral ridge | 10x | 0.696 | 0.764 | 0.130 | 0.085 | 0.276 |
| Spectral ridge | 5x | 0.719 | 0.779 | 0.121 | 0.078 | 0.295 |
| Output-specific ridge | 5x | 0.710 | 0.782 | 0.123 | 0.080 | 0.281 |
| Failure-gated spectral model | 5x | **0.722** | **0.777** | **0.121** | **0.076** | **0.307** |
| Improved mixed rank-5 FMRVR | 5x | 0.589 | 0.615 | 0.150 | 0.097 | 0.183 |

The failure-gated model uses a development-selected combination of a global
spectral ridge model and two spectral ridge experts for stable and failed
simulations. Its fixed-test failure-classification accuracy is 86.7%.

### Ten stratified outer splits

| Model | Mean R2 | SD | Lower | Upper | Mean nRMSE | Mean nMAE | Mean a10 |
|---|---:|---:|---:|---:|---:|---:|---:|
| FMRVR | 0.452 | 0.074 | 0.340 | 0.537 | 0.176 | 0.120 | 0.185 |
| Random forest | 0.594 | 0.039 | 0.534 | 0.653 | 0.150 | 0.096 | 0.271 |
| Spectral ridge, 5x | 0.654 | 0.044 | 0.546 | 0.693 | 0.134 | 0.090 | 0.290 |
| Output-specific ridge, 5x, nested | 0.639 | 0.052 | 0.519 | 0.694 | 0.137 | 0.092 | 0.279 |
| Failure-gated spectral, 5x, nested | **0.660** | **0.041** | **0.567** | **0.708** | **0.133** | **0.087** | **0.303** |

The fixed held-out split supports a mean R2 above 0.7. Resampling does not
support a global mean above 0.7 with the present 150 simulations. Because the
fixed test results informed subsequent research decisions, the nested repeated
estimate should be treated as the primary generalization result unless a new
external test set is generated.

Across nested output-specific validation, horizontal stress has mean R2 0.74
and pore-pressure change has mean R2 approximately 0.70. Other response
families average between 0.55 and 0.68. Claims above 0.7 can therefore be made
for specific response families more strongly than for the full 67-output mean.

### FMRVR-specific nested comparison

On ten matched outer splits, the original FMRVR averaged R2 = 0.491 and the
improved mixed rank-5 FMRVR averaged R2 = 0.632 (SD 0.037; range
0.580--0.691). The improved model won all ten matched splits, with mean
delta R2 = +0.140. This is a material improvement to FMRVR itself and brings
it close to the strongest nested spectral models, but it does not establish a
global R2 above 0.7.

### Multiscale failure-aware FMRVR

A subsequent FMRVR-only development search tested training-only target
transformation and Gaussian kernels averaged over several length scales.
Target transformation did not improve development error. The selected global
model retained the rank-5 output representation and a 0.50 linear contribution,
while averaging Gaussian kernels at 0.5, 1, and 2 times the median input
distance. It used 31 relevance bases in the fixed development fit.

On the repeatedly inspected fixed 105/45 split, the global multiscale FMRVR
reached mean R2 = 0.704. A soft-gated combination of the global model and
separate FMRVR experts for stable and sentinel-bearing simulations reached
mean R2 = 0.710, median R2 = 0.751, mean nRMSE = 0.124, mean nMAE = 0.075,
and mean a10 = 0.328. Forty-five of 67 nonconstant outputs exceeded R2 = 0.7,
24 exceeded 0.8, and 5 exceeded 0.9. Fixed-test instability classification
accuracy was 86.7%.

Across ten matched outer splits, with the global/expert blend chosen inside
each development subset, the global multiscale FMRVR averaged R2 = 0.641
(SD 0.032). The failure-aware FMRVR experts averaged R2 = 0.674 (SD 0.037;
range 0.633--0.744), mean nRMSE = 0.127, mean nMAE = 0.080, and mean a10 =
0.314. The experts improved all ten splits, with mean delta R2 = +0.034 and
mean instability-classification accuracy = 90.2%.

The output-level aggregation confirms that the gain is broad rather than
concentrated in a few responses: 61 of 67 nonconstant outputs improve over
the global multiscale FMRVR. Thirty-seven outputs have a ten-split mean R2 of
at least 0.7 and 15 reach at least 0.8; none reaches 0.9 across all ten outer
splits. By family, mean R2 is 0.688 for X displacement, 0.654 for Y
displacement, 0.744 for horizontal stress, 0.614 for vertical stress, 0.695
for the seven nonconstant pore-pressure outputs, 0.696 for shear-strain
increment, and 0.635 for the state-variable increment. Horizontal stress is
the strongest family, whereas vertical stress remains the clearest target for
future improvement.

This is the strongest nested FMRVR result obtained so far and slightly exceeds
the earlier failure-gated spectral benchmark mean of 0.660. The fixed split
remains secondary evidence because it has been repeatedly inspected. A new
locked external set is still required for a pristine final estimate.

### Rejected severity/family refinement

A subsequent nested experiment predicted normalized time remaining after the
screening onset and allowed response-family-specific gates and rank-2/rank-3
FMRVR models for the three weakest response families. All auxiliary predictions
and model choices were generated inside each development subset. The matched
binary-gated baseline and the refined model both averaged R2 = 0.6743; the mean
difference was 0.00002, and the refinement won five of ten splits. Vertical
stress decreased from 0.614 to 0.612 and Y displacement decreased from 0.654
to 0.653. The refinement fails the predeclared +0.01 improvement criterion and
is retained only as a negative research result. It is not the proposed model.

### Assessment of the R2 = 0.9 objective

Dense response spectra at 25 periods, Arias-energy timing, 20 Fourier-energy
bands, 16 time-window RMS and peak descriptors, and 152 spectral polynomial
terms were tested with development-selected reduced-rank ridge models. None
improved on the compact 16-feature spectral representation. The selected
fixed-split rank-5 model has mean R2 = 0.719, with 7 of 67 variable outputs
above 0.9.

As a deliberately optimistic diagnostic, selecting the best fixed-test result
for each output across all model families already evaluated gives mean R2 =
0.732 and only 8 of 67 outputs above 0.9. This is not a valid predictive model
because it uses test outcomes for selection. It demonstrates that further
selection among the present model and feature families cannot support a claim
that most responses exceed 0.9. Reaching that level will require new
information: more FLAC2D simulations, modal-period/transfer-function features,
or a validated representation learned directly from the acceleration history.

### Development-only modal-period analysis

Input-to-response transfer shapes were estimated from 69 stable development
simulations and 4,623 nonconstant record--point histories. The fixed test
records and every failed history were excluded. Detrended transfer peaks were
aggregated across the seven response families. Two candidates were highly
consistent across families: 1.700 s (family range 1.667--1.700 s) and 0.802 s
(0.802--0.817 s). A third, less stable candidate was 0.476 s
(0.393--0.535 s). These are operational modal-period candidates inferred from
forced-response histories; they should not be described as formal eigenmodes
until confirmed by a small-strain FLAC2D eigenvalue, free-vibration, or
low-amplitude pulse analysis.

Adding Sa at these periods and their half/double-period neighbors produced
development OOF R2 = 0.624, compared with 0.630 for the compact 16-feature
spectral set. Development selection therefore retained the 16-feature rank-5
model. Its fixed-test result remained mean R2 = 0.719, with 7 of 67 outputs
above 0.9. The modal analysis improved physical interpretation but did not
improve predictive accuracy with the current database.

## Superseded scalar-paper recommendation

This recommendation applied to the scalar-demand draft and is retained for
provenance. The revised paper should center the cumulative response-evolution
workflow and describe the scalar formulation as a harder terminal-demand
benchmark. It should report the ten-split 0.8321 result as primary and state
plainly that FMRVR supplies a small nonlinear residual correction to a strong
regularized trajectory backbone.

To support a robust global R2 above 0.7, the next simulations should form a new
locked external test set. Additional records should target sparse regions of
the 16-feature space and balance stable and failed outcomes. A FLAC modal or
transfer-function analysis should also identify the dam's dominant periods so
that spectral ordinates can be placed at physically verified periods rather
than only the generic 0.1--3.0 s grid.

## Technical sources

- USGS explains why spectral acceleration reflects oscillator response near a
  structure's period: https://www.usgs.gov/programs/earthquake-hazards/science/earthquake-hazards-201-technical-qa
- PEER NGA-West2 uses 5%-damped pseudo-absolute spectral acceleration over a
  broad period range: https://peer.berkeley.edu/node/1372
- MATLAB exact Gaussian-process and ARD-kernel implementation:
  https://www.mathworks.com/help/stats/fitrgp.html
- MATLAB LSBoost implementation:
  https://www.mathworks.com/help/stats/ensemble-algorithms.html
- Multi-output Gaussian-process background: Alvarez et al., JMLR 12,
  https://jmlr.csail.mit.edu/papers/volume12/alvarez11a/alvarez11a.pdf
- Original sparse Bayesian learning/RVM framework and input-scale optimization:
  Tipping, JMLR 1, https://www.jmlr.org/papers/v1/tipping01a.html
- Ha and Zhang's matrix-Gaussian FMRVR formulation:
  https://doi.org/10.1016/j.econmod.2019.04.007
- A mixed multi-output RVM applied to rockfill-dam inversion:
  https://doi.org/10.1108/EC-09-2019-0429
- PEER's framework for testing whether an intensity measure is sufficient for
  an engineering demand parameter:
  https://peer.berkeley.edu/node/1339
- PEER research identifying Sa(T) and Sa at multiples of the structural period
  as efficient predictors for earth slopes and other nonlinear systems:
  https://apps.peer.berkeley.edu/publications/annual_report/old_ar/year7/yr7_projects/ta2/2362003.html
- PEER's 2025 report on learning structural response from ground-motion
  histories and physics-informed sequence models:
  https://peer.berkeley.edu/node/1932
