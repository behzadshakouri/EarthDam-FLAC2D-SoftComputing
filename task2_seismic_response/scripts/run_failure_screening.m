function run_failure_screening()
root=setup_task2; cfg=task2_config(root); S=load(cfg.consolidated_file,'dataset');
validate_consolidated_dataset(S.dataset,cfg);
failure_data=build_failure_database(S.dataset,cfg);
save(cfg.failure_file,'failure_data','-v7.3');
fprintf('Saved %s\n',cfg.failure_file);
counts_by_response = squeeze(sum(sum(failure_data.failure_detected,1),2));
fprintf('Detector: %s\n', cfg.detector.version);
for r = 1:cfg.num_responses
    fprintf('R%d detected histories: %d / %d\n', r, ...
        counts_by_response(r), cfg.num_realizations * cfg.num_points);
end
fprintf('All detected histories: %d / %d\n', ...
    nnz(failure_data.failure_detected), numel(failure_data.failure_detected));
end
