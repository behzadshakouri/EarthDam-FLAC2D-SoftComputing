function report = run_task3_spectral_repeated_validation()
%RUN_TASK3_SPECTRAL_REPEATED_VALIDATION Ten-split check of the 5x spectral ridge.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3'); [X,~,groups]=build_task3_augmented_features(raw.Task3,cfg);X=X(:,groups.spectral);
[Y,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
screenedIds=find(audit.had_sentinel);stableIds=find(~audit.had_sentinel);rows=table;perOutput=table;
for repeat=1:10
    rng(cfg.seed+500+repeat,'twister');a=screenedIds(randperm(numel(screenedIds)));b=stableIds(randperm(numel(stableIds)));
    dev=sort([a(1:34);b(1:71)]);test=sort([a(35:end);b(72:end)]);
    model=fit_model(X(dev,:),Y(dev,:),cfg);prediction=predict_model(model,X(test,:));
    mt=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance);use=~[mt.constant];
    rows=[rows;table(repeat,mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]), ...
        mean([mt(use).nMAE]),mean([mt(use).a10]),sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8), ...
        'VariableNames',{'repeat','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','outputs_R2_ge_07','outputs_R2_ge_08'})]; %#ok<AGROW>
    perOutput=[perOutput;table(repmat(repeat,cfg.num_outputs,1),(1:cfg.num_outputs)', ...
        string({prepared.dataset.output_dictionary.label})',[mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.a10]',[mt.constant]', ...
        'VariableNames',{'repeat','output_column','label','R2','nRMSE','nMAE','a10','constant'})]; %#ok<AGROW>
end
summary=table(mean(rows.mean_R2),std(rows.mean_R2),min(rows.mean_R2),max(rows.mean_R2), ...
    median(rows.mean_R2),mean(rows.mean_nRMSE),mean(rows.mean_nMAE),mean(rows.mean_a10), ...
    'VariableNames',{'mean_R2','sd_R2','minimum_R2','maximum_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10'});
writetable(rows,fullfile(resultsDir,'spectral_repeated_split_metrics.csv'));
writetable(perOutput,fullfile(resultsDir,'spectral_repeated_split_per_output.csv'));
writetable(summary,fullfile(resultsDir,'spectral_repeated_split_summary.csv'));
f=figure('Visible','off','Color','w','Position',[100 100 760 450]);plot(rows.repeat,rows.mean_R2,'-o','LineWidth',1.8,'MarkerFaceColor',[0.10 0.35 0.62]);
yline(.7,'--','Target 0.70');grid on;xlabel('Stratified split');ylabel('Mean held-out R^2');title('Spectral ridge robustness at the 5x failure threshold');
set(gca,'XTick',1:10);set(f,'PaperPositionMode','auto');print(f,fullfile(figuresDir,'spectral_repeated_split.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'spectral_repeated_split.png'),'-dpng','-r220');close(f);report.summary=summary;report.metrics=rows;
fprintf('Spectral repeated validation: mean R2 %.4f, range %.4f--%.4f.\n',summary.mean_R2,summary.minimum_R2,summary.maximum_R2);
end
function model=fit_model(X,Y,cfg)
model.scale=median(abs(X),1);model.scale(model.scale<=eps)=1;X=asinh(bsxfun(@rdivide,X,model.scale));
model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs);Y=apply_task3_standardizer(Y,model.ys);A=[ones(size(X,1),1) X];P=eye(size(A,2));P(1,1)=0;
model.beta=(A'*A+10*P)\(A'*Y);
end
function Y=predict_model(model,X)
X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,model.scale)),model.xs);Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);
end
