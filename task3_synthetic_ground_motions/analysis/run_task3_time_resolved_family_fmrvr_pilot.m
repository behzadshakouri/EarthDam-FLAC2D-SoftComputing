function report=run_task3_time_resolved_family_fmrvr_pilot(repeats)
%RUN_TASK3_TIME_RESOLVED_FAMILY_FMRVR_PILOT Direct family-wise FMRVR audit.
if nargin<1, repeats=2; end
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
cfg.fmrvr.max_iterations=300; cfg.fmrvr.tolerance=.2;
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[~,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
data=build_task3_time_resolved_dataset(raw.Task3,prepared.dataset,audit,cfg,100);
failure=logical(audit.had_sentinel); failed=find(failure); stable=find(~failure);
spec.width_factors=[.5 1 2]; spec.linear_mix=.5; spec.target_transform="none"; spec.output_rank=5;
sampleWithin=round(linspace(1,data.samples_per_record,5)); outer=table;
for repeat=1:repeats
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    devIds=sort([a(1:34);b(1:71)]); testIds=sort([a(35:end);b(72:end)]);
    subset=select_rows(data.realization_id,devIds,sampleWithin); test=ismember(data.realization_id,testIds);
    prediction=zeros(nnz(test),cfg.num_outputs); bases=0;
    for response=1:7
        ids=response:7:cfg.num_outputs;
        model=fit_task3_fmrvr_advanced(data.X(subset,:),data.Y(subset,ids),spec,cfg);
        prediction(:,ids)=predict_task3_fmrvr_advanced(model,data.X(test,:)); bases=bases+numel(model.used);
    end
    prediction=max(prediction,0);
    mt=calculate_task3_metrics(data.Y(test,:),prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    outer=[outer;table(repeat,bases,mean([mt(use).R2]),median([mt(use).R2]), ...
        mean([mt(use).nRMSE]),mean([mt(use).nMAE]),sum([mt(use).R2]>=.7), ...
        sum([mt(use).R2]>=.8),sum([mt(use).R2]>=.9), ...
        'VariableNames',{'repeat','relevance_bases','mean_R2','median_R2','mean_nRMSE', ...
        'mean_nMAE','outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'})]; %#ok<AGROW>
    fprintf('Family FMRVR %d/%d: R2 %.4f, %d bases.\n',repeat,repeats,outer.mean_R2(end),bases);
end
summary=table(mean(outer.mean_R2),std(outer.mean_R2),mean(outer.median_R2), ...
    mean(outer.outputs_R2_ge_07),mean(outer.outputs_R2_ge_08),mean(outer.outputs_R2_ge_09), ...
    mean(outer.relevance_bases),'VariableNames',{'mean_R2','sd_R2','mean_median_R2', ...
    'mean_outputs_R2_ge_07','mean_outputs_R2_ge_08','mean_outputs_R2_ge_09','mean_relevance_bases'});
writetable(outer,fullfile(resultsDir,'time_resolved_family_fmrvr_pilot_metrics.csv'));
writetable(summary,fullfile(resultsDir,'time_resolved_family_fmrvr_pilot_summary.csv'));
report=struct('metrics',outer,'summary',summary); disp(summary);
end

function take=select_rows(realization,ids,sampleWithin)
take=false(size(realization));
for id=ids'
    rows=find(realization==id); take(rows(sampleWithin))=true;
end
end
