function sensitivity=run_task3_screening_sensitivity_final()
%RUN_TASK3_SCREENING_SENSITIVITY_FINAL Compare 10x/20x with adopted 5x rule.
analysisDir=fileparts(mfilename('fullpath')); root=fileparts(analysisDir);
addpath(root); setup_task3; cfg=task3_config(root);
prepared=load(fullfile(cfg.results_dir,'task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[Ybase,auditBase]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
sensitivity=table;
for multiplier=[10 20]
    [Yalt,auditAlt]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,multiplier);
    scale=max(abs(Ybase),1e-12); relative=abs(Yalt-Ybase)./scale;
    finiteRows=isfinite(auditAlt.screening_onset_s) & isfinite(auditBase.screening_onset_s);
    onsetDifference=abs(auditAlt.screening_onset_s(finiteRows)-auditBase.screening_onset_s(finiteRows));
    sensitivity=[sensitivity;table(multiplier,median(relative(:)),percentile(relative(:),95), ...
        max(relative(:)),median(onsetDifference),max(onsetDifference), ...
        sum(auditAlt.had_sentinel),sum(isfinite(auditAlt.screening_onset_s)), ...
        'VariableNames',{'threshold_multiplier','median_relative_target_change', ...
        'p95_relative_target_change','maximum_relative_target_change', ...
        'median_onset_change_s','maximum_onset_change_s', ...
        'sentinel_realizations','screened_realizations'})]; %#ok<AGROW>
end
out=task3_analysis_results_root(root); if ~exist(out,'dir'),mkdir(out);end
writetable(sensitivity,fullfile(out,'screening_sensitivity.csv'));
writetable(sensitivity,fullfile(root,'reference_results','screening_sensitivity.csv'));
generate_task3_screening_sensitivity_figure();
disp(sensitivity);
end

function value=percentile(x,p)
x=sort(x(isfinite(x))); if isempty(x),value=NaN;return;end
position=1+(numel(x)-1)*p/100;lower=floor(position);upper=ceil(position);
if lower==upper,value=x(lower);else,value=x(lower)+(position-lower)*(x(upper)-x(lower));end
end
