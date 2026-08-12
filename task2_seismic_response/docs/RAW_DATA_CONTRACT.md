# Preparation input contract

The canonical adapter reads the historical `Task2Data.mat` produced from the
FLAC2D histories. Configure unresolved paths in `config/task2_user_paths.m`.

The adapter must construct:

- `X`: `600000 x 16`, ordered by time step then realization;
- `Y`: `600000 x 10 x 7`, with dimensions row, point, response;
- each response history interpolated at `0.01:0.01:20.00` s;
- each target transformed using `cummax(abs(raw_response))`.

Row mapping:

```matlab
row = (step - 1) * 300 + realization;
time_s = step * 0.01;
```

The first 15 predictors are the physical realization inputs. Predictor 16 is
the cumulative absolute PGA envelope. The adapter prefers
`Task2.Inputs.InputsMatrix`; otherwise it reads `RVs+WL.xlsx`.

The response histories must cover the full canonical interval. Duplicate raw
times are removed stably before linear interpolation. Any missing source field,
insufficient time coverage, nonfinite input, dimension mismatch, or ambiguous
source file causes an explicit error.

The P1-P10 physical locations and the exact meanings/units of R6/R7 must still
be confirmed in the dictionaries before publication; the code does not infer
scientific labels from filenames.
