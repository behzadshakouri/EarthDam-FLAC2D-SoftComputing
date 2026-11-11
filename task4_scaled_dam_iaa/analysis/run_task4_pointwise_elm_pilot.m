function report=run_task4_pointwise_elm_pilot(hiddenNeurons)
%RUN_TASK4_TIME_RESOLVED_ELM_PILOT Point-wise no-ridge independent-output ELM baseline.
if nargin<1, hiddenNeurons=300; end
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_task4;
s=load(fullfile(task4_results_root(root),'scale_aware','task4_scale_aware_dataset.mat'),'dataset');
d=s.dataset; X=double(d.X); Y=double(d.Y); mask=d.admissible;
[development,test]=scale_stratified_split(d.metadata.scale_factor,20260830);
isDevelopment=ismember(double(d.record_id),development); isTest=ismember(double(d.record_id),test);
metrics=table; predictions=cell(10,1); models=cell(10,1);
for point=1:10
    cols=(point-1)*7+(1:7); safe=all(mask(:,cols),2); fitRows=isDevelopment&safe; testRows=isTest&safe;
    model=fit_elm(X(fitRows,:),Y(fitRows,cols),hiddenNeurons,20260830+point);
    predicted=predict_elm(model,X(testRows,:)); ids=double(d.record_id(testRows));
    predicted=enforce_envelopes(predicted,ids); observed=Y(testRows,cols);
    familyMetrics=calculate_metrics(observed,predicted,cols,d.output_dictionary);
    familyMetrics.point(:)=point; metrics=[metrics;familyMetrics]; %#ok<AGROW>
    models{point}=model; predictions{point}=single(predicted);
    fprintf('Point-wise no-ridge ELM P%d: mean R2=%.4f.\n',point,mean(familyMetrics.R2));
end
usable=~metrics.constant;
summary=table(mean(metrics.R2(usable)),median(metrics.R2(usable)),mean(metrics.nRMSE(usable)), ...
    mean(metrics.nMAE(usable)),sum(metrics.R2(usable)>=.8),sum(metrics.R2(usable)>=.9),hiddenNeurons, ...
    'VariableNames',{'mean_R2','median_R2','mean_nRMSE','mean_nMAE', ...
    'outputs_R2_ge_08','outputs_R2_ge_09','hidden_neurons'});
family=groupsummary(metrics(~metrics.constant,:),"point","mean",["R2" "nRMSE" "nMAE"]);
out=fullfile(task4_results_root(root),'scale_aware','development');
writetable(metrics,fullfile(out,sprintf('pointwise_elm%d_pilot_per_output.csv',hiddenNeurons)));
writetable(summary,fullfile(out,sprintf('pointwise_elm%d_pilot_summary.csv',hiddenNeurons)));
save(fullfile(out,sprintf('pointwise_elm%d_pilot.mat',hiddenNeurons)),'models','predictions','development','test','-v7.3');
disp(summary);disp(family);report=struct('summary',summary,'metrics',metrics,'family',family);
end

function model=fit_elm(X,Y,h,seed)
model.ymax=max(Y,[],1);
model.xmean=mean(X,1);model.xstd=std(X,0,1);model.xstd(model.xstd<=1e-12)=1;
X=(X-model.xmean)./model.xstd;model.yscale=median(Y,1);model.yscale(model.yscale<=1e-12)=1;
T=log1p(Y./model.yscale);model.ymean=mean(T,1);model.ystd=std(T,0,1);
model.ystd(model.ystd<=1e-12)=1;T=(T-model.ymean)./model.ystd;
rng(seed,'twister');model.W=randn(h,size(X,2))/sqrt(size(X,2));model.b=2*rand(1,h)-1;
H=tanh(X*model.W'+model.b);H=[ones(size(H,1),1) H];
model.beta=H\T;model.hidden=h;
end

function Y=predict_elm(model,X)
X=(double(X)-model.xmean)./model.xstd;H=tanh(X*model.W'+model.b);
T=[ones(size(H,1),1) H]*model.beta;T=T.*model.ystd+model.ymean;
Y=min(max(expm1(T).*model.yscale,0),model.ymax);
end

function prediction=enforce_envelopes(prediction,recordId)
for id=unique(recordId(:))',rows=find(recordId==id);prediction(rows,:)=cummax(max(prediction(rows,:),0),1);end
end

function [development,test]=scale_stratified_split(scale,seed)
rng(seed,'twister');development=[];test=[];
for value=unique(scale(:))',ids=find(scale==value);ids=ids(randperm(numel(ids)));n=round(.2*numel(ids));test=[test;ids(1:n)];development=[development;ids(n+1:end)];end %#ok<AGROW>
development=sort(development);test=sort(test);
end

function metrics=calculate_metrics(observed,predicted,cols,dictionary)
n=size(observed,2);R2=nan(n,1);nRMSE=R2;nMAE=R2;constant=false(n,1);
for j=1:n,y=observed(:,j);p=predicted(:,j);span=max(y)-min(y);constant(j)=span<=max(1e-12,1e-10*max(abs(y)));R2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);nRMSE(j)=sqrt(mean((y-p).^2))/max(span,eps);nMAE(j)=mean(abs(y-p))/max(span,eps);end
metrics=table(cols(:),string({dictionary(cols).label})',[dictionary(cols).point]',[dictionary(cols).response]',R2,nRMSE,nMAE,constant,'VariableNames',{'output_column','label','point','response','R2','nRMSE','nMAE','constant'});
end
