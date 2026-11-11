function report=verify_task3_common_onset_envelope_equivalence()
%VERIFY_TASK3_COMMON_ONSET_ENVELOPE_EQUIVALENCE Confirm target equivalence.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);
saved=load(fullfile(resultsDir,'task3_screened_targets.mat'),'Y','screeningAudit');
raw=load(cfg.raw.task3_data_file,'Task3'); dictionary=task3_response_dictionary();
Yenvelope=nan(size(saved.Y));
for i=1:cfg.num_realizations
    time=double(raw.Task3.Outputs.dytime{i}(:));
    onset=saved.screeningAudit.screening_onset_s(i);
    for k=1:cfg.num_outputs
        p=dictionary(k).point; r=dictionary(k).response;
        values=double(raw.Task3.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r)){i}(:));
        admissible=isfinite(values) & abs(values)<cfg.qc.sentinel_abs_threshold;
        if isfinite(onset), admissible=admissible & time<onset; end
        values=values(admissible);
        if ismember(r,[3 4 5])
            envelope=cummax(abs(values-values(1)));
        else
            envelope=cummax(abs(values));
        end
        Yenvelope(i,k)=envelope(end);
    end
end
difference=abs(Yenvelope-saved.Y);
report=table(max(difference(:)),mean(difference(:)),nnz(difference>0), ...
    'VariableNames',{'maximum_absolute_difference','mean_absolute_difference', ...
    'nonzero_differences'});
assert(report.maximum_absolute_difference<=1e-12*max(1,max(abs(saved.Y(:)))));
writetable(report,fullfile(resultsDir,'common_onset_envelope_equivalence.csv'));
fprintf('Common-onset envelope equivalence: max difference %.16g across %d targets.\n', ...
    report.maximum_absolute_difference,numel(saved.Y));
end
