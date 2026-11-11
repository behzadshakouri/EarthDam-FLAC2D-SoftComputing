function report=run_task3_compact_pointwise_fmrvr_pilot()
%RUN_TASK3_COMPACT_POINTWISE_FMRVR_PILOT Inner-selected feasibility test.
analysisDir=fileparts(mfilename('fullpath'));root=fileparts(analysisDir);addpath(root);setup_task3;
cfg=task3_config(root);prepared=load(fullfile(task3_results_root(root),'final_production', ...
    'task3_prepared_dataset.mat'),'dataset','qc');raw=load(cfg.raw.task3_data_file,'Task3');
[~,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
data=build_task3_time_resolved_dataset(raw.Task3,prepared.dataset,audit,cfg,100);
failure=logical(audit.had_sentinel);failed=find(failure);stable=find(~failure);
rng(cfg.seed+1501,'twister');a=failed(randperm(numel(failed)));b=stable(randperm(numel(stable)));
development=sort([a(1:34);b(1:71)]);test=sort([a(35:end);b(72:end)]);
folds=stratified_folds(failure(development),3,cfg.seed+17100);
bases=["linear" "quadratic"];transforms=["none" "log1p" "asinh"];
featureSets={1:size(data.X,2),1:27};featureNames=["all33" "without_running_Sa"];
candidate=table;selected=table;models=cell(10,1);prediction=zeros(nnz(ismember(data.realization_id,test)),70);
for point=1:10
    cols=(point-1)*7+(1:7);bestScore=inf;best=struct;
    for fs=1:numel(featureSets)
        features=featureSets{fs};
        for basis=bases
            for transform=transforms
                scores=nan(3,1);
                for fold=1:3
                    trIds=development(folds~=fold);vaIds=development(folds==fold);
                    tr=ismember(data.realization_id,trIds);va=ismember(data.realization_id,vaIds);
                    options=struct('basis',basis,'target_transform',transform,'output_rank',7, ...
                        'max_iterations',400,'tolerance',.05);
                    model=fit_task3_compact_pointwise_fmrvr(data.X(tr,features),data.Y(tr,cols),options);
                    pred=predict_task3_compact_pointwise_fmrvr(model,data.X(va,features));
                    pred=enforce_envelopes(pred,data.realization_id(va));
                    pm=calculate_metrics(data.Y(va,cols),pred,cols,prepared.dataset.output_dictionary);
                    scores(fold)=mean(pm.nRMSE(~pm.constant));
                end
                score=mean(scores);candidate=[candidate;table(point,featureNames(fs),basis,transform,score, ...
                    'VariableNames',{'point','feature_set','basis','target_transform','inner_nRMSE'})]; %#ok<AGROW>
                if score<bestScore,bestScore=score;best=struct('features',features,'feature_set',featureNames(fs), ...
                        'basis',basis,'transform',transform);end
            end
        end
    end
    dev=ismember(data.realization_id,development);tst=ismember(data.realization_id,test);
    options=struct('basis',best.basis,'target_transform',best.transform,'output_rank',7, ...
        'max_iterations',500,'tolerance',.05);
    models{point}=fit_task3_compact_pointwise_fmrvr(data.X(dev,best.features),data.Y(dev,cols),options);
    pred=predict_task3_compact_pointwise_fmrvr(models{point},data.X(tst,best.features));
    pred=enforce_envelopes(pred,data.realization_id(tst));prediction(:,cols)=pred;
    pm=calculate_metrics(data.Y(tst,cols),pred,cols,prepared.dataset.output_dictionary);pm.point(:)=point;
    if point==1,metrics=pm;else,metrics=[metrics;pm];end %#ok<AGROW>
    selected=[selected;table(point,best.feature_set,best.basis,best.transform,bestScore, ...
        numel(models{point}.used),models{point}.candidate_basis_count, ...
        'VariableNames',{'point','feature_set','basis','target_transform','inner_nRMSE', ...
        'relevance_bases','candidate_bases'})]; %#ok<AGROW>
    fprintf('Compact FMRVR P%d: %s/%s/%s inner nRMSE %.4f, test R2 %.4f, bases %d/%d.\n', ...
        point,best.feature_set,best.basis,best.transform,bestScore,mean(pm.R2(~pm.constant)), ...
        numel(models{point}.used),models{point}.candidate_basis_count);
end
usable=~metrics.constant;summary=table(mean(metrics.R2(usable)),median(metrics.R2(usable)), ...
    mean(metrics.nRMSE(usable)),mean(metrics.nMAE(usable)),sum(metrics.R2(usable)>=.7), ...
    sum(metrics.R2(usable)>=.8),sum(metrics.R2(usable)>=.9), ...
    'VariableNames',{'mean_R2','median_R2','mean_nRMSE','mean_nMAE','outputs_R2_ge_07', ...
    'outputs_R2_ge_08','outputs_R2_ge_09'});
out=task3_analysis_results_root(root);if ~exist(out,'dir'),mkdir(out);end
writetable(candidate,fullfile(out,'compact_pointwise_fmrvr_inner_screen.csv'));
writetable(selected,fullfile(out,'compact_pointwise_fmrvr_selections.csv'));
writetable(metrics,fullfile(out,'compact_pointwise_fmrvr_per_output.csv'));
writetable(summary,fullfile(out,'compact_pointwise_fmrvr_summary.csv'));
save(fullfile(out,'compact_pointwise_fmrvr_pilot.mat'),'models','prediction','development','test','-v7.3');
disp(summary);disp(selected);report=struct('summary',summary,'metrics',metrics,'selections',selected);
end

function fold=stratified_folds(label,k,seed)
rng(seed,'twister');fold=zeros(numel(label),1);
for value=[false true],ids=find(label==value);ids=ids(randperm(numel(ids)));
    for j=1:numel(ids),fold(ids(j))=mod(j-1,k)+1;end
end
end
function prediction=enforce_envelopes(prediction,recordId)
for id=unique(recordId(:))',rows=find(recordId==id);prediction(rows,:)=cummax(max(prediction(rows,:),0),1);end
end
function metrics=calculate_metrics(observed,predicted,cols,dictionary)
n=size(observed,2);R2=nan(n,1);nRMSE=R2;nMAE=R2;constant=false(n,1);
for j=1:n,y=observed(:,j);p=predicted(:,j);span=max(y)-min(y);constant(j)=span<=max(1e-12,1e-10*max(abs(y)));
    R2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);nRMSE(j)=sqrt(mean((y-p).^2))/max(span,eps);nMAE(j)=mean(abs(y-p))/max(span,eps);end
metrics=table(cols(:),string({dictionary(cols).label})',[dictionary(cols).point]',[dictionary(cols).response]', ...
    R2,nRMSE,nMAE,constant,'VariableNames',{'output_column','label','point','response','R2','nRMSE','nMAE','constant'});
end
