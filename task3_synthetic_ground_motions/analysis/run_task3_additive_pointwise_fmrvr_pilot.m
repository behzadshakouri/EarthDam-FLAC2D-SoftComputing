function report=run_task3_additive_pointwise_fmrvr_pilot()
%RUN_TASK3_ADDITIVE_POINTWISE_FMRVR_PILOT Rejected development experiment.
% This fixed-split diagnostic is retained for reproducibility. Its results are
% not production evidence and must not be used in the manuscript.
analysisDir=fileparts(mfilename('fullpath'));root=fileparts(analysisDir);addpath(root);setup_task3;
cfg=task3_config(root);prepared=load(fullfile(task3_results_root(root),'final_production', ...
    'task3_prepared_dataset.mat'),'dataset','qc');raw=load(cfg.raw.task3_data_file,'Task3');
[~,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
data=build_task3_time_resolved_dataset(raw.Task3,prepared.dataset,audit,cfg,100);
failure=logical(audit.had_sentinel);failed=find(failure);stable=find(~failure);
rng(cfg.seed+1501,'twister');a=failed(randperm(numel(failed)));b=stable(randperm(numel(stable)));
development=sort([a(1:34);b(1:71)]);test=sort([a(35:end);b(72:end)]);
dev=ismember(data.realization_id,development);tst=ismember(data.realization_id,test);
models=cell(10,1);prediction=zeros(nnz(tst),70);metrics=table;
options=struct('record_count',16,'record_rank',8,'dynamic_rank',8, ...
    'record_centers',60,'dynamic_centers',60,'width_factors',[.3 .7 1.5], ...
    'max_iterations',600,'tolerance',.03,'seed',cfg.seed);
for point=1:10
    cols=(point-1)*7+(1:7);options.seed=cfg.seed+point;
    models{point}=fit_task3_additive_pointwise_fmrvr(data.X(dev,:),data.Y(dev,cols),options);
    predicted=predict_task3_additive_pointwise_fmrvr(models{point},data.X(tst,:));
    predicted=enforce_envelopes(predicted,data.realization_id(tst));prediction(:,cols)=predicted;
    pm=calculate_metrics(data.Y(tst,cols),predicted,cols,prepared.dataset.output_dictionary);pm.point(:)=point;
    metrics=[metrics;pm]; %#ok<AGROW>
    fprintf('Task 3 additive point-wise FMRVR P%d: mean R2=%.4f bases=%d.\n', ...
        point,mean(pm.R2(~pm.constant)),numel(models{point}.used));
end
usable=~metrics.constant;summary=table(mean(metrics.R2(usable)),median(metrics.R2(usable)), ...
    mean(metrics.nRMSE(usable)),mean(metrics.nMAE(usable)),sum(metrics.R2(usable)>=.7), ...
    sum(metrics.R2(usable)>=.8),sum(metrics.R2(usable)>=.9),sum(cellfun(@(m)numel(m.used),models)), ...
    'VariableNames',{'mean_R2','median_R2','mean_nRMSE','mean_nMAE','outputs_R2_ge_07', ...
    'outputs_R2_ge_08','outputs_R2_ge_09','relevance_bases'});
byPoint=groupsummary(metrics(~metrics.constant,:),"point","mean",["R2" "nRMSE" "nMAE"]);
out=task3_analysis_results_root(root);if ~exist(out,'dir'),mkdir(out);end
writetable(metrics,fullfile(out,'additive_pointwise_fmrvr_pilot_per_output.csv'));
writetable(summary,fullfile(out,'additive_pointwise_fmrvr_pilot_summary.csv'));
writetable(byPoint,fullfile(out,'additive_pointwise_fmrvr_pilot_by_point.csv'));
save(fullfile(out,'additive_pointwise_fmrvr_pilot.mat'),'models','prediction','development','test','-v7.3');
disp(summary);disp(byPoint);report=struct('summary',summary,'metrics',metrics,'by_point',byPoint);
end

function prediction=enforce_envelopes(prediction,recordId)
for id=unique(recordId(:))',rows=find(recordId==id);prediction(rows,:)=cummax(max(prediction(rows,:),0),1);end
end
function metrics=calculate_metrics(observed,predicted,cols,dictionary)
n=size(observed,2);R2=nan(n,1);nRMSE=R2;nMAE=R2;constant=false(n,1);for j=1:n,y=observed(:,j);p=predicted(:,j);span=max(y)-min(y);constant(j)=span<=max(1e-12,1e-10*max(abs(y)));R2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);nRMSE(j)=sqrt(mean((y-p).^2))/max(span,eps);nMAE(j)=mean(abs(y-p))/max(span,eps);end
metrics=table(cols(:),string({dictionary(cols).label})',[dictionary(cols).point]',[dictionary(cols).response]',R2,nRMSE,nMAE,constant,'VariableNames',{'output_column','label','point','response','R2','nRMSE','nMAE','constant'});
end
