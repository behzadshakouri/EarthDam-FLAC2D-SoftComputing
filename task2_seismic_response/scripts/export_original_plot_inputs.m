function plotRoots = export_original_plot_inputs(resultsDir)
%EXPORT_ORIGINAL_PLOT_INPUTS Convert saved reviewer-valid results to the
% P#/R#/*_obs_pred.csv layout used by the author's original plot functions.
% No metric, prediction, or plotting equation is changed.
root = setup_task2;
cfg = task2_config(root);
if nargin < 1 || isempty(resultsDir), resultsDir = cfg.results_dir; end
resultsDir = char(resultsDir);
if ~isfolder(resultsDir)
    error('Task2:ResultsFolderNotFound','Results folder does not exist: %s',resultsDir);
end
models = {'ELM','ELMABC','ELMACOR','ELMIGWO'};
plotRoots = struct;
savedCaseCount = 0;
for im = 1:numel(models)
    method = models{im};
    sourceDir = fullfile(resultsDir, method);
    targetRoot = fullfile(resultsDir, 'original_plot_inputs', method);
    plotRoots.(method) = targetRoot;
    if ~isfolder(sourceDir), continue; end
    files = dir(fullfile(sourceDir, 'P*_R*.mat'));
    savedCaseCount = savedCaseCount + numel(files);
    for k = 1:numel(files)
        S = load(fullfile(files(k).folder,files(k).name),'case_result');
        cr = S.case_result;
        required = {'y_test','y_pred','test_step','test_sim_ids'};
        missing = required(~isfield(cr,required));
        if ~isempty(missing)
            error('Task2:MissingSavedPredictions','%s lacks fields required by the original plots: %s.',files(k).name,strjoin(missing,', '));
        end
        caseDir = fullfile(targetRoot,sprintf('P%d',cr.point),sprintf('R%d',cr.response));
        if ~isfolder(caseDir), mkdir(caseDir); end
        time_s = double(cr.test_step(:))*cfg.time_step_s;
        step_id = double(cr.test_step(:));
        sim_id = double(cr.test_sim_ids(:));
        y_obs = double(cr.y_test(:));
        y_pred = double(cr.y_pred(:));
        status = repmat("SAFE",numel(y_obs),1);
        T = table(time_s,step_id,sim_id,y_obs,y_pred,status);
        outFile = fullfile(caseDir,sprintf('%s_P%d_R%d_obs_pred.csv',method,cr.point,cr.response));
        writetable(T,outFile);
    end
end
if savedCaseCount == 0
    error('Task2:NoSavedCases', ...
        'No saved P#_R#.mat model cases were found under: %s',resultsDir);
end
fprintf('Original-plot CSV inputs exported under: %s\n',fullfile(resultsDir,'original_plot_inputs'));
end
