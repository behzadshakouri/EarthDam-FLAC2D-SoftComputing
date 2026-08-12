# Failure screening and represented domain

Screening is applied separately to every realization, monitoring point, and
response. A detected onset row and every later row from that same history are
excluded. Models therefore represent the mechanically admissible pre-failure
domain; they are not post-failure predictors.

The detector is the preserved `legacy_v4_2_adapter`. It combines a response-
specific baseline level, a derivative z-score jump, and a sustained-hold
criterion. The configuration is stored in every failure database and exported
by `generate_failure_screening_report`.

| Response | Baseline (s) | z threshold | Level factor | Hold steps | Logic |
|---|---:|---:|---:|---:|---|
| R1 | 2 | 6 | 50 | 10 | jump AND level |
| R2 | 2 | 6 | 50 | 10 | jump AND level |
| R3 | 1 | 5 | 2.5 | 5 | sustained level/jump |
| R4 | 1 | 5 | 2.5 | 5 | sustained level/jump |
| R5 | 1 | 5 | 2.5 | 5 | sustained level/jump |
| R6 | 2 | 6 | 50 | 10 | jump AND level |
| R7 | 2 | 6 | 50 | 10 | jump AND level |

These parameters reproduce the previously validated failure-screening
workflow; they are operational numerical-instability criteria rather than
physical limit-state thresholds. Their purpose is to exclude histories after
loss of numerical/mechanical admissibility. The manuscript should state this
distinction and avoid interpreting detector onset as a calibrated dam-failure
probability.

Regenerate the database and auditable summaries with:

```matlab
run_failure_screening;
generate_failure_screening_report;
```
