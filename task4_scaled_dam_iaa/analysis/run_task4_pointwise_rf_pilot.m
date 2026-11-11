function report=run_task4_pointwise_rf_pilot(treeCount)
%RUN_TASK4_TIME_RESOLVED_RF_PILOT Point-wise single-output random-forest comparator.
if nargin<1,treeCount=100;end
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_task4;
s=load(fullfile(task4_results_root(root),'scale_aware','task4_scale_aware_dataset.mat'),'dataset');d=s.dataset;
X=double(d.X);Y=double(d.Y);mask=d.admissible;
[development,test]=scale_stratified_split(d.metadata.scale_factor,20260830);
isDev=ismember(double(d.record_id),development);isTest=ismember(double(d.record_id),test);
metrics=table;models=cell(10,7);predictions=cell(10,1);
template=templateTree('MinLeafSize',5,'NumVariablesToSample',max(1,round(sqrt(size(X,2)))));
for point=1:10
    cols=(point-1)*7+(1:7);safe=all(mask(:,cols),2);fitRows=isDev&safe;testRows=isTest&safe;
    predicted=zeros(nnz(testRows),7);
    for j=1:7
        scale=max(median(Y(fitRows,cols(j))),eps);target=log1p(Y(fitRows,cols(j))/scale);
        models{point,j}=fitrensemble(X(fitRows,:),target,'Method','Bag', ...
            'NumLearningCycles',treeCount,'Learners',template);
        predicted(:,j)=max(expm1(predict(models{point,j},X(testRows,:)))*scale,0);
    end
    ids=double(d.record_id(testRows));predicted=enforce_envelopes(predicted,ids);
    fm=calculate_metrics(Y(testRows,cols),predicted,cols,d.output_dictionary);fm.point(:)=point;
    metrics=[metrics;fm];predictions{point}=single(predicted); %#ok<AGROW>
    fprintf('Point-wise RF%d P%d: mean R2=%.4f.\n',treeCount,point,mean(fm.R2));
end
usable=~metrics.constant;summary=table(mean(metrics.R2(usable)),median(metrics.R2(usable)), ...
    mean(metrics.nRMSE(usable)),mean(metrics.nMAE(usable)),sum(metrics.R2(usable)>=.8), ...
    sum(metrics.R2(usable)>=.9),treeCount,'VariableNames',{'mean_R2','median_R2', ...
    'mean_nRMSE','mean_nMAE','outputs_R2_ge_08','outputs_R2_ge_09','trees'});
family=groupsummary(metrics(~metrics.constant,:),"point","mean",["R2" "nRMSE" "nMAE"]);
out=fullfile(task4_results_root(root),'scale_aware','development');
writetable(metrics,fullfile(out,sprintf('pointwise_rf%d_pilot_per_output.csv',treeCount)));
writetable(summary,fullfile(out,sprintf('pointwise_rf%d_pilot_summary.csv',treeCount)));
save(fullfile(out,sprintf('pointwise_rf%d_pilot.mat',treeCount)),'models','predictions','development','test','-v7.3');
disp(summary);disp(family);report=struct('summary',summary,'metrics',metrics,'family',family);
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
