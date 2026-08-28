# Repository status

Last structural audit: 2026-08-28

## Task 1: first impoundment

- Paper-derived portable MATLAB workflow is present.
- Response production covers 10 QoIs, four responses, four methods, and sample
  sizes 50, 100, 150, 200, 300, 400, and 500.
- FoS production covers four methods across the same seven sample sizes.
- Published Tables 7 and 8 are included as restrained CSV reference targets.
- Seventy original MATLAB scripts are retained under `legacy` for provenance.
- Raw datasets, generated checkpoints, FLAC2D case files, FISH files, and
  machine-specific operational paths are excluded from the canonical package.
- MATLAB execution and published-value parity validation remain pending and
  are tracked in the Task 1 release checklist.

## Task 2: seismic response

- Complete paper-specific MATLAB workflow, safe-domain screening, fixed split,
  four production methods, twelve neuron-sweep configurations, plotting,
  tests, and reference metrics are present.
- Version-pinned YPEA and I-GWO dependencies and their licenses are included.
- Raw FLAC2D histories and generated checkpoints are excluded.
- Before tagging a release, rerun the documented dependency, synthetic, and
  private-data validation commands in the target MATLAB environment.

## Repository-wide audit checks

- Both tasks contain README, citation, license, version, setup, dependency,
  production, test, data-contract, legacy, and reference-result components.
- No `.mat`, `.xlsx`, `.xls`, `.dat`, or `.fis` data/model files are committed
  within either task package.
- Published reference results are stored as auditable CSV files.
- Task-specific code and historical scripts remain separated.
- General FLAC2D batch execution remains in `Dam_Model_FLAC2D_Runner`.

This audit records repository structure and static consistency. It does not
substitute for execution in MATLAB with the complete private datasets.
