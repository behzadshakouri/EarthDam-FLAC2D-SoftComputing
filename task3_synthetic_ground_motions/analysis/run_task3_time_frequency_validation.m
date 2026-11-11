function report=run_task3_time_frequency_validation()
%RUN_TASK3_TIME_FREQUENCY_VALIDATION Nested test of time-frequency inputs.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3'); [X,names]=build_task3_time_frequency_features(raw.Task3,cfg);
[Y,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
failure=logical(audit.had_sentinel); failed=find(failure); stable=find(~failure);
components=[0 5 10 20 30 50]; lambdas=[.1 1 10 100 1000]; outer=table; selections=table;
for repeat=1:10
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    dev=sort([a(1:34);b(1:71)]); test=sort([a(35:end);b(72:end)]);
    fold=stratified_folds(failure(dev),3,cfg.seed+8200+repeat); bestScore=inf; bestComponents=0; bestLambda=10;
    for c=components
        for lambda=lambdas
            pred=nan(numel(dev),cfg.num_outputs);
            for f=1:3
                tr=dev(fold~=f); va=dev(fold==f);
                model=fit_model(X(tr,:),Y(tr,:),c,lambda,cfg);
                pred(fold==f,:)=predict_model(model,X(va,:));
            end
            mt=calculate_task3_metrics(Y(dev,:),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
            score=mean([mt(use).nRMSE]);
            if score<bestScore, bestScore=score; bestComponents=c; bestLambda=lambda; end
        end
    end
    model=fit_model(X(dev,:),Y(dev,:),bestComponents,bestLambda,cfg);
    pred=predict_model(model,X(test,:)); mt=calculate_task3_metrics(Y(test,:),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    outer=[outer;table(repeat,bestComponents,bestLambda,bestScore,mean([mt(use).R2]), ...
        median([mt(use).R2]),mean([mt(use).nRMSE]),mean([mt(use).nMAE]), ...
        sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8),sum([mt(use).R2]>=.9), ...
        'VariableNames',{'repeat','tf_pca_components','lambda','inner_nRMSE','mean_R2', ...
        'median_R2','mean_nRMSE','mean_nMAE','outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'})]; %#ok<AGROW>
    selections=[selections;table(repeat,bestComponents,bestLambda,bestScore, ...
        'VariableNames',{'repeat','tf_pca_components','lambda','inner_nRMSE'})]; %#ok<AGROW>
    fprintf('Time-frequency validation %d/10: components %d, R2 %.4f.\n',repeat,bestComponents,outer.mean_R2(end));
end
summary=table(mean(outer.mean_R2),std(outer.mean_R2),min(outer.mean_R2),max(outer.mean_R2), ...
    mean(outer.median_R2),mean(outer.mean_nRMSE),mean(outer.mean_nMAE), ...
    mean(outer.outputs_R2_ge_07),mean(outer.outputs_R2_ge_08),mean(outer.outputs_R2_ge_09), ...
    'VariableNames',{'mean_R2','sd_R2','minimum_R2','maximum_R2','mean_median_R2', ...
    'mean_nRMSE','mean_nMAE','mean_outputs_R2_ge_07','mean_outputs_R2_ge_08','mean_outputs_R2_ge_09'});
writetable(outer,fullfile(resultsDir,'time_frequency_nested_metrics.csv'));
writetable(selections,fullfile(resultsDir,'time_frequency_nested_selections.csv'));
writetable(summary,fullfile(resultsDir,'time_frequency_nested_summary.csv'));
writetable(table((1:numel(names))',names(:),'VariableNames',{'feature_index','feature'}), ...
    fullfile(resultsDir,'time_frequency_feature_dictionary.csv'));
report=struct('metrics',outer,'summary',summary,'selections',selections); disp(summary);
end

function model=fit_model(X,Y,nComponents,lambda,cfg)
model.scale=median(abs(X),1); model.scale(model.scale<=eps)=1;
X=asinh(bsxfun(@rdivide,X,model.scale));
model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs); model.loading=[];
if nComponents>0
    [~,~,V]=svd(X(:,17:end),'econ'); model.loading=V(:,1:min(nComponents,size(V,2)));
    X=[X(:,1:16) X(:,17:end)*model.loading];
else
    X=X(:,1:16);
end
model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
Y=apply_task3_standardizer(Y,model.ys); A=[ones(size(X,1),1) X]; P=eye(size(A,2)); P(1,1)=0;
model.beta=(A'*A+lambda*P)\(A'*Y);
end

function Y=predict_model(model,X)
X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,model.scale)),model.xs);
if ~isempty(model.loading), X=[X(:,1:16) X(:,17:end)*model.loading]; else, X=X(:,1:16); end
Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);
end

function fold=stratified_folds(label,k,seed)
rng(seed,'twister'); fold=zeros(numel(label),1);
for value=[false true]
    ids=find(label==value); ids=ids(randperm(numel(ids)));
    for j=1:numel(ids), fold(ids(j))=mod(j-1,k)+1; end
end
end
