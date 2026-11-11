function report = evaluate_task3_spectral_detector_sensitivity()
%EVALUATE_TASK3_SPECTRAL_DETECTOR_SENSITIVITY Locked spectral models at 5/10/20x.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3'); [X,~,groups]=build_task3_augmented_features(raw.Task3,cfg);
X=X(:,groups.spectral); dev=saved.developmentIds; test=saved.testIds; rows=table; perOutput=table;
for multiplier=[5 10 20]
    Y=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,multiplier);
    [ridge,forest]=fit_models(X,Y,dev,test,cfg); blend=0.7*ridge+0.3*forest;
    names=["Spectral ridge";"Locked spectral blend"]; predictions={ridge;blend};
    for k=1:2
        mt=calculate_task3_metrics(Y(test,:),predictions{k},cfg.preprocessing.constant_tolerance);use=~[mt.constant];
        rows=[rows;table(multiplier,names(k),mean([mt(use).R2]),median([mt(use).R2]), ...
            mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
            sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8), ...
            'VariableNames',{'threshold_multiplier','model','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','outputs_R2_ge_07','outputs_R2_ge_08'})]; %#ok<AGROW>
        perOutput=[perOutput;table(repmat(multiplier,cfg.num_outputs,1),repmat(names(k),cfg.num_outputs,1), ...
            (1:cfg.num_outputs)',string({prepared.dataset.output_dictionary.label})',[mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.a10]',[mt.constant]', ...
            'VariableNames',{'threshold_multiplier','model','output_column','label','R2','nRMSE','nMAE','a10','constant'})]; %#ok<AGROW>
    end
    fprintf('Locked spectral models evaluated at %gx.\n',multiplier);
end
writetable(rows,fullfile(resultsDir,'spectral_detector_model_sensitivity.csv'));
writetable(perOutput,fullfile(resultsDir,'spectral_detector_model_sensitivity_per_output.csv'));
make_figure(rows,figuresDir);report.summary=rows;
end
function [ridge,forest]=fit_models(X,Y,dev,test,cfg)
scale=median(abs(X(dev,:)),1);scale(scale<=eps)=1;Xd=asinh(bsxfun(@rdivide,X(dev,:),scale));Xt=asinh(bsxfun(@rdivide,X(test,:),scale));
xs=fit_task3_standardizer(Xd,cfg.preprocessing.constant_tolerance);ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
Xd=apply_task3_standardizer(Xd,xs);Xt=apply_task3_standardizer(Xt,xs);Yd=apply_task3_standardizer(Y(dev,:),ys);modeled=~ys.constant;
A=[ones(size(Xd,1),1) Xd];penalty=eye(size(A,2));penalty(1,1)=0;beta=(A'*A+10*penalty)\(A'*Yd);
ridge=reverse_task3_standardizer([ones(size(Xt,1),1) Xt]*beta,ys);
rng(cfg.seed+1301,'twister');z=zeros(numel(test),cfg.num_outputs);
for j=find(modeled),m=TreeBagger(200,Xd,Yd(:,j),'Method','regression','MinLeafSize',5,'NumPredictorsToSample',5,'OOBPrediction','off');z(:,j)=predict(m,Xt);end
forest=reverse_task3_standardizer(z,ys);
end
function make_figure(rows,outDir)
f=figure('Visible','off','Color','w','Position',[100 100 780 470]);hold on;names=unique(rows.model,'stable');colors=lines(numel(names));
for k=1:numel(names),u=rows.model==names(k);plot(rows.threshold_multiplier(u),rows.mean_R2(u),'-o','LineWidth',1.8,'MarkerFaceColor',colors(k,:),'Color',colors(k,:),'DisplayName',names(k));end
yline(.7,'--','Target 0.70');grid on;set(gca,'XTick',[5 10 20]);xlabel('Runaway threshold multiplier');ylabel('Mean held-out R^2');
title('Spectral models under detector sensitivity');legend('Location','best');set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'spectral_detector_sensitivity.pdf'),'-dpdf','-painters','-bestfit');print(f,fullfile(outDir,'spectral_detector_sensitivity.png'),'-dpng','-r220');close(f);
end
