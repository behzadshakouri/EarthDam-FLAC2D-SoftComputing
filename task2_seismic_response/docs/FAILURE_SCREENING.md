# Failure screening and represented domain

Screening is applied separately to every realization, monitoring point, and
response. A detected onset row and every later row from that same history are
excluded. Models therefore represent the mechanically admissible pre-failure
domain; they are not post-failure predictors.

The detector algorithm is the preserved `detect_failure_per_sim_col17_v4_2`,
implemented in this package as `legacy_v4_2_adapter`. It combines a
response-specific baseline level, a derivative z-score jump, and a
sustained-hold criterion. The selected parameter set was described in the
historical scripts as the "v5 strategy carried forward," but that label refers
to the parameter/masking workflow rather than to a different detector
algorithm. `build_row_valid_from_step_fail_v5` converts the detected onset into
the rule that the onset row and all later rows are inadmissible. The historical
`FAILURE_TIMES_v6.mat` name identifies the aggregate 70-case container; its
builder explicitly retains the v4.2 detector unchanged.

Original detector source `detect_failure_per_sim_col17_v4_2.m` checked in the
authors' external source archive on 2026-09-20.

SHA-256: `0A3831F056D928160BE70ECC5B890E72A0C87D8DC8A162ACA0F0A57585702893`

The configuration is stored in every rebuilt failure database and exported by
`generate_failure_screening_report`.

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
