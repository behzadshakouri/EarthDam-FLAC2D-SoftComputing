function report=run_task4_time_resolved_fmrvr_pilot()
%RUN_TASK4_TIME_RESOLVED_FMRVR_PILOT Joint ten-point envelope prediction.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_task4;
s=load(fullfile(task4_results_root(root),'scale_aware','task4_scale_aware_dataset.mat'),'dataset');
d=s.dataset; X=double(d.X); Y=double(d.Y); mask=d.admissible;
[development,test]=scale_stratified_split(d.metadata.scale_factor,20260830);
isDevelopment=ismember(double(d.record_id),development);
isTest=ismember(double(d.record_id),test);
models=cell(7,1); metrics=table; predictions=cell(7,1); observations=cell(7,1);
options=struct('output_rank',10,'center_count',80,'width_factors',[.2 .4 .8 1.6], ...
    'max_iterations',500,'tolerance',.03,'seed',20260830);
for response=1:7
    cols=response:7:70; familySafe=all(mask(:,cols),2);
    fitRows=isDevelopment & familySafe; testRows=isTest & familySafe;
    options.seed=20260830+response;
    models{response}=fit_task4_fmrvr_peak(X(fitRows,:),Y(fitRows,cols),options);
    predicted=predict_task4_fmrvr_peak(models{response},X(testRows,:));
    ids=double(d.record_id(testRows)); predicted=enforce_envelopes(predicted,ids);
    observed=Y(testRows,cols); familyMetrics=calculate_metrics(observed,predicted,cols,d.output_dictionary);
    familyMetrics.response(:)=response; metrics=[metrics;familyMetrics]; %#ok<AGROW>
    predictions{response}=single(predicted); observations{response}=single(observed);
    fprintf('Time-resolved FMRVR R%d: train=%d test=%d mean R2=%.4f bases=%d.\n', ...
        response,nnz(fitRows),nnz(testRows),mean(familyMetrics.R2),numel(models{response}.used));
end
usable=~metrics.constant;
summary=table(mean(metrics.R2(usable)),median(metrics.R2(usable)), ...
    mean(metrics.nRMSE(usable)),mean(metrics.nMAE(usable)), ...
    sum(metrics.R2(usable)>=.7),sum(metrics.R2(usable)>=.8), ...
    sum(metrics.R2(usable)>=.9),sum(cellfun(@(m)numel(m.used),models)), ...
    'VariableNames',{'mean_R2','median_R2','mean_nRMSE','mean_nMAE', ...
    'outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09','relevance_bases'});
family=groupsummary(metrics(~metrics.constant,:),"response","mean",["R2" "nRMSE" "nMAE"]);
out=fullfile(task4_results_root(root),'scale_aware','development'); if ~exist(out,'dir'),mkdir(out);end
writetable(metrics,fullfile(out,'time_resolved_fmrvr_pilot_per_output.csv'));
writetable(family,fullfile(out,'time_resolved_fmrvr_pilot_by_family.csv'));
writetable(summary,fullfile(out,'time_resolved_fmrvr_pilot_summary.csv'));
save(fullfile(out,'time_resolved_fmrvr_pilot.mat'),'models','predictions','observations', ...
    'development','test','-v7.3');
disp(summary); disp(family); report=struct('summary',summary,'metrics',metrics,'family',family);
end

function prediction=enforce_envelopes(prediction,recordId)
prediction=max(prediction,0);
for id=unique(recordId(:))'
    rows=find(recordId==id); prediction(rows,:)=cummax(prediction(rows,:),1);
end
end

function [development,test]=scale_stratified_split(scale,seed)
rng(seed,'twister'); development=[]; test=[];
for value=unique(scale(:))'
    ids=find(scale==value); ids=ids(randperm(numel(ids)));
    ntest=round(.2*numel(ids)); test=[test;ids(1:ntest)]; %#ok<AGROW>
    development=[development;ids(ntest+1:end)]; %#ok<AGROW>
end
development=sort(development); test=sort(test);
end

function metrics=calculate_metrics(observed,predicted,cols,dictionary)
n=size(observed,2); R2=nan(n,1); nRMSE=R2; nMAE=R2; constant=false(n,1);
for j=1:n
    y=observed(:,j); p=predicted(:,j); span=max(y)-min(y);
    constant(j)=span<=max(1e-12,1e-10*max(abs(y)));
    R2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);
    nRMSE(j)=sqrt(mean((y-p).^2))/max(span,eps);
    nMAE(j)=mean(abs(y-p))/max(span,eps);
end
metrics=table(cols(:),string({dictionary(cols).label})',[dictionary(cols).point]', ...
    [dictionary(cols).response]',R2,nRMSE,nMAE,constant, ...
    'VariableNames',{'output_column','label','point','response','R2','nRMSE','nMAE','constant'});
end
