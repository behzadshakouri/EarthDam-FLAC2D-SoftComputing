function report=run_task4_pointwise_fmrvr_validation(repeats)
%RUN_TASK4_POINTWISE_FMRVR_VALIDATION Repeated record-level validation.
% Hyperparameters are frozen from the development pilot. Each outer split is
% stratified by scale and keeps every time row from a record in one partition.
if nargin<1,repeats=10;end
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_task4;cfg=task4_config(root);
s=load(fullfile(cfg.results_dir,'scale_aware','task4_scale_aware_dataset.mat'),'dataset');d=s.dataset;
% Match the Task 2 production definition: 14 material variables, water
% level, running PGA, plus geometric scale for the four-scale extension.
requiredFeatures=["density_core" "density_shell" "density_filter" "density_drainage" ...
    "modulus_core" "modulus_shell" "modulus_drainage" "modulus_alluvium" ...
    "poisson_core" "cohesion_core" "friction_shell" "friction_filter" ...
    "friction_drainage" "friction_alluvium" "water_level_m" ...
    "running_PGA_g" "scale_factor"];
[found,featureColumns]=ismember(requiredFeatures,string(d.feature_names));
assert(all(found),'The scale-aware dataset is missing a required Task 2-aligned predictor.');
X=double(d.X(:,featureColumns));Y=double(d.Y);mask=logical(d.admissible);recordId=double(d.record_id);
scaleRows=double(d.scale_factor);recordScale=double(d.metadata.scale_factor);
options=struct('output_rank',7,'center_count',80,'width_factors',[.2 .4 .8 1.6], ...
    'max_iterations',500,'tolerance',.03,'seed',20260927, ...
    'target_transform',"log1p",'scale_normalize',false,'scale_column',17);
outer=table;perOutput=table;perScale=table;perScaleOutput=table;timing=table;
splitAssignments=table;splitOne=struct;
for repeat=1:repeats
    seed=20260927+repeat;[development,test]=scale_stratified_split(recordScale,seed);
    partition=repmat("development",numel(recordScale),1);partition(test)="test";
    splitAssignments=[splitAssignments;table(repmat(repeat,numel(recordScale),1), ...
        (1:numel(recordScale))',recordScale,partition, ...
        'VariableNames',{'repeat','record_id','scale_factor','partition'})]; %#ok<AGROW>
    isDev=ismember(recordId,development);isTest=ismember(recordId,test);
    models=cell(10,1);repeatMetrics=table;repeatPredictions=cell(10,1);
    repeatObservations=cell(10,1);repeatScales=cell(10,1);repeatRecordIds=cell(10,1);trainSeconds=0;
    for point=1:10
        cols=(point-1)*7+(1:7);safe=all(mask(:,cols),2);
        fitRows=isDev&safe;testRows=isTest&safe;options.seed=seed+100*point;
        started=tic;models{point}=fit_task4_pointwise_fmrvr(X(fitRows,:),Y(fitRows,cols),options);
        trainSeconds=trainSeconds+toc(started);
        predicted=predict_task4_fmrvr_peak(models{point},X(testRows,:));
        predicted=enforce_envelopes(predicted,recordId(testRows));
        observed=Y(testRows,cols);pm=calculate_metrics(observed,predicted,cols,d.output_dictionary);
        pm.repeat(:)=repeat;repeatMetrics=[repeatMetrics;pm]; %#ok<AGROW>
        repeatPredictions{point}=single(predicted);repeatObservations{point}=single(observed);
        repeatScales{point}=scaleRows(testRows);
        repeatRecordIds{point}=recordId(testRows);
        for scale=unique(recordScale(:))'
            atScale=scaleRows(testRows)==scale;
            sm=calculate_metrics(observed(atScale,:),predicted(atScale,:),cols,d.output_dictionary);
            sm.repeat(:)=repeat;sm.scale_factor(:)=scale;perScaleOutput=[perScaleOutput;sm]; %#ok<AGROW>
            usable=~sm.constant;
            perScale=[perScale;table(repeat,scale,point,sum(usable),mean(sm.R2(usable)), ...
                mean(sm.nRMSE(usable)),mean(sm.nMAE(usable)),mean(sm.a10(usable),'omitnan'), ...
                'VariableNames',{'repeat','scale_factor','point','outputs','mean_R2','mean_nRMSE','mean_nMAE','mean_a10'})]; %#ok<AGROW>
        end
        fprintf('Repeat %d/%d P%d: train=%d test=%d mean R2=%.4f.\n', ...
            repeat,repeats,point,nnz(fitRows),nnz(testRows),mean(pm.R2(~pm.constant)));
    end
    [predictSeconds,~]=benchmark_prediction(models,X(isTest,:),recordId(isTest),5,100);
    usable=~repeatMetrics.constant;
    outer=[outer;table(repeat,seed,mean(repeatMetrics.R2(usable)),median(repeatMetrics.R2(usable)), ...
        mean(repeatMetrics.nRMSE(usable)),mean(repeatMetrics.nMAE(usable)),mean(repeatMetrics.a10(usable),'omitnan'), ...
        sum(repeatMetrics.R2(usable)>=.7),sum(repeatMetrics.R2(usable)>=.8), ...
        sum(repeatMetrics.R2(usable)>=.9),'VariableNames',{'repeat','seed','mean_R2', ...
        'median_R2','mean_nRMSE','mean_nMAE','mean_a10','outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'})]; %#ok<AGROW>
    modelInfo=whos('models');timing=[timing;table(repeat,trainSeconds,predictSeconds, ...
        predictSeconds/numel(test),modelInfo.bytes/1024^2,5,100,'VariableNames',{'repeat','training_s', ...
        'prediction_s','prediction_s_per_record','model_size_MB','warmup_runs','measured_runs'})]; %#ok<AGROW>
    perOutput=[perOutput;repeatMetrics]; %#ok<AGROW>
    if repeat==1
        splitOne=struct('models',{models},'predictions',{repeatPredictions}, ...
            'observations',{repeatObservations},'scales',{repeatScales}, ...
            'record_ids',{repeatRecordIds},'feature_names',{requiredFeatures}, ...
            'development_records',development,'test_records',test);
    end
end
summary=table(mean(outer.mean_R2),std(outer.mean_R2),min(outer.mean_R2),max(outer.mean_R2), ...
    mean(outer.median_R2),mean(outer.mean_nRMSE),mean(outer.mean_nMAE),mean(outer.mean_a10), ...
    mean(outer.outputs_R2_ge_07),mean(outer.outputs_R2_ge_08),mean(outer.outputs_R2_ge_09), ...
    'VariableNames',{'mean_R2','sd_R2','minimum_R2','maximum_R2','mean_median_R2', ...
    'mean_nRMSE','mean_nMAE','mean_a10','mean_outputs_R2_ge_07','mean_outputs_R2_ge_08','mean_outputs_R2_ge_09'});
scaleSummary=table;
for scale=unique(perScaleOutput.scale_factor)'
    rows=perScaleOutput(perScaleOutput.scale_factor==scale & ~perScaleOutput.constant,:);
    scaleSummary=[scaleSummary;table(scale,height(rows),mean(rows.R2),median(rows.R2), ...
        prctile(rows.R2,10),prctile(rows.R2,25),mean(rows.nRMSE),mean(rows.nMAE),mean(rows.a10,'omitnan'),mean(rows.R2>=.7),mean(rows.R2>=.8), ...
        'VariableNames',{'scale_factor','output_evaluations','mean_R2','median_R2','p10_R2','p25_R2', ...
        'mean_nRMSE','mean_nMAE','mean_a10','fraction_R2_ge_07','fraction_R2_ge_08'})]; %#ok<AGROW>
end
pointSummary=groupsummary(perOutput(~perOutput.constant,:),"point","mean",["R2" "nRMSE" "nMAE" "a10"]);
responseSummary=groupsummary(perOutput(~perOutput.constant,:),"response","mean",["R2" "nRMSE" "nMAE" "a10"]);
out=fullfile(cfg.results_dir,'scale_aware','production');if ~exist(out,'dir'),mkdir(out);end
writetable(outer,fullfile(out,'pointwise_fmrvr_outer_metrics.csv'));
writetable(perOutput,fullfile(out,'pointwise_fmrvr_per_output.csv'));
writetable(perScale,fullfile(out,'pointwise_fmrvr_per_scale.csv'));
writetable(perScaleOutput,fullfile(out,'pointwise_fmrvr_per_scale_output.csv'));
writetable(timing,fullfile(out,'pointwise_fmrvr_timing.csv'));
writetable(splitAssignments,fullfile(out,'pointwise_fmrvr_split_assignments.csv'));
writetable(summary,fullfile(out,'pointwise_fmrvr_summary.csv'));
writetable(scaleSummary,fullfile(out,'pointwise_fmrvr_scale_summary.csv'));
writetable(pointSummary,fullfile(out,'pointwise_fmrvr_point_summary.csv'));
writetable(responseSummary,fullfile(out,'pointwise_fmrvr_response_summary.csv'));
save(fullfile(out,'pointwise_fmrvr_split1.mat'),'splitOne','-v7.3');
disp(summary);disp(scaleSummary);disp(timing);
report=struct('summary',summary,'outer',outer,'per_output',perOutput, ...
    'per_scale',perScale,'per_scale_output',perScaleOutput, ...
    'timing',timing,'scale_summary',scaleSummary,'split_assignments',splitAssignments);
end

function prediction=enforce_envelopes(prediction,recordId)
for id=unique(recordId(:))',rows=find(recordId==id);prediction(rows,:)=cummax(max(prediction(rows,:),0),1);end
end

function [development,test]=scale_stratified_split(scale,seed)
rng(seed,'twister');development=[];test=[];
for value=unique(scale(:))'
    ids=find(scale==value);ids=ids(randperm(numel(ids)));n=round(.2*numel(ids));
    test=[test;ids(1:n)];development=[development;ids(n+1:end)]; %#ok<AGROW>
end
development=sort(development);test=sort(test);
end

function metrics=calculate_metrics(observed,predicted,cols,dictionary)
n=size(observed,2);R2=nan(n,1);nRMSE=R2;nMAE=R2;a10=R2;constant=false(n,1);
for j=1:n
    y=observed(:,j);p=predicted(:,j);span=max(y)-min(y);
    constant(j)=span<=max(1e-12,1e-10*max(abs(y)));
    R2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);
    nRMSE(j)=sqrt(mean((y-p).^2))/max(span,eps);nMAE(j)=mean(abs(y-p))/max(span,eps);
    nonzero=abs(y)>0;
    if any(nonzero)
        epsilon=max(1e-12,.01*median(abs(y(nonzero))));eligible=abs(y)>epsilon;
        if any(eligible),a10(j)=mean(abs(p(eligible)-y(eligible))./abs(y(eligible))<=.10);end
    end
end
metrics=table(cols(:),string({dictionary(cols).label})',[dictionary(cols).point]', ...
    [dictionary(cols).response]',R2,nRMSE,nMAE,a10,constant,'VariableNames', ...
    {'output_column','label','point','response','R2','nRMSE','nMAE','a10','constant'});
end

function [medianSeconds,prediction]=benchmark_prediction(models,X,recordId,warmups,repeats)
for k=1:warmups,predict_task4_pointwise_fmrvr(models,X,recordId);end
times=zeros(repeats,1);prediction=[];
for k=1:repeats
    started=tic;prediction=predict_task4_pointwise_fmrvr(models,X,recordId);times(k)=toc(started);
end
medianSeconds=median(times);
end
