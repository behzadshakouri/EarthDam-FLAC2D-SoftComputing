function run_data_preparation()
%RUN_DATA_PREPARATION Rebuild the canonical dataset from historical Task2Data.
root = setup_task2;
cfg = task2_config(root);

paths = resolve_task2_input_paths(cfg);
fprintf('Task2 data : %s\n', paths.task2_data_file);
fprintf('PGA data   : %s\n', paths.pga_file);
if ~isempty(paths.inputs_file)
    fprintf('Inputs     : %s\n', paths.inputs_file);
end

source = load(paths.task2_data_file, 'Task2');
if ~isfield(source, 'Task2')
    error('Task2:MissingVariable', '%s does not contain variable Task2.', paths.task2_data_file);
end

[X, Y, preparation] = build_dataset_from_task2(source.Task2, paths, cfg);
dataset = assemble_consolidated_dataset(X, Y, cfg);
dataset.preparation = preparation;

if ~exist(cfg.data_dir, 'dir'), mkdir(cfg.data_dir); end
save(cfg.consolidated_file, 'dataset', '-v7.3');
fprintf('Saved canonical dataset: %s\n', cfg.consolidated_file);
fprintf('X: %d x %d | Y: %d x %d x %d | time: %.2f to %.2f s\n', ...
    size(X,1), size(X,2), size(Y,1), size(Y,2), size(Y,3), ...
    cfg.time_s(1), cfg.time_s(end));
end
