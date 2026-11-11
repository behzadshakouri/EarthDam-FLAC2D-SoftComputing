function paths = task3_user_paths(root)
%TASK3_USER_PATHS Machine-specific paths kept outside tracked source code.
paths.task3_data_file = fullfile(root, 'data', 'Task3Data.mat');
paths.results_root = fullfile(root, 'results');
paths.analysis_results_root = fullfile(root, 'analysis', 'results');
paths.output_root = fullfile(root, 'output');
localFile = fullfile(root, 'config', 'task3_local_paths.m');
if exist(localFile, 'file') == 2
    paths = task3_local_paths(paths);
end
end
