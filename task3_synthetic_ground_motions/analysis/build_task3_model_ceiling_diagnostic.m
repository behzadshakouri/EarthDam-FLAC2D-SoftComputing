function report=build_task3_model_ceiling_diagnostic()
%BUILD_TASK3_MODEL_CEILING_DIAGNOSTIC Test-informed upper-bound diagnostic.
% This deliberately uses fixed-test outcomes and must never be presented as
% a predictive model. It asks whether any already-evaluated model performs
% well for each output, even with impossible after-the-fact model selection.
analysisDir=fileparts(mfilename('fullpath')); resultsDir=task3_analysis_results_root(root);
files=dir(fullfile(resultsDir,'*test_per_output.csv')); labels=strings(0,1); best=zeros(0,1); source=strings(0,1);
for f=1:numel(files)
    t=readtable(fullfile(files(f).folder,files(f).name));
    if ~all(ismember({'label','R2','constant'},t.Properties.VariableNames)), continue; end
    for i=1:height(t)
        if t.constant(i) || ~isfinite(t.R2(i)), continue; end
        label=string(t.label(i)); idx=find(labels==label,1);
        if isempty(idx),labels=[labels;label];best=[best;t.R2(i)];source=[source;string(files(f).name)]; %#ok<AGROW>
        elseif t.R2(i)>best(idx),best(idx)=t.R2(i);source(idx)=string(files(f).name);end
    end
end
detail=table(labels,best,source,'VariableNames',{'label','oracle_best_R2','source_file'});detail=sortrows(detail,'label');
summary=table(numel(best),mean(best),sum(best>=.7),sum(best>=.8),sum(best>=.9), ...
    'VariableNames',{'outputs','oracle_mean_R2','outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'});
writetable(detail,fullfile(resultsDir,'model_ceiling_oracle_per_output.csv'));
writetable(summary,fullfile(resultsDir,'model_ceiling_oracle_summary.csv'));
report.detail=detail;report.summary=summary;
fprintf('Test-informed oracle only: mean R2 %.4f; %d/%d outputs >=0.9.\n',summary.oracle_mean_R2,summary.outputs_R2_ge_09,summary.outputs);
end
