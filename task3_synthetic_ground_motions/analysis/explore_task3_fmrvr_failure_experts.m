function report=explore_task3_fmrvr_failure_experts()
%EXPLORE_TASK3_FMRVR_FAILURE_EXPERTS Soft-gated multiscale FMRVR experts.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
cfg.fmrvr.max_iterations=400; cfg.fmrvr.tolerance=.2;
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3'); [X,~,groups]=build_task3_augmented_features(raw.Task3,cfg);
X=X(:,groups.spectral); Y=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
failure=any(prepared.qc.truncated,2); dev=saved.developmentIds(:); test=saved.testIds(:);
spec.width_factors=[.5 1 2]; spec.linear_mix=.5; spec.target_transform="none"; spec.output_rank=5;
fold=stratified_folds(failure(dev),3,cfg.seed+2301);
globalOof=nan(numel(dev),size(Y,2)); expertOof=globalOof; probability=nan(numel(dev),1);
for f=1:3
    tr=dev(fold~=f); va=dev(fold==f);
    globalModel=fit_task3_fmrvr_advanced(X(tr,:),Y(tr,:),spec,cfg);
    stableModel=fit_task3_fmrvr_advanced(X(tr(~failure(tr)),:),Y(tr(~failure(tr)),:),spec,cfg);
    unstableModel=fit_task3_fmrvr_advanced(X(tr(failure(tr)),:),Y(tr(failure(tr)),:),spec,cfg);
    globalOof(fold==f,:)=predict_task3_fmrvr_advanced(globalModel,X(va,:));
    stablePrediction=predict_task3_fmrvr_advanced(stableModel,X(va,:));
    unstablePrediction=predict_task3_fmrvr_advanced(unstableModel,X(va,:));
    [A,B]=classifier_features(X(tr,:),X(va,:),cfg);
    classifier=fitclinear(A,double(failure(tr)),'Learner','logistic', ...
        'Regularization','ridge','Lambda',.1);
    [~,score]=predict(classifier,B); col=find(classifier.ClassNames==1,1);
    p=min(max(score(:,col),0),1); probability(fold==f)=p;
    expertOof(fold==f,:)=bsxfun(@times,1-p,stablePrediction)+bsxfun(@times,p,unstablePrediction);
    fprintf('FMRVR expert fold %d/3 complete.\n',f);
end

rows=table; predictions=cell(11,1);
for j=0:10
    alpha=j/10; predictions{j+1}=alpha*globalOof+(1-alpha)*expertOof;
    mt=calculate_task3_metrics(Y(dev,:),predictions{j+1},cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    rows=[rows;table(alpha,mean([mt(use).R2]),median([mt(use).R2]), ...
        mean([mt(use).nRMSE]),mean([mt(use).nMAE]), ...
        'VariableNames',{'global_weight','mean_R2','median_R2','mean_nRMSE','mean_nMAE'})]; %#ok<AGROW>
end
[~,best]=min(rows.mean_nRMSE); alpha=rows.global_weight(best);
globalModel=fit_task3_fmrvr_advanced(X(dev,:),Y(dev,:),spec,cfg);
stableModel=fit_task3_fmrvr_advanced(X(dev(~failure(dev)),:),Y(dev(~failure(dev)),:),spec,cfg);
unstableModel=fit_task3_fmrvr_advanced(X(dev(failure(dev)),:),Y(dev(failure(dev)),:),spec,cfg);
[A,B]=classifier_features(X(dev,:),X(test,:),cfg);
classifier=fitclinear(A,double(failure(dev)),'Learner','logistic','Regularization','ridge','Lambda',.1);
[~,score]=predict(classifier,B); col=find(classifier.ClassNames==1,1); p=min(max(score(:,col),0),1);
globalPrediction=predict_task3_fmrvr_advanced(globalModel,X(test,:));
stablePrediction=predict_task3_fmrvr_advanced(stableModel,X(test,:));
unstablePrediction=predict_task3_fmrvr_advanced(unstableModel,X(test,:));
expertPrediction=bsxfun(@times,1-p,stablePrediction)+bsxfun(@times,p,unstablePrediction);
prediction=alpha*globalPrediction+(1-alpha)*expertPrediction;
mt=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
summary=table(alpha,mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]), ...
    mean([mt(use).nMAE]),mean([mt(use).a10]),mean((p>=.5)==failure(test)), ...
    sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8),sum([mt(use).R2]>=.9), ...
    'VariableNames',{'global_weight','mean_R2','median_R2','mean_nRMSE','mean_nMAE', ...
    'mean_a10','instability_accuracy','outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'});
writetable(rows,fullfile(resultsDir,'fmrvr_failure_experts_development_cv.csv'));
writetable(summary,fullfile(resultsDir,'fmrvr_failure_experts_fixed_test_summary.csv'));
save(fullfile(resultsDir,'fmrvr_failure_experts_selected.mat'),'globalModel','stableModel', ...
    'unstableModel','classifier','spec','alpha','summary','rows','prediction','-v7.3');
f=figure('Visible','off','Color','w','Position',[100 100 720 440]);
plot(rows.global_weight,rows.mean_R2,'-o','LineWidth',1.8,'MarkerFaceColor',[.12 .42 .68]); grid on;
xlabel('Weight on global multiscale FMRVR'); ylabel('Development OOF mean R^2');
title('FMRVR failure-expert selection'); set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'fmrvr_failure_experts_selection.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'fmrvr_failure_experts_selection.png'),'-dpng','-r220'); close(f);
report=struct('development',rows,'summary',summary,'alpha',alpha);
fprintf('FMRVR experts: weight %.1f, fixed-test R2 %.4f, gate accuracy %.3f.\n', ...
    alpha,summary.mean_R2,summary.instability_accuracy);
end

function [A,B]=classifier_features(A,B,cfg)
scale=median(abs(A),1); scale(scale<=eps)=1;
A=asinh(bsxfun(@rdivide,A,scale)); B=asinh(bsxfun(@rdivide,B,scale));
xs=fit_task3_standardizer(A,cfg.preprocessing.constant_tolerance);
A=apply_task3_standardizer(A,xs); B=apply_task3_standardizer(B,xs);
end

function fold=stratified_folds(label,k,seed)
rng(seed,'twister'); fold=zeros(numel(label),1);
for value=[false true]
    ids=find(label==value); ids=ids(randperm(numel(ids)));
    for j=1:numel(ids), fold(ids(j))=mod(j-1,k)+1; end
end
end
