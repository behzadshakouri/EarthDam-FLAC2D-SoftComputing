# Task 3 Raw-Data Contract

## Required structure

```text
Task3
├── Inputs
│   ├── Simulations = 150
│   └── InputsMatrix(1:150)
│       ├── time
│       ├── accel
│       └── PGA
└── Outputs
    ├── Simulations = 150
    └── P1 ... P10
        └── R1 ... R7   (150-by-1 cell arrays)
```

Ground-motion time and acceleration vectors must have equal lengths, contain
finite values, and use strictly increasing time. Response-history lengths may
vary by realization. A magnitude of at least `1e30`, NaN, or Inf marks an
invalid FLAC2D value; the history is truncated immediately before its first
occurrence.

## Output mapping

The response matrix is P-major:

```text
1=P1R1, 2=P1R2, ..., 7=P1R7,
8=P2R1, ..., 70=P10R7.
```

The response dictionary and units are defined by
`config/task3_response_dictionary.m`. Reduction rules are centralized in
`config/task3_config.m` and recorded with the prepared dataset.

## Current feature and target contract

Nine descriptors are calculated directly from each acceleration history:
PGA, PGV, PGD, Arias intensity, CAV, 5--95% significant duration, acceleration
RMS, amplitude-weighted mean frequency, and predominant period. Acceleration
is currently declared in units of `g`; this must be verified against the
source generator before production execution.

The accepted response-evolution dataset adds record duration and six final
5%-damped spectral accelerations to form 16 record descriptors. At each of 100
equally spaced native-duration samples it adds elapsed time, duration fraction,
absolute acceleration, running PGA/PGV/PGD, running Arias intensity and its
fraction, running CAV and its fraction, running RMS acceleration, and six
running spectral accelerations. This gives 33 predictors. Every sample from a
record remains in one realization-level partition.

Targets are positive nondecreasing envelopes. R1, R2, R6, and R7 use
`cummax(abs(response))`; R3, R4, and R5 use
`cummax(abs(response-response(1)))`. Samples at and after the common numerical
runaway onset are excluded. Model predictions are projected back onto the same
nonnegative nondecreasing space using a per-record cumulative maximum.
