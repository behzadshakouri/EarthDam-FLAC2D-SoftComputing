%% RUN_TASK2_PRODUCTION
% Runs the reviewer-adapted production workflow while leaving all model
% algorithms inside the original-method call chain.
%
% Completed cases are resumed automatically. This script does not delete
% checkpoints and does not implement or modify ELM, ABC, ACOR, or IGWO.

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
cfg = task2_config(projectRoot);

fprintf('\nTask 2 production run\n');
fprintf('Project: %s\n', projectRoot);
fprintf('Methods: ELM, ELMABC, ELMACOR, ELMIGWO\n\n');

% The production dispatcher applies the fixed realization split,
% response-specific admissibility mask, train-only scaling, and the original
% FULL70 maxPGAperTemplate reduction. It then calls the configured original
% model methods and writes one checkpoint per P-R case.
results = run_all_models({'ELM','ELMABC','ELMACOR','ELMIGWO'},[],cfg.results_dir);

% Rebuild all available case and summary plots from saved checkpoints.
generate_original_task2_plots(cfg.results_dir);

fprintf('\nProduction workflow completed.\n');
fprintf('Metrics: %s\n', ...
    fullfile(cfg.results_dir,'task2_all_model_metrics.csv'));
fprintf('Results: %s\n', ...
    fullfile(cfg.results_dir,'task2_all_model_results.mat'));
fprintf('Plots:   %s\n', fullfile(cfg.results_dir,'plots','original','latest'));
