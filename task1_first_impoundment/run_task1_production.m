%% RUN_TASK1_PRODUCTION
% Validates private inputs and runs checkpointed paper-method experiments.
clearvars; close all; clc;
root=setup_task1; cfg=task1_config(root);
D=load_task1_dataset(cfg);
summary=run_task1_experiments(D,cfg); %#ok<NASGU>
fprintf('Task 1 production workflow completed: %s\n',cfg.results_dir);
