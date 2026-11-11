function report=run_task4_fmrvr_peak_pilot()
%RUN_TASK4_FMRVR_PEAK_PILOT One untouched, scale-stratified development test.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_task4;
s=load(fullfile(task4_results_root(root),'scale_aware','task4_scale_aware_dataset.mat'),'dataset');
d=s.dataset; X=double(d.record_features); Y=double(d.safe_peak_targets);
assert(isequal(size(X),[750 17])&&isequal(size(Y),[750 70]));
[development,test]=scale_stratified_split(d.metadata.scale_factor,20260830);
options=struct('output_rank',20,'center_count',80,'width_factors',[.35 .7 1.4], ...
    'max_iterations',400,'tolerance',.05,'seed',20260830);
model=fit_task4_fmrvr_peak(X(development,:),Y(development,:),options);
prediction=predict_task4_fmrvr_peak(model,X(test,:));
metrics=peak_metrics(Y(test,:),prediction,d.output_dictionary);
usable=~metrics.constant;
summary=table(mean(metrics.R2(usable)),median(metrics.R2(usable)), ...
    mean(metrics.nRMSE(usable)),mean(metrics.nMAE(usable)), ...
    sum(metrics.R2(usable)>=.7),sum(metrics.R2(usable)>=.8), ...
    sum(metrics.R2(usable)>=.9),numel(model.used),model.candidate_basis_count, ...
    'VariableNames',{'mean_R2','median_R2','mean_nRMSE','mean_nMAE', ...
    'outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09', ...
    'relevance_bases','candidate_bases'});
out=fullfile(task4_results_root(root),'scale_aware','development'); if ~exist(out,'dir'),mkdir(out);end
writetable(metrics,fullfile(out,'fmrvr_peak_pilot_per_output.csv'));
writetable(summary,fullfile(out,'fmrvr_peak_pilot_summary.csv'));
save(fullfile(out,'fmrvr_peak_pilot.mat'),'model','prediction','development','test','-v7.3');
disp(summary); report=struct('summary',summary,'metrics',metrics);
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

function metrics=peak_metrics(observed,predicted,dictionary)
n=size(observed,2); R2=nan(n,1); nRMSE=R2; nMAE=R2; constant=false(n,1);
for j=1:n
    y=observed(:,j); p=predicted(:,j); span=max(y)-min(y);
    constant(j)=span<=max(1e-12,1e-10*max(abs(y)));
    R2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);
    nRMSE(j)=sqrt(mean((y-p).^2))/max(span,eps);
    nMAE(j)=mean(abs(y-p))/max(span,eps);
end
metrics=table((1:n)',string({dictionary.label})',[dictionary.point]', ...
    [dictionary.response]',R2,nRMSE,nMAE,constant, ...
    'VariableNames',{'output_column','label','point','response','R2','nRMSE','nMAE','constant'});
end
