function report=run_task3_direct_fmrvr_validation(repeats)
%RUN_TASK3_DIRECT_FMRVR_VALIDATION Standalone time-resolved FMRVR.
if nargin<1, repeats=3; end
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3;
cfg=task3_config(root); cfg.fmrvr.max_iterations=500; cfg.fmrvr.tolerance=.1;
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[~,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
data=build_task3_time_resolved_dataset(raw.Task3,prepared.dataset,audit,cfg,100);
failure=logical(audit.had_sentinel); failed=find(failure); stable=find(~failure);
ranks=[5 10 20]; sampleWithin=round(linspace(1,100,20));
outer=table; perOutput=table; splitOne=struct;
for repeat=1:repeats
    rng(cfg.seed+1500+repeat,'twister');
    a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    devIds=sort([a(1:34);b(1:71)]); testIds=sort([a(35:end);b(72:end)]);
    folds=record_folds(devIds,failure,3,cfg.seed+9100+repeat);
    scores=nan(numel(ranks),1);
    for q=1:numel(ranks)
        foldScores=nan(3,1);
        for fold=1:3
            vaIds=devIds(folds==fold); trIds=setdiff(devIds,vaIds);
            tr=select_rows(data.realization_id,trIds,sampleWithin);
            va=ismember(data.realization_id,vaIds);
            model=fit_task3_fmrvr_basis(data.X(tr,:),data.Y(tr,:),ranks(q),cfg);
            prediction=enforce_envelopes(predict_task3_fmrvr_basis(model,data.X(va,:)),data.realization_id(va));
            mt=calculate_task3_metrics(data.Y(va,:),prediction,cfg.preprocessing.constant_tolerance);
            use=~[mt.constant]; foldScores(fold)=mean([mt(use).nRMSE]);
        end
        scores(q)=mean(foldScores);
    end
    [innerScore,best]=min(scores); selectedRank=ranks(best);
    tr=select_rows(data.realization_id,devIds,sampleWithin);
    test=ismember(data.realization_id,testIds);
    model=fit_task3_fmrvr_basis(data.X(tr,:),data.Y(tr,:),selectedRank,cfg);
    prediction=enforce_envelopes(predict_task3_fmrvr_basis(model,data.X(test,:)),data.realization_id(test));
    observed=data.Y(test,:);
    mt=calculate_task3_metrics(observed,prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    outer=[outer;table(repeat,selectedRank,innerScore,numel(model.used),mean([mt(use).R2]), ...
        median([mt(use).R2]),mean([mt(use).nRMSE]),mean([mt(use).nMAE]), ...
        sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8),sum([mt(use).R2]>=.9), ...
        'VariableNames',{'repeat','selected_rank','inner_nRMSE','relevance_bases', ...
        'mean_R2','median_R2','mean_nRMSE','mean_nMAE','outputs_R2_ge_07', ...
        'outputs_R2_ge_08','outputs_R2_ge_09'})]; %#ok<AGROW>
    perOutput=[perOutput;table(repmat(repeat,cfg.num_outputs,1),(1:cfg.num_outputs)', ...
        string({prepared.dataset.output_dictionary.label})',[prepared.dataset.output_dictionary.point]', ...
        [prepared.dataset.output_dictionary.response]',[mt.R2]',[mt.nRMSE]',[mt.nMAE]', ...
        [mt.a10]',[mt.constant]','VariableNames',{'repeat','output_column','label','point', ...
        'response','R2','nRMSE','nMAE','a10','constant'})]; %#ok<AGROW>
    if repeat==1
        splitOne=struct('observed',observed,'prediction',prediction, ...
            'record_id',data.realization_id(test),'time_s',data.time_s(test), ...
            'test_ids',testIds,'selected_rank',selectedRank);
    end
    fprintf('Direct FMRVR %d/%d: rank %d, R2 %.4f, %d bases.\n', ...
        repeat,repeats,selectedRank,outer.mean_R2(end),numel(model.used));
end
summary=table(mean(outer.mean_R2),std(outer.mean_R2),min(outer.mean_R2),max(outer.mean_R2), ...
    mean(outer.median_R2),mean(outer.mean_nRMSE),mean(outer.mean_nMAE), ...
    mean(outer.outputs_R2_ge_07),mean(outer.outputs_R2_ge_08),mean(outer.outputs_R2_ge_09), ...
    'VariableNames',{'mean_R2','sd_R2','minimum_R2','maximum_R2','mean_median_R2', ...
    'mean_nRMSE','mean_nMAE','mean_outputs_R2_ge_07','mean_outputs_R2_ge_08','mean_outputs_R2_ge_09'});
writetable(outer,fullfile(resultsDir,'direct_fmrvr_nested_metrics.csv'));
writetable(perOutput,fullfile(resultsDir,'direct_fmrvr_nested_per_output.csv'));
writetable(summary,fullfile(resultsDir,'direct_fmrvr_nested_summary.csv'));
save(fullfile(resultsDir,'direct_fmrvr_split1.mat'),'-struct','splitOne','-v7.3');
report=struct('metrics',outer,'summary',summary,'per_output',perOutput); disp(summary);
end

function take=select_rows(realization,ids,sampleWithin)
take=false(size(realization));
for id=ids'
    rows=find(realization==id); take(rows(sampleWithin))=true;
end
end

function folds=record_folds(ids,failure,k,seed)
rng(seed,'twister'); folds=zeros(numel(ids),1);
for state=[false true]
    pos=find(failure(ids)==state); pos=pos(randperm(numel(pos)));
    folds(pos)=mod((0:numel(pos)-1)',k)+1;
end
end

function prediction=enforce_envelopes(prediction,recordId)
prediction=max(prediction,0);
for id=unique(recordId(:))'
    rows=find(recordId==id); prediction(rows,:)=cummax(prediction(rows,:),1);
end
end
