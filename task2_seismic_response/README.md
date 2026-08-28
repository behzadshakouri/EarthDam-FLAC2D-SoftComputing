# Earth Dam Task 2 MATLAB Surrogate-Modeling Workflow

This self-contained task package is part of the umbrella
`EarthDam-FLAC2D-SoftComputing` repository. Run all MATLAB commands from this
directory; `setup_task2` resolves paths relative to this task root.

Reproducible MATLAB workflow for seismic-response surrogate modeling of an
earth dam using ELM, ELM-ABC, ELM-ACOR, and ELM-IGWO. The package rebuilds the
70 point-response cases, detects response-specific numerical-instability
onset, restricts modeling to the admissible pre-failure domain, preserves a
fixed realization-level split, evaluates held-out predictions, and recreates
paper-ready tables and plots.

## Final selected configurations

| Method | Hidden neurons | Mean R2 | Mean nRMSE | Mean nMAE | Mean a10 | R2 >= 0.90 | Measured training time |
|---|---:|---:|---:|---:|---:|---:|---:|
| ELM | 30 | 0.8064 | 0.0704 | 0.0500 | 0.4762 | 13/67 | 7.81 s |
| ELM-ABC | 15 | 0.8500 | 0.0602 | 0.0424 | 0.5157 | 21/67 | 106.3 min |
| ELM-ACOR | 15 | 0.7568 | 0.0813 | 0.0589 | 0.4412 | 12/67 | 372.6 min |
| **ELM-IGWO** | **5** | **0.8857** | **0.0511** | **0.0348** | **0.5572** | **36/67** | **53.6 min** |

All values use the same fixed 210-development/90-test realization split. The
complete 12-configuration sensitivity table and the 70-case CSVs are under
`reference_results/`.

## Scientific conventions

- 300 realizations, 10 monitoring points, and 7 responses: 70 cases.
- 2,000 retained samples per history at 0.01 s intervals (0.01-20.00 s).
- Targets are cumulative absolute response envelopes.
- Instability screening is response- and location-specific.
- The detected onset row and every later row are excluded.
- Scaling and PGA-template reduction are fitted/applied on development data.
- Fixed test realizations are untouched by fitting. The neuron sweep is
  reported transparently as a fixed-test sensitivity comparison.
- Metrics use only held-out admissible test observations.
- Constant targets are handled explicitly (R5 at P8-P10 in the current data).

The surrogates represent the stable/pre-failure numerical domain and are not
post-failure predictors.

## Requirements

- MATLAB R2020a or newer
- Statistics and Machine Learning Toolbox (`pdist`, `pdist2`, `squareform`)
- Deep Learning Toolbox (`mapminmax`)
- Sufficient memory for the consolidated 600,000-row dataset

YPEA and I-GWO sources required by the supplied method lineage are bundled
under `third_party/` with their original licenses. Confirm the resolved
environment before running:

```matlab
setup_task2;
check_task2_dependencies;
run_synthetic_self_test;
```

## Required private inputs

Place or configure:

- `Task2Data.mat`, containing inputs and P1-P10/R1-R7 histories;
- one PGA source: `IAAPGA20sec.xlsx`, `IAA-20sec.xlsx`, or `IAAPGA20sec.mat`;
- `RVs+WL.xlsx` only when `Task2.Inputs.InputsMatrix` is unavailable.

Set non-discoverable paths in `config/task2_user_paths.m`. The complete FLAC2D
database is not redistributed; `reference_results/` provides auditable metrics
and the synthetic test provides a data-independent structural check.

To recreate the IAA methodology panels in manuscript Figure 3 from the signed
acceleration record, run:

```matlab
generate_iaa_methodology_figures('E:\path\to\IAA-20sec.xlsx');
```

The command creates the manuscript panels `a_PSA_heatmap.png` and
`b_PSV_heatmap.png`, together with the separate IAA acceleration-and-envelope
illustration `IAA.png`, under `results/final_manuscript_figures/`. The current
manuscript has no Figure 3(c). See `docs/FINAL_MANUSCRIPT_PLOTS.md` for input,
unit, and plotting options.

## Canonical workflow

```matlab
clear all;
clear functions;
rehash toolboxcache;

setup_task2;
check_task2_dependencies;
run_synthetic_self_test;
run_data_preparation;
run_failure_screening;
generate_failure_screening_report;
run_all_models;
generate_original_task2_plots;
```

`run_all_models` uses the final 30/15/15/5 configuration and checkpoints every
case under `results/final_production/<METHOD>/P#_R#.mat`. Repeating
the command resumes only configuration-compatible checkpoints.

## Reproduce the neuron sensitivity analysis

```matlab
run_method_neuron_sweep('ELM');
run_method_neuron_sweep('ELMABC');
run_method_neuron_sweep('ELMACOR');
run_method_neuron_sweep('ELMIGWO');
```

ELM uses 10, 20, and 30 neurons. Each optimized method uses 5, 10, and 15.
Outputs are isolated under `results/method_neuron_sweep/METHOD_N###`.

Generate sensitivity and log-runtime figures from either the completed live
summary or the bundled reference summary:

```matlab
generate_neuron_sweep_plots;
```

After all configurations finish, collect the four selected models and produce
their direct comparison:

```matlab
assemble_final_selected_results(true);
```

This validates all 280 selected checkpoints, writes final aggregate CSV/MAT
files, and calls the recovered original plotting suite.

## Failure-screening outputs

```matlab
run_failure_screening;
generate_failure_screening_report;
```

This writes the detector parameter table, case-wise failure summary, detected-
fraction heatmap, and onset-time heatmaps under `results/failure_screening`.
See `docs/FAILURE_SCREENING.md` for the criterion and its interpretation.

## Model implementation

The authors' original ELM workflow used the LabCISNE ELMToolbox class. The
canonical package uses a project-local functional implementation with sigmoid
activation, deterministic initialization, and ridge-regularized output weights
(ridge coefficient 1e-4). It does not require the external ELM class.

ABC, ACOR, and I-GWO optimize the hidden-layer input weights and biases. ELM
output weights remain determined analytically by ridge-regularized least
squares. The optimizers do not search over hidden-neuron count.

Method provenance, pinned versions, licenses, and citations are recorded in
`THIRD_PARTY_NOTICES.md`.

## Reproducibility records

Each case checkpoint records:

- model and effective hidden-neuron count;
- input/output scalers;
- fixed realization split;
- held-out observations and predictions;
- original row, realization, and time-step identifiers;
- convergence history and measured training time;
- R2, nRMSE, nMAE, and a10.

See `docs/PIPELINE.md`, `docs/AGGREGATE_AND_SPLIT_AUDIT.md`,
`docs/MODEL_PARITY_AUDIT.md`, `docs/FAILURE_SCREENING.md`, and
`docs/REVIEWER_READINESS.md`.

## License and citation

Project-authored code is released under the MIT license. Bundled third-party
files retain their original licenses. Cite the associated article and the
software record described in `CITATION.cff`.
