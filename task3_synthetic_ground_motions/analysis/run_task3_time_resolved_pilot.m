function report=run_task3_time_resolved_pilot(samplesPerRecord)
%RUN_TASK3_TIME_RESOLVED_PILOT Record-separated Task 2-style pilot.
if nargin<1, samplesPerRecord=40; end
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[~,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
data=build_task3_time_resolved_dataset(raw.Task3,prepared.dataset,audit,cfg,samplesPerRecord);
failure=logical(audit.had_sentinel); failed=find(failure); stable=find(~failure);
lambdas=[.01 .1 1 10 100 1000]; outer=table; perOutput=table;
for repeat=1:10
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    devIds=sort([a(1:34);b(1:71)]); testIds=sort([a(35:end);b(72:end)]);
    fold=stratified_folds(failure(devIds),3,cfg.seed+10400+repeat); score=zeros(numel(lambdas),1);
    for q=1:numel(lambdas)
        predictions=[]; observations=[];
        for f=1:3
            trIds=devIds(fold~=f); vaIds=devIds(fold==f);
            tr=ismember(data.realization_id,trIds); va=ismember(data.realization_id,vaIds);
            model=fit_ridge(data.X(tr,:),data.Y(tr,:),lambdas(q),cfg);
            predictions=[predictions;predict_ridge(model,data.X(va,:))]; %#ok<AGROW>
            observations=[observations;data.Y(va,:)]; %#ok<AGROW>
        end
        mt=calculate_task3_metrics(observations,predictions,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
        score(q)=mean([mt(use).nRMSE]);
    end
    [innerScore,best]=min(score); lambda=lambdas(best);
    tr=ismember(data.realization_id,devIds); te=ismember(data.realization_id,testIds);
    model=fit_ridge(data.X(tr,:),data.Y(tr,:),lambda,cfg); prediction=predict_ridge(model,data.X(te,:));
    mt=calculate_task3_metrics(data.Y(te,:),prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    outer=[outer;table(repeat,lambda,innerScore,mean([mt(use).R2]),median([mt(use).R2]), ...
        mean([mt(use).nRMSE]),mean([mt(use).nMAE]),sum([mt(use).R2]>=.7), ...
        sum([mt(use).R2]>=.8),sum([mt(use).R2]>=.9), ...
        'VariableNames',{'repeat','lambda','inner_nRMSE','mean_R2','median_R2','mean_nRMSE', ...
        'mean_nMAE','outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'})]; %#ok<AGROW>
    perOutput=[perOutput;table(repmat(repeat,cfg.num_outputs,1),(1:cfg.num_outputs)', ...
        string({prepared.dataset.output_dictionary.label})',[prepared.dataset.output_dictionary.response]', ...
        [mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.constant]','VariableNames',{'repeat','output_column', ...
        'label','response','R2','nRMSE','nMAE','constant'})]; %#ok<AGROW>
    fprintf('Time-resolved pilot %d/10: R2 %.4f, %d outputs >=0.9.\n',repeat,outer.mean_R2(end),outer.outputs_R2_ge_09(end));
end
summary=table(mean(outer.mean_R2),std(outer.mean_R2),min(outer.mean_R2),max(outer.mean_R2), ...
    mean(outer.median_R2),mean(outer.mean_nRMSE),mean(outer.mean_nMAE), ...
    mean(outer.outputs_R2_ge_07),mean(outer.outputs_R2_ge_08),mean(outer.outputs_R2_ge_09), ...
    'VariableNames',{'mean_R2','sd_R2','minimum_R2','maximum_R2','mean_median_R2', ...
    'mean_nRMSE','mean_nMAE','mean_outputs_R2_ge_07','mean_outputs_R2_ge_08','mean_outputs_R2_ge_09'});
family=table;
for response=1:7
    rows=perOutput(perOutput.response==response & ~perOutput.constant,:);
    family=[family;table(response,string(prepared.dataset.output_dictionary(response).name), ...
        mean(rows.R2),std(rows.R2),'VariableNames',{'response','response_name','mean_R2','sd_R2'})]; %#ok<AGROW>
end
suffix=sprintf('%dpoints',samplesPerRecord);
writetable(outer,fullfile(resultsDir,['time_resolved_pilot_nested_metrics_' suffix '.csv']));
writetable(perOutput,fullfile(resultsDir,['time_resolved_pilot_nested_per_output_' suffix '.csv']));
writetable(summary,fullfile(resultsDir,['time_resolved_pilot_nested_summary_' suffix '.csv']));
writetable(family,fullfile(resultsDir,['time_resolved_pilot_nested_family_summary_' suffix '.csv']));
writetable(table((1:numel(data.feature_names))',data.feature_names(:), ...
    'VariableNames',{'feature_index','feature'}),fullfile(resultsDir,'time_resolved_feature_dictionary.csv'));
report=struct('metrics',outer,'summary',summary,'family',family); disp(summary); disp(family);
end

function model=fit_ridge(X,Y,lambda,cfg)
model.scale=median(abs(X),1); model.scale(model.scale<=eps)=1;
X=asinh(bsxfun(@rdivide,X,model.scale)); model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs); Y=apply_task3_standardizer(Y,model.ys);
A=[ones(size(X,1),1) X]; P=eye(size(A,2)); P(1,1)=0; model.beta=(A'*A+lambda*P)\(A'*Y);
end

function Y=predict_ridge(model,X)
X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,model.scale)),model.xs);
Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys); Y=max(Y,0);
end

function fold=stratified_folds(label,k,seed)
rng(seed,'twister'); fold=zeros(numel(label),1);
for value=[false true]
    ids=find(label==value); ids=ids(randperm(numel(ids)));
    for j=1:numel(ids), fold(ids(j))=mod(j-1,k)+1; end
end
end
