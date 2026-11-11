# Reference results

This directory contains compact Task 4 evidence suitable for source control.
Raw databases, complete prediction arrays, and trained model MAT files remain
ignored.

The primary result is a ten-split, record-level, scale-stratified validation of
ten ridge-free point-wise FMRVR models. Each model jointly predicts the seven
response envelopes at one response-extraction point; one wrapper returns all 70 outputs.

Across the 67 nonconstant outputs, mean R2 is 0.8842 +/- 0.0042, mean median R2
is 0.8846, mean nRMSE is 0.0556, mean nMAE is 0.0371, and mean a10 is 0.4698. On average, about 57
outputs exceed R2 = 0.8 and 26 exceed 0.9.

Under the final Task 2-compatible timing protocol, the median of 100 measured
all-70 calls is 1.198 s for 150 held-out records (0.00799 s per record) after
five warmups. Mean training time is 51.5 s for the ten point models.

The scale summary retains mean, median, lower-decile, lower-quartile, and
normalized-error diagnostics. Within-scale mean R2 is sensitive to narrow-range
outputs and must be interpreted with the median, lower quartile, and normalized
errors. The complete CSV retains the negative lower-tail scores.

Files:

- `pointwise_fmrvr_summary.csv`: aggregate validation result;
- `pointwise_fmrvr_outer_metrics.csv`: split-level metrics;
- `pointwise_fmrvr_per_output.csv`: all outputs across all splits;
- `pointwise_fmrvr_point_summary.csv`: response-extraction-point summary;
- `pointwise_fmrvr_response_summary.csv`: response-family summary;
- `pointwise_fmrvr_scale_summary.csv`: scale-specific audit;
- `pointwise_fmrvr_timing.csv`: training and prediction evidence; its raw
  model-size column is retained only for traceability;
- `pointwise_fmrvr_split_assignments.csv`: exact development/test membership
  for all 750 records and ten outer splits;
- `validated_workflow_verification.csv`: final artifact and consistency check.

The `difficult_point_fmrvr_option_*.csv` files document a development-only
rejected refinement. They must not be pooled with the outer-test evidence.
