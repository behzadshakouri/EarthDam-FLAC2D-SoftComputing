function export_task3_qc(dataset,qc,cfg)
%EXPORT_TASK3_QC Write local feature and response-cleaning audit tables.
featureTable = array2table(dataset.X,'VariableNames',dataset.feature_names);
featureTable = addvars(featureTable,dataset.realization_id,'Before',1, ...
    'NewVariableNames','realization_id');
writetable(featureTable,fullfile(cfg.results_dir,'task3_input_features.csv'));

dictionary = dataset.output_dictionary;
truncatedCount = sum(qc.truncated,1)';
minimumCleanLength = min(qc.clean_length,[],1)';
maximumCleanLength = max(qc.clean_length,[],1)';
invalidTargetCount = sum(qc.invalid_Y,1)';
qcTable = table((1:cfg.num_outputs)',{dictionary.label}',truncatedCount, ...
    minimumCleanLength,maximumCleanLength,invalidTargetCount, ...
    qc.constant_outputs(:),'VariableNames',{'output_column','label', ...
    'truncated_realizations','minimum_clean_length','maximum_clean_length', ...
    'invalid_target_count','constant_output'});
writetable(qcTable,fullfile(cfg.results_dir,'task3_response_qc.csv'));

pgaTable = table(dataset.realization_id,qc.source_PGA,dataset.X(:,1), ...
    qc.computed_minus_source_PGA,'VariableNames',{'realization_id', ...
    'stored_PGA','computed_PGA','difference'});
writetable(pgaTable,fullfile(cfg.results_dir,'task3_pga_qc.csv'));
end
