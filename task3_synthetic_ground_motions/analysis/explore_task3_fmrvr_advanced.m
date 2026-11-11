function report=explore_task3_fmrvr_advanced()
%EXPLORE_TASK3_FMRVR_ADVANCED Development-only advanced FMRVR selection.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
cfg.fmrvr.max_iterations=400; cfg.fmrvr.tolerance=.2;
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3'); [X,~,groups]=build_task3_augmented_features(raw.Task3,cfg);
X=X(:,groups.spectral); Y=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
failure=any(prepared.qc.truncated,2); dev=saved.developmentIds(:); test=saved.testIds(:);
fold=stratified_folds(failure(dev),3,cfg.seed+2201);

specs=repmat(make_spec(.5,.5,"none"),0,1);
for transform=["none" "asinh" "log1p"]
    for mix=[.5 .75]
        specs(end+1)=make_spec(.5,mix,transform); %#ok<AGROW>
        specs(end+1)=make_spec([.25 .5 1],mix,transform); %#ok<AGROW>
        specs(end+1)=make_spec([.5 1 2],mix,transform); %#ok<AGROW>
    end
end

rows=table; predictions=cell(numel(specs),1);
for c=1:numel(specs)
    pred=nan(numel(dev),size(Y,2)); bases=zeros(3,1);
    for f=1:3
        tr=dev(fold~=f); va=dev(fold==f);
        model=fit_task3_fmrvr_advanced(X(tr,:),Y(tr,:),specs(c),cfg);
        pred(fold==f,:)=predict_task3_fmrvr_advanced(model,X(va,:));
        bases(f)=numel(model.used);
    end
    predictions{c}=pred; mt=calculate_task3_metrics(Y(dev,:),pred,cfg.preprocessing.constant_tolerance);
    use=~[mt.constant]; rows=[rows;table(c,string(specs(c).target_transform), ...
        string(mat2str(specs(c).width_factors)),specs(c).linear_mix, ...
        mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]), ...
        mean([mt(use).nMAE]),mean(bases),'VariableNames',{'candidate_id', ...
        'target_transform','width_factors','linear_mix','mean_R2','median_R2', ...
        'mean_nRMSE','mean_nMAE','mean_relevance_bases'})]; %#ok<AGROW>
    fprintf('Advanced FMRVR %d/%d: transform %s, widths %s, mix %.2f, OOF R2 %.4f.\n', ...
        c,numel(specs),specs(c).target_transform,mat2str(specs(c).width_factors), ...
        specs(c).linear_mix,rows.mean_R2(end));
end
[~,best]=min(rows.mean_nRMSE); selected=specs(best);
model=fit_task3_fmrvr_advanced(X(dev,:),Y(dev,:),selected,cfg);
prediction=predict_task3_fmrvr_advanced(model,X(test,:));
mt=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
summary=table(best,string(selected.target_transform),string(mat2str(selected.width_factors)), ...
    selected.linear_mix,mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]), ...
    mean([mt(use).nMAE]),mean([mt(use).a10]),numel(model.used), ...
    'VariableNames',{'candidate_id','target_transform','width_factors','linear_mix', ...
    'mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','relevance_basis_count'});
writetable(rows,fullfile(resultsDir,'fmrvr_advanced_development_cv.csv'));
writetable(summary,fullfile(resultsDir,'fmrvr_advanced_fixed_test_summary.csv'));
save(fullfile(resultsDir,'fmrvr_advanced_selected.mat'),'model','selected','rows','summary','fold','-v7.3');
f=figure('Visible','off','Color','w','Position',[100 100 900 460]);
bar(rows.mean_R2,'FaceColor',[.15 .42 .67]); hold on; bar(best,rows.mean_R2(best),'FaceColor',[.85 .33 .10]);
grid on; xlabel('Development candidate'); ylabel('Three-fold OOF mean R^2');
title('Advanced FMRVR development screening'); set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'fmrvr_advanced_development_cv.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'fmrvr_advanced_development_cv.png'),'-dpng','-r220'); close(f);
report=struct('development',rows,'summary',summary,'selected',selected);
fprintf('Selected advanced FMRVR: fixed-test R2 %.4f with %d bases.\n', ...
    summary.mean_R2,summary.relevance_basis_count);
end

function spec=make_spec(widths,mix,transform)
spec.width_factors=widths; spec.linear_mix=mix; spec.target_transform=string(transform); spec.output_rank=5;
end

function fold=stratified_folds(label,k,seed)
rng(seed,'twister'); fold=zeros(numel(label),1);
for value=[false true]
    ids=find(label==value); ids=ids(randperm(numel(ids)));
    for j=1:numel(ids), fold(ids(j))=mod(j-1,k)+1; end
end
end
