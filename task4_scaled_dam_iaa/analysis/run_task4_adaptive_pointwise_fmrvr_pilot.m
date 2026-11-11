function report=run_task4_adaptive_pointwise_fmrvr_pilot()
%RUN_TASK4_ADAPTIVE_POINTWISE_FMRVR_PILOT Conservative inner-fold selection.
% The ten-model architecture and RBF basis remain fixed. At each point, a
% development-only split selects the target transform and scale normalization.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_task4;
s=load(fullfile(task4_results_root(root),'scale_aware','task4_scale_aware_dataset.mat'),'dataset');d=s.dataset;
requiredFeatures=["density_core" "density_shell" "density_filter" "density_drainage" ...
    "modulus_core" "modulus_shell" "modulus_drainage" "modulus_alluvium" ...
    "poisson_core" "cohesion_core" "friction_shell" "friction_filter" ...
    "friction_drainage" "friction_alluvium" "water_level_m" ...
    "running_PGA_g" "scale_factor"];
[found,featureColumns]=ismember(requiredFeatures,string(d.feature_names));
assert(all(found),'The scale-aware dataset is missing a required Task 2-aligned predictor.');
X=double(d.X(:,featureColumns));Y=double(d.Y);mask=logical(d.admissible);recordId=double(d.record_id);
recordScale=double(d.metadata.scale_factor);
[development,test]=scale_stratified_split(recordScale,20260830,.2);
[innerTrain,innerValidation]=subset_scale_split(development,recordScale,20260927,.2);
transforms=["none" "log1p" "asinh"];normalizations=[false true];
candidate=table;selected=table;metrics=table;models=cell(10,1);
for point=1:10
    cols=(point-1)*7+(1:7);safe=all(mask(:,cols),2);bestScore=inf;best=struct;
    for normalize=normalizations
        for transform=transforms
            tr=ismember(recordId,innerTrain)&safe;va=ismember(recordId,innerValidation)&safe;
            options=make_options(transform,normalize,300,20260927+point);
            model=fit_task4_fmrvr_peak(X(tr,:),Y(tr,cols),options);
            pred=predict_task4_fmrvr_peak(model,X(va,:));pred=enforce_envelopes(pred,recordId(va));
            pm=calculate_metrics(Y(va,cols),pred,cols,d.output_dictionary);usable=~pm.constant;
            score=mean(pm.nRMSE(usable));candidate=[candidate;table(point,transform,normalize, ...
                mean(pm.R2(usable)),score,mean(pm.nMAE(usable)),numel(model.used), ...
                'VariableNames',{'point','target_transform','scale_normalize','mean_R2', ...
                'mean_nRMSE','mean_nMAE','relevance_bases'})]; %#ok<AGROW>
            if score<bestScore,bestScore=score;best=struct('transform',transform,'normalize',normalize);end
        end
    end
    tr=ismember(recordId,development)&safe;tst=ismember(recordId,test)&safe;
    options=make_options(best.transform,best.normalize,500,20260830+point);
    models{point}=fit_task4_fmrvr_peak(X(tr,:),Y(tr,cols),options);
    pred=predict_task4_fmrvr_peak(models{point},X(tst,:));pred=enforce_envelopes(pred,recordId(tst));
    pm=calculate_metrics(Y(tst,cols),pred,cols,d.output_dictionary);pm.point(:)=point;
    metrics=[metrics;pm];selected=[selected;table(point,best.transform,best.normalize,bestScore, ...
        mean(pm.R2(~pm.constant)),numel(models{point}.used), ...
        'VariableNames',{'point','target_transform','scale_normalize','inner_nRMSE','test_mean_R2','relevance_bases'})]; %#ok<AGROW>
    fprintf('Adaptive Task 4 P%d: %s scale=%d inner nRMSE %.4f test R2 %.4f.\n', ...
        point,best.transform,best.normalize,bestScore,mean(pm.R2(~pm.constant)));
end
usable=~metrics.constant;summary=table(mean(metrics.R2(usable)),median(metrics.R2(usable)), ...
    mean(metrics.nRMSE(usable)),mean(metrics.nMAE(usable)),sum(metrics.R2(usable)>=.7), ...
    sum(metrics.R2(usable)>=.8),sum(metrics.R2(usable)>=.9), ...
    'VariableNames',{'mean_R2','median_R2','mean_nRMSE','mean_nMAE','outputs_R2_ge_07', ...
    'outputs_R2_ge_08','outputs_R2_ge_09'});
out=fullfile(task4_results_root(root),'scale_aware','development','adaptive_pointwise');if ~exist(out,'dir'),mkdir(out);end
writetable(candidate,fullfile(out,'inner_candidates.csv'));writetable(selected,fullfile(out,'selections.csv'));
writetable(metrics,fullfile(out,'per_output.csv'));writetable(summary,fullfile(out,'summary.csv'));
save(fullfile(out,'pilot.mat'),'models','development','test','-v7.3');disp(summary);disp(selected);
report=struct('summary',summary,'metrics',metrics,'selected',selected,'candidates',candidate);
end

function options=make_options(transform,normalize,iterations,seed)
options=struct('output_rank',7,'center_count',80,'width_factors',[.2 .4 .8 1.6], ...
    'max_iterations',iterations,'tolerance',.03,'seed',seed, ...
    'target_transform',transform,'scale_normalize',normalize,'scale_column',17);
end
function [development,test]=scale_stratified_split(scale,seed,fraction)
rng(seed,'twister');development=[];test=[];for value=unique(scale(:))'
    ids=find(scale==value);ids=ids(randperm(numel(ids)));n=round(fraction*numel(ids));
    test=[test;ids(1:n)];development=[development;ids(n+1:end)]; %#ok<AGROW>
end
development=sort(development);test=sort(test);
end
function [training,validation]=subset_scale_split(ids,scale,seed,fraction)
rng(seed,'twister');training=[];validation=[];for value=unique(scale(ids))'
    group=ids(scale(ids)==value);group=group(randperm(numel(group)));n=round(fraction*numel(group));
    validation=[validation;group(1:n)];training=[training;group(n+1:end)]; %#ok<AGROW>
end
training=sort(training);validation=sort(validation);
end
function prediction=enforce_envelopes(prediction,recordId)
for id=unique(recordId(:))',rows=find(recordId==id);prediction(rows,:)=cummax(max(prediction(rows,:),0),1);end
end
function metrics=calculate_metrics(observed,predicted,cols,dictionary)
n=size(observed,2);R2=nan(n,1);nRMSE=R2;nMAE=R2;constant=false(n,1);for j=1:n
    y=observed(:,j);p=predicted(:,j);span=max(y)-min(y);constant(j)=span<=max(1e-12,1e-10*max(abs(y)));
    R2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);nRMSE(j)=sqrt(mean((y-p).^2))/max(span,eps);nMAE(j)=mean(abs(y-p))/max(span,eps);end
metrics=table(cols(:),string({dictionary(cols).label})',[dictionary(cols).point]',[dictionary(cols).response]', ...
    R2,nRMSE,nMAE,constant,'VariableNames',{'output_column','label','point','response','R2','nRMSE','nMAE','constant'});
end
