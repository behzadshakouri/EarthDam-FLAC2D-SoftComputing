function report=run_task3_failure_classifier_benchmark()
%RUN_TASK3_FAILURE_CLASSIFIER_BENCHMARK Nested nonlinear gate benchmark.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3'); [X,~,groups]=build_task3_augmented_features(raw.Task3,cfg); X=X(:,groups.spectral);
failure=any(prepared.qc.truncated,2); failed=find(failure); stable=find(~failure);
methods=["logistic" "linear_svm" "rbf_svm_0p5" "rbf_svm_1" "rbf_svm_2" ...
    "bagged_trees_2" "bagged_trees_5" "bagged_trees_10"];
rows=table; predictions=table;
for repeat=1:10
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    dev=sort([a(1:34);b(1:71)]); test=sort([a(35:end);b(72:end)]);
    fold=stratified_folds(failure(dev),3,cfg.seed+9300+repeat); inner=zeros(numel(methods),1);
    for m=1:numel(methods)
        p=nan(numel(dev),1);
        for f=1:3
            tr=dev(fold~=f); va=dev(fold==f);
            model=fit_classifier(X(tr,:),failure(tr),methods(m),cfg);
            p(fold==f)=predict_classifier(model,X(va,:));
        end
        inner(m)=mean((p-failure(dev)).^2);
    end
    [innerBrier,best]=min(inner); selected=methods(best);
    model=fit_classifier(X(dev,:),failure(dev),selected,cfg); p=predict_classifier(model,X(test,:));
    [~,~,~,auc]=perfcurve(failure(test),p,true);
    rows=[rows;table(repeat,selected,innerBrier,mean((p>=.5)==failure(test)),auc, ...
        mean((p-failure(test)).^2),'VariableNames',{'repeat','selected_method','inner_brier', ...
        'test_accuracy','test_auc','test_brier'})]; %#ok<AGROW>
    predictions=[predictions;table(repmat(repeat,numel(test),1),test,p,failure(test), ...
        repmat(selected,numel(test),1),'VariableNames',{'repeat','realization_id','failure_probability', ...
        'observed_failure','selected_method'})]; %#ok<AGROW>
    fprintf('Failure classifier %d/10: %s, accuracy %.3f, AUC %.3f.\n',repeat,selected,rows.test_accuracy(end),auc);
end
summary=table(mean(rows.test_accuracy),std(rows.test_accuracy),mean(rows.test_auc), ...
    mean(rows.test_brier),'VariableNames',{'mean_accuracy','sd_accuracy','mean_auc','mean_brier'});
writetable(rows,fullfile(resultsDir,'failure_classifier_nested_benchmark.csv'));
writetable(predictions,fullfile(resultsDir,'failure_classifier_nested_predictions.csv'));
writetable(summary,fullfile(resultsDir,'failure_classifier_nested_summary.csv'));
report=struct('metrics',rows,'predictions',predictions,'summary',summary); disp(summary);
end

function model=fit_classifier(X,y,method,cfg)
model.method=method; model.scale=median(abs(X),1); model.scale(model.scale<=eps)=1;
X=asinh(bsxfun(@rdivide,X,model.scale)); model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs);
if method=="logistic"
    model.fit=fitclinear(X,double(y),'Learner','logistic','Regularization','ridge','Lambda',.1);
elseif method=="linear_svm"
    base=fitcsvm(X,y,'KernelFunction','linear','BoxConstraint',1,'ClassNames',[false true]);
    model.fit=fitPosterior(base,X,y);
elseif startsWith(method,"rbf_svm")
    factor=str2double(strrep(extractAfter(method,"rbf_svm_"),'p','.'));
    d=pdist(X); width=median(d(d>0))*factor;
    base=fitcsvm(X,y,'KernelFunction','rbf','KernelScale',max(width,eps), ...
        'BoxConstraint',1,'ClassNames',[false true]);
    model.fit=fitPosterior(base,X,y);
else
    leaf=str2double(extractAfter(method,"bagged_trees_"));
    template=templateTree('MinLeafSize',leaf,'Surrogate','off');
    model.fit=fitcensemble(X,y,'Method','Bag','NumLearningCycles',200,'Learners',template,'ClassNames',[false true]);
end
end

function p=predict_classifier(model,X)
X=asinh(bsxfun(@rdivide,X,model.scale)); X=apply_task3_standardizer(X,model.xs);
[~,score]=predict(model.fit,X); col=find(model.fit.ClassNames==true,1); p=min(max(score(:,col),0),1);
end

function fold=stratified_folds(label,k,seed)
rng(seed,'twister'); fold=zeros(numel(label),1);
for value=[false true]
    ids=find(label==value); ids=ids(randperm(numel(ids)));
    for j=1:numel(ids), fold(ids(j))=mod(j-1,k)+1; end
end
end
