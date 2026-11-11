function [dataset, qc] = load_and_prepare_task3_data(cfg)
%LOAD_AND_PREPARE_TASK3_DATA Load the private MAT database and prepare it.
assert(exist(cfg.raw.task3_data_file,'file') == 2, ...
    'Task3Data.mat not found. Configure task3_local_paths.m.');
loaded = load(cfg.raw.task3_data_file, 'Task3');
assert(isfield(loaded,'Task3'), 'The MAT-file must contain variable Task3.');
[dataset, qc] = build_task3_dataset(loaded.Task3, cfg);
end
