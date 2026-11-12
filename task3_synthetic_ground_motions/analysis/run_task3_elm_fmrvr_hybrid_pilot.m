function report=run_task3_elm_fmrvr_hybrid_pilot(hiddenNeurons)
%RUN_TASK3_ELM_FMRVR_HYBRID_PILOT Task 2-style ELM plus point-wise FMRVR.
if nargin<1,hiddenNeurons=100;end
analysisDir=fileparts(mfilename('fullpath'));root=fileparts(analysisDir);addpath(root);setup_task3;
cfg=task3_config(root);prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');[~,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
data=build_task3_time_resolved_dataset(raw.Task3,prepared.dataset,audit,cfg,100);
failure=logical(audit.had_sentinel);failed=find(failure);stable=find(~failure);
rng(cfg.seed+1501,'twister');a=failed(randperm(numel(failed)));b=stable(randperm(numel(stable)));
development=sort([a(1:34);b(1:71)]);test=sort([a(35:end);b(72:end)]);
fold=stratified_folds(failure(development),3,cfg.seed+11201);
baseOof=nan(size(data.Y));oofRows=false(size(data.realization_id));
for f=1:3
    trIds=development(fold~=f);vaIds=development(fold==f);
    tr=ismember(data.realization_id,trIds);va=ismember(data.realization_id,vaIds);oofRows=oofRows|va;
    for point=1:10
        cols=(point-1)*7+(1:7);m=fit_elm(data.X(tr,:),data.Y(tr,cols),hiddenNeurons,1e-4,cfg.seed+100*f+point);
        baseOof(va,cols)=predict_elm(m,data.X(va,:));
    end
end
dev=ismember(data.realization_id,development);tst=ismember(data.realization_id,test);
assert(all(oofRows(dev))&&all(isfinite(baseOof(dev,:)),'all'));
baseTest=zeros(nnz(tst),70);models=cell(10,1);residualModels=cell(10,1);correction=zeros(nnz(tst),70);
options=struct('output_rank',7,'center_count',80,'width_factors',[.2 .4 .8 1.6], ...
    'max_iterations',500,'tolerance',.03,'seed',cfg.seed,'target_transform',"none");
for point=1:10
    cols=(point-1)*7+(1:7);
    models{point}=fit_elm(data.X(dev,:),data.Y(dev,cols),hiddenNeurons,1e-4,cfg.seed+point);
    baseTest(:,cols)=predict_elm(models{point},data.X(tst,:));
    residual=data.Y(dev,cols)-baseOof(dev,cols);options.seed=cfg.seed+500+point;
    residualModels{point}=fit_task3_pointwise_fmrvr(data.X(dev,:),residual,options);
    correction(:,cols)=predict_task3_pointwise_fmrvr(residualModels{point},data.X(tst,:));
end
baseTest=enforce_envelopes(baseTest,data.realization_id(tst));observed=data.Y(tst,:);
weights=(0:.1:1)';aggregate=table;
for k=1:numel(weights)
    pred=enforce_envelopes(baseTest+weights(k)*correction,data.realization_id(tst));
    mt=calculate_all_metrics(observed,pred);use=~mt.constant;
    aggregate=[aggregate;table(weights(k),mean(mt.R2(use)),median(mt.R2(use)), ...
        mean(mt.nRMSE(use)),sum(mt.R2(use)>=.8),sum(mt.R2(use)>=.9), ...
        'VariableNames',{'residual_weight','mean_R2','median_R2','mean_nRMSE', ...
        'outputs_R2_ge_08','outputs_R2_ge_09'})]; %#ok<AGROW>
end
[~,best]=max(aggregate.mean_R2);bestWeight=weights(best);
prediction=enforce_envelopes(baseTest+bestWeight*correction,data.realization_id(tst));
out=task3_analysis_results_root(root);writetable(aggregate,fullfile(out,'elm_fmrvr_hybrid_pilot_weights.csv'));
save(fullfile(out,'elm_fmrvr_hybrid_pilot.mat'),'models','residualModels','prediction','baseTest', ...
    'correction','development','test','bestWeight','-v7.3');
disp(aggregate);report=struct('weights',aggregate,'best_weight',bestWeight);
end

function model=fit_elm(X,Y,h,lambda,seed)
[Xs,model.xmin,model.xrange]=scale_fit(X);[Ts,model.ymin,model.yrange]=scale_fit(Y);
rng(seed,'twister');model.W=2*rand(h,size(X,2))-1;model.b=2*rand(1,h)-1;
H=1./(1+exp(-(Xs*model.W'+model.b)));model.beta=(H'*H+lambda*eye(h))\(H'*Ts);
end
function Y=predict_elm(model,X)
Xs=2*(X-model.xmin)./model.xrange-1;H=1./(1+exp(-(Xs*model.W'+model.b)));
Ts=H*model.beta;Y=(Ts+1).*model.yrange/2+model.ymin;Y=max(Y,0);
end
function [Z,mn,rg]=scale_fit(X)
mn=min(X,[],1);rg=max(X,[],1)-mn;rg(rg<=1e-12)=1;Z=2*(X-mn)./rg-1;
end
function Y=enforce_envelopes(Y,id)
for k=unique(id(:))',rows=find(id==k);Y(rows,:)=cummax(max(Y(rows,:),0),1);end
end
function fold=stratified_folds(label,k,seed)
rng(seed,'twister');fold=zeros(numel(label),1);for value=[false true],ids=find(label==value);ids=ids(randperm(numel(ids)));for j=1:numel(ids),fold(ids(j))=mod(j-1,k)+1;end,end
end
function m=calculate_all_metrics(y,p)
n=size(y,2);R2=nan(n,1);nRMSE=R2;constant=false(n,1);for j=1:n,span=max(y(:,j))-min(y(:,j));constant(j)=span<=max(1e-12,1e-10*max(abs(y(:,j))));R2(j)=1-sum((y(:,j)-p(:,j)).^2)/max(sum((y(:,j)-mean(y(:,j))).^2),eps);nRMSE(j)=sqrt(mean((y(:,j)-p(:,j)).^2))/max(span,eps);end;m=table(R2,nRMSE,constant);
end
