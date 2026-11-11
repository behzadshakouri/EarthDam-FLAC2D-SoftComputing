function report = run_task3_detector_model_sensitivity()
%RUN_TASK3_DETECTOR_MODEL_SENSITIVITY Isolate failure-threshold effects.
% The fixed manuscript split and fixed model settings are used at 5x, 10x,
% and 20x. Thus any score change is caused by target screening alone.

analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3'); X=prepared.dataset.X;
dev=saved.developmentIds; test=saved.testIds;
methodNames=["FMRVR";"Linear ridge";"ELM";"Gaussian SVR";"Random forest"];
multipliers=[5 10 20]; rows=table; outputRows=table; targetRows=table;

for a=1:numel(multipliers)
    multiplier=multipliers(a);
    [Y,audit,screening]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,multiplier);
    xs=fit_task3_standardizer(X(dev,:),cfg.preprocessing.constant_tolerance);
    ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
    Xdev=apply_task3_standardizer(X(dev,:),xs); Xtest=apply_task3_standardizer(X(test,:),xs);
    Ydev=apply_task3_standardizer(Y(dev,:),ys); modeled=~ys.constant;
    predictions=cell(numel(methodNames),1);

    width=0.5*task3_median_distance(Xdev);
    model=train_task3_fmrvr(Xdev,Ydev(:,modeled),width,cfg);
    z=zeros(numel(test),cfg.num_outputs); z(:,modeled)=predict_task3_fmrvr(model,Xtest);
    predictions{1}=reverse_task3_standardizer(z,ys);
    predictions{2}=fit_ridge_fixed(X,Y,dev,test,cfg,1);
    predictions{3}=fit_elm_fixed(X,Y,dev,test,cfg,10,1,cfg.seed+1099);

    z=zeros(numel(test),cfg.num_outputs);
    for j=find(modeled)
        m=fitrsvm(Xdev,Ydev(:,j),'KernelFunction','gaussian','KernelScale','auto', ...
            'BoxConstraint',1,'Epsilon',0.1,'Standardize',false);
        z(:,j)=predict(m,Xtest);
    end
    predictions{4}=reverse_task3_standardizer(z,ys);
    rng(cfg.seed+71,'twister'); z=zeros(numel(test),cfg.num_outputs);
    for j=find(modeled)
        m=TreeBagger(100,Xdev,Ydev(:,j),'Method','regression','MinLeafSize',5,'OOBPrediction','off');
        z(:,j)=predict(m,Xtest);
    end
    predictions{5}=reverse_task3_standardizer(z,ys);

    for k=1:numel(methodNames)
        metrics=calculate_task3_metrics(Y(test,:),predictions{k},cfg.preprocessing.constant_tolerance);
        use=~[metrics.constant];
        rows=[rows;table(multiplier,methodNames(k),mean([metrics(use).R2]), ...
            median([metrics(use).R2]),mean([metrics(use).nRMSE]),mean([metrics(use).nMAE]), ...
            mean([metrics(use).a10]),'VariableNames',{'threshold_multiplier','method', ...
            'mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10'})]; %#ok<AGROW>
        outputRows=[outputRows;table(repmat(multiplier,cfg.num_outputs,1), ...
            repmat(methodNames(k),cfg.num_outputs,1),(1:cfg.num_outputs)', ...
            string({prepared.dataset.output_dictionary.label})',[metrics.R2]',[metrics.nRMSE]', ...
            [metrics.nMAE]',[metrics.a10]',[metrics.constant]', ...
            'VariableNames',{'threshold_multiplier','method','output_column','label', ...
            'R2','nRMSE','nMAE','a10','constant'})]; %#ok<AGROW>
    end
    targetRows=[targetRows;table(multiplier,sum(audit.had_sentinel),sum(isfinite(audit.screening_onset_s)), ...
        median(audit.first_sentinel_s-audit.screening_onset_s,'omitnan'), ...
        sum(audit.runaway_markers),sum(audit.filled_tail_samples),screening.multiplier, ...
        'VariableNames',{'threshold_multiplier','sentinel_records','screened_records', ...
        'median_lead_time_s','runaway_markers','filled_tail_samples','stored_multiplier'})]; %#ok<AGROW>
    fprintf('Detector/model sensitivity %gx complete.\n',multiplier);
end

writetable(rows,fullfile(resultsDir,'detector_model_sensitivity.csv'));
writetable(outputRows,fullfile(resultsDir,'detector_model_sensitivity_per_output.csv'));
writetable(targetRows,fullfile(resultsDir,'detector_screening_summary.csv'));
make_figure(rows,methodNames,multipliers,figuresDir);
report.metrics=rows; report.screening=targetRows;
end

function prediction=fit_ridge_fixed(X,Y,dev,test,cfg,lambda)
xs=fit_task3_standardizer(X(dev,:),cfg.preprocessing.constant_tolerance);
ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
A=[ones(numel(dev),1) apply_task3_standardizer(X(dev,:),xs)]; penalty=eye(size(A,2)); penalty(1,1)=0;
beta=(A'*A+lambda*penalty)\(A'*apply_task3_standardizer(Y(dev,:),ys));
prediction=reverse_task3_standardizer([ones(numel(test),1) apply_task3_standardizer(X(test,:),xs)]*beta,ys);
end

function prediction=fit_elm_fixed(X,Y,dev,test,cfg,hidden,lambda,seed)
xs=fit_task3_standardizer(X(dev,:),cfg.preprocessing.constant_tolerance);
ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
rng(seed,'twister'); W=randn(size(X,2),hidden); b=randn(1,hidden);
H=tanh(bsxfun(@plus,apply_task3_standardizer(X(dev,:),xs)*W,b)); A=[ones(size(H,1),1) H];
penalty=eye(size(A,2)); penalty(1,1)=0;
beta=(A'*A+lambda*penalty)\(A'*apply_task3_standardizer(Y(dev,:),ys));
Ht=tanh(bsxfun(@plus,apply_task3_standardizer(X(test,:),xs)*W,b));
prediction=reverse_task3_standardizer([ones(size(Ht,1),1) Ht]*beta,ys);
end

function make_figure(rows,names,multipliers,outDir)
f=figure('Visible','off','Color','w','Position',[100 100 900 500]); hold on;
colors=lines(numel(names));
for k=1:numel(names)
    use=rows.method==names(k); plot(rows.threshold_multiplier(use),rows.mean_R2(use),'-o', ...
        'LineWidth',1.6,'MarkerFaceColor',colors(k,:),'Color',colors(k,:),'DisplayName',names(k));
end
set(gca,'XTick',multipliers); xlabel('Runaway threshold multiplier'); ylabel('Mean held-out R^2');
title('Model sensitivity to failure-onset threshold'); grid on; legend('Location','best');
set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'detector_model_sensitivity.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(outDir,'detector_model_sensitivity.png'),'-dpng','-r220'); close(f);
end
