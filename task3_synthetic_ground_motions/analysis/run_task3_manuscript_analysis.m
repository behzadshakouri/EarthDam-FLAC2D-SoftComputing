function result = run_task3_manuscript_analysis()
%RUN_TASK3_MANUSCRIPT_ANALYSIS Derive paper results without changing source files.
analysisDir=fileparts(mfilename('fullpath'));

root=fileparts(analysisDir);
addpath(root);
setup_task3;
cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);
figuresDir=fullfile(task3_output_root(root),'figures');
if ~isfolder(resultsDir), mkdir(resultsDir); end
if ~isfolder(figuresDir), mkdir(figuresDir); end
cfg.results_dir=resultsDir;

prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'), ...
    'dataset','qc');
dataset=prepared.dataset; qc=prepared.qc;
screenedFile=fullfile(resultsDir,'task3_screened_targets.mat');
if isfile(screenedFile)
    screened=load(screenedFile,'Y','screeningAudit','screening');
    dataset.Y=screened.Y; screeningAudit=screened.screeningAudit; screening=screened.screening;
else
    raw=load(cfg.raw.task3_data_file,'Task3');
    [Y,screeningAudit,screening]=build_task3_screened_targets(raw.Task3,dataset,qc,cfg);
    save(screenedFile,'Y','screeningAudit','screening','-v7.3');
    dataset.Y=Y;
end
assert(all(isfinite(dataset.Y(:))) && max(abs(dataset.Y(:)))<cfg.qc.sentinel_abs_threshold);
writetable(screeningAudit,fullfile(resultsDir,'instability_screening_audit.csv'));
thresholdTable=table((1:cfg.num_outputs)',string({dataset.output_dictionary.label})', ...
    screening.reference_maximum',screening.runaway_threshold', ...
    'VariableNames',{'output_column','label','finite_reference_maximum','runaway_threshold'});
writetable(thresholdTable,fullfile(resultsDir,'runaway_thresholds.csv'));

% Preserve the fixed precommit realization-level 105/45 split.
split=create_task3_split(cfg);
developmentIds=split.development_ids; testIds=split.test_ids;
includedIds=(1:cfg.num_realizations)'; excludedIds=zeros(0,1);
assert(numel(developmentIds)==105 && numel(testIds)==45);

xScaler=fit_task3_standardizer(dataset.X(developmentIds,:),cfg.preprocessing.constant_tolerance);
yScaler=fit_task3_standardizer(dataset.Y(developmentIds,:),cfg.preprocessing.constant_tolerance);
Xdevelopment=apply_task3_standardizer(dataset.X(developmentIds,:),xScaler);
Xtest=apply_task3_standardizer(dataset.X(testIds,:),xScaler);
Ydevelopment=apply_task3_standardizer(dataset.Y(developmentIds,:),yScaler);
modeled=~yScaler.constant;

selection=select_task3_kernel_width(dataset.X(developmentIds,:), ...
    dataset.Y(developmentIds,:),cfg);
tic; model=train_task3_fmrvr(Xdevelopment,Ydevelopment(:,modeled), ...
    selection.selected_width,cfg); trainingSeconds=toc;
tic; modeledPrediction=predict_task3_fmrvr(model,Xtest); inferenceSeconds=toc;
predictionStd=zeros(numel(testIds),cfg.num_outputs);
predictionStd(:,modeled)=modeledPrediction;
prediction=reverse_task3_standardizer(predictionStd,yScaler);
observed=dataset.Y(testIds,:);
metrics=calculate_task3_metrics(observed,prediction,cfg.preprocessing.constant_tolerance);

export_task3_results(observed,prediction,testIds,metrics,dataset.output_dictionary, ...
    selection,model,trainingSeconds,inferenceSeconds,cfg);

dictionary=dataset.output_dictionary;
metricTable=readtable(fullfile(resultsDir,'task3_output_metrics.csv'));
nonconstant=~metricTable.constant;
summary=table(numel(includedIds),sum(screeningAudit.had_sentinel),numel(excludedIds),numel(developmentIds), ...
    numel(testIds),sum(modeled),model.output_rank,numel(model.used), ...
    selection.selected_width,trainingSeconds,inferenceSeconds, ...
    mean(metricTable.R2(nonconstant)),median(metricTable.R2(nonconstant)), ...
    mean(metricTable.nRMSE(nonconstant)),mean(metricTable.nMAE(nonconstant)), ...
    mean(metricTable.a10(nonconstant)), ...
    'VariableNames',{'admissible_realizations','screened_realizations','excluded_realizations', ...
    'development_realizations','test_realizations','modeled_outputs', ...
    'output_rank','relevance_basis_count','selected_kernel_width', ...
    'training_seconds','test_inference_seconds','mean_R2','median_R2', ...
    'mean_nRMSE','mean_nMAE','mean_a10'});
writetable(summary,fullfile(resultsDir,'manuscript_run_summary.csv'));

responseSummary=table;
for r=1:cfg.num_responses
    use=metricTable.response==r & nonconstant;
    responseSummary=[responseSummary; table(r,string(dictionary(r).name),sum(use), ...
        mean(metricTable.R2(use)),median(metricTable.R2(use)), ...
        mean(metricTable.nRMSE(use)),mean(metricTable.nMAE(use)), ...
        mean(metricTable.a10(use)), ...
        'VariableNames',{'response','response_name','outputs','mean_R2', ...
        'median_R2','mean_nRMSE','mean_nMAE','mean_a10'})]; %#ok<AGROW>
end
writetable(responseSummary,fullfile(resultsDir,'response_category_metrics.csv'));

partition=repmat("development",cfg.num_realizations,1);
partition(developmentIds)="development"; partition(testIds)="test";
writetable(table((1:cfg.num_realizations)',partition, ...
    'VariableNames',{'realization_id','partition'}), ...
    fullfile(resultsDir,'manuscript_realization_split.csv'));

featureStats=table(string(dataset.feature_names(:)), ...
    min(dataset.X,[],1)',median(dataset.X,1)',max(dataset.X,[],1)', ...
    'VariableNames',{'feature','minimum','median','maximum'});
writetable(featureStats,fullfile(resultsDir,'feature_summary.csv'));
save(fullfile(resultsDir,'task3_manuscript_model.mat'),'model','xScaler','yScaler', ...
    'selection','developmentIds','testIds','includedIds','excludedIds','modeled','cfg','-v7.3');

make_figures(metricTable,selection,observed,prediction,dataset.Y, ...
    modeled,dictionary,figuresDir);

result.summary=summary; result.metrics=metricTable; result.responseSummary=responseSummary;
result.developmentIds=developmentIds; result.testIds=testIds;
fprintf('Task 3 manuscript analysis complete: %d admissible, %d screened, %d/%d split.\n', ...
    numel(includedIds),sum(screeningAudit.had_sentinel),numel(developmentIds),numel(testIds));
fprintf('Mean test R2 %.6f; mean nRMSE %.6f; relevance bases %d.\n', ...
    summary.mean_R2,summary.mean_nRMSE,summary.relevance_basis_count);
end

function make_figures(metricTable,selection,observed,predicted,Ystable,modeled,dictionary,outDir)
colors=[0.10 0.35 0.62; 0.85 0.33 0.10; 0.20 0.60 0.35];

f=figure('Visible','off','Color','w','Position',[100 100 760 460]);
bar([150 150 48],'FaceColor',colors(1,:));
set(gca,'XTickLabel',{'Generated','Modeled','Screened'},'FontSize',11); ylabel('Realizations');
title('Database screening for model development'); grid on; ylim([0 165]);
text(1:3,[150 150 48]+5,string([150 150 48]),'HorizontalAlignment','center');
save_figure(f,fullfile(outDir,'database_screening')); close(f);

f=figure('Visible','off','Color','w','Position',[100 100 760 460]);
semilogx(selection.width_factors,selection.mean_scores,'-o','LineWidth',1.8, ...
    'MarkerFaceColor',colors(1,:),'Color',colors(1,:)); grid on;
xlabel('Kernel-width factor'); ylabel('Five-fold CV mean nRMSE');
title('Development-only kernel-width selection');
save_figure(f,fullfile(outDir,'kernel_selection')); close(f);

r2=reshape(metricTable.R2,[7 10])';
f=figure('Visible','off','Color','w','Position',[100 100 900 560]);
imagesc(r2,[-0.5 1]); axis tight; colorbar; colormap(parula(256));
xlabel('Response'); ylabel('Monitoring point'); title('Held-out R^2 by output');
set(gca,'XTick',1:7,'XTickLabel', ...
    {'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}','P_{pore}','\delta\gamma','\delta\nu_s'}, ...
    'TickLabelInterpreter','tex','YTick',1:10,'FontSize',10);
for i=1:10, for j=1:7
    if isfinite(r2(i,j)), text(j,i,sprintf('%.2f',r2(i,j)), ...
            'HorizontalAlignment','center','FontSize',7,'Color','k'); end
end, end
save_figure(f,fullfile(outDir,'r2_heatmap')); close(f);

f=figure('Visible','off','Color','w','Position',[100 100 900 480]); hold on;
for r=1:7
    ids=find(metricTable.response==r & ~metricTable.constant);
    x=r+linspace(-0.16,0.16,numel(ids));
    scatter(x,metricTable.R2(ids),34,colors(1,:),'filled','MarkerFaceAlpha',0.7);
    plot([r-0.23 r+0.23],[median(metricTable.R2(ids)) median(metricTable.R2(ids))], ...
        'Color',colors(2,:),'LineWidth',2.2);
end
yline(0,'k:'); grid on; xlim([0.5 7.5]); ylabel('Held-out R^2');
set(gca,'XTick',1:7,'XTickLabel', ...
    {'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}','P_{pore}','\delta\gamma','\delta\nu_s'}, ...
    'TickLabelInterpreter','tex','FontSize',10);
title('Output-level performance by response category');
save_figure(f,fullfile(outDir,'response_performance')); close(f);

valid=find(~metricTable.constant & isfinite(metricTable.R2));
[~,order]=sort(metricTable.R2(valid)); sorted=valid(order);
pick=unique(sorted(round(linspace(1,numel(sorted),6))),'stable');
f=figure('Visible','off','Color','w','Position',[100 100 1000 650]);
for k=1:numel(pick)
    j=pick(k); subplot(2,3,k); y=observed(:,j); p=predicted(:,j);
    scatter(y,p,22,colors(1,:),'filled','MarkerFaceAlpha',0.65); hold on;
    lo=min([y;p]); hi=max([y;p]); plot([lo hi],[lo hi],'k--','LineWidth',1.1);
    axis square; grid on; title(sprintf('%s, R^2=%.2f',dictionary(j).label,metricTable.R2(j)));
    xlabel('Observed'); ylabel('Predicted');
end
sgtitle('Representative held-out predictions');
save_figure(f,fullfile(outDir,'representative_scatter')); close(f);

C=corrcoef(Ystable(:,modeled));
f=figure('Visible','off','Color','w','Position',[100 100 720 620]);
imagesc(C,[-1 1]); axis square tight; colorbar; colormap(parula(256));
xlabel('Nonconstant output index'); ylabel('Nonconstant output index');
title('Correlation among admissible response targets');
save_figure(f,fullfile(outDir,'output_correlation')); close(f);
end

function save_figure(fig,pathBase)
set(fig,'PaperPositionMode','auto');
print(fig,[pathBase '.pdf'],'-dpdf','-painters','-bestfit');
print(fig,[pathBase '.png'],'-dpng','-r220');
end
