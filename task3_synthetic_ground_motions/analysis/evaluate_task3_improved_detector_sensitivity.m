function report = evaluate_task3_improved_detector_sensitivity()
%EVALUATE_TASK3_IMPROVED_DETECTOR_SENSITIVITY Apply the locked blend at 5/10/20x.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3'); X=prepared.dataset.X; dev=saved.developmentIds; test=saved.testIds;
rows=table; perOutput=table;
for multiplier=[5 10 20]
    [Y,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,multiplier);
    [prediction,ridgePrediction,forestPrediction]=fit_locked_blend(X,Y,dev,test,cfg);
    names=["Locked blend";"asinhX ridge";"Random forest"];
    preds={prediction;ridgePrediction;forestPrediction};
    for k=1:numel(names)
        mt=calculate_task3_metrics(Y(test,:),preds{k},cfg.preprocessing.constant_tolerance); use=~[mt.constant];
        rows=[rows;table(multiplier,names(k),mean([mt(use).R2]),median([mt(use).R2]), ...
            mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
            sum([mt(use).R2]>=0.7),sum([mt(use).R2]>=0.8), ...
            'VariableNames',{'threshold_multiplier','model','mean_R2','median_R2','mean_nRMSE', ...
            'mean_nMAE','mean_a10','outputs_R2_ge_07','outputs_R2_ge_08'})]; %#ok<AGROW>
        perOutput=[perOutput;table(repmat(multiplier,cfg.num_outputs,1),repmat(names(k),cfg.num_outputs,1), ...
            (1:cfg.num_outputs)',string({prepared.dataset.output_dictionary.label})',[mt.R2]',[mt.nRMSE]', ...
            [mt.nMAE]',[mt.a10]',[mt.constant]','VariableNames',{'threshold_multiplier','model', ...
            'output_column','label','R2','nRMSE','nMAE','a10','constant'})]; %#ok<AGROW>
    end
    fprintf('Locked improved blend evaluated at %gx (%d screened records).\n',multiplier,sum(audit.had_sentinel));
end
writetable(rows,fullfile(resultsDir,'improved_detector_model_sensitivity.csv'));
writetable(perOutput,fullfile(resultsDir,'improved_detector_model_sensitivity_per_output.csv'));
make_figure(rows,figuresDir); report.summary=rows;
end

function [blend,ridge,forest]=fit_locked_blend(X,Y,dev,test,cfg)
xScale=median(abs(X(dev,:)),1); xScale(xScale<=eps)=1;
Xd=asinh(bsxfun(@rdivide,X(dev,:),xScale)); Xt=asinh(bsxfun(@rdivide,X(test,:),xScale));
xs=fit_task3_standardizer(Xd,cfg.preprocessing.constant_tolerance);
ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
Xd=apply_task3_standardizer(Xd,xs); Xt=apply_task3_standardizer(Xt,xs);
Yd=apply_task3_standardizer(Y(dev,:),ys); modeled=~ys.constant;
A=[ones(size(Xd,1),1) Xd]; penalty=eye(size(A,2)); penalty(1,1)=0;
beta=(A'*A+penalty)\(A'*Yd); ridge=reverse_task3_standardizer([ones(size(Xt,1),1) Xt]*beta,ys);
rng(cfg.seed+1099,'twister'); z=zeros(numel(test),cfg.num_outputs);
for j=find(modeled)
    m=TreeBagger(150,Xd,Yd(:,j),'Method','regression','MinLeafSize',5, ...
        'NumPredictorsToSample',3,'OOBPrediction','off'); z(:,j)=predict(m,Xt);
end
forest=reverse_task3_standardizer(z,ys); blend=0.5*ridge+0.5*forest;
end

function make_figure(rows,outDir)
use=rows.model=="Locked blend"; f=figure('Visible','off','Color','w','Position',[100 100 760 470]);
plot(rows.threshold_multiplier(use),rows.mean_R2(use),'-o','LineWidth',2, ...
    'MarkerFaceColor',[0.10 0.35 0.62],'Color',[0.10 0.35 0.62]);
yline(0.7,'--','Target 0.70'); grid on; set(gca,'XTick',[5 10 20]);
xlabel('Runaway threshold multiplier'); ylabel('Mean held-out R^2');
title('Locked improved model under detector sensitivity'); set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'improved_detector_sensitivity.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(outDir,'improved_detector_sensitivity.png'),'-dpng','-r220'); close(f);
end
