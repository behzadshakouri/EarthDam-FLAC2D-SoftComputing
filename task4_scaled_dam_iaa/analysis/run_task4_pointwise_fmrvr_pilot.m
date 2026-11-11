function report=run_task4_pointwise_fmrvr_pilot()
%RUN_TASK4_POINTWISE_FMRVR_PILOT Ten models, seven coupled responses each.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_task4;
s=load(fullfile(task4_results_root(root),'scale_aware','task4_scale_aware_dataset.mat'),'dataset');d=s.dataset;
X=double(d.X);Y=double(d.Y);mask=d.admissible;
[development,test]=scale_stratified_split(d.metadata.scale_factor,20260830);
isDev=ismember(double(d.record_id),development);isTest=ismember(double(d.record_id),test);
models=cell(10,1);metrics=table;predictions=cell(10,1);observations=cell(10,1);
options=struct('output_rank',7,'center_count',80,'width_factors',[.2 .4 .8 1.6], ...
    'max_iterations',500,'tolerance',.03,'seed',20260830);
for point=1:10
    cols=(point-1)*7+(1:7);safe=all(mask(:,cols),2);fitRows=isDev&safe;testRows=isTest&safe;
    options.seed=20260830+point;models{point}=fit_task4_fmrvr_peak(X(fitRows,:),Y(fitRows,cols),options);
    predicted=predict_task4_fmrvr_peak(models{point},X(testRows,:));ids=double(d.record_id(testRows));
    predicted=enforce_envelopes(predicted,ids);observed=Y(testRows,cols);
    pm=calculate_metrics(observed,predicted,cols,d.output_dictionary);pm.point(:)=point;
    metrics=[metrics;pm];predictions{point}=single(predicted);observations{point}=single(observed); %#ok<AGROW>
    fprintf('Point-wise FMRVR P%d: train=%d test=%d mean R2=%.4f bases=%d.\n',point,nnz(fitRows),nnz(testRows),mean(pm.R2(~pm.constant)),numel(models{point}.used));
end
usable=~metrics.constant;summary=table(mean(metrics.R2(usable)),median(metrics.R2(usable)), ...
    mean(metrics.nRMSE(usable)),mean(metrics.nMAE(usable)),sum(metrics.R2(usable)>=.7), ...
    sum(metrics.R2(usable)>=.8),sum(metrics.R2(usable)>=.9),sum(cellfun(@(m)numel(m.used),models)), ...
    'VariableNames',{'mean_R2','median_R2','mean_nRMSE','mean_nMAE','outputs_R2_ge_07', ...
    'outputs_R2_ge_08','outputs_R2_ge_09','relevance_bases'});
byPoint=groupsummary(metrics(~metrics.constant,:),"point","mean",["R2" "nRMSE" "nMAE"]);
byResponse=groupsummary(metrics(~metrics.constant,:),"response","mean",["R2" "nRMSE" "nMAE"]);
out=fullfile(task4_results_root(root),'scale_aware','development');
writetable(metrics,fullfile(out,'pointwise_fmrvr_pilot_per_output.csv'));
writetable(byPoint,fullfile(out,'pointwise_fmrvr_pilot_by_point.csv'));
writetable(byResponse,fullfile(out,'pointwise_fmrvr_pilot_by_response.csv'));
writetable(summary,fullfile(out,'pointwise_fmrvr_pilot_summary.csv'));
save(fullfile(out,'pointwise_fmrvr_pilot.mat'),'models','predictions','observations','development','test','-v7.3');
disp(summary);disp(byPoint);disp(byResponse);report=struct('summary',summary,'metrics',metrics,'by_point',byPoint,'by_response',byResponse);
end

function prediction=enforce_envelopes(prediction,recordId)
for id=unique(recordId(:))',rows=find(recordId==id);prediction(rows,:)=cummax(max(prediction(rows,:),0),1);end
end
function [development,test]=scale_stratified_split(scale,seed)
rng(seed,'twister');development=[];test=[];for value=unique(scale(:))',ids=find(scale==value);ids=ids(randperm(numel(ids)));n=round(.2*numel(ids));test=[test;ids(1:n)];development=[development;ids(n+1:end)];end %#ok<AGROW>
development=sort(development);test=sort(test);
end
function metrics=calculate_metrics(observed,predicted,cols,dictionary)
n=size(observed,2);R2=nan(n,1);nRMSE=R2;nMAE=R2;constant=false(n,1);for j=1:n,y=observed(:,j);p=predicted(:,j);span=max(y)-min(y);constant(j)=span<=max(1e-12,1e-10*max(abs(y)));R2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);nRMSE(j)=sqrt(mean((y-p).^2))/max(span,eps);nMAE(j)=mean(abs(y-p))/max(span,eps);end
metrics=table(cols(:),string({dictionary(cols).label})',[dictionary(cols).point]',[dictionary(cols).response]',R2,nRMSE,nMAE,constant,'VariableNames',{'output_column','label','point','response','R2','nRMSE','nMAE','constant'});
end
