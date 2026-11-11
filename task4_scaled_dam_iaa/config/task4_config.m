function cfg = task4_config(root)
%TASK4_CONFIG Confirmed Task 4 facts and conservative QC settings.
if nargin < 1 || isempty(root)
    root = fileparts(fileparts(mfilename('fullpath')));
end
cfg.root = root;
cfg.seed = 20260830;
cfg.num_simulations = 450;
cfg.num_points = 10;
cfg.num_responses = 7;
cfg.num_cases = 70;
cfg.scale_block_size = 150;
cfg.scale_factors = [0.25 0.50 1.50];
cfg.scale_ranges = [1 150; 151 300; 301 450];
cfg.expected_end_time_s = 20;
cfg.sentinel_abs_threshold = 1e30;
cfg.minimum_clean_samples = 2;
cfg.raw = task4_user_paths(root);
cfg.results_dir = cfg.raw.results_root;
cfg.output_root = cfg.raw.output_root;
% Cross-scale pairing is deliberately false until source evidence confirms it.
cfg.cross_scale_matching_confirmed = false;
% Task 2 v4.2 operational screening; scale-specific validation remains pending.
cfg.time_s = (0.01:0.01:20)';
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

end
