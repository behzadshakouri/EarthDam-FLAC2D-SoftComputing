function report=run_task3_reviewer_ablation(repeats)
%RUN_TASK3_REVIEWER_ABLATION Evidence requested during coauthor review.
% This analysis keeps the final ridge-free point-wise FMRVR formulation and
% the frozen outer partitions. It does not revive earlier ridge/residual
% models. It evaluates: (1) predictor groups, (2) matched multi-output versus
% independent single-output RVR, (3) physical post-processing, (4) terminal
% demand accuracy, and (5) motion ranking/critical-point preservation.
if nargin<1 || isempty(repeats), repeats=10; end

analysisDir=fileparts(mfilename('fullpath')); root=fileparts(analysisDir);
addpath(root); setup_task3; cfg=task3_config(root);
prepared=load(fullfile(cfg.results_dir,'task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[~,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
data=build_task3_time_resolved_dataset(raw.Task3,prepared.dataset,audit,cfg,100);
assert(size(data.X,2)==33,'Expected the final 33-predictor representation.');

referenceDir=fullfile(root,'reference_results');
assignments=readtable(fullfile(referenceDir,'compact_pointwise_fmrvr_split_assignments.csv'));
selections=readtable(fullfile(referenceDir,'compact_pointwise_fmrvr_inner_selections.csv'));
% Columns 18, 24, and 26 are duration, Arias, and CAV fractions normalized
% by their complete-record totals. They vary with time but are not causal.
% The 14-column prefix-only set excludes those three quantities.
predictorSets=struct('name',{'full_33','complete_record_16', ...
    'time_varying_17','prefix_only_14'}, ...
    'columns',{1:33,1:16,17:33,[17 19:23 25 27:33]});

predictorRows=table; methodRows=table; projectionRows=table;
terminalRows=table; rankingRows=table; correctionRows=table;
for repeat=1:repeats
    split=assignments(assignments.repeat==repeat,:);
    development=split.realization_id(split.partition=="development");
    test=split.realization_id(split.partition=="test");
    devMask=ismember(data.realization_id,development);
    testMask=ismember(data.realization_id,test);
    transformByPoint=strings(10,1);
    for point=1:10
        row=selections(selections.repeat==repeat & selections.point==point,:);
        transformByPoint(point)=string(row.target_transform(1));
    end

    % Predictor ablation: identical rows, partitions, transforms, and model
    % settings; only the predictor columns change.
    fullModels=[]; fullRaw=[]; fullBounded=[]; fullProjected=[];
    for setIndex=1:numel(predictorSets)
        cols=predictorSets(setIndex).columns;
        [models,rawPrediction,trainingSeconds,predictionSeconds,bases]= ...
            fit_multi(data.X(devMask,cols),data.Y(devMask,:), ...
            data.X(testMask,cols),transformByPoint);
        bounded=min(max(rawPrediction,0),target_max(models));
        projected=enforce_envelopes(bounded,data.realization_id(testMask));
        m=metrics(data.Y(testMask,:),projected,prepared.dataset.output_dictionary);
        use=~m.constant;
        predictorRows=[predictorRows;table(repeat,string(predictorSets(setIndex).name), ...
            numel(cols),mean(m.R2(use)),median(m.R2(use)),mean(m.nRMSE(use)), ...
            mean(m.nMAE(use)),trainingSeconds,predictionSeconds,bases, ...
            'VariableNames',{'repeat','predictor_set','predictors','mean_R2','median_R2', ...
            'mean_nRMSE','mean_nMAE','training_s','prediction_s','relevance_bases'})]; %#ok<AGROW>
        if setIndex==1
            fullModels=models; fullRaw=rawPrediction; fullBounded=bounded;
            fullProjected=projected; fullTraining=trainingSeconds; %#ok<NASGU>
            fullPredictionSeconds=predictionSeconds; fullBases=bases;
        end
    end

    % Projection ablation uses the same fitted full-predictor models.
    variants={fullRaw,fullBounded,fullProjected};
    variantNames=["unconstrained" "nonnegative_bounded" "monotonic_projected"];
    for k=1:3
        m=metrics(data.Y(testMask,:),variants{k},prepared.dataset.output_dictionary);
        use=~m.constant;
        projectionRows=[projectionRows;table(repeat,variantNames(k),mean(m.R2(use)), ...
            median(m.R2(use)),mean(m.nRMSE(use)),mean(m.nMAE(use)), ...
            'VariableNames',{'repeat','projection','mean_R2','median_R2','mean_nRMSE','mean_nMAE'})]; %#ok<AGROW>
    end
    [fractionPaths,fractionValues]=correction_fraction(fullRaw,fullBounded, ...
        data.realization_id(testMask));
    correctionRows=[correctionRows;table(repeat,fractionPaths,fractionValues, ...
        'VariableNames',{'repeat','fraction_paths_corrected','fraction_values_changed'})]; %#ok<AGROW>

    % Matched independent single-output RVR: same predictor rows, split,
    % target transform, compact linear basis, convergence tolerance, and
    % maximum iterations as the point-wise multi-output models.
    started=tic; singleModels=cell(70,1); singleBases=0;
    for point=1:10
        outputs=(point-1)*7+(1:7);
        for local=1:7
            options=make_options(transformByPoint(point),1);
            model=fit_task3_compact_pointwise_fmrvr(data.X(devMask,:), ...
                data.Y(devMask,outputs(local)),options);
            singleModels{outputs(local)}=model;
            singleBases=singleBases+numel(model.used);
        end
    end
    singleTraining=toc(started); started=tic;
    singlePrediction=zeros(nnz(testMask),70);
    for output=1:70
        singlePrediction(:,output)=predict_task3_compact_pointwise_fmrvr( ...
            singleModels{output},data.X(testMask,:));
    end
    singlePredictionSeconds=toc(started);
    singlePrediction=enforce_envelopes(singlePrediction,data.realization_id(testMask));
    multiMetrics=metrics(data.Y(testMask,:),fullProjected,prepared.dataset.output_dictionary);
    singleMetrics=metrics(data.Y(testMask,:),singlePrediction,prepared.dataset.output_dictionary);
    methodRows=[methodRows;method_row(repeat,"pointwise_multioutput_FMRVR",multiMetrics, ...
        fullTraining,fullPredictionSeconds,fullBases); ...
        method_row(repeat,"independent_singleoutput_RVR",singleMetrics, ...
        singleTraining,singlePredictionSeconds,singleBases)]; %#ok<AGROW>

    [terminal,ranking]=terminal_and_ranking(data.Y(testMask,:),fullProjected, ...
        data.realization_id(testMask),prepared.dataset.output_dictionary,repeat);
    terminalRows=[terminalRows;terminal]; rankingRows=[rankingRows;ranking]; %#ok<AGROW>
    recent=predictorRows(end-3:end,:);
    fprintf(['Reviewer ablation %d/%d: full %.4f, time-varying %.4f, ' ...
        'prefix-only %.4f, complete %.4f, single-output %.4f.\n'],repeat,repeats, ...
        recent.mean_R2(1),recent.mean_R2(3),recent.mean_R2(4), ...
        recent.mean_R2(2),methodRows.mean_R2(end));
end

out=fullfile(cfg.analysis_results_dir,'reviewer_ablation_20261107');
if ~exist(out,'dir'),mkdir(out);end
writetable(predictorRows,fullfile(out,'predictor_ablation_by_split.csv'));
writetable(methodRows,fullfile(out,'multi_vs_single_by_split.csv'));
writetable(projectionRows,fullfile(out,'projection_ablation_by_split.csv'));
writetable(correctionRows,fullfile(out,'projection_correction_fraction.csv'));
writetable(terminalRows,fullfile(out,'terminal_metrics_by_family_split.csv'));
writetable(rankingRows,fullfile(out,'ranking_critical_point_by_family_split.csv'));

predictorSummary=summarize(predictorRows,'predictor_set');
methodSummary=summarize(methodRows,'method');
projectionSummary=summarize(projectionRows,'projection');
terminalSummary=groupsummary(terminalRows,'response','mean', ...
    {'R2','nRMSE','nMAE'});
rankingSummary=groupsummary(rankingRows,'response','mean', ...
    {'motion_spearman','critical_point_accuracy'});
writetable(predictorSummary,fullfile(out,'predictor_ablation_summary.csv'));
writetable(methodSummary,fullfile(out,'multi_vs_single_summary.csv'));
writetable(projectionSummary,fullfile(out,'projection_ablation_summary.csv'));
writetable(terminalSummary,fullfile(out,'terminal_metrics_by_family_summary.csv'));
writetable(rankingSummary,fullfile(out,'ranking_critical_point_by_family_summary.csv'));

report=struct('predictor',predictorRows,'method',methodRows,'projection',projectionRows, ...
    'correction',correctionRows,'terminal',terminalRows,'ranking',rankingRows, ...
    'output_directory',out);
disp(predictorSummary); disp(methodSummary); disp(projectionSummary);
end

function options=make_options(transform,rank)
options=struct('basis',"linear",'target_transform',transform,'output_rank',rank, ...
    'max_iterations',500,'tolerance',.05);
end

function [models,rawPrediction,trainingSeconds,predictionSeconds,bases]= ...
    fit_multi(Xdev,Ydev,Xtest,transformByPoint)
models=cell(10,1); rawPrediction=zeros(size(Xtest,1),70); bases=0;
started=tic;
for point=1:10
    outputs=(point-1)*7+(1:7);
    models{point}=fit_task3_compact_pointwise_fmrvr(Xdev,Ydev(:,outputs), ...
        make_options(transformByPoint(point),7));
    bases=bases+numel(models{point}.used);
end
trainingSeconds=toc(started); started=tic;
for point=1:10
    outputs=(point-1)*7+(1:7);
    rawPrediction(:,outputs)=predict_unconstrained(models{point},Xtest);
end
predictionSeconds=toc(started);
end

function Y=predict_unconstrained(model,X)
X=asinh(double(X)./model.input_scale); X=(X-model.x_location)./model.x_scale;
Phi=[ones(size(X,1),1) X]./model.basis_scale;
latent=Phi(:,model.used)*model.Mu+model.latent_mean;
Ty=(latent*model.output_basis').*model.y_scale+model.y_location;
switch model.target_transform
    case "none",Y=Ty;
    case "log1p",Y=expm1(Ty).*model.target_scale;
    case "asinh",Y=sinh(Ty).*model.target_scale;
end
end

function maximum=target_max(models)
maximum=zeros(1,70);
for point=1:10,maximum((point-1)*7+(1:7))=models{point}.target_max;end
end

function prediction=enforce_envelopes(prediction,recordId)
for id=unique(recordId(:))'
    rows=find(recordId==id); prediction(rows,:)=cummax(max(prediction(rows,:),0),1);
end
end

function [fractionPaths,fractionValues]=correction_fraction(raw,bounded,recordId)
changedPaths=0; totalPaths=0; changedValues=0; totalValues=numel(raw);
for id=unique(recordId(:))'
    rows=find(recordId==id);
    for j=1:size(raw,2)
        r=raw(rows,j); b=bounded(rows,j); projected=cummax(b);
        changed=abs(projected-r)>1e-12*max(1,max(abs(r)));
        changedPaths=changedPaths+any(changed); totalPaths=totalPaths+1;
        changedValues=changedValues+sum(changed);
    end
end
fractionPaths=changedPaths/totalPaths; fractionValues=changedValues/totalValues;
end

function row=method_row(repeat,name,m,training,prediction,bases)
use=~m.constant;
row=table(repeat,name,mean(m.R2(use)),median(m.R2(use)),mean(m.nRMSE(use)), ...
    mean(m.nMAE(use)),training,prediction,bases, ...
    'VariableNames',{'repeat','method','mean_R2','median_R2','mean_nRMSE','mean_nMAE', ...
    'training_s','prediction_s','relevance_bases'});
end

function [terminalRows,rankingRows]=terminal_and_ranking(observed,predicted,recordId,dictionary,repeat)
ids=unique(recordId(:)); terminalObserved=zeros(numel(ids),70); terminalPredicted=terminalObserved;
for i=1:numel(ids)
    row=find(recordId==ids(i),1,'last'); terminalObserved(i,:)=observed(row,:);
    terminalPredicted(i,:)=predicted(row,:);
end
terminalRows=table; rankingRows=table;
for response=1:7
    outputs=response:7:70; span=max(terminalObserved(:,outputs),[],1)-min(terminalObserved(:,outputs),[],1);
    usable=span>max(1e-12,1e-10*max(abs(terminalObserved(:,outputs)),[],1));
    y=terminalObserved(:,outputs(usable)); p=terminalPredicted(:,outputs(usable));
    r2=1-sum((y-p).^2,1)./max(sum((y-mean(y,1)).^2,1),eps);
    nrmse=sqrt(mean((y-p).^2,1))./max(span(usable),eps);
    nmae=mean(abs(y-p),1)./max(span(usable),eps);
    terminalRows=[terminalRows;table(repeat,response,mean(r2),mean(nrmse),mean(nmae), ...
        'VariableNames',{'repeat','response','R2','nRMSE','nMAE'})]; %#ok<AGROW>
    rho=nan(1,numel(outputs));
    for k=1:numel(outputs)
        rho(k)=corr(terminalObserved(:,outputs(k)),terminalPredicted(:,outputs(k)), ...
            'Type','Spearman','Rows','complete');
    end
    [~,criticalObserved]=max(terminalObserved(:,outputs),[],2);
    [~,criticalPredicted]=max(terminalPredicted(:,outputs),[],2);
    rankingRows=[rankingRows;table(repeat,response,mean(rho,'omitnan'), ...
        mean(criticalObserved==criticalPredicted), ...
        'VariableNames',{'repeat','response','motion_spearman','critical_point_accuracy'})]; %#ok<AGROW>
end
end

function result=summarize(rows,groupName)
result=groupsummary(rows,groupName,'mean',intersect( ...
    {'mean_R2','median_R2','mean_nRMSE','mean_nMAE','training_s','prediction_s','relevance_bases'}, ...
    rows.Properties.VariableNames,'stable'));
end

function m=metrics(observed,predicted,dictionary)
n=size(observed,2); R2=nan(n,1); nRMSE=R2; nMAE=R2; constant=false(n,1);
for j=1:n
    y=observed(:,j); p=predicted(:,j); span=max(y)-min(y);
    constant(j)=span<=max(1e-12,1e-10*max(abs(y)));
    R2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);
    nRMSE(j)=sqrt(mean((y-p).^2))/max(span,eps);
    nMAE(j)=mean(abs(y-p))/max(span,eps);
end
m=table((1:n)',string({dictionary(1:n).label})',[dictionary(1:n).point]', ...
    [dictionary(1:n).response]',R2,nRMSE,nMAE,constant, ...
    'VariableNames',{'output_column','label','point','response','R2','nRMSE','nMAE','constant'});
end
