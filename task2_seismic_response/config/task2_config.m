function cfg = task2_config(root)
%TASK2_CONFIG Single source of truth for the rebuilt workflow.
if nargin < 1 || isempty(root)
    root = fileparts(fileparts(mfilename('fullpath')));
end
cfg.root = root;
cfg.seed = 20260810;
cfg.num_realizations = 300;
cfg.num_points = 10;
cfg.num_responses = 7;
cfg.num_time_steps = 2000;
cfg.time_step_s = 0.01;
cfg.time_s = (1:cfg.num_time_steps)' * cfg.time_step_s;
cfg.development_count = 210;
cfg.test_count = 90;
cfg.input_count = 16;
cfg.data_dir = fullfile(root, 'data');
% Isolate the final selected production workflow from sweep checkpoints.
cfg.results_dir = fullfile(root, 'results', 'final_production');
cfg.consolidated_file = fullfile(cfg.data_dir, 'task2_consolidated_dataset.mat');
cfg.failure_file = fullfile(cfg.data_dir, 'task2_failure_database.mat');
cfg.split_file = fullfile(cfg.data_dir, 'task2_realization_split.mat');
cfg.metrics_file = fullfile(cfg.results_dir, 'task2_case_metrics.csv');
cfg.raw = task2_user_paths(root);
cfg.elm.hidden_neurons = 30;
cfg.elm.ridge = 1e-4;
cfg.elm.activation = 'sigmoid';
% Production model settings. Metaheuristic values are preserved from the
% original FULL70 scripts supplied with this project.
cfg.production.models = {'ELM','ELMABC','ELMACOR','ELMIGWO'};
cfg.production.max_fit_samples = 50000;
cfg.production.max_pga_per_template = 10;
cfg.production.bound_scale = 2.0;
cfg.production.bound_cap = 10;
cfg.production.resume = true;
cfg.production.save_predictions = true;
cfg.production.progress_every = 10;
% The simplified replacement plot wrappers are retained only for backward
% compatibility. The author's original plotting suite is the default.
cfg.production.make_case_plots = false;
cfg.production.make_summary_plots = false;
% Final model-specific sizes selected by the controlled sensitivity sweep.
cfg.production.elm.hidden_neurons = 30;
cfg.production.elm.ridge = 1e-4;
cfg.production.elm.activation = 'sigmoid';
cfg.production.elm.multistart_count = 30;
cfg.production.elm.validation_fraction = 0.20;
cfg.production.abc.max_iter = 1000;
cfg.production.abc.pop_size = 30;
cfg.production.abc.onlooker_count = 20;
cfg.production.abc.max_acceleration = 0.4;
cfg.production.abc.hidden_neurons = 15;
cfg.production.acor.max_iter = 1000;
cfg.production.acor.pop_size = 40;
cfg.production.acor.sample_count = 40;
cfg.production.acor.q = 0.1;
cfg.production.acor.zeta = 1.0;
cfg.production.acor.hidden_neurons = 15;
cfg.production.igwo.max_iter = 1000;
cfg.production.igwo.pop_size = 30;
cfg.production.igwo.hidden_neurons = 5;
cfg.production.require_original_optimizers = true;
% Apply optional user overrides after defining the validated FULL70 defaults.
% Keep task2_user_settings.m unchanged when replacing future package versions.
if exist('task2_user_settings', 'file') == 2
    cfg = task2_user_settings(cfg);
end
neuron_counts = [cfg.production.elm.hidden_neurons, ...
    cfg.production.abc.hidden_neurons, ...
    cfg.production.acor.hidden_neurons, ...
    cfg.production.igwo.hidden_neurons];
assert(all(isfinite(neuron_counts) & neuron_counts >= 1 & ...
    neuron_counts == round(neuron_counts)), ...
    'Hidden-neuron counts must be positive integers.');
% Failure detector: settings carried forward from the previously validated
% detect_failure_per_sim_col17_v4_2 / v5 workflow.
cfg.detector.version = 'legacy_v4_2_adapter';
cfg.detector.smoothing_window = 11;
cfg.detector.baseline_s = [2 2 1 1 1 2 2];
cfg.detector.z_threshold = [6 6 5 5 5 6 6];
cfg.detector.level_factor = [50 50 2.5 2.5 2.5 50 50];
cfg.detector.hold_steps = [10 10 5 5 5 10 10];
cfg.detector.logic = ["and" "and" "or" "or" "or" "and" "and"];
cfg.detector.use_log = false;
cfg.detector.min_exceed_factor = 0.5;
cfg.detector.jump_only_hold = [1 1 3 3 3 1 1];
cfg.detector.jump_lookback_steps = [1 1 25 25 25 1 1];
cfg.detector.minimum_signal = 1e-12;
cfg.detector.minimum_derivative_std = 1e-12;
cfg.detector.absolute_jump_threshold = zeros(1, 7);
assert(cfg.time_s(1) == 0.01 && cfg.time_s(end) == 20.00);
assert(cfg.development_count + cfg.test_count == cfg.num_realizations);
end
