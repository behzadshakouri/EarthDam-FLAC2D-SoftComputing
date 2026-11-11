function report = run_task3_failure_mixture_repeated_validation()
%RUN_TASK3_FAILURE_MIXTURE_REPEATED_VALIDATION Nested repeated gate validation.
analysisDir=fileparts(mfilename('fullpath'));root=fileparts(analysisDir);addpath(root);setup_task3;cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');raw=load(cfg.raw.task3_data_file,'Task3');
[X,~,groups]=build_task3_augmented_features(raw.Task3,cfg);X=X(:,groups.spectral);[Y,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
failure=logical(audit.had_sentinel);screenedIds=find(failure);stableIds=find(~failure);rows=table;
for repeat=1:10
    rng(cfg.seed+500+repeat,'twister');a=screenedIds(randperm(numel(screenedIds)));b=stableIds(randperm(numel(stableIds)));dev=sort([a(1:34);b(1:71)]);test=sort([a(35:end);b(72:end)]);
    inner=make_folds(numel(dev),5,cfg.seed+2000+repeat);globalOof=nan(numel(dev),cfg.num_outputs);mixOof=globalOof;
    for f=1:5
        tr=dev(inner~=f);va=dev(inner==f);gm=fit_model(X(tr,:),Y(tr,:),10,cfg);globalOof(inner==f,:)=predict_model(gm,X(va,:));
        sm=fit_model(X(tr(~failure(tr)),:),Y(tr(~failure(tr)),:),10,cfg);fm=fit_model(X(tr(failure(tr)),:),Y(tr(failure(tr)),:),10,cfg);
        [Xa,Xb]=classifier_features(X(tr,:),X(va,:),cfg);cl=fitclinear(Xa,double(failure(tr)),'Learner','logistic','Regularization','ridge','Lambda',.1);[~,sc]=predict(cl,Xb);p=sc(:,find(cl.ClassNames==1,1));
        mixOof(inner==f,:)=bsxfun(@times,1-p,predict_model(sm,X(va,:)))+bsxfun(@times,p,predict_model(fm,X(va,:)));
    end
    scores=inf(11,1);for q=0:10,alpha=q/10;pred=alpha*globalOof+(1-alpha)*mixOof;mt=calculate_task3_metrics(Y(dev,:),pred,cfg.preprocessing.constant_tolerance);u=~[mt.constant];scores(q+1)=mean([mt(u).nRMSE]);end
    [~,q]=min(scores);alpha=(q-1)/10;
    gm=fit_model(X(dev,:),Y(dev,:),10,cfg);sm=fit_model(X(dev(~failure(dev)),:),Y(dev(~failure(dev)),:),10,cfg);fm=fit_model(X(dev(failure(dev)),:),Y(dev(failure(dev)),:),10,cfg);
    [Xa,Xb]=classifier_features(X(dev,:),X(test,:),cfg);cl=fitclinear(Xa,double(failure(dev)),'Learner','logistic','Regularization','ridge','Lambda',.1);[~,sc]=predict(cl,Xb);p=sc(:,find(cl.ClassNames==1,1));
    pg=predict_model(gm,X(test,:));pm=bsxfun(@times,1-p,predict_model(sm,X(test,:)))+bsxfun(@times,p,predict_model(fm,X(test,:)));pred=alpha*pg+(1-alpha)*pm;
    mt=calculate_task3_metrics(Y(test,:),pred,cfg.preprocessing.constant_tolerance);u=~[mt.constant];
    rows=[rows;table(repeat,alpha,mean([mt(u).R2]),median([mt(u).R2]),mean([mt(u).nRMSE]),mean([mt(u).nMAE]),mean([mt(u).a10]),mean((p>=.5)==failure(test)), ...
        'VariableNames',{'repeat','global_weight','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','failure_accuracy'})]; %#ok<AGROW>
    fprintf('Nested failure-mixture split %d/10: R2 %.4f, gate accuracy %.3f.\n',repeat,rows.mean_R2(end),rows.failure_accuracy(end));
end
summary=table(mean(rows.mean_R2),std(rows.mean_R2),min(rows.mean_R2),max(rows.mean_R2),median(rows.mean_R2),mean(rows.mean_nRMSE),mean(rows.mean_nMAE),mean(rows.mean_a10),mean(rows.failure_accuracy), ...
    'VariableNames',{'mean_R2','sd_R2','minimum_R2','maximum_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','mean_failure_accuracy'});
writetable(rows,fullfile(resultsDir,'failure_mixture_repeated_split_metrics.csv'));writetable(summary,fullfile(resultsDir,'failure_mixture_repeated_split_summary.csv'));
f=figure('Visible','off','Color','w','Position',[100 100 760 450]);plot(rows.repeat,rows.mean_R2,'-o','LineWidth',1.8,'MarkerFaceColor',[.10 .35 .62]);yline(.7,'--','Target 0.70');grid on;
xlabel('Nested stratified split');ylabel('Mean held-out R^2');title('Failure-gated spectral model robustness');set(gca,'XTick',1:10);set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'failure_mixture_repeated_split.pdf'),'-dpdf','-painters','-bestfit');print(f,fullfile(figuresDir,'failure_mixture_repeated_split.png'),'-dpng','-r220');close(f);
report.summary=summary;report.metrics=rows;fprintf('Failure-mixture repeated validation: mean R2 %.4f, range %.4f--%.4f.\n',summary.mean_R2,summary.minimum_R2,summary.maximum_R2);
end
function model=fit_model(X,Y,lambda,cfg),model.scale=median(abs(X),1);model.scale(model.scale<=eps)=1;X=asinh(bsxfun(@rdivide,X,model.scale));model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);X=apply_task3_standardizer(X,model.xs);Y=apply_task3_standardizer(Y,model.ys);A=[ones(size(X,1),1) X];P=eye(size(A,2));P(1,1)=0;model.beta=(A'*A+lambda*P)\(A'*Y);end
function Y=predict_model(model,X),X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,model.scale)),model.xs);Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);end
function [A,B]=classifier_features(A,B,cfg),s=median(abs(A),1);s(s<=eps)=1;A=asinh(bsxfun(@rdivide,A,s));B=asinh(bsxfun(@rdivide,B,s));xs=fit_task3_standardizer(A,cfg.preprocessing.constant_tolerance);A=apply_task3_standardizer(A,xs);B=apply_task3_standardizer(B,xs);end
function fold=make_folds(n,k,seed),rng(seed,'twister');order=randperm(n);fold=zeros(n,1);for i=1:n,fold(order(i))=mod(i-1,k)+1;end,end
