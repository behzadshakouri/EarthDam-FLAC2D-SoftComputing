function summary = run_elm_difficult_cases_sampling_sweep(pga_caps)
%RUN_ELM_DIFFICULT_CASES_SAMPLING_SWEEP Test development-data coverage.
% Keeps the ELM architecture fixed at 30 hidden neurons and changes only
% maxPGAperTemplate for the five difficult response-location cases. Each
% cap is written to a separate directory, so production results and prior
% sweeps are not overwritten.

if nargin < 1 || isempty(pga_caps)
    pga_caps = [10 25 50 100];
end
validateattributes(pga_caps, {'numeric'}, ...
    {'vector','integer','positive','finite'}, mfilename, 'pga_caps');
pga_caps = unique(pga_caps(:)', 'stable');

root = setup_task2;
cfg = task2_config(root);
assert(exist(cfg.split_file, 'file') == 2, ...
    'Fixed split is missing. Complete data preparation before this sweep.');

cases = [7 5; 9 3; 10 4; 10 6; 10 7];
sweep_root = fullfile(root, 'results', ...
    'elm_difficult_cases_sampling_sweep');
if ~exist(sweep_root, 'dir'), mkdir(sweep_root); end

summary = table();

for cap = pga_caps
    out_dir = fullfile(sweep_root, sprintf('ELM_N030_PGACAP_%03d', cap));

    override = struct();
    override.elm = cfg.production.elm;
    override.elm.hidden_neurons = 30;
    override.max_pga_per_template = cap;
    override.make_case_plots = false;
    override.make_summary_plots = false;
    override.resume = true;

    fprintf('\n====================================================\n');
    fprintf('ELM difficult-case sampling sweep: cap = %d\n', cap);
    fprintf('Hidden neurons: 30\n');
    fprintf('Output: %s\n', out_dir);
    fprintf('====================================================\n');

    run_all_models({'ELM'}, cases, out_dir, override);

    metrics_file = fullfile(out_dir, 'task2_elm_metrics.csv');
    T = readtable(metrics_file);

    cap_column = repmat(cap, height(T), 1);
    T = addvars(T, cap_column, ...
        'Before', 1, 'NewVariableNames', 'max_pga_per_template');
    summary = [summary; T]; %#ok<AGROW>

    summary = sortrows(summary, ...
        {'point','response','max_pga_per_template'});
    writetable(summary, fullfile(sweep_root, ...
        'elm_difficult_cases_sampling_sweep_summary.csv'));
    save(fullfile(sweep_root, ...
        'elm_difficult_cases_sampling_sweep_summary.mat'), ...
        'summary', 'pga_caps', 'cases', '-v7.3');
end

disp(summary(:, {'max_pga_per_template','point','response', ...
    'R2','nRMSE','nMAE','a10','n_test','train_s'}));

fprintf('\nSummary written to:\n%s\n', fullfile(sweep_root, ...
    'elm_difficult_cases_sampling_sweep_summary.csv'));
end
