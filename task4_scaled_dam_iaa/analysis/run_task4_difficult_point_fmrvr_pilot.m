function report=run_task4_difficult_point_fmrvr_pilot()
%RUN_TASK4_DIFFICULT_POINT_FMRVR_PILOT Development-only option study.
% The outer test records are never evaluated. This study checks whether a
% response transform or physically motivated scale normalization improves the
% three consistently difficult response-extraction points.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_task4;cfg=task4_config(root);
s=load(fullfile(cfg.results_dir,'scale_aware','task4_scale_aware_dataset.mat'),'dataset');d=s.dataset;
required=["density_core" "density_shell" "density_filter" "density_drainage" ...
    "modulus_core" "modulus_shell" "modulus_drainage" "modulus_alluvium" ...
    "poisson_core" "cohesion_core" "friction_shell" "friction_filter" ...
    "friction_drainage" "friction_alluvium" "water_level_m" "running_PGA_g" "scale_factor"];
[found,colsX]=ismember(required,string(d.feature_names));assert(all(found));
X=double(d.X(:,colsX));Y=double(d.Y);mask=logical(d.admissible);recordId=double(d.record_id);recordScale=double(d.metadata.scale_factor);
[development,~]=scale_stratified_split(recordScale,20260928);fold=scale_stratified_folds(recordScale(development),2,20261016);
transforms=["log1p" "asinh" "none" "log1p" "asinh" "log1p" "asinh"];
scaleNormalize=[false false false true true false true];centerCounts=[80 80 80 80 80 120 120];points=[3 7 10];scores=table;
for point=points
    outputs=(point-1)*7+(1:7);safe=all(mask(:,outputs),2);
    for candidate=1:numel(transforms)
        for k=1:2
            trainRecords=development(fold~=k);validationRecords=development(fold==k);
            trainRows=ismember(recordId,trainRecords)&safe;validationRows=ismember(recordId,validationRecords)&safe;
            options=struct('output_rank',7,'center_count',centerCounts(candidate),'width_factors',[.2 .4 .8 1.6], ...
                'max_iterations',500,'tolerance',.03,'seed',20261016+1000*point+100*candidate+k, ...
                'target_transform',transforms(candidate),'scale_normalize',scaleNormalize(candidate),'scale_column',17);
            model=fit_task4_pointwise_fmrvr(X(trainRows,:),Y(trainRows,outputs),options);
            prediction=predict_task4_fmrvr_peak(model,X(validationRows,:));
            prediction=enforce_envelopes(prediction,recordId(validationRows));
            [r2,nrmse]=metrics(Y(validationRows,outputs),prediction);
            scores=[scores;table(point,candidate,k,transforms(candidate),scaleNormalize(candidate),centerCounts(candidate),mean(r2),mean(nrmse), ...
                'VariableNames',{'point','candidate','fold','transform','scale_normalize','center_count','mean_R2','mean_nRMSE'})]; %#ok<AGROW>
        end
    end
end
summary=groupsummary(scores,{'point','candidate','transform','scale_normalize','center_count'},'mean',{'mean_R2','mean_nRMSE'});
summary.selected=false(height(summary),1);
for point=points
    rows=find(summary.point==point);[~,best]=min(summary.mean_mean_nRMSE(rows));summary.selected(rows(best))=true;
end
out=fullfile(cfg.results_dir,'scale_aware','development');if ~exist(out,'dir'),mkdir(out);end
writetable(scores,fullfile(out,'difficult_point_fmrvr_option_folds.csv'));
writetable(summary,fullfile(out,'difficult_point_fmrvr_option_summary.csv'));
disp(summary(summary.selected,:));report=struct('fold_scores',scores,'summary',summary);
end

function [development,test]=scale_stratified_split(scale,seed)
rng(seed,'twister');development=[];test=[];
for value=unique(scale(:))',ids=find(scale==value);ids=ids(randperm(numel(ids)));n=round(.2*numel(ids));test=[test;ids(1:n)];development=[development;ids(n+1:end)];end %#ok<AGROW>
development=sort(development);test=sort(test);
end
function fold=scale_stratified_folds(scale,k,seed)
rng(seed,'twister');fold=zeros(numel(scale),1);for value=unique(scale(:))',ids=find(scale==value);ids=ids(randperm(numel(ids)));fold(ids)=mod(0:numel(ids)-1,k)+1;end
end
function prediction=enforce_envelopes(prediction,recordId)
for id=unique(recordId(:))',rows=find(recordId==id);prediction(rows,:)=cummax(max(prediction(rows,:),0),1);end
end
function [r2,nrmse]=metrics(observed,predicted)
r2=nan(1,size(observed,2));nrmse=r2;for j=1:size(observed,2),y=observed(:,j);p=predicted(:,j);span=max(y)-min(y);r2(j)=1-sum((y-p).^2)/max(sum((y-mean(y)).^2),eps);nrmse(j)=sqrt(mean((y-p).^2))/max(span,eps);end
end
