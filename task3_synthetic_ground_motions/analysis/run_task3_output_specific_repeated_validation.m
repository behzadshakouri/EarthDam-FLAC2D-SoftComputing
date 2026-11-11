function report = run_task3_output_specific_repeated_validation()
%RUN_TASK3_OUTPUT_SPECIFIC_REPEATED_VALIDATION Nested 10-split validation.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');[X,~,groups]=build_task3_augmented_features(raw.Task3,cfg);
[Y,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
groupNames=["base9";"duration10";"spectral16";"all20"];groupIds={groups.base;groups.duration;groups.spectral;groups.all};lambdas=[.01 .1 1 10 100];
screenedIds=find(audit.had_sentinel);stableIds=find(~audit.had_sentinel);rows=table;perOutput=table;selectionAudit=table;
for repeat=1:10
    rng(cfg.seed+500+repeat,'twister');a=screenedIds(randperm(numel(screenedIds)));b=stableIds(randperm(numel(stableIds)));
    dev=sort([a(1:34);b(1:71)]);test=sort([a(35:end);b(72:end)]);inner=make_folds(numel(dev),5,cfg.seed+2000+repeat);
    candidatePred=cell(20,1);candidateGroup=zeros(20,1);candidateLambda=zeros(20,1);c=0;
    for g=1:4
        ids=groupIds{g};
        for lambda=lambdas
            c=c+1;candidateGroup(c)=g;candidateLambda(c)=lambda;oof=nan(numel(dev),cfg.num_outputs);
            for f=1:5,tr=dev(inner~=f);va=dev(inner==f);model=fit_model(X(tr,ids),Y(tr,:),lambda,cfg);oof(inner==f,:)=predict_model(model,X(va,ids));end
            candidatePred{c}=oof;
        end
    end
    selected=ones(1,cfg.num_outputs);
    for j=1:cfg.num_outputs
        obs=Y(dev,j);range=max(obs)-min(obs);if range<=cfg.preprocessing.constant_tolerance,continue;end
        errors=zeros(20,1);for k=1:20,errors(k)=sqrt(mean((obs-candidatePred{k}(:,j)).^2))/range;end
        [~,selected(j)]=min(errors);
        selectionAudit=[selectionAudit;table(repeat,j,string(prepared.dataset.output_dictionary(j).label), ...
            groupNames(candidateGroup(selected(j))),candidateLambda(selected(j)), ...
            'VariableNames',{'repeat','output_column','label','feature_group','lambda'})]; %#ok<AGROW>
    end
    finalPred=cell(20,1);
    for k=1:20,ids=groupIds{candidateGroup(k)};model=fit_model(X(dev,ids),Y(dev,:),candidateLambda(k),cfg);finalPred{k}=predict_model(model,X(test,ids));end
    prediction=zeros(numel(test),cfg.num_outputs);for j=1:cfg.num_outputs,prediction(:,j)=finalPred{selected(j)}(:,j);end
    mt=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance);use=~[mt.constant];
    rows=[rows;table(repeat,mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
        sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8),'VariableNames',{'repeat','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','outputs_R2_ge_07','outputs_R2_ge_08'})]; %#ok<AGROW>
    perOutput=[perOutput;table(repmat(repeat,cfg.num_outputs,1),(1:cfg.num_outputs)',string({prepared.dataset.output_dictionary.label})', ...
        [mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.a10]',[mt.constant]','VariableNames',{'repeat','output_column','label','R2','nRMSE','nMAE','a10','constant'})]; %#ok<AGROW>
    fprintf('Nested output-specific split %d/10: mean R2 %.4f.\n',repeat,rows.mean_R2(end));
end
summary=table(mean(rows.mean_R2),std(rows.mean_R2),min(rows.mean_R2),max(rows.mean_R2),median(rows.mean_R2), ...
    mean(rows.mean_nRMSE),mean(rows.mean_nMAE),mean(rows.mean_a10),'VariableNames',{'mean_R2','sd_R2','minimum_R2','maximum_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10'});
writetable(rows,fullfile(resultsDir,'output_specific_repeated_split_metrics.csv'));writetable(summary,fullfile(resultsDir,'output_specific_repeated_split_summary.csv'));
writetable(perOutput,fullfile(resultsDir,'output_specific_repeated_split_per_output.csv'));writetable(selectionAudit,fullfile(resultsDir,'output_specific_repeated_selection_audit.csv'));
f=figure('Visible','off','Color','w','Position',[100 100 760 450]);plot(rows.repeat,rows.mean_R2,'-o','LineWidth',1.8,'MarkerFaceColor',[.10 .35 .62]);yline(.7,'--','Target 0.70');grid on;
xlabel('Nested stratified split');ylabel('Mean held-out R^2');title('Output-specific model robustness');set(gca,'XTick',1:10);set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'output_specific_repeated_split.pdf'),'-dpdf','-painters','-bestfit');print(f,fullfile(figuresDir,'output_specific_repeated_split.png'),'-dpng','-r220');close(f);
report.summary=summary;report.metrics=rows;fprintf('Nested repeated validation: mean R2 %.4f, range %.4f--%.4f.\n',summary.mean_R2,summary.minimum_R2,summary.maximum_R2);
end
function model=fit_model(X,Y,lambda,cfg)
model.scale=median(abs(X),1);model.scale(model.scale<=eps)=1;X=asinh(bsxfun(@rdivide,X,model.scale));model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs);Y=apply_task3_standardizer(Y,model.ys);A=[ones(size(X,1),1) X];P=eye(size(A,2));P(1,1)=0;model.beta=(A'*A+lambda*P)\(A'*Y);
end
function Y=predict_model(model,X),X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,model.scale)),model.xs);Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);end
function fold=make_folds(n,k,seed),rng(seed,'twister');order=randperm(n);fold=zeros(n,1);for i=1:n,fold(order(i))=mod(i-1,k)+1;end,end
