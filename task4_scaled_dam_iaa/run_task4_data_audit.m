function outputs = run_task4_data_audit()
%RUN_TASK4_DATA_AUDIT Validate private data and export compact CSV audits.
root=setup_task4(); cfg=task4_config(root);
assert(exist(cfg.raw.task4_data_file,'file')==2, ...
    'Task4Data.mat not found. Configure config/task4_local_paths.m.');
if H5F.is_hdf5(cfg.raw.task4_data_file)
    [source,closeSource]=open_task4_history_reader(cfg.raw.task4_data_file,cfg); %#ok<NASGU>
else
    loaded=load(cfg.raw.task4_data_file,'Task4');
    assert(isfield(loaded,'Task4'),'The MAT-file must contain variable Task4.');
    validate_task4_structure(loaded.Task4,cfg); source=loaded.Task4;
end
metadata=build_task4_metadata(cfg);
[historyAudit,caseSummary]=audit_task4_responses(source,metadata,cfg);
if ~isfolder(cfg.results_dir), mkdir(cfg.results_dir); end
writetable(metadata,fullfile(cfg.results_dir,'task4_simulation_metadata.csv'));
writetable(historyAudit,fullfile(cfg.results_dir,'task4_history_qc.csv'));
writetable(caseSummary,fullfile(cfg.results_dir,'task4_case_qc_summary.csv'));
save(fullfile(cfg.results_dir,'task4_audit_config.mat'),'cfg');
outputs.metadata=metadata; outputs.historyAudit=historyAudit; outputs.caseSummary=caseSummary;
fprintf('Task 4 audit complete: %d simulations and %d histories.\n', ...
    height(metadata),height(historyAudit));
fprintf('Raw truncated histories: %d; screened unusable histories: %d; length mismatches: %d.\n', ...
    sum(historyAudit.was_truncated),sum(~historyAudit.is_usable),sum(~historyAudit.length_matches_time));
end
