function report=run_task3_time_resolved_fmrvr_pilot(repeats)
%RUN_TASK3_TIME_RESOLVED_FMRVR_PILOT FMRVR on cumulative response paths.
if nargin<1, repeats=3; end
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
cfg.fmrvr.max_iterations=400; cfg.fmrvr.tolerance=.2;
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[~,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
data=build_task3_time_resolved_dataset(raw.Task3,prepared.dataset,audit,cfg,40);
failure=logical(audit.had_sentinel); failed=find(failure); stable=find(~failure);
spec.width_factors=[.5 1 2]; spec.linear_mix=.5; spec.target_transform="none"; spec.output_rank=5;
sampleWithin=round(linspace(1,data.samples_per_record,5)); outer=table; perOutput=table;
for repeat=1:repeats
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    devIds=sort([a(1:34);b(1:71)]); testIds=sort([a(35:end);b(72:end)]);
    train=false(size(data.realization_id));
    for id=devIds'
        rows=find(data.realization_id==id); train(rows(sampleWithin))=true;
    end
    test=ismember(data.realization_id,testIds);
    model=fit_task3_fmrvr_advanced(data.X(train,:),data.Y(train,:),spec,cfg);
    prediction=predict_task3_fmrvr_advanced(model,data.X(test,:));
    mt=calculate_task3_metrics(data.Y(test,:),prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    outer=[outer;table(repeat,nnz(train),numel(model.used),mean([mt(use).R2]), ...
        median([mt(use).R2]),mean([mt(use).nRMSE]),mean([mt(use).nMAE]), ...
        sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8),sum([mt(use).R2]>=.9), ...
        'VariableNames',{'repeat','training_rows','relevance_bases','mean_R2','median_R2', ...
        'mean_nRMSE','mean_nMAE','outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'})]; %#ok<AGROW>
    perOutput=[perOutput;table(repmat(repeat,cfg.num_outputs,1),(1:cfg.num_outputs)', ...
        string({prepared.dataset.output_dictionary.label})',[prepared.dataset.output_dictionary.response]', ...
        [mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.constant]','VariableNames',{'repeat','output_column', ...
        'label','response','R2','nRMSE','nMAE','constant'})]; %#ok<AGROW>
    fprintf('Time-resolved FMRVR %d/%d: R2 %.4f, %d bases.\n',repeat,repeats,outer.mean_R2(end),numel(model.used));
end
summary=table(mean(outer.mean_R2),std(outer.mean_R2),min(outer.mean_R2),max(outer.mean_R2), ...
    mean(outer.median_R2),mean(outer.mean_nRMSE),mean(outer.mean_nMAE), ...
    mean(outer.outputs_R2_ge_07),mean(outer.outputs_R2_ge_08),mean(outer.outputs_R2_ge_09), ...
    mean(outer.relevance_bases),'VariableNames',{'mean_R2','sd_R2','minimum_R2','maximum_R2', ...
    'mean_median_R2','mean_nRMSE','mean_nMAE','mean_outputs_R2_ge_07', ...
    'mean_outputs_R2_ge_08','mean_outputs_R2_ge_09','mean_relevance_bases'});
writetable(outer,fullfile(resultsDir,'time_resolved_fmrvr_pilot_metrics.csv'));
writetable(perOutput,fullfile(resultsDir,'time_resolved_fmrvr_pilot_per_output.csv'));
writetable(summary,fullfile(resultsDir,'time_resolved_fmrvr_pilot_summary.csv'));
report=struct('metrics',outer,'summary',summary,'per_output',perOutput); disp(summary);
end
