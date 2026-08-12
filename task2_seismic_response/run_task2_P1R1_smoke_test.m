%% RUN_TASK2_P1R1_SMOKE_TEST
% End-to-end validation of P1-R1 with the four original FULL70 methods.
% This script rebuilds the canonical dataset and failure database, then runs
% only P1-R1. Outputs are isolated under results/P1R1_smoke_test so they can
% never be resumed by or overwrite the production FULL70 run.

clearvars;
close all;
clc;

scriptFile = mfilename('fullpath');
if isempty(scriptFile)
    projectRoot = pwd;
else
    projectRoot = fileparts(scriptFile);
end
cd(projectRoot);
setup_task2;

fprintf('\nTask 2 end-to-end P1-R1 smoke test\n');
fprintf('Methods: ELM, ELMABC, ELMACOR, ELMIGWO\n');
fprintf('The production hyperparameters are retained (including 1000 optimizer iterations).\n\n');

% Fail early if dependencies from the user's original methods are absent.
requiredYPEA = {'ypea_problem','ypea_var','ypea_abc','ypea_acor'};
missingYPEA = requiredYPEA(cellfun(@(f) exist(f,'file') == 0,requiredYPEA));
requiredIGWO = {'IGWO','initialization','boundConstraint','pdist','pdist2','squareform'};
missingIGWO = requiredIGWO(cellfun(@(f) exist(f,'file') == 0,requiredIGWO));
if ~isempty(missingYPEA) || ~isempty(missingIGWO)
    missing = [missingYPEA,missingIGWO];
    error('Task2:MissingOriginalDependencies', ...
        ['Missing dependencies used by your original FULL70 methods: %s. ' ...
         'Add the same YPEA files and MATLAB toolboxes/helpers used by your original runs, then rerun.'], ...
        strjoin(unique(missing,'stable'),', '));
end

cfg = task2_config(projectRoot);
fprintf('[1/4] Rebuilding canonical consolidated dataset...\n');
run_data_preparation;

fprintf('\n[2/4] Rebuilding response-specific failure/admissibility database...\n');
run_failure_screening;

fprintf('\n[3/4] Creating/verifying the fixed 210/90 realization split...\n');
split = create_realization_split(cfg);
save(cfg.split_file,'split');
assert(numel(split.development_ids) == cfg.development_count);
assert(numel(split.test_ids) == cfg.test_count);
assert(isempty(intersect(split.development_ids,split.test_ids)));
fprintf('Development realizations: %d | held-out test realizations: %d | overlap: 0\n', ...
    numel(split.development_ids),numel(split.test_ids));

fprintf('\n[4/4] Running only P1-R1 with all four original methods...\n');
runStamp = datestr(now,'yyyymmdd_HHMMSS');
smokeResultsDir = fullfile(projectRoot,'results',['P1R1_smoke_test_' runStamp]);
models = {'ELM','ELMABC','ELMACOR','ELMIGWO'};
results = run_all_models(models,[1 1],smokeResultsDir);

assert(height(results) == 4,'Expected exactly four P1-R1 model results.');
assert(all(results.point == 1 & results.response == 1), ...
    'Smoke-test output contains a case other than P1-R1.');
writetable(results,fullfile(smokeResultsDir,'P1R1_all_methods_metrics.csv'));
save(fullfile(smokeResultsDir,'P1R1_all_methods_results.mat'),'results','split','-v7.3');

fprintf('\nGenerating the author-original plots from saved P1-R1 predictions...\n');
generate_original_task2_plots(smokeResultsDir,1,1);

fprintf('\nP1-R1 smoke test completed successfully.\n');
disp(results);
fprintf('Outputs: %s\n',smokeResultsDir);
