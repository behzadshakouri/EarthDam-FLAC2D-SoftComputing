# Roadmap

## Current release

- Complete MATLAB execution and published-value parity validation for the Task 1 paper-derived workflow while maintaining its verified publication record.
- Publish the complete Task 2 seismic-response reproducibility workflow.
- Keep the FLAC2D runner in its independent general-purpose repository.

## Future tasks

New task directories will be added only when they contain meaningful,
reviewable material. Shared, genuinely task-independent utilities may then be
promoted into `common/`; task-specific code remains inside its originating
task to preserve paper reproducibility.

## Compatibility policy

- Paper releases are immutable tags.
- Task entry points remain self-contained.
- Changes to shared utilities must not silently change archived task results.
- Large generated data, checkpoints, and plots remain outside Git history.
