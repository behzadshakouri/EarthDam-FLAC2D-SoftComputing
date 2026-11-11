function cfg = task3_config(root)
%TASK3_CONFIG Single source of truth for the Task 3 workflow.
if nargin < 1 || isempty(root)
    root = fileparts(fileparts(mfilename('fullpath')));
end
cfg.root = root;
cfg.seed = 20260830;
cfg.num_realizations = 150;
cfg.num_points = 10;
cfg.num_responses = 7;
cfg.num_outputs = cfg.num_points * cfg.num_responses;
cfg.development_count = 105;
cfg.test_count = 45;
cfg.data_dir = fullfile(root, 'data');
cfg.split_dir = fullfile(root, 'splits');
cfg.raw = task3_user_paths(root);
cfg.results_root = cfg.raw.results_root;
cfg.results_dir = fullfile(cfg.results_root, 'final_production');
cfg.analysis_results_dir = cfg.raw.analysis_results_root;
cfg.output_root = cfg.raw.output_root;

% Ground-motion histories are presently interpreted as acceleration in g.
% Change this explicitly if the source database uses m/s^2.
cfg.features.acceleration_units = 'g';
cfg.features.gravity_m_s2 = 9.80665;
cfg.features.names = {'PGA_g','PGV_m_s','PGD_m','Arias_m_s', ...
    'CAV_m_s','D5_95_s','RMS_accel_g','mean_frequency_Hz', ...
    'predominant_period_s'};

% FLAC2D invalid-output sentinel and response reduction rules.
cfg.qc.sentinel_abs_threshold = 1e30;
cfg.qc.minimum_history_length = 2;
cfg.qc.constant_tolerance = 1e-12;
cfg.output.reduction_modes = {'max_absolute','max_absolute', ...
    'max_absolute_increment','max_absolute_increment', ...
    'max_absolute_increment','max_absolute','max_absolute'};

% Realization-level split and development-only preprocessing.
cfg.split_file = fullfile(cfg.split_dir, 'task3_realization_split.csv');
cfg.preprocessing.constant_tolerance = 1e-12;

% Original Ha--Zhang FMRVR with Gaussian RBF bases and a bias column.
cfg.fmrvr.kernel_type = '+gauss';
cfg.fmrvr.kernel_width_factors = [0.25 0.5 1 2 4];
cfg.fmrvr.cv_folds = 5;
cfg.fmrvr.max_iterations = 1000;
cfg.fmrvr.tolerance = 0.1;
cfg.fmrvr.selection_metric = 'mean_nrmse';
cfg.production.save_model_mat = true; % local/ignored; never committed

if exist('task3_user_settings', 'file') == 2
    cfg = task3_user_settings(cfg);
end
assert(cfg.development_count + cfg.test_count == cfg.num_realizations);
assert(cfg.num_outputs == 70);
end
