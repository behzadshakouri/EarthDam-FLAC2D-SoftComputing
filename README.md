# EarthDam-FLAC2D-SoftComputing

Research software and reproducibility materials for a multi-task program on
FLAC2D-based earth-dam analysis, uncertainty assessment, failure screening,
and machine-learning surrogate modeling.

This repository complements—but does not replace—the independent general
automation project
[`Dam_Model_FLAC2D_Runner`](https://github.com/behzadshakouri/Dam_Model_FLAC2D_Runner).
That repository manages reusable FLAC2D simulation execution. This repository
contains paper- and task-specific scientific processing, surrogate models,
evaluation, figures, and reproducibility records.

## Research tasks

| Task | Scope | Repository status |
|---|---|---|
| Task 1 | First-impoundment modeling and sensitivity analysis | Paper-derived workflow and published reference results; validation pending |
| Task 2 | Seismic-response simulation and ELM-based surrogates | Complete reproducibility package |
| Tasks 3-4 | Future research extensions | Added only when publishable code or documentation is available |

The repository intentionally contains no empty Task 3 or Task 4 directories.
See [`REPOSITORY_STATUS.md`](REPOSITORY_STATUS.md) for the latest structural
audit and remaining environment-specific validation steps.

## Current structure

```text
EarthDam-FLAC2D-SoftComputing/
├── README.md
├── LICENSE
├── CITATION.cff
├── ROADMAP.md
├── REPOSITORY_STATUS.md
├── common/
├── task1_first_impoundment/
└── task2_seismic_response/
```

### Task 1: first impoundment

The publication record for Task 1 is documented under
[`task1_first_impoundment/`](task1_first_impoundment/). It includes the
published Computers and Geotechnics article, the IWA World Water Congress &
Exhibition 2022 conference paper, and the 2024 sensitivity-analysis article in
Water and Irrigation Management. Task 1 now provides a portable paper-derived workflow, paper-specific configuration,
data contracts, response and FoS modeling, tests, third-party dependencies, and
all original author-supplied MATLAB scripts preserved for provenance. MATLAB
execution and published-value parity validation remain release-checklist items. Raw FLAC2D
data and machine-specific case-study files remain outside Git.

### Task 2: seismic response

The current complete implementation is under
[`task2_seismic_response/`](task2_seismic_response/). It includes:

- ELM, ELM-ABC, ELM-ACOR, and ELM-IGWO;
- response-specific numerical-instability screening;
- a fixed 210-development/90-test realization split;
- all twelve hidden-neuron sensitivity configurations;
- final selected configurations: ELM-30, ABC-15, ACOR-15, IGWO-5;
- reference metrics, aggregation, plots, tests, dependency sources, and
  licensing information.

Start with [`task2_seismic_response/README.md`](task2_seismic_response/README.md).

## Citation

If you use the paper-specific workflows or reproducibility materials in this
repository, please cite this software repository and the relevant publication.
Machine-readable metadata are provided in [`CITATION.cff`](CITATION.cff).

- Shakouri, B., Mohammadi, M., Safari, M. J. S., & Hariri-Ardebili, M. A.
  (2023). A collaborative numerical simulation-soft computing approach for
  earth dams first impoundment modeling. *Computers and Geotechnics, 164*,
  105814. https://doi.org/10.1016/j.compgeo.2023.105814
- Shakouri, B., Mohammadi, M., Safari, M. J. S., & Hariri-Ardebili, M. A.
  (2022). First Impoundment Response Analysis of an Earth Dam using Coupled
  Numerical-Soft Computing technique. *IWA World Water Congress & Exhibition
  2022*.
- Shakouri, B., Mohammadi, M., & Safari, M. J. S. (2024). Sensitivity analysis
  for uncertainty quantification in earth dams modeling (Case study: Maku
  dam). *Water and Irrigation Management, 14*(1), 75–90.
  https://doi.org/10.22059/jwim.2023.360452.1084

### Related automation software

For the reusable MATLAB–FLAC2D execution and archiving framework used alongside
these paper-specific workflows, see and cite:

- Shakouri, B. (2026). *Dam_Model_FLAC2D_Runner* (Version 0.1.0) [Computer
  software]. GitHub.
  https://github.com/behzadshakouri/Dam_Model_FLAC2D_Runner

## Releases

Each paper-specific reproducibility snapshot should receive its own tag:

```text
task1-v1.0.0
task2-v1.0.0
```

Future development may continue on the default branch without changing an
archived paper release. A release DOI can be added to the task-specific
citation record when the GitHub release is archived.

## Data policy

Large or restricted FLAC2D datasets are not committed. Each task documents its
required inputs, representative/reference results, and regeneration steps.
Complete datasets may be made available under the associated article's data-
availability statement.

## License and attribution

Project-authored code is released under the root MIT license. Task-specific
third-party components remain under their original licenses and notices. See the task-specific `THIRD_PARTY_NOTICES.md` files for dependency records.
