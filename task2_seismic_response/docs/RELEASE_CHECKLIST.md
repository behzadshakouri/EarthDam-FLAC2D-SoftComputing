# Release checklist

- [x] Four production methods retained.
- [x] Final hidden-neuron configuration set to 30/15/15/5.
- [x] Fixed realization-level split and safe-domain screening retained.
- [x] All twelve sweep metric tables included and reconciled.
- [x] Selected-model aggregation and plotting entry point included.
- [x] Failure-screening tables and canonical plots included.
- [x] YPEA source pinned with MIT license.
- [x] I-GWO source/helpers included with original license.
- [x] LabCISNE ELM lineage credited without redistributing its class.
- [x] Dependency checker, synthetic test, license, and citation included.
- [x] Raw FLAC2D histories and trained checkpoints excluded.

Before creating a tagged GitHub release, run in the target MATLAB environment:

```matlab
setup_task2;
check_task2_dependencies;
run_synthetic_self_test;
```

Then run the complete private-data workflow and confirm the generated metrics
against `reference_results/final_selected_summary.csv` within the expected
stochastic tolerance of the optimized methods.
