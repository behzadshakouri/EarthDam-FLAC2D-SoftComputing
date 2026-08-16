function summary = run_elm_difficult_cases_sweep()
% Targeted plain-ELM capacity test for the difficult response-location cases.
%
% Neuron selection must be based on development-validation RMSE, not testing
% R2. The fixed 90-realization testing set remains evaluation-only.

root = setup_task2;
cfg = task2_config(root);

cases = [
     7  5   % P7-R5: pore-water pressure
    10  4   % P10-R4: vertical normal stress
    10  6   % P10-R6: incremental shear strain
    10  7   % P10-R7: incremental volumetric strain
     9  3   % P9-R3: horizontal normal stress
];

neuron_counts = [30 50 75 100 150];

sweep_root = fullfile(root, 'results', ...
    'elm_difficult_cases_neuron_sweep');

if ~exist(sweep_root, 'dir')
    mkdir(sweep_root);
end

summary = table();

for n = neuron_counts

    out_dir = fullfile(sweep_root, sprintf('ELM_N%03d', n));

    override = struct();
    override.elm = cfg.production.elm;
    override.elm.hidden_neurons = n;

    % Keep the number of candidate initializations fixed so that this
    % experiment tests neuron count rather than two factors simultaneously.
    override.elm.multistart_count = 30;
    override.elm.validation_fraction = 0.20;

    override.make_case_plots = false;
    override.make_summary_plots = false;
    override.resume = true;

    fprintf('\n====================================================\n');
    fprintf('ELM difficult-case sweep: %d hidden neurons\n', n);
    fprintf('Output: %s\n', out_dir);
    fprintf('====================================================\n');

    run_all_models({'ELM'}, cases, out_dir, override);

    for k = 1:size(cases,1)

        p = cases(k,1);
        r = cases(k,2);

        case_file = fullfile( ...
            out_dir, 'ELM', sprintf('P%d_R%d.mat', p, r));

        S = load(case_file, 'case_result');
        cr = S.case_result;

        validation_rmse = NaN;

        if isfield(cr, 'selection') && ...
                isstruct(cr.selection) && ...
                isfield(cr.selection, 'validation_rmse_scaled')

            validation_rmse = ...
                cr.selection.validation_rmse_scaled;
        end

        one = table( ...
            n, ...
            p, ...
            r, ...
            validation_rmse, ...
            cr.metrics.R2, ...
            cr.metrics.nRMSE, ...
            cr.metrics.nMAE, ...
            cr.metrics.a10, ...
            cr.metrics.n_test, ...
            cr.metrics.train_s, ...
            'VariableNames', { ...
            'hidden_neurons', ...
            'point', ...
            'response', ...
            'validation_RMSE_scaled', ...
            'test_R2', ...
            'test_nRMSE', ...
            'test_nMAE', ...
            'test_a10', ...
            'n_test', ...
            'train_s'});

        summary = [summary; one]; %#ok<AGROW>
    end

    writetable(summary, fullfile( ...
        sweep_root, ...
        'elm_difficult_cases_neuron_sweep_summary.csv'));

    save(fullfile( ...
        sweep_root, ...
        'elm_difficult_cases_neuron_sweep_summary.mat'), ...
        'summary', 'cases', 'neuron_counts', '-v7.3');
end

summary = sortrows(summary, ...
    {'point','response','hidden_neurons'});

writetable(summary, fullfile( ...
    sweep_root, ...
    'elm_difficult_cases_neuron_sweep_summary.csv'));

% Select the neuron count using development-validation performance only.
selection = table();

unique_cases = unique(summary(:,{'point','response'}), 'rows');

for k = 1:height(unique_cases)

    p = unique_cases.point(k);
    r = unique_cases.response(k);

    q = summary.point == p & summary.response == r;
    case_rows = summary(q,:);

    valid = isfinite(case_rows.validation_RMSE_scaled);

    if any(valid)
        candidates = case_rows(valid,:);
        [~, idx] = min(candidates.validation_RMSE_scaled);
        selected = candidates(idx,:);
        selection = [selection; selected]; %#ok<AGROW>
    end
end

writetable(selection, fullfile( ...
    sweep_root, ...
    'elm_difficult_cases_validation_selected.csv'));

disp(summary);
fprintf('\nValidation-selected configurations:\n');
disp(selection);

fprintf('\nSummary written to:\n%s\n', ...
    fullfile(sweep_root, ...
    'elm_difficult_cases_neuron_sweep_summary.csv'));

end