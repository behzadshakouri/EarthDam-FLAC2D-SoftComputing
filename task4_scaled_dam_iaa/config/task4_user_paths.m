function paths = task4_user_paths(root)
%TASK4_USER_PATHS Default private-data location with optional local override.
paths.task4_data_file = fullfile(root,'data','Task4Data.mat');
paths.task2_data_file = '';
paths.task4_rvs_file = '';
paths.task4_water_level_file = '';
paths.ground_motion_file = '';
paths.results_root = fullfile(root,'results');
paths.output_root = fullfile(root,'output');
if exist('task4_local_paths','file') == 2
    paths = task4_local_paths(paths);
end
end
