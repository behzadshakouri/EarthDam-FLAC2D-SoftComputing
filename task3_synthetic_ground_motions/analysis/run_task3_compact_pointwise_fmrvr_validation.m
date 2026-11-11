function report=run_task3_compact_pointwise_fmrvr_validation(repeats)
%RUN_TASK3_COMPACT_POINTWISE_FMRVR_VALIDATION Repeated nested validation.
% The pilot-frozen architecture uses all 33 inputs and a linear Bayesian
% basis. Only the response transform is selected in inner record folds.
if nargin<1,repeats=10;end
analysisDir=fileparts(mfilename('fullpath'));root=fileparts(analysisDir);addpath(root);setup_task3;
cfg=task3_config(root);prepared=load(fullfile(cfg.results_dir, ...
    'task3_prepared_dataset.mat'),'dataset','qc');raw=load(cfg.raw.task3_data_file,'Task3');
[~,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
data=build_task3_time_resolved_dataset(raw.Task3,prepared.dataset,audit,cfg,100);
failure=logical(audit.had_sentinel);failed=find(failure);stable=find(~failure);
transforms=["none" "log1p" "asinh"];outer=table;selections=table;perOutput=table;timing=table;
splitAssignments=table;splitOne=struct;
for repeat=1:repeats
    rng(cfg.seed+1500+repeat,'twister');a=failed(randperm(numel(failed)));b=stable(randperm(numel(stable)));
    development=sort([a(1:34);b(1:71)]);test=sort([a(35:end);b(72:end)]);
    partition=repmat("development",cfg.num_realizations,1);partition(test)="test";
    splitAssignments=[splitAssignments;table(repmat(repeat,cfg.num_realizations,1), ...
        (1:cfg.num_realizations)',partition,failure, ...
        'VariableNames',{'repeat','realization_id','partition','had_sentinel'})]; %#ok<AGROW>
    folds=stratified_folds(failure(development),3,cfg.seed+17100+repeat);
    models=cell(10,1);tst=ismember(data.realization_id,test);prediction=zeros(nnz(tst),70);
    trainingSeconds=0;
    for point=1:10
        cols=(point-1)*7+(1:7);scores=nan(numel(transforms),1);
        for q=1:numel(transforms)
            foldScores=nan(3,1);
            for fold=1:3
                tr=ismember(data.realization_id,development(folds~=fold));
                va=ismember(data.realization_id,development(folds==fold));
                options=make_options(transforms(q),400);
                model=fit_task3_compact_pointwise_fmrvr(data.X(tr,:),data.Y(tr,cols),options);
                pred=predict_task3_compact_pointwise_fmrvr(model,data.X(va,:));
                pred=enforce_envelopes(pred,data.realization_id(va));
                pm=calculate_metrics(data.Y(va,cols),pred,cols,prepared.dataset.output_dictionary);
                foldScores(fold)=mean(pm.nRMSE(~pm.constant));
            end
            scores(q)=mean(foldScores);
        end
        [innerScore,best]=min(scores);selectedTransform=transforms(best);
        dev=ismember(data.realization_id,development);options=make_options(selectedTransform,500);
        started=tic;models{point}=fit_task3_compact_pointwise_fmrvr(data.X(dev,:),data.Y(dev,cols),options);
        trainingSeconds=trainingSeconds+toc(started);
        pred=predict_task3_compact_pointwise_fmrvr(models{point},data.X(tst,:));
        pred=enforce_envelopes(pred,data.realization_id(tst));
        prediction(:,cols)=pred;
        selections=[selections;table(repeat,point,selectedTransform,innerScore,numel(models{point}.used), ...
            'VariableNames',{'repeat','point','target_transform','inner_nRMSE','relevance_bases'})]; %#ok<AGROW>
    end
    [predictionSeconds,prediction]=benchmark_prediction(models,data.X(tst,:),data.realization_id(tst),5,100);
    metrics=calculate_metrics(data.Y(tst,:),prediction,1:70,prepared.dataset.output_dictionary);
    metrics.repeat(:)=repeat;perOutput=[perOutput;metrics];usable=~metrics.constant; %#ok<AGROW>
    outer=[outer;table(repeat,mean(metrics.R2(usable)),median(metrics.R2(usable)), ...
        mean(metrics.nRMSE(usable)),mean(metrics.nMAE(usable)),mean(metrics.a10(usable),'omitnan'), ...
        sum(metrics.R2(usable)>=.7), ...
        sum(metrics.R2(usable)>=.8),sum(metrics.R2(usable)>=.9), ...
        'VariableNames',{'repeat','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10', ...
        'outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'})]; %#ok<AGROW>
    modelInfo=whos('models');timing=[timing;table(repeat,trainingSeconds,predictionSeconds, ...
        predictionSeconds/numel(test),modelInfo.bytes/1024^2,5,100,'VariableNames',{'repeat','training_s', ...
        'prediction_s','prediction_s_per_record','model_size_MB','warmup_runs','measured_runs'})]; %#ok<AGROW>
    if repeat==1
        splitOne=struct('models',{models},'observed',data.Y(tst,:), ...
            'prediction',prediction,'record_id',data.realization_id(tst),'time_s',data.time_s(tst), ...
            'feature_names',{data.feature_names},'development_records',development,'test_records',test);
    end
    fprintf('Compact point-wise FMRVR %d/%d: mean R2 %.4f, median %.4f.\n', ...
        repeat,repeats,outer.mean_R2(end),outer.median_R2(end));
end
summary=table(mean(outer.mean_R2),std(outer.mean_R2),min(outer.mean_R2),max(outer.mean_R2), ...
    mean(outer.median_R2),mean(outer.mean_nRMSE),mean(outer.mean_nMAE),mean(outer.mean_a10), ...
    mean(outer.outputs_R2_ge_07),mean(outer.outputs_R2_ge_08),mean(outer.outputs_R2_ge_09), ...
    'VariableNames',{'mean_R2','sd_R2','minimum_R2','maximum_R2','mean_median_R2', ...
    'mean_nRMSE','mean_nMAE','mean_a10','mean_outputs_R2_ge_07','mean_outputs_R2_ge_08','mean_outputs_R2_ge_09'});
pointSummary=groupsummary(perOutput(~perOutput.constant,:),"point","mean",["R2" "nRMSE" "nMAE" "a10"]);
responseSummary=groupsummary(perOutput(~perOutput.constant,:),"response","mean",["R2" "nRMSE" "nMAE" "a10"]);
out=fullfile(cfg.results_root,'compact_pointwise_fmrvr');if ~exist(out,'dir'),mkdir(out);end
writetable(outer,fullfile(out,'outer_metrics.csv'));writetable(selections,fullfile(out,'inner_selections.csv'));
writetable(perOutput,fullfile(out,'per_output.csv'));writetable(timing,fullfile(out,'timing.csv'));
writetable(splitAssignments,fullfile(out,'split_assignments.csv'));
writetable(summary,fullfile(out,'summary.csv'));writetable(pointSummary,fullfile(out,'point_summary.csv'));
writetable(responseSummary,fullfile(out,'response_summary.csv'));
save(fullfile(out,'split1.mat'),'splitOne','-v7.3');disp(summary);disp(pointSummary);disp(timing);
report=struct('summary',summary,'outer',outer,'selections',selections,'per_output',perOutput, ...
    'timing',timing,'split_assignments',splitAssignments);
end

function options=make_options(transform,iterations)
options=struct('basis',"linear",'target_transform',transform,'output_rank',7, ...
    'max_iterations',iterations,'tolerance',.05);
end
function fold=stratified_folds(label,k,seed)
rng(seed,'twister');fold=zeros(numel(label),1);
for value=[false true]
    ids=find(label==value);ids=ids(randperm(numel(ids)));
    for j=1:numel(ids)
        fold(ids(j))=mod(j-1,k)+1;
    end
end
end
function prediction=enforce_envelopes(prediction,recordId)
for id=unique(recordId(:))',rows=find(recordId==id);prediction(rows,:)=cummax(max(prediction(rows,:),0),1);end
end
function metrics=calculate_metrics(observed,predicted,cols,dictionary)
n=size(observed,2);R2=nan(n,1);nRMSE=R2;nMAE=R2;a10=R2;constant=false(n,1);
for j=1:n
    y=observed(:,j);p=predicted(:,j);span=max(y)-min(y);constant(j)=span<=max(1e-12,1e-10*max(abs(y)));
    R2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);nRMSE(j)=sqrt(mean((y-p).^2))/max(span,eps);nMAE(j)=mean(abs(y-p))/max(span,eps);
    nonzero=abs(y)>0;
    if any(nonzero)
        epsilon=max(1e-12,.01*median(abs(y(nonzero))));eligible=abs(y)>epsilon;
        if any(eligible)
            a10(j)=mean(abs(p(eligible)-y(eligible))./abs(y(eligible))<=.10);
        end
    end
end
metrics=table(cols(:),string({dictionary(cols).label})',[dictionary(cols).point]',[dictionary(cols).response]', ...
    R2,nRMSE,nMAE,a10,constant,'VariableNames',{'output_column','label','point','response','R2','nRMSE','nMAE','a10','constant'});
end
function [medianSeconds,prediction]=benchmark_prediction(models,X,recordId,warmups,repeats)
for k=1:warmups,predict_task3_compact_all70(models,X,recordId);end
times=zeros(repeats,1);prediction=[];
for k=1:repeats
    started=tic;prediction=predict_task3_compact_all70(models,X,recordId);times(k)=toc(started);
end
medianSeconds=median(times);
end
