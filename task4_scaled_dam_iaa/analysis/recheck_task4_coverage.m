function recheck_task4_coverage()
%RECHECK_TASK4_COVERAGE Re-evaluate histories that failed the initial audit.
analysisDir=fileparts(mfilename('fullpath'));root=fileparts(analysisDir);
addpath(root);setup_task4;run_synthetic_self_test;cfg=task4_config(root);
[reader,closeSource]=open_task4_history_reader(cfg.raw.task4_data_file,cfg);
path=fullfile(cfg.results_dir,'task4_history_qc.csv');
T=readtable(path);
T.screening_status=cellstr(string(T.screening_status));
T.screening_message=cellstr(string(T.screening_message));
failed=find(~strcmp(T.screening_status,'screened'));
for j=1:numel(failed)
    k=failed(j); i=T.simulation_id(k); p=T.point(k); r=T.response(k);
    t=reader('/Task4/Outputs/dytime',i);
    y=reader(sprintf('/Task4/Outputs/P%d/R%d',p,r),i);
    try
        [~,~,info]=prepare_task4_history(t,y,r,cfg);
        T.is_usable(k)=info.is_usable;
        T.removed_nonfinite_pairs(k)=info.removed_nonfinite_pairs;
        T.admissible_samples(k)=info.admissible_samples;
        T.onset_time_s(k)=info.onset_time_s;
        T.padded_tail_samples(k)=info.padded_tail_samples;
        T.screening_status{k}='screened'; T.screening_message{k}='';
    catch err
        if ~startsWith(err.identifier,'Task4:'), rethrow(err); end
        T.screening_status{k}=err.identifier; T.screening_message{k}=err.message;
        T.removed_nonfinite_pairs(k)=sum(~isfinite(t) | ~isfinite(y));
    end
    if mod(j,500)==0, fprintf('Rechecked %d/%d coverage failures.\n',j,numel(failed)); end
end
clear closeSource;
assert(height(T)==31500 && all(logical(T.is_usable)==(T.admissible_samples>=2)));
caseSummary=groupsummary(T,{'scale_factor','case_id','point','response','label'}, ...
    {'sum','min','max'},{'was_truncated','clean_length','maximum_absolute_clean_value','is_usable','admissible_samples'});
writetable(T,path); writetable(caseSummary,fullfile(cfg.results_dir,'task4_case_qc_summary.csv'));
save(fullfile(cfg.results_dir,'task4_audit_config.mat'),'cfg');
fprintf('FINAL AUDIT: screened=%d, unusable=%d, padded_histories=%d.\n',sum(strcmp(T.screening_status,'screened')),sum(~T.is_usable),sum(T.padded_tail_samples>0));
end
