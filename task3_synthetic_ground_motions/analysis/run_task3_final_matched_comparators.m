function report=run_task3_final_matched_comparators()
%RUN_TASK3_FINAL_MATCHED_COMPARATORS Locked comparators on final FMRVR splits.
% Uses the same 16 predictors, 5x screened targets, and outer split sequence
% as run_task3_fmrvr_experts_nested_validation. The comparator settings are
% fixed before the outer tests; no held-out response is used for tuning.

analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[X,~,groups]=build_task3_augmented_features(raw.Task3,cfg); X=X(:,groups.spectral);
Y=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
failure=any(prepared.qc.truncated,2); failed=find(failure); stable=find(~failure);
methods=["Linear ridge (16 predictors)";"Random forest"]; rows=table;

for repeat=1:10
    rng(cfg.seed+1500+repeat,'twister');
    a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    dev=sort([a(1:34);b(1:71)]); test=sort([a(35:end);b(72:end)]);

    xScale=median(abs(X(dev,:)),1); xScale(xScale<=eps)=1;
    Xdev=asinh(bsxfun(@rdivide,X(dev,:),xScale));
    Xtest=asinh(bsxfun(@rdivide,X(test,:),xScale));
    xs=fit_task3_standardizer(Xdev,cfg.preprocessing.constant_tolerance);
    ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
    Xdev=apply_task3_standardizer(Xdev,xs); Xtest=apply_task3_standardizer(Xtest,xs);
    Ydev=apply_task3_standardizer(Y(dev,:),ys); modeled=~ys.constant;

    A=[ones(size(Xdev,1),1) Xdev]; penalty=eye(size(A,2)); penalty(1,1)=0;
    beta=(A'*A+10*penalty)\(A'*Ydev);
    ridge=reverse_task3_standardizer([ones(size(Xtest,1),1) Xtest]*beta,ys);

    rng(cfg.seed+3500+repeat,'twister'); z=zeros(numel(test),cfg.num_outputs);
    for j=find(modeled)
        model=TreeBagger(200,Xdev,Ydev(:,j),'Method','regression','MinLeafSize',5, ...
            'NumPredictorsToSample',5,'OOBPrediction','off');
        z(:,j)=predict(model,Xtest);
    end
    forest=reverse_task3_standardizer(z,ys);

    predictions={ridge;forest};
    for k=1:numel(methods)
        mt=calculate_task3_metrics(Y(test,:),predictions{k},cfg.preprocessing.constant_tolerance);
        use=~[mt.constant];
        rows=[rows;table(repeat,methods(k),mean([mt(use).R2]),median([mt(use).R2]), ...
            mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
            'VariableNames',{'repeat','method','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10'})]; %#ok<AGROW>
    end
    fprintf('Final matched comparators %d/10: ridge %.4f, RF %.4f.\n',repeat, ...
        rows.mean_R2(end-1),rows.mean_R2(end));
end

summary=table;
for k=1:numel(methods)
    use=rows.method==methods(k);
    summary=[summary;table(methods(k),mean(rows.mean_R2(use)),std(rows.mean_R2(use)), ...
        min(rows.mean_R2(use)),max(rows.mean_R2(use)),mean(rows.mean_nRMSE(use)), ...
        mean(rows.mean_nMAE(use)),mean(rows.mean_a10(use)), ...
        'VariableNames',{'method','mean_R2','sd_R2','minimum_R2','maximum_R2', ...
        'mean_nRMSE','mean_nMAE','mean_a10'})]; %#ok<AGROW>
end
writetable(rows,fullfile(resultsDir,'final_matched_comparator_metrics.csv'));
writetable(summary,fullfile(resultsDir,'final_matched_comparator_summary.csv'));
report=struct('metrics',rows,'summary',summary);
fprintf('Final matched comparator analysis complete.\n');
end
