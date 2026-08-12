function summary = assemble_final_selected_results(make_plots)
%ASSEMBLE_FINAL_SELECTED_RESULTS Collect the four sweep-selected models.
% ELM=30, ELM-ABC=15, ELM-ACOR=15, and ELM-IGWO=5.
if nargin<1,make_plots=true;end
root=setup_task2;
spec={ 'ELM',30;'ELMABC',15;'ELMACOR',15;'ELMIGWO',5 };
sweepRoot=fullfile(root,'results','method_neuron_sweep');
outRoot=fullfile(root,'results','final_selected_models');
if ~isfolder(outRoot),mkdir(outRoot);end
allRows=table(); summary=table();
for i=1:size(spec,1)
    method=spec{i,1}; neurons=spec{i,2};
    sourceDir=fullfile(sweepRoot,sprintf('%s_N%03d',method,neurons),method);
    targetDir=fullfile(outRoot,method);
    if ~isfolder(sourceDir)
        error('Task2:MissingSelectedSweep','Missing selected sweep: %s',sourceDir);
    end
    if ~isfolder(targetDir),mkdir(targetDir);end
    files=dir(fullfile(sourceDir,'P*_R*.mat'));
    if numel(files)~=70
        error('Task2:IncompleteSelectedSweep','%s contains %d/70 cases.',sourceDir,numel(files));
    end
    rows=table();
    for k=1:numel(files)
        sourceFile=fullfile(files(k).folder,files(k).name);
        S=load(sourceFile,'case_result'); cr=S.case_result;
        saved=checkpoint_neurons(cr);
        if isempty(saved)||saved~=neurons
            error('Task2:SelectedCheckpointMismatch','%s is not a %d-neuron checkpoint.',sourceFile,neurons);
        end
        copyfile(sourceFile,fullfile(targetDir,files(k).name),'f');
        rows=[rows;cr.metrics]; %#ok<AGROW>
    end
    rows=sortrows(rows,{'point','response'});
    writetable(rows,fullfile(outRoot,sprintf('task2_%s_selected_metrics.csv',lower(method))));
    modeled=~rows.constant_reference & isfinite(rows.R2);
    one=table(string(method),neurons,height(rows),sum(modeled), ...
        mean(rows.R2(modeled),'omitnan'),median(rows.R2(modeled),'omitnan'), ...
        mean(rows.nRMSE(modeled),'omitnan'),mean(rows.nMAE(modeled),'omitnan'), ...
        mean(rows.a10(modeled),'omitnan'),sum(rows.R2(modeled)>=0.90), ...
        sum(rows.train_s,'omitnan'), ...
        'VariableNames',{'method','hidden_neurons','case_count','modeled_cases', ...
        'mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10', ...
        'cases_R2_ge_090','total_train_s'});
    summary=[summary;one]; allRows=[allRows;rows]; %#ok<AGROW>
end
writetable(allRows,fullfile(outRoot,'task2_final_selected_metrics.csv'));
writetable(summary,fullfile(outRoot,'task2_final_selected_summary.csv'));
save(fullfile(outRoot,'task2_final_selected_results.mat'),'allRows','summary','spec','-v7.3');
if make_plots,generate_original_task2_plots(outRoot,1:10,1:7);end
fprintf('Final selected results assembled under %s\n',outRoot);
end

function n=checkpoint_neurons(cr)
n=[];
if isfield(cr,'hidden_neurons'),n=double(cr.hidden_neurons);return;end
if isfield(cr,'model')&&isstruct(cr.model)&&isfield(cr.model,'hidden_neurons')
    n=double(cr.model.hidden_neurons);
end
end
