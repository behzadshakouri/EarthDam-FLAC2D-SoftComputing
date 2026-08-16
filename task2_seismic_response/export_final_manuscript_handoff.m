function output_file = export_final_manuscript_handoff
%EXPORT_FINAL_MANUSCRIPT_HANDOFF Write final manuscript data to one XLSX.
% Reads saved results only; no surrogate is fitted or rerun.

root=setup_task2;
cfg=task2_config(root);
spec={'ELM',30;'ELMABC',15;'ELMACOR',15;'ELMIGWO',5};
sweep_root=fullfile(root,'results','method_neuron_sweep');
stamp=datestr(now,'yyyymmdd_HHMMSS');
output_file=fullfile(root,'results', ...
    ['task2_final_manuscript_handoff_' stamp '.xlsx']);

all_metrics=table();
model_summary=table();
for i=1:size(spec,1)
    method=spec{i,1}; neurons=spec{i,2};
    experiment=fullfile(sweep_root,sprintf('%s_N%03d',method,neurons));
    metrics_file=fullfile(experiment,sprintf('task2_%s_metrics.csv',lower(method)));
    if exist(metrics_file,'file')~=2
        error('Task2:MissingSelectedMetrics','Missing selected metrics: %s',metrics_file);
    end
    T=readtable(metrics_file);
    if height(T)~=70
        error('Task2:IncompleteSelectedMetrics','%s contains %d/70 cases.',method,height(T));
    end
    T.model=repmat(string(method),height(T),1);
    T.selected_configuration=repmat(string(sprintf('%s-%d',method,neurons)),height(T),1);
    all_metrics=[all_metrics;T]; %#ok<AGROW>

    modeled=~T.constant_reference & isfinite(T.R2);
    one=table(string(method),neurons,height(T),sum(modeled), ...
        mean(T.R2(modeled),'omitnan'),median(T.R2(modeled),'omitnan'), ...
        min(T.R2(modeled),[],'omitnan'),max(T.R2(modeled),[],'omitnan'), ...
        mean(T.nRMSE(modeled),'omitnan'),mean(T.nMAE(modeled),'omitnan'), ...
        mean(T.a10(modeled),'omitnan'),sum(T.R2(modeled)>=0.90), ...
        sum(T.train_s,'omitnan'), ...
        'VariableNames',{'model','hidden_neurons','case_count','modeled_cases', ...
        'mean_R2','median_R2','min_R2','max_R2','mean_nRMSE','mean_nMAE', ...
        'mean_a10','cases_R2_ge_090','total_train_s'});
    model_summary=[model_summary;one]; %#ok<AGROW>
end

all_metrics=sortrows(all_metrics,{'model','point','response'});
by_response=summarize_groups(all_metrics,{'model','response'});
by_point=summarize_groups(all_metrics,{'model','point'});
modeled=~all_metrics.constant_reference & isfinite(all_metrics.R2);
ranked=sortrows(all_metrics(modeled,:),{'model','R2'},{'ascend','ascend'});
low_R2=table();
for i=1:size(spec,1)
    q=ranked.model==string(spec{i,1});
    one=ranked(q,:); one=one(1:min(10,height(one)),:);
    low_R2=[low_R2;one]; %#ok<AGROW>
end
% readtable imports CSV logical flags as numeric 0/1 in MATLAB R2020a.
% Convert explicitly before using the flag as a row index; otherwise zeros
% are interpreted as invalid numeric indices rather than false values.
constant_cases=all_metrics(logical(all_metrics.constant_reference),:);
difficult=all_metrics( ...
    (all_metrics.point==7 & all_metrics.response==5) | ...
    (all_metrics.point==9 & all_metrics.response==3) | ...
    (all_metrics.point==10 & ismember(all_metrics.response,[4 6 7])),:);

readme=table( ...
    ["Purpose";"Selected models";"Primary metric scope";"Case count"; ...
     "Nonconstant cases per model";"Constant-reference cases"; ...
     "Split";"Important exclusion";"Generated"], ...
    ["Final manuscript/rebuttal handoff; saved results only"; ...
     "ELM-30; ELMABC-15; ELMACOR-15; ELMIGWO-5"; ...
     "Fixed held-out test realizations; pooled case-wise metrics"; ...
     "70 response-location cases per model"; ...
     "67";"P8-R5, P9-R5, and P10-R5"; ...
     "210 development / 90 test realizations"; ...
     "Neuron/cap/two-stage difficult-case experiments are diagnostic only"; ...
     string(datetime('now'))], ...
    'VariableNames',{'item','value'});

writetable(readme,output_file,'Sheet','README');
writetable(model_summary,output_file,'Sheet','model_summary');
writetable(all_metrics,output_file,'Sheet','selected_case_metrics');
writetable(by_response,output_file,'Sheet','by_response');
writetable(by_point,output_file,'Sheet','by_point');
writetable(difficult,output_file,'Sheet','difficult_cases');
writetable(low_R2,output_file,'Sheet','lowest_R2_cases');
writetable(constant_cases,output_file,'Sheet','constant_cases');

neuron_file=fullfile(sweep_root,'method_neuron_sweep_summary.csv');
if exist(neuron_file,'file')==2
    writetable(readtable(neuron_file),output_file,'Sheet','neuron_sweep');
end

split_file=cfg.split_file;
if exist(split_file,'file')==2
    Q=load(split_file,'split');
    split_ids=table([double(Q.split.development_ids(:));double(Q.split.test_ids(:))], ...
        [repmat("development",numel(Q.split.development_ids),1); ...
         repmat("test",numel(Q.split.test_ids),1)], ...
        'VariableNames',{'simulation_id','partition'});
    writetable(split_ids,output_file,'Sheet','split_ids');
end

optional={ ...
    fullfile(root,'results','failure_screening','failure_screening_summary.csv'), ...
        'failure_summary'; ...
    fullfile(root,'results','failure_screening','failure_detector_parameters.csv'), ...
        'failure_parameters'; ...
    fullfile(root,'results','final_production','difficult_case_diagnostics', ...
        'difficult_cases_diagnostic_summary.csv'),'diagnostics_only'; ...
    fullfile(root,'results','p7_r5_two_stage_experiment', ...
        'p7_r5_two_stage_summary.csv'),'two_stage_diagnostic'};
for i=1:size(optional,1)
    if exist(optional{i,1},'file')==2
        writetable(readtable(optional{i,1}),output_file,'Sheet',optional{i,2});
    end
end

fprintf('\nFinal one-file handoff written to:\n%s\n',output_file);
fprintf('Upload this XLSX for the final manuscript and response-letter update.\n');
end

function out=summarize_groups(T,group_names)
keys=unique(T(:,group_names),'rows','stable'); out=table();
for i=1:height(keys)
    q=true(height(T),1);
    for j=1:numel(group_names)
        name=group_names{j};
        if isstring(T.(name)) || iscellstr(T.(name))
            q=q & string(T.(name))==string(keys.(name)(i));
        else
            q=q & T.(name)==keys.(name)(i);
        end
    end
    U=T(q & ~T.constant_reference & isfinite(T.R2),:);
    row=keys(i,:);
    row.modeled_cases=height(U);
    row.mean_R2=mean(U.R2,'omitnan'); row.median_R2=median(U.R2,'omitnan');
    row.min_R2=min(U.R2,[],'omitnan'); row.max_R2=max(U.R2,[],'omitnan');
    row.mean_nRMSE=mean(U.nRMSE,'omitnan');
    row.mean_nMAE=mean(U.nMAE,'omitnan'); row.mean_a10=mean(U.a10,'omitnan');
    row.cases_R2_ge_090=sum(U.R2>=0.90);
    out=[out;row]; %#ok<AGROW>
end
end
