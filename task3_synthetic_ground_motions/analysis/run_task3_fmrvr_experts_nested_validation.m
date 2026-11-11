function report=run_task3_fmrvr_experts_nested_validation()
%RUN_TASK3_FMRVR_EXPERTS_NESTED_VALIDATION Repeated outer validation.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
cfg.fmrvr.max_iterations=400; cfg.fmrvr.tolerance=.2;
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3'); [X,featureNames,groups]=build_task3_augmented_features(raw.Task3,cfg);
X=X(:,groups.spectral); featureNames=featureNames(groups.spectral);
Y=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
failure=any(prepared.qc.truncated,2); failed=find(failure); stable=find(~failure);
spec.width_factors=[.5 1 2]; spec.linear_mix=.5; spec.target_transform="none"; spec.output_rank=5;
outer=table; selections=table; perOutput=table; outerPredictions=table; importance=table;
dictionary=prepared.dataset.output_dictionary;
for repeat=1:10
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    dev=sort([a(1:34);b(1:71)]); test=sort([a(35:end);b(72:end)]);
    fold=stratified_folds(failure(dev),3,cfg.seed+2400+repeat);
    globalOof=nan(numel(dev),size(Y,2)); expertOof=globalOof;
    for f=1:3
        tr=dev(fold~=f); va=dev(fold==f);
        gm=fit_task3_fmrvr_advanced(X(tr,:),Y(tr,:),spec,cfg);
        sm=fit_task3_fmrvr_advanced(X(tr(~failure(tr)),:),Y(tr(~failure(tr)),:),spec,cfg);
        um=fit_task3_fmrvr_advanced(X(tr(failure(tr)),:),Y(tr(failure(tr)),:),spec,cfg);
        globalOof(fold==f,:)=predict_task3_fmrvr_advanced(gm,X(va,:));
        ps=predict_task3_fmrvr_advanced(sm,X(va,:)); pu=predict_task3_fmrvr_advanced(um,X(va,:));
        [A,B]=classifier_features(X(tr,:),X(va,:),cfg);
        cl=fitclinear(A,double(failure(tr)),'Learner','logistic','Regularization','ridge','Lambda',.1);
        [~,score]=predict(cl,B); col=find(cl.ClassNames==1,1); p=min(max(score(:,col),0),1);
        expertOof(fold==f,:)=bsxfun(@times,1-p,ps)+bsxfun(@times,p,pu);
    end
    scores=nan(11,1);
    for j=0:10
        prediction=(j/10)*globalOof+(1-j/10)*expertOof;
        mt=calculate_task3_metrics(Y(dev,:),prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
        scores(j+1)=mean([mt(use).nRMSE]);
    end
    [innerScore,index]=min(scores); alpha=(index-1)/10;
    gm=fit_task3_fmrvr_advanced(X(dev,:),Y(dev,:),spec,cfg);
    sm=fit_task3_fmrvr_advanced(X(dev(~failure(dev)),:),Y(dev(~failure(dev)),:),spec,cfg);
    um=fit_task3_fmrvr_advanced(X(dev(failure(dev)),:),Y(dev(failure(dev)),:),spec,cfg);
    [A,B]=classifier_features(X(dev,:),X(test,:),cfg);
    cl=fitclinear(A,double(failure(dev)),'Learner','logistic','Regularization','ridge','Lambda',.1);
    [~,score]=predict(cl,B); col=find(cl.ClassNames==1,1); p=min(max(score(:,col),0),1);
    pg=predict_task3_fmrvr_advanced(gm,X(test,:));
    ps=predict_task3_fmrvr_advanced(sm,X(test,:)); pu=predict_task3_fmrvr_advanced(um,X(test,:));
    pe=bsxfun(@times,1-p,ps)+bsxfun(@times,p,pu); prediction=alpha*pg+(1-alpha)*pe;
    globalMetrics=calculate_task3_metrics(Y(test,:),pg,cfg.preprocessing.constant_tolerance);
    expertMetrics=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance);
    use=~[expertMetrics.constant];
    outer=[outer;table(repeat,mean([globalMetrics(use).R2]),mean([expertMetrics(use).R2]), ...
        median([expertMetrics(use).R2]),mean([expertMetrics(use).nRMSE]), ...
        mean([expertMetrics(use).nMAE]),mean([expertMetrics(use).a10]), ...
        mean((p>=.5)==failure(test)),alpha, ...
        'VariableNames',{'repeat','global_mean_R2','expert_mean_R2','expert_median_R2', ...
        'expert_mean_nRMSE','expert_mean_nMAE','expert_mean_a10','instability_accuracy','global_weight'})]; %#ok<AGROW>
    selections=[selections;table(repeat,alpha,innerScore,'VariableNames',{'repeat','global_weight','inner_nRMSE'})]; %#ok<AGROW>
    perOutput=[perOutput;table(repmat(repeat,cfg.num_outputs,1),(1:cfg.num_outputs)', ...
        string({dictionary.label})',[dictionary.point]',[dictionary.response]',string({dictionary.name})', ...
        [globalMetrics.R2]',[expertMetrics.R2]',[expertMetrics.R2]'-[globalMetrics.R2]', ...
        [expertMetrics.nRMSE]',[expertMetrics.nMAE]',[expertMetrics.a10]',[expertMetrics.constant]', ...
        'VariableNames',{'repeat','output_column','label','point','response','response_name', ...
        'global_R2','expert_R2','delta_R2','expert_nRMSE','expert_nMAE','expert_a10','constant'})]; %#ok<AGROW>

    % Retain every outer-test prediction for the all-70 diagnostic figure.
    [caseIndex,outputIndex]=ndgrid((1:numel(test))',(1:cfg.num_outputs)');
    observedLinear=Y(sub2ind(size(Y),test(caseIndex(:)),outputIndex(:)));
    predictedLinear=prediction(sub2ind(size(prediction),caseIndex(:),outputIndex(:)));
    outerPredictions=[outerPredictions;table( ...
        repmat(repeat,numel(caseIndex),1),test(caseIndex(:)),outputIndex(:), ...
        string({dictionary(outputIndex(:)).label})',observedLinear,predictedLinear, ...
        repmat(failure(test(caseIndex(:))),1,1), ...
        'VariableNames',{'repeat','realization_id','output_column','label', ...
        'observed','predicted','sentinel_bearing'})]; %#ok<AGROW>

    % Held-out permutation importance. The fitted models and blend remain
    % fixed; only one test predictor is shuffled at a time.
    baselineR2=mean([expertMetrics(use).R2]);
    for feature=1:numel(featureNames)
        rng(cfg.seed+6100+100*repeat+feature,'twister');
        Xpermuted=X(test,:); Xpermuted(:,feature)=Xpermuted(randperm(numel(test)),feature);
        [~,Bpermuted]=classifier_features(X(dev,:),Xpermuted,cfg);
        [~,scorePermuted]=predict(cl,Bpermuted);
        pPermuted=min(max(scorePermuted(:,col),0),1);
        pgPermuted=predict_task3_fmrvr_advanced(gm,Xpermuted);
        psPermuted=predict_task3_fmrvr_advanced(sm,Xpermuted);
        puPermuted=predict_task3_fmrvr_advanced(um,Xpermuted);
        pePermuted=bsxfun(@times,1-pPermuted,psPermuted)+ ...
            bsxfun(@times,pPermuted,puPermuted);
        predictionPermuted=alpha*pgPermuted+(1-alpha)*pePermuted;
        permutedMetrics=calculate_task3_metrics(Y(test,:),predictionPermuted, ...
            cfg.preprocessing.constant_tolerance);
        permutedR2=mean([permutedMetrics(use).R2]);
        importance=[importance;table(repeat,feature,string(featureNames{feature}), ...
            baselineR2,permutedR2,baselineR2-permutedR2, ...
            'VariableNames',{'repeat','feature_index','feature','baseline_mean_R2', ...
            'permuted_mean_R2','R2_decrease'})]; %#ok<AGROW>
    end
    fprintf('Nested FMRVR experts %d/10: global %.4f, experts %.4f, weight %.1f.\n', ...
        repeat,outer.global_mean_R2(end),outer.expert_mean_R2(end),alpha);
end
summary=table(mean(outer.global_mean_R2),std(outer.global_mean_R2), ...
    mean(outer.expert_mean_R2),std(outer.expert_mean_R2),min(outer.expert_mean_R2), ...
    max(outer.expert_mean_R2),median(outer.expert_mean_R2),mean(outer.expert_mean_nRMSE), ...
    mean(outer.expert_mean_nMAE),mean(outer.expert_mean_a10),mean(outer.instability_accuracy), ...
    mean(outer.expert_mean_R2-outer.global_mean_R2),sum(outer.expert_mean_R2>outer.global_mean_R2), ...
    'VariableNames',{'global_mean_R2','global_sd_R2','expert_mean_R2','expert_sd_R2', ...
    'expert_minimum_R2','expert_maximum_R2','expert_median_R2','expert_mean_nRMSE', ...
    'expert_mean_nMAE','expert_mean_a10','mean_instability_accuracy', ...
    'mean_expert_delta_R2','expert_wins'});
writetable(outer,fullfile(resultsDir,'fmrvr_experts_nested_metrics.csv'));
writetable(selections,fullfile(resultsDir,'fmrvr_experts_nested_selections.csv'));
writetable(summary,fullfile(resultsDir,'fmrvr_experts_nested_summary.csv'));
writetable(perOutput,fullfile(resultsDir,'fmrvr_experts_nested_per_output_by_split.csv'));
writetable(outerPredictions,fullfile(resultsDir,'fmrvr_experts_nested_predictions.csv'));
writetable(importance,fullfile(resultsDir,'fmrvr_experts_permutation_importance_by_split.csv'));
[outputSummary,familyBySplit,familySummary]=summarize_outputs(perOutput,dictionary);
writetable(outputSummary,fullfile(resultsDir,'fmrvr_experts_nested_per_output_summary.csv'));
writetable(familyBySplit,fullfile(resultsDir,'fmrvr_experts_nested_family_by_split.csv'));
writetable(familySummary,fullfile(resultsDir,'fmrvr_experts_nested_family_summary.csv'));
importanceSummary=summarize_importance(importance);
writetable(importanceSummary,fullfile(resultsDir,'fmrvr_experts_permutation_importance_summary.csv'));
f=figure('Visible','off','Color','w','Position',[100 100 800 460]);
plot(outer.repeat,outer.global_mean_R2,'-o','LineWidth',1.4); hold on;
plot(outer.repeat,outer.expert_mean_R2,'-s','LineWidth',1.4); yline(.7,':'); grid on;
xlabel('Outer split'); ylabel('Mean held-out R^2'); legend('Global multiscale FMRVR','FMRVR experts','Location','best');
title('Nested validation of multiscale FMRVR experts'); set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'fmrvr_experts_nested_validation.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'fmrvr_experts_nested_validation.png'),'-dpng','-r220'); close(f);
make_output_figure(outputSummary,figuresDir);
generate_task3_nested_diagnostics;
report=struct('metrics',outer,'selections',selections,'summary',summary, ...
    'per_output',outputSummary,'family',familySummary, ...
    'predictions',outerPredictions,'permutation_importance',importanceSummary);
fprintf('Nested FMRVR experts: global %.4f, experts %.4f, delta %.4f, wins %d/10.\n', ...
    summary.global_mean_R2,summary.expert_mean_R2,summary.mean_expert_delta_R2,summary.expert_wins);
end

function summary=summarize_importance(importance)
features=unique(importance.feature_index,'stable'); summary=table;
for feature=features'
    rows=importance(importance.feature_index==feature,:);
    summary=[summary;table(feature,rows.feature(1),mean(rows.R2_decrease), ...
        std(rows.R2_decrease),sum(rows.R2_decrease>0), ...
        'VariableNames',{'feature_index','feature','mean_R2_decrease', ...
        'sd_R2_decrease','positive_splits'})]; %#ok<AGROW>
end
summary=sortrows(summary,'mean_R2_decrease','descend');
end

function [outputSummary,familyBySplit,familySummary]=summarize_outputs(perOutput,dictionary)
outputSummary=table;
for j=1:numel(dictionary)
    rows=perOutput(perOutput.output_column==j & ~perOutput.constant,:);
    outputSummary=[outputSummary;table(j,string(dictionary(j).label),dictionary(j).point, ...
        dictionary(j).response,string(dictionary(j).name),height(rows),mean(rows.global_R2), ...
        mean(rows.expert_R2),std(rows.expert_R2),mean(rows.delta_R2), ...
        mean(rows.expert_nRMSE),mean(rows.expert_nMAE),mean(rows.expert_a10), ...
        'VariableNames',{'output_column','label','point','response','response_name','valid_splits', ...
        'global_mean_R2','expert_mean_R2','expert_sd_R2','mean_delta_R2', ...
        'expert_mean_nRMSE','expert_mean_nMAE','expert_mean_a10'})]; %#ok<AGROW>
end
familyBySplit=table;
for repeat=unique(perOutput.repeat)'
    for response=1:7
        rows=perOutput(perOutput.repeat==repeat & perOutput.response==response & ~perOutput.constant,:);
        familyBySplit=[familyBySplit;table(repeat,response,string(dictionary(response).name), ...
            height(rows),mean(rows.global_R2),mean(rows.expert_R2),mean(rows.delta_R2), ...
            mean(rows.expert_nRMSE),mean(rows.expert_nMAE),mean(rows.expert_a10), ...
            'VariableNames',{'repeat','response','response_name','nonconstant_outputs', ...
            'global_mean_R2','expert_mean_R2','mean_delta_R2','expert_mean_nRMSE', ...
            'expert_mean_nMAE','expert_mean_a10'})]; %#ok<AGROW>
    end
end
familySummary=table;
for response=1:7
    rows=familyBySplit(familyBySplit.response==response,:);
    familySummary=[familySummary;table(response,string(dictionary(response).name), ...
        mean(rows.nonconstant_outputs),mean(rows.global_mean_R2),mean(rows.expert_mean_R2), ...
        std(rows.expert_mean_R2),mean(rows.mean_delta_R2),mean(rows.expert_mean_nRMSE), ...
        mean(rows.expert_mean_nMAE),mean(rows.expert_mean_a10), ...
        'VariableNames',{'response','response_name','mean_nonconstant_outputs','global_mean_R2', ...
        'expert_mean_R2','expert_sd_R2','mean_delta_R2','expert_mean_nRMSE', ...
        'expert_mean_nMAE','expert_mean_a10'})]; %#ok<AGROW>
end
end

function make_output_figure(outputSummary,figuresDir)
r2=nan(7,10); delta=r2;
for i=1:height(outputSummary)
    r2(outputSummary.response(i),outputSummary.point(i))=outputSummary.expert_mean_R2(i);
    delta(outputSummary.response(i),outputSummary.point(i))=outputSummary.mean_delta_R2(i);
end

f=figure('Visible','off','Color','w','Position',[100 100 1050 650]);
subplot(2,1,1);h=imagesc(r2);set(h,'AlphaData',~isnan(r2));set(gca,'Color',[.86 .86 .86]);colorbar;caxis([0 1]);
set(gca,'XTick',1:10,'YTick',1:7,'YTickLabel', ...
    {'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}','P_{pore}','\delta\gamma','\delta\nu_s'}, ...
    'TickLabelInterpreter','tex');
xlabel('Monitoring point');ylabel('Response');title('Failure-aware FMRVR: mean held-out R^2');
subplot(2,1,2);h=imagesc(delta);set(h,'AlphaData',~isnan(delta));set(gca,'Color',[.86 .86 .86]);colorbar;lim=max(abs(delta(:)),[],'omitnan');if lim<=eps,lim=1;end;caxis([-lim lim]);
set(gca,'XTick',1:10,'YTick',1:7,'YTickLabel', ...
    {'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}','P_{pore}','\delta\gamma','\delta\nu_s'}, ...
    'TickLabelInterpreter','tex');
xlabel('Monitoring point');ylabel('Response');title('Mean R^2 gain over global multiscale FMRVR');
set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'fmrvr_experts_output_map.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'fmrvr_experts_output_map.png'),'-dpng','-r220');close(f);
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
