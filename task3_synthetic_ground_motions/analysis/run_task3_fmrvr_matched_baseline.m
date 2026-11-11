function report=run_task3_fmrvr_matched_baseline()
%RUN_TASK3_FMRVR_MATCHED_BASELINE Original FMRVR on improved-model splits.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
Y=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5); X=prepared.dataset.X;
audit=readtable(fullfile(resultsDir,'instability_screening_audit.csv'));
failed=find(logical(audit.had_sentinel)); stable=find(~logical(audit.had_sentinel));
improved=readtable(fullfile(resultsDir,'fmrvr_improved_nested_metrics.csv')); rows=table;
for repeat=1:height(improved)
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    dev=sort([a(1:34);b(1:71)]); test=sort([a(35:end);b(72:end)]);
    xs=fit_task3_standardizer(X(dev,:),cfg.preprocessing.constant_tolerance);
    ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
    Xt=apply_task3_standardizer(X(dev,:),xs); modeled=~ys.constant;
    Yt=apply_task3_standardizer(Y(dev,:),ys);
    model=train_task3_fmrvr(Xt,Yt(:,modeled),.5*task3_median_distance(Xt),cfg);
    z=zeros(numel(test),size(Y,2)); z(:,modeled)=predict_task3_fmrvr(model,apply_task3_standardizer(X(test,:),xs));
    pred=reverse_task3_standardizer(z,ys); mt=calculate_task3_metrics(Y(test,:),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    rows=[rows;table(repeat,mean([mt(use).R2]),improved.mean_R2(repeat),improved.mean_R2(repeat)-mean([mt(use).R2]), ...
        'VariableNames',{'repeat','original_R2','improved_R2','delta_R2'})]; %#ok<AGROW>
end
summary=table(mean(rows.original_R2),mean(rows.improved_R2),mean(rows.delta_R2),sum(rows.delta_R2>0),height(rows), ...
    'VariableNames',{'original_mean_R2','improved_mean_R2','mean_delta_R2','improved_wins','repeats'});
writetable(rows,fullfile(resultsDir,'fmrvr_improved_matched_comparison.csv'));
writetable(summary,fullfile(resultsDir,'fmrvr_improved_matched_summary.csv'));
report.summary=summary;report.metrics=rows;
fprintf('Matched FMRVR: original %.4f, improved %.4f, delta %.4f (%d/%d wins).\n',summary.original_mean_R2,summary.improved_mean_R2,summary.mean_delta_R2,summary.improved_wins,summary.repeats);
end
