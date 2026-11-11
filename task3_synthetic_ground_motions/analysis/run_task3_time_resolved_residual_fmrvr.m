function report=run_task3_time_resolved_residual_fmrvr(repeats,samplesPerRecord)
%RUN_TASK3_TIME_RESOLVED_RESIDUAL_FMRVR Nested FMRVR residual correction.
if nargin<1, repeats=3; end
if nargin<2, samplesPerRecord=100; end
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
cfg.fmrvr.max_iterations=300; cfg.fmrvr.tolerance=.2;
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[~,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
data=build_task3_time_resolved_dataset(raw.Task3,prepared.dataset,audit,cfg,samplesPerRecord);
failure=logical(audit.had_sentinel); failed=find(failure); stable=find(~failure);
spec.width_factors=[.5 1 2]; spec.linear_mix=.5; spec.target_transform="none"; spec.output_rank=5;
sampleWithin=round(linspace(1,data.samples_per_record,5)); betaGrid=0:.1:1;
outer=table; selections=table; perOutput=table; splitOne=struct;
for repeat=1:repeats
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    devIds=sort([a(1:34);b(1:71)]); testIds=sort([a(35:end);b(72:end)]);
    fold=stratified_folds(failure(devIds),3,cfg.seed+11200+repeat);
    baseOof=[]; correctedOof=[]; observedOof=[]; realizationOof=[];
    for f=1:3
        trIds=devIds(fold~=f); vaIds=devIds(fold==f);
        tr=ismember(data.realization_id,trIds); va=ismember(data.realization_id,vaIds);
        ridge=fit_ridge(data.X(tr,:),data.Y(tr,:),10,cfg);
        baseVa=enforce_envelopes(predict_ridge(ridge,data.X(va,:)),data.realization_id(va));
        subset=select_rows(data.realization_id,trIds,sampleWithin);
        fittedSubset=enforce_envelopes(predict_ridge(ridge,data.X(subset,:)),data.realization_id(subset));
        residual=data.Y(subset,:)-fittedSubset;
        correction=fit_task3_fmrvr_advanced(data.X(subset,:),residual,spec,cfg);
        baseOof=[baseOof;baseVa]; %#ok<AGROW>
        correctedOof=[correctedOof;predict_task3_fmrvr_advanced(correction,data.X(va,:))]; %#ok<AGROW>
        observedOof=[observedOof;data.Y(va,:)]; %#ok<AGROW>
        realizationOof=[realizationOof;data.realization_id(va)]; %#ok<AGROW>
    end
    beta=zeros(7,1); innerScore=zeros(7,1);
    for response=1:7
        ids=response:7:cfg.num_outputs; scores=nan(numel(betaGrid),1);
        for q=1:numel(betaGrid)
            pred=enforce_envelopes(max(baseOof(:,ids)+betaGrid(q)*correctedOof(:,ids),0),realizationOof);
            mt=calculate_task3_metrics(observedOof(:,ids),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
            scores(q)=mean([mt(use).nRMSE]);
        end
        [innerScore(response),best]=min(scores); beta(response)=betaGrid(best);
        selections=[selections;table(repeat,response,beta(response),innerScore(response), ...
            'VariableNames',{'repeat','response','residual_weight','inner_nRMSE'})]; %#ok<AGROW>
    end
    dev=ismember(data.realization_id,devIds); test=ismember(data.realization_id,testIds);
    ridge=fit_ridge(data.X(dev,:),data.Y(dev,:),10,cfg);
    base=enforce_envelopes(predict_ridge(ridge,data.X(test,:)),data.realization_id(test));
    subset=select_rows(data.realization_id,devIds,sampleWithin);
    fittedSubset=enforce_envelopes(predict_ridge(ridge,data.X(subset,:)),data.realization_id(subset));
    residual=data.Y(subset,:)-fittedSubset;
    correction=fit_task3_fmrvr_advanced(data.X(subset,:),residual,spec,cfg);
    residualPrediction=predict_task3_fmrvr_advanced(correction,data.X(test,:)); prediction=base;
    for response=1:7
        ids=response:7:cfg.num_outputs; prediction(:,ids)=max(base(:,ids)+beta(response)*residualPrediction(:,ids),0);
    end
    prediction=enforce_envelopes(prediction,data.realization_id(test));
    baseMetrics=calculate_task3_metrics(data.Y(test,:),base,cfg.preprocessing.constant_tolerance);
    mt=calculate_task3_metrics(data.Y(test,:),prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    outer=[outer;table(repeat,mean(beta),mean(innerScore),mean([baseMetrics(use).R2]),mean([mt(use).R2]), ...
        median([mt(use).R2]),mean([mt(use).nRMSE]),mean([mt(use).nMAE]),numel(correction.used), ...
        sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8),sum([mt(use).R2]>=.9), ...
        'VariableNames',{'repeat','residual_weight','inner_nRMSE','ridge_mean_R2','corrected_mean_R2', ...
        'corrected_median_R2','mean_nRMSE','mean_nMAE','relevance_bases', ...
        'outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'})]; %#ok<AGROW>
    dictionary=prepared.dataset.output_dictionary;
    perOutput=[perOutput;table(repmat(repeat,cfg.num_outputs,1),(1:cfg.num_outputs)', ...
        string({dictionary.label})',[dictionary.point]',[dictionary.response]',string({dictionary.name})', ...
        [baseMetrics.R2]',[mt.R2]',[mt.R2]'-[baseMetrics.R2]',[mt.nRMSE]',[mt.nMAE]', ...
        [mt.a10]',[mt.constant]','VariableNames',{'repeat','output_column','label','point', ...
        'response','response_name','ridge_R2','corrected_R2','delta_R2','nRMSE','nMAE','a10','constant'})]; %#ok<AGROW>
    if repeat==1
        splitOne=struct('observed',data.Y(test,:),'ridge_prediction',base, ...
            'corrected_prediction',prediction,'realization_id',data.realization_id(test), ...
            'time_s',data.time_s(test),'test_ids',testIds,'residual_weight',beta, ...
            'feature_names',data.feature_names);
    end
    fprintf('Residual FMRVR %d/%d: ridge %.4f, corrected %.4f, mean weight %.2f.\n', ...
        repeat,repeats,outer.ridge_mean_R2(end),outer.corrected_mean_R2(end),mean(beta));
end
summary=table(mean(outer.ridge_mean_R2),mean(outer.corrected_mean_R2),std(outer.corrected_mean_R2), ...
    mean(outer.corrected_mean_R2-outer.ridge_mean_R2),mean(outer.residual_weight), ...
    mean(outer.outputs_R2_ge_07),mean(outer.outputs_R2_ge_08),mean(outer.outputs_R2_ge_09), ...
    'VariableNames',{'ridge_mean_R2','corrected_mean_R2','corrected_sd_R2','mean_delta_R2', ...
    'mean_residual_weight','mean_outputs_R2_ge_07','mean_outputs_R2_ge_08','mean_outputs_R2_ge_09'});
family=table;
for response=1:7
    rows=perOutput(perOutput.response==response & ~perOutput.constant,:);
    bySplit=table;
    for repeat=unique(rows.repeat)'
        part=rows(rows.repeat==repeat,:);
        bySplit=[bySplit;table(repeat,mean(part.ridge_R2),mean(part.corrected_R2),mean(part.delta_R2), ...
            'VariableNames',{'repeat','ridge_R2','corrected_R2','delta_R2'})]; %#ok<AGROW>
    end
    family=[family;table(response,string(prepared.dataset.output_dictionary(response).name), ...
        mean(bySplit.ridge_R2),mean(bySplit.corrected_R2),std(bySplit.corrected_R2), ...
        mean(bySplit.delta_R2),'VariableNames',{'response','response_name','ridge_mean_R2', ...
        'corrected_mean_R2','corrected_sd_R2','mean_delta_R2'})]; %#ok<AGROW>
end
suffix=sprintf('%dpoints',samplesPerRecord);
writetable(outer,fullfile(resultsDir,['time_resolved_residual_fmrvr_family_metrics_' suffix '.csv']));
writetable(selections,fullfile(resultsDir,['time_resolved_residual_fmrvr_family_selections_' suffix '.csv']));
writetable(perOutput,fullfile(resultsDir,['time_resolved_residual_fmrvr_per_output_' suffix '.csv']));
writetable(family,fullfile(resultsDir,['time_resolved_residual_fmrvr_response_family_' suffix '.csv']));
writetable(summary,fullfile(resultsDir,['time_resolved_residual_fmrvr_family_summary_' suffix '.csv']));
save(fullfile(resultsDir,['time_resolved_residual_fmrvr_split1_' suffix '.mat']),'splitOne','-v7.3');
report=struct('metrics',outer,'summary',summary,'selections',selections, ...
    'per_output',perOutput,'family',family,'split_one',splitOne); disp(summary); disp(family);
end

function Y=enforce_envelopes(Y,realization)
ids=unique(realization,'stable');
for id=ids'
    rows=find(realization==id); Y(rows,:)=cummax(max(Y(rows,:),0),1);
end
end

function take=select_rows(realization,ids,sampleWithin)
take=false(size(realization));
for id=ids'
    rows=find(realization==id); take(rows(sampleWithin))=true;
end
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
