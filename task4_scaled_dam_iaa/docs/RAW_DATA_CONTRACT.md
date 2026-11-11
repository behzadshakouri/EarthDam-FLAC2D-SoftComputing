# Task 4 raw-data contract

The confirmed database contains 450 scaled-dam IAA simulations:

| Task 4 IDs | Scale factor | Count |
|---:|---:|---:|
| 1--150 | 0.25 | 150 |
| 151--300 | 0.50 | 150 |
| 301--450 | 1.50 | 150 |

`Task4.Inputs` presently contains only `Simulations = 450`. It does not contain
the random-variable/predictor matrix, IAA input histories, or evidence that
equal within-scale row numbers are paired across scales.

`Task4.Outputs` contains `dytime{1:450}` and `P1`--`P10`; each point contains
`R1`--`R7`, and every response is a 450-element cell array of variable-length
histories. Values with magnitude at least `1e30`, NaN, or Inf are treated as
invalid output sentinels.
