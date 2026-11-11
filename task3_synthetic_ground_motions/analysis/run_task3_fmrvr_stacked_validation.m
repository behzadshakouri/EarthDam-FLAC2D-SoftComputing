function report=run_task3_fmrvr_stacked_validation()
%RUN_TASK3_FMRVR_STACKED_VALIDATION Nested FMRVR/ridge error-complement audit.
% Every blend weight and ridge penalty is selected from outer-development
% out-of-fold predictions. Outer-test responses never influence selection.

analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
cfg.fmrvr.max_iterations=400; cfg.fmrvr.tolerance=.2;
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[X,~,groups]=build_task3_augmented_features(raw.Task3,cfg); X=X(:,groups.spectral);
[Y,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
failure=logical(audit.had_sentinel); failed=find(failure); stable=find(~failure);
spec.width_factors=[.5 1 2]; spec.linear_mix=.5; spec.target_transform="none"; spec.output_rank=5;
alphaGrid=0:.1:1; stackGrid=0:.1:1; lambdas=[.01 .1 1 10 100];
outer=table; selections=table; perOutput=table; dictionary=prepared.dataset.output_dictionary;

for repeat=1:10
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    dev=sort([a(1:34);b(1:71)]); test=sort([a(35:end);b(72:end)]);
    fold=stratified_folds(failure(dev),3,cfg.seed+2400+repeat);
    globalOof=nan(numel(dev),cfg.num_outputs); expertOof=globalOof;
    ridgeOof=cell(numel(lambdas),1); for q=1:numel(lambdas), ridgeOof{q}=globalOof; end
    for f=1:3
        tr=dev(fold~=f); va=dev(fold==f); rows=fold==f;
        gm=fit_task3_fmrvr_advanced(X(tr,:),Y(tr,:),spec,cfg);
        sm=fit_task3_fmrvr_advanced(X(tr(~failure(tr)),:),Y(tr(~failure(tr)),:),spec,cfg);
        um=fit_task3_fmrvr_advanced(X(tr(failure(tr)),:),Y(tr(failure(tr)),:),spec,cfg);
        globalOof(rows,:)=predict_task3_fmrvr_advanced(gm,X(va,:));
        ps=predict_task3_fmrvr_advanced(sm,X(va,:)); pu=predict_task3_fmrvr_advanced(um,X(va,:));
        [A,B]=classifier_features(X(tr,:),X(va,:),cfg);
        cl=fitclinear(A,double(failure(tr)),'Learner','logistic','Regularization','ridge','Lambda',.1);
        [~,score]=predict(cl,B); col=find(cl.ClassNames==1,1); p=min(max(score(:,col),0),1);
        expertOof(rows,:)=bsxfun(@times,1-p,ps)+bsxfun(@times,p,pu);
        for q=1:numel(lambdas)
            rm=fit_ridge(X(tr,:),Y(tr,:),lambdas(q),cfg);
            ridgeOof{q}(rows,:)=predict_ridge(rm,X(va,:));
        end
    end

    % First select one FMRVR global/expert blend and one ridge penalty.
    scoreAlpha=nan(numel(alphaGrid),1);
    for q=1:numel(alphaGrid)
        pred=alphaGrid(q)*globalOof+(1-alphaGrid(q))*expertOof;
        mt=calculate_task3_metrics(Y(dev,:),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
        scoreAlpha(q)=mean([mt(use).nRMSE]);
    end
    [~,q]=min(scoreAlpha); alpha=alphaGrid(q); fmrvrOof=alpha*globalOof+(1-alpha)*expertOof;
    scoreLambda=nan(numel(lambdas),1);
    for q=1:numel(lambdas)
        mt=calculate_task3_metrics(Y(dev,:),ridgeOof{q},cfg.preprocessing.constant_tolerance); use=~[mt.constant];
        scoreLambda(q)=mean([mt(use).nRMSE]);
    end
    [~,q]=min(scoreLambda); lambda=lambdas(q); selectedRidgeOof=ridgeOof{q};

    % Select a conservative family-wise FMRVR weight from development OOF.
    familyWeight=zeros(7,1);
    for response=1:7
        ids=response:7:cfg.num_outputs; bestScore=inf;
        for q=1:numel(stackGrid)
            w=stackGrid(q); pred=w*fmrvrOof(:,ids)+(1-w)*selectedRidgeOof(:,ids);
            mt=calculate_task3_metrics(Y(dev,ids),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
            score=mean([mt(use).nRMSE]);
            if score<bestScore, bestScore=score; familyWeight(response)=w; end
        end
        selections=[selections;table(repeat,response,string(dictionary(response).name), ...
            alpha,lambda,familyWeight(response),bestScore,'VariableNames',{'repeat','response', ...
            'response_name','global_fmrvr_weight','ridge_lambda','stack_fmrvr_weight','inner_nRMSE'})]; %#ok<AGROW>
    end

    gm=fit_task3_fmrvr_advanced(X(dev,:),Y(dev,:),spec,cfg);
    sm=fit_task3_fmrvr_advanced(X(dev(~failure(dev)),:),Y(dev(~failure(dev)),:),spec,cfg);
    um=fit_task3_fmrvr_advanced(X(dev(failure(dev)),:),Y(dev(failure(dev)),:),spec,cfg);
    pg=predict_task3_fmrvr_advanced(gm,X(test,:));
    ps=predict_task3_fmrvr_advanced(sm,X(test,:)); pu=predict_task3_fmrvr_advanced(um,X(test,:));
    [A,B]=classifier_features(X(dev,:),X(test,:),cfg);
    cl=fitclinear(A,double(failure(dev)),'Learner','logistic','Regularization','ridge','Lambda',.1);
    [~,score]=predict(cl,B); col=find(cl.ClassNames==1,1); p=min(max(score(:,col),0),1);
    pe=bsxfun(@times,1-p,ps)+bsxfun(@times,p,pu);
    fmrvrPrediction=alpha*pg+(1-alpha)*pe;
    ridgeModel=fit_ridge(X(dev,:),Y(dev,:),lambda,cfg); ridgePrediction=predict_ridge(ridgeModel,X(test,:));
    stackedPrediction=zeros(size(Y(test,:)));
    for response=1:7
        ids=response:7:cfg.num_outputs; w=familyWeight(response);
        stackedPrediction(:,ids)=w*fmrvrPrediction(:,ids)+(1-w)*ridgePrediction(:,ids);
    end
    fm=calculate_task3_metrics(Y(test,:),fmrvrPrediction,cfg.preprocessing.constant_tolerance);
    rm=calculate_task3_metrics(Y(test,:),ridgePrediction,cfg.preprocessing.constant_tolerance);
    smt=calculate_task3_metrics(Y(test,:),stackedPrediction,cfg.preprocessing.constant_tolerance);
    use=~[smt.constant];
    outer=[outer;table(repeat,mean([fm(use).R2]),mean([rm(use).R2]),mean([smt(use).R2]), ...
        median([smt(use).R2]),mean([smt(use).nRMSE]),mean([smt(use).nMAE]), ...
        sum([smt(use).R2]>=.7),sum([smt(use).R2]>=.8),sum([smt(use).R2]>=.9),alpha,lambda, ...
        'VariableNames',{'repeat','fmrvr_mean_R2','ridge_mean_R2','stacked_mean_R2', ...
        'stacked_median_R2','stacked_mean_nRMSE','stacked_mean_nMAE','outputs_R2_ge_07', ...
        'outputs_R2_ge_08','outputs_R2_ge_09','global_fmrvr_weight','ridge_lambda'})]; %#ok<AGROW>
    perOutput=[perOutput;table(repmat(repeat,cfg.num_outputs,1),(1:cfg.num_outputs)', ...
        string({dictionary.label})',[dictionary.response]',[fm.R2]',[rm.R2]',[smt.R2]',[smt.constant]', ...
        'VariableNames',{'repeat','output_column','label','response','fmrvr_R2','ridge_R2', ...
        'stacked_R2','constant'})]; %#ok<AGROW>
    fprintf('Stacked FMRVR %d/10: FMRVR %.4f, ridge %.4f, stack %.4f.\n', ...
        repeat,outer.fmrvr_mean_R2(end),outer.ridge_mean_R2(end),outer.stacked_mean_R2(end));
end

summary=table(mean(outer.fmrvr_mean_R2),mean(outer.ridge_mean_R2), ...
    mean(outer.stacked_mean_R2),std(outer.stacked_mean_R2),min(outer.stacked_mean_R2), ...
    max(outer.stacked_mean_R2),mean(outer.stacked_median_R2),mean(outer.stacked_mean_nRMSE), ...
    mean(outer.stacked_mean_nMAE),mean(outer.outputs_R2_ge_07),mean(outer.outputs_R2_ge_08), ...
    mean(outer.outputs_R2_ge_09),sum(outer.stacked_mean_R2>outer.fmrvr_mean_R2), ...
    'VariableNames',{'fmrvr_mean_R2','ridge_mean_R2','stacked_mean_R2','stacked_sd_R2', ...
    'stacked_minimum_R2','stacked_maximum_R2','stacked_median_R2','stacked_mean_nRMSE', ...
    'stacked_mean_nMAE','mean_outputs_R2_ge_07','mean_outputs_R2_ge_08', ...
    'mean_outputs_R2_ge_09','stacked_wins_over_fmrvr'});
family=table;
for response=1:7
    rows=perOutput(perOutput.response==response & ~perOutput.constant,:);
    family=[family;table(response,string(dictionary(response).name),mean(rows.fmrvr_R2), ...
        mean(rows.ridge_R2),mean(rows.stacked_R2),std(rows.stacked_R2), ...
        'VariableNames',{'response','response_name','fmrvr_mean_R2','ridge_mean_R2', ...
        'stacked_mean_R2','stacked_sd_R2'})]; %#ok<AGROW>
end
writetable(outer,fullfile(resultsDir,'fmrvr_stacked_nested_metrics.csv'));
writetable(selections,fullfile(resultsDir,'fmrvr_stacked_nested_selections.csv'));
writetable(perOutput,fullfile(resultsDir,'fmrvr_stacked_nested_per_output.csv'));
writetable(summary,fullfile(resultsDir,'fmrvr_stacked_nested_summary.csv'));
writetable(family,fullfile(resultsDir,'fmrvr_stacked_nested_family_summary.csv'));
report=struct('metrics',outer,'summary',summary,'selections',selections,'family',family);
disp(summary); disp(family);
end

function model=fit_ridge(X,Y,lambda,cfg)
model.scale=median(abs(X),1); model.scale(model.scale<=eps)=1;
X=asinh(bsxfun(@rdivide,X,model.scale));
model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs); Y=apply_task3_standardizer(Y,model.ys);
A=[ones(size(X,1),1) X]; P=eye(size(A,2)); P(1,1)=0; model.beta=(A'*A+lambda*P)\(A'*Y);
end

function Y=predict_ridge(model,X)
X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,model.scale)),model.xs);
Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);
end

function [A,B]=classifier_features(A,B,cfg)
scale=median(abs(A),1); scale(scale<=eps)=1;
A=asinh(bsxfun(@rdivide,A,scale)); B=asinh(bsxfun(@rdivide,B,scale));
xs=fit_task3_standardizer(A,cfg.preprocessing.constant_tolerance);
A=apply_task3_standardizer(A,xs); B=apply_task3_standardizer(B,xs);
end

function fold=stratified_folds(label,k,seed)
rng(seed,'twister'); fold=zeros(numel(label),1);
for value=[false true]
    ids=find(label==value); ids=ids(randperm(numel(ids)));
    for j=1:numel(ids), fold(ids(j))=mod(j-1,k)+1; end
end
end
