# Common components

This directory contains utilities that are demonstrably shared by two or more
research tasks. Task-specific scientific workflows remain self-contained.

## MAT-file inventory

`mat_inventory/inventory_task_mat.m` creates a bounded recursive inventory of
a large MATLAB data file. Convenience entry points are provided for Tasks 1--4:

```matlab
addpath(fullfile(repositoryRoot,'common','mat_inventory'));
inventory_task1_mat
inventory_task2_mat
inventory_task3_mat
inventory_task4_mat
```

The generated `<MAT-name>_structure.txt` report is saved in the same folder as
the selected MAT-file. Generated reports and raw MAT-files are not committed.
