# Implementation status

Implemented:

- confirmed scale-block metadata;
- structural validation of all 450-by-70 histories;
- first-sentinel truncation audit;
- response/time-length consistency checks;
- per-history and grouped CSV QC exports;
- public-data-free synthetic self-test.
- Task 2-derived interpolation, cumulative response envelopes, and v4.2
  response-specific onset masking, with explicit finite-sentinel exclusion;
- separate raw-prefix and screened-domain usability reporting.
- native-history preparation that preserves ordinary finite early endings and
  carries only explicit failure sentinels to the 20 s analysis boundary;
- a combined 750-record, four-scale data set with 17 predictors (14 material
  variables, water level, running PGA, and scale), 70 positive
  nondecreasing response envelopes, and response-specific admissibility masks;
- ten point-wise FMRVR models, each jointly predicting the seven response
  quantities at one response-extraction point;
- matched fixed-split development checks with random forest, approximate
  Gaussian SVR, and plain ELM;
- a single prediction wrapper that executes all ten FMRVR point models and
  returns the 70 outputs in point-major order;
- a final-results figure generator for repeated validation, response and point
  summaries with outer-split standard-deviation bars, the 70-output map,
  scale audit, and all-70 observed-versus-
  predicted panel.

Validated production finding:

- Across ten record-level, scale-stratified outer splits, point-wise FMRVR gives
  mean R2 = 0.8842 +/- 0.0042 across the 67 nonconstant outputs. Mean median R2
  is 0.8846; on average, about 57 outputs exceed R2 = 0.8 and 26 exceed 0.9.
- Training the ten point models takes 51.5 s on average. After five warmups,
  the median of 100 measured full all-70 predictions is 1.198 s for 150
  held-out records, or 0.00799 s per record.
- Earlier comparator pilots used the superseded exploratory predictor matrix
  and cannot be compared with this 17-predictor production result. They are
  therefore excluded from algorithm-ranking claims.

Scope retained for future extensions:

- leave-one-scale-out transfer checks for extrapolation to an unseen scale;
- matched RF, SVR, plain ELM, or Task 2 ELM-IGWO comparisons if a future study
  is intended to rank algorithms under the final 17-predictor contract.

The present manuscript limits its claim to scale-stratified interpolation and
does not use unmatched comparator pilots to establish superiority. The primary
submission draft has been converted to the Infrastructures template.

Rejected global-peak, response-family, and other development pilots remain
separate from production evidence.

A development-only difficult-point study also tested `asinh` and untransformed
targets, scale normalization, and 120 instead of 80 centers at P3, P7, and
P10. P3 improved modestly with `asinh`, but the implied aggregate gain was only
about 0.002--0.003; the P7 and P10 alternatives were negligible or traded a
small nRMSE reduction against lower R2. The uniform 80-center log-transform
specification was therefore retained for methodological consistency.
