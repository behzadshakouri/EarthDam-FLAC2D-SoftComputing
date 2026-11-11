function report = explore_task3_augmented_features()
%EXPLORE_TASK3_AUGMENTED_FEATURES Development-only spectral feature search.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset');
screened=load(fullfile(resultsDir,'task3_screened_targets.mat'),'Y');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3'); Y=screened.Y; dev=saved.developmentIds; test=saved.testIds;
[X,names,groups]=build_task3_augmented_features(raw.Task3,cfg);
writetable(array2table(X,'VariableNames',cellstr(names)),fullfile(resultsDir,'augmented_ground_motion_features.csv'));
fold=make_folds(numel(dev),5,cfg.seed+901); groupNames=["base9";"duration10";"spectral16";"all20"];
groupIds={groups.base;groups.duration;groups.spectral;groups.all}; lambdas=[0.01 0.1 1 10 100]; cv=table;
for g=1:numel(groupNames)
    ids=groupIds{g};
    for lambda=lambdas
        oof=nan(numel(dev),cfg.num_outputs);
        for f=1:5
            tr=dev(fold~=f); va=dev(fold==f);
            model=fit_ridge(X(tr,ids),Y(tr,:),lambda,cfg); oof(fold==f,:)=predict_ridge(model,X(va,ids));
        end
        mt=calculate_task3_metrics(Y(dev,:),oof,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
        cv=[cv;table(groupNames(g),numel(ids),lambda,mean([mt(use).R2]),median([mt(use).R2]), ...
            mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
            'VariableNames',{'feature_group','feature_count','lambda','oof_mean_R2','oof_median_R2', ...
            'oof_mean_nRMSE','oof_mean_nMAE','oof_mean_a10'})]; %#ok<AGROW>
    end
end
[~,best]=min(cv.oof_mean_nRMSE); ids=groupIds{find(groupNames==cv.feature_group(best),1)};
model=fit_ridge(X(dev,ids),Y(dev,:),cv.lambda(best),cfg); prediction=predict_ridge(model,X(test,ids));
mt=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
summary=table(cv.feature_group(best),numel(ids),cv.lambda(best),mean([mt(use).R2]), ...
    median([mt(use).R2]),mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
    sum([mt(use).R2]>=0.7),sum([mt(use).R2]>=0.8), ...
    'VariableNames',{'feature_group','feature_count','lambda','mean_R2','median_R2','mean_nRMSE', ...
    'mean_nMAE','mean_a10','outputs_R2_ge_07','outputs_R2_ge_08'});
writetable(cv,fullfile(resultsDir,'augmented_feature_development_cv.csv'));
writetable(summary,fullfile(resultsDir,'augmented_feature_test_summary.csv'));
writetable(table((1:cfg.num_outputs)',string({prepared.dataset.output_dictionary.label})', ...
    [mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.a10]',[mt.constant]', ...
    'VariableNames',{'output_column','label','R2','nRMSE','nMAE','a10','constant'}), ...
    fullfile(resultsDir,'augmented_feature_test_per_output.csv'));
save(fullfile(resultsDir,'augmented_feature_selected.mat'),'model','names','ids','cv','fold','-v7.3');
make_figure(cv,best,figuresDir); report.cv=cv; report.test=summary;
fprintf('Augmented features selected %s (%d features): OOF R2 %.4f, test R2 %.4f.\n', ...
    cv.feature_group(best),numel(ids),cv.oof_mean_R2(best),summary.mean_R2);
end

function model=fit_ridge(X,Y,lambda,cfg)
model.scale=median(abs(X),1); model.scale(model.scale<=eps)=1; X=asinh(bsxfun(@rdivide,X,model.scale));
model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
Xs=apply_task3_standardizer(X,model.xs); Ys=apply_task3_standardizer(Y,model.ys);
A=[ones(size(Xs,1),1) Xs]; penalty=eye(size(A,2)); penalty(1,1)=0;
model.beta=(A'*A+lambda*penalty)\(A'*Ys);
end
function prediction=predict_ridge(model,X)
X=asinh(bsxfun(@rdivide,X,model.scale)); X=apply_task3_standardizer(X,model.xs);
prediction=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);
end
function fold=make_folds(n,k,seed)
rng(seed,'twister'); order=randperm(n); fold=zeros(n,1);
for i=1:n,fold(order(i))=mod(i-1,k)+1;end
end
function make_figure(cv,best,outDir)
f=figure('Visible','off','Color','w','Position',[100 100 850 500]); hold on;
groups=unique(cv.feature_group,'stable'); colors=lines(numel(groups));
for g=1:numel(groups),u=cv.feature_group==groups(g);semilogx(cv.lambda(u),cv.oof_mean_R2(u),'-o','LineWidth',1.6,'Color',colors(g,:),'DisplayName',groups(g));end
scatter(cv.lambda(best),cv.oof_mean_R2(best),100,'k','filled'); grid on; legend('Location','best');
xlabel('Ridge penalty'); ylabel('Development-only OOF mean R^2'); title('Spectral feature-set selection');
set(f,'PaperPositionMode','auto'); print(f,fullfile(outDir,'augmented_feature_selection.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(outDir,'augmented_feature_selection.png'),'-dpng','-r220'); close(f);
end
