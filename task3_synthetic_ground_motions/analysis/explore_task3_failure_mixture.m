function report = explore_task3_failure_mixture()
%EXPLORE_TASK3_FAILURE_MIXTURE Two-stage failure gate plus response experts.
analysisDir=fileparts(mfilename('fullpath'));root=fileparts(analysisDir);addpath(root);setup_task3;cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3');[X,~,groups]=build_task3_augmented_features(raw.Task3,cfg);X=X(:,groups.spectral);
[Y,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);failure=logical(audit.had_sentinel);dev=saved.developmentIds;test=saved.testIds;
fold=make_folds(numel(dev),5,cfg.seed+901);globalOof=nan(numel(dev),cfg.num_outputs);mixtureOof=globalOof;probOof=nan(numel(dev),1);
for f=1:5
    tr=dev(fold~=f);va=dev(fold==f);globalModel=fit_model(X(tr,:),Y(tr,:),10,cfg);globalOof(fold==f,:)=predict_model(globalModel,X(va,:));
    stableModel=fit_model(X(tr(~failure(tr)),:),Y(tr(~failure(tr)),:),10,cfg);failedModel=fit_model(X(tr(failure(tr)),:),Y(tr(failure(tr)),:),10,cfg);
    [Xtr,Xva]=classifier_features(X(tr,:),X(va,:),cfg);classifier=fitclinear(Xtr,double(failure(tr)),'Learner','logistic','Regularization','ridge','Lambda',.1);
    [~,score]=predict(classifier,Xva);col=find(classifier.ClassNames==1,1);p=min(max(score(:,col),0),1);probOof(fold==f)=p;
    ps=predict_model(stableModel,X(va,:));pf=predict_model(failedModel,X(va,:));mixtureOof(fold==f,:)=bsxfun(@times,1-p,ps)+bsxfun(@times,p,pf);
end
candidates=table;preds=cell(0,1);names=strings(0,1);
for alpha=0:.1:1
    names(end+1)=sprintf('%.1f global + %.1f gated experts',alpha,1-alpha);preds{end+1}=alpha*globalOof+(1-alpha)*mixtureOof; %#ok<AGROW>
end
for c=1:numel(names)
    mt=calculate_task3_metrics(Y(dev,:),preds{c},cfg.preprocessing.constant_tolerance);use=~[mt.constant];
    candidates=[candidates;table(c,names(c),(c-1)/10,mean([mt(use).R2]),mean([mt(use).nRMSE]),mean([mt(use).nMAE]), ...
        'VariableNames',{'candidate_id','candidate','global_weight','oof_mean_R2','oof_mean_nRMSE','oof_mean_nMAE'})]; %#ok<AGROW>
end
[~,best]=min(candidates.oof_mean_nRMSE);alpha=candidates.global_weight(best);
globalModel=fit_model(X(dev,:),Y(dev,:),10,cfg);stableModel=fit_model(X(dev(~failure(dev)),:),Y(dev(~failure(dev)),:),10,cfg);failedModel=fit_model(X(dev(failure(dev)),:),Y(dev(failure(dev)),:),10,cfg);
[Xtr,Xt]=classifier_features(X(dev,:),X(test,:),cfg);classifier=fitclinear(Xtr,double(failure(dev)),'Learner','logistic','Regularization','ridge','Lambda',.1);
[~,score]=predict(classifier,Xt);col=find(classifier.ClassNames==1,1);p=min(max(score(:,col),0),1);
pg=predict_model(globalModel,X(test,:));ps=predict_model(stableModel,X(test,:));pf=predict_model(failedModel,X(test,:));pm=bsxfun(@times,1-p,ps)+bsxfun(@times,p,pf);prediction=alpha*pg+(1-alpha)*pm;
mt=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance);use=~[mt.constant];predictedFailure=p>=.5;
summary=table(alpha,mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
    mean(predictedFailure==failure(test)),sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8), ...
    'VariableNames',{'global_weight','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','failure_accuracy','outputs_R2_ge_07','outputs_R2_ge_08'});
writetable(candidates,fullfile(resultsDir,'failure_mixture_development_cv.csv'));writetable(summary,fullfile(resultsDir,'failure_mixture_test_summary.csv'));
writetable(table(test(:),failure(test),p,predictedFailure,'VariableNames',{'realization_id','observed_failure','predicted_failure_probability','predicted_failure'}),fullfile(resultsDir,'failure_classifier_test_predictions.csv'));
save(fullfile(resultsDir,'failure_mixture_selected.mat'),'candidates','summary','prediction','probOof','fold','-v7.3');
f=figure('Visible','off','Color','w','Position',[100 100 720 440]);plot(candidates.global_weight,candidates.oof_mean_R2,'-o','LineWidth',1.8,'MarkerFaceColor',[.10 .35 .62]);grid on;
xlabel('Weight on global spectral ridge');ylabel('Development-only OOF mean R^2');title('Failure-gated mixture selection');set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'failure_mixture_selection.pdf'),'-dpdf','-painters','-bestfit');print(f,fullfile(figuresDir,'failure_mixture_selection.png'),'-dpng','-r220');close(f);
report.cv=candidates;report.test=summary;fprintf('Failure mixture: weight %.1f, test R2 %.4f, failure accuracy %.3f.\n',alpha,summary.mean_R2,summary.failure_accuracy);
end
function model=fit_model(X,Y,lambda,cfg)
model.scale=median(abs(X),1);model.scale(model.scale<=eps)=1;X=asinh(bsxfun(@rdivide,X,model.scale));model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);X=apply_task3_standardizer(X,model.xs);Y=apply_task3_standardizer(Y,model.ys);A=[ones(size(X,1),1) X];P=eye(size(A,2));P(1,1)=0;model.beta=(A'*A+lambda*P)\(A'*Y);
end
function Y=predict_model(model,X),X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,model.scale)),model.xs);Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);end
function [A,B]=classifier_features(A,B,cfg),s=median(abs(A),1);s(s<=eps)=1;A=asinh(bsxfun(@rdivide,A,s));B=asinh(bsxfun(@rdivide,B,s));xs=fit_task3_standardizer(A,cfg.preprocessing.constant_tolerance);A=apply_task3_standardizer(A,xs);B=apply_task3_standardizer(B,xs);end
function fold=make_folds(n,k,seed),rng(seed,'twister');order=randperm(n);fold=zeros(n,1);for i=1:n,fold(order(i))=mod(i-1,k)+1;end,end
