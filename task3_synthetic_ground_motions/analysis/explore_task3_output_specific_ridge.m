function report = explore_task3_output_specific_ridge()
%EXPLORE_TASK3_OUTPUT_SPECIFIC_RIDGE Per-output feature/penalty selection at 5x.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3');[X,~,groups]=build_task3_augmented_features(raw.Task3,cfg);
Y=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);dev=saved.developmentIds;test=saved.testIds;
groupNames=["base9";"duration10";"spectral16";"all20"];groupIds={groups.base;groups.duration;groups.spectral;groups.all};
lambdas=[.01 .1 1 10 100];fold=make_folds(numel(dev),5,cfg.seed+901);candidate=table;predictions=cell(0,1);candidateId=0;
for g=1:numel(groupNames)
    ids=groupIds{g};
    for lambda=lambdas
        candidateId=candidateId+1;oof=nan(numel(dev),cfg.num_outputs);
        for f=1:5,tr=dev(fold~=f);va=dev(fold==f);model=fit_model(X(tr,ids),Y(tr,:),lambda,cfg);oof(fold==f,:)=predict_model(model,X(va,ids));end
        predictions{candidateId}=oof; %#ok<AGROW>
        mt=calculate_task3_metrics(Y(dev,:),oof,cfg.preprocessing.constant_tolerance);
        candidate=[candidate;table(candidateId,groupNames(g),numel(ids),lambda,mean([mt(~[mt.constant]).R2]),mean([mt(~[mt.constant]).nRMSE]), ...
            'VariableNames',{'candidate_id','feature_group','feature_count','lambda','mean_R2','mean_nRMSE'})]; %#ok<AGROW>
    end
end
selection=zeros(1,cfg.num_outputs);selectionRows=table;
for j=1:cfg.num_outputs
    errors=inf(height(candidate),1);
    for c=1:height(candidate)
        obs=Y(dev,j);p=predictions{c}(:,j);range=max(obs)-min(obs);
        if range>cfg.preprocessing.constant_tolerance,errors(c)=sqrt(mean((obs-p).^2))/range;end
    end
    [bestError,selection(j)]=min(errors);
    selectionRows=[selectionRows;table(j,string(prepared.dataset.output_dictionary(j).label),selection(j), ...
        candidate.feature_group(selection(j)),candidate.lambda(selection(j)),bestError, ...
        'VariableNames',{'output_column','label','candidate_id','feature_group','lambda','development_oof_nRMSE'})]; %#ok<AGROW>
end
finalCandidatePred=cell(height(candidate),1);
for c=1:height(candidate)
    ids=groupIds{find(groupNames==candidate.feature_group(c),1)};model=fit_model(X(dev,ids),Y(dev,:),candidate.lambda(c),cfg);
    finalCandidatePred{c}=predict_model(model,X(test,ids));
end
prediction=zeros(numel(test),cfg.num_outputs);for j=1:cfg.num_outputs,prediction(:,j)=finalCandidatePred{selection(j)}(:,j);end
mt=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance);use=~[mt.constant];
summary=table(mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
    sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8),'VariableNames',{'mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','outputs_R2_ge_07','outputs_R2_ge_08'});
writetable(candidate,fullfile(resultsDir,'output_specific_ridge_candidates.csv'));
writetable(selectionRows,fullfile(resultsDir,'output_specific_ridge_selection.csv'));
writetable(summary,fullfile(resultsDir,'output_specific_ridge_test_summary.csv'));
writetable(table((1:cfg.num_outputs)',string({prepared.dataset.output_dictionary.label})',[mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.a10]',[mt.constant]', ...
    'VariableNames',{'output_column','label','R2','nRMSE','nMAE','a10','constant'}),fullfile(resultsDir,'output_specific_ridge_test_per_output.csv'));
save(fullfile(resultsDir,'output_specific_ridge_selected.mat'),'candidate','selectionRows','selection','fold','-v7.3');
counts=groupsummary(selectionRows,{'feature_group','lambda'});writetable(counts,fullfile(resultsDir,'output_specific_ridge_selection_counts.csv'));
f=figure('Visible','off','Color','w','Position',[100 100 820 470]);histogram([mt(use).R2],0:.05:1,'FaceColor',[0.10 .35 .62]);xline(.7,'--');xline(.8,'--');grid on;
xlabel('Held-out R^2');ylabel('Nonconstant outputs');title('Output-specific spectral ridge performance');set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'output_specific_ridge_r2.pdf'),'-dpdf','-painters','-bestfit');print(f,fullfile(figuresDir,'output_specific_ridge_r2.png'),'-dpng','-r220');close(f);
report.summary=summary;report.selection=selectionRows;fprintf('Output-specific ridge: test mean R2 %.4f; %d outputs >=0.8.\n',summary.mean_R2,summary.outputs_R2_ge_08);
end
function model=fit_model(X,Y,lambda,cfg)
model.scale=median(abs(X),1);model.scale(model.scale<=eps)=1;X=asinh(bsxfun(@rdivide,X,model.scale));model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs);Y=apply_task3_standardizer(Y,model.ys);A=[ones(size(X,1),1) X];P=eye(size(A,2));P(1,1)=0;model.beta=(A'*A+lambda*P)\(A'*Y);
end
function Y=predict_model(model,X),X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,model.scale)),model.xs);Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);end
function fold=make_folds(n,k,seed),rng(seed,'twister');order=randperm(n);fold=zeros(n,1);for i=1:n,fold(order(i))=mod(i-1,k)+1;end,end
