function report=run_task3_envelope_target_audit()
%RUN_TASK3_ENVELOPE_TARGET_AUDIT Build and compare Task 2-style Task 3 targets.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[Y,audit,summary]=build_task3_envelope_targets(raw.Task3,cfg);
[Yold,oldAudit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);

scale=max(abs(Yold),1e-12);
relative=abs(Y-Yold)./scale;
comparison=table(mean(relative,1)',median(relative,1)',max(relative,[],1)', ...
    'VariableNames',{'mean_relative_change','median_relative_change','maximum_relative_change'});
dictionary=prepared.dataset.output_dictionary;
comparison.output_column=(1:cfg.num_outputs)';
comparison.point=[dictionary.point]'; comparison.response=[dictionary.response]';
comparison=comparison(:,{'output_column','point','response','mean_relative_change', ...
    'median_relative_change','maximum_relative_change'});

save(fullfile(resultsDir,'task3_envelope_targets.mat'),'Y','audit','summary','comparison','oldAudit','-v7.3');
writetable(audit,fullfile(resultsDir,'task3_envelope_screening_audit.csv'));
writetable(summary,fullfile(resultsDir,'task3_envelope_screening_summary.csv'));
writetable(comparison,fullfile(resultsDir,'task3_envelope_target_comparison.csv'));
fprintf('Envelope audit: %d sentinel simulations, %d detector-positive simulations, %d detector-positive histories.\n', ...
    summary.sentinel_simulations,summary.detected_simulations,summary.detected_histories);
fprintf('Median target change %.6g; 95th percentile %.6g; maximum %.6g.\n', ...
    median(relative(:)),prctile(relative(:),95),max(relative(:)));
report=struct('Y',Y,'audit',audit,'summary',summary,'comparison',comparison);
end
