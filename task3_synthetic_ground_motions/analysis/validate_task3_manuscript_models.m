function report = validate_task3_manuscript_models()
%VALIDATE_TASK3_MANUSCRIPT_MODELS Benchmarks, replay, and sensitivity checks.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
screened=load(fullfile(resultsDir,'task3_screened_targets.mat'),'Y','screeningAudit','screening');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'));
dataset=prepared.dataset; dataset.Y=screened.Y;
dev=saved.developmentIds; test=saved.testIds; modeled=saved.modeled;
observed=dataset.Y(test,:);

% Exact saved-model prediction replay.
Xt=apply_task3_standardizer(dataset.X(test,:),saved.xScaler);
z=zeros(numel(test),cfg.num_outputs); z(:,modeled)=predict_task3_fmrvr(saved.model,Xt);
fmrvrPrediction=reverse_task3_standardizer(z,saved.yScaler);
exported=readtable(fullfile(resultsDir,'task3_test_predictions.csv'));
exportedMatrix=zeros(size(fmrvrPrediction));
for j=1:cfg.num_outputs, exportedMatrix(:,j)=exported{:,2*j+1}; end
replayError=max(abs(fmrvrPrediction(:)-exportedMatrix(:)));
assert(replayError<=1e-10*max(1,max(abs(exportedMatrix(:)))));

methodNames=["FMRVR";"Mean baseline";"Linear ridge";"ELM";"Gaussian SVR";"Random forest"];
predictions=cell(numel(methodNames),1); predictions{1}=fmrvrPrediction;
predictions{2}=repmat(mean(dataset.Y(dev,:),1),numel(test),1);

[predictions{3},ridgeInfo]=fit_ridge(dataset.X,dataset.Y,dev,test,cfg);
[predictions{4},elmInfo]=fit_elm(dataset.X,dataset.Y,dev,test,cfg);

Xdev=apply_task3_standardizer(dataset.X(dev,:),saved.xScaler);
Ydev=apply_task3_standardizer(dataset.Y(dev,:),saved.yScaler);
svrStd=zeros(numel(test),cfg.num_outputs); forestStd=zeros(numel(test),cfg.num_outputs);
tic;
for j=find(modeled)
    svr=fitrsvm(Xdev,Ydev(:,j),'KernelFunction','gaussian','KernelScale','auto', ...
        'BoxConstraint',1,'Epsilon',0.1,'Standardize',false);
    svrStd(:,j)=predict(svr,Xt);
end
svrSeconds=toc; predictions{5}=reverse_task3_standardizer(svrStd,saved.yScaler);

rng(cfg.seed+71,'twister'); tic;
for j=find(modeled)
    forest=TreeBagger(100,Xdev,Ydev(:,j),'Method','regression', ...
        'MinLeafSize',5,'OOBPrediction','off');
    forestStd(:,j)=predict(forest,Xt);
end
forestSeconds=toc; predictions{6}=reverse_task3_standardizer(forestStd,saved.yScaler);

benchmark=table;
perOutput=table;
for k=1:numel(methodNames)
    metrics=calculate_task3_metrics(observed,predictions{k},cfg.preprocessing.constant_tolerance);
    use=~[metrics.constant];
    row=table(methodNames(k),mean([metrics(use).R2]),median([metrics(use).R2]), ...
        mean([metrics(use).nRMSE]),mean([metrics(use).nMAE]),mean([metrics(use).a10]), ...
        'VariableNames',{'method','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10'});
    benchmark=[benchmark;row]; %#ok<AGROW>
    perOutput=[perOutput;table(repmat(methodNames(k),cfg.num_outputs,1), ...
        string({dataset.output_dictionary.label})',[metrics.R2]',[metrics.nRMSE]', ...
        [metrics.nMAE]',[metrics.a10]',[metrics.constant]', ...
        'VariableNames',{'method','label','R2','nRMSE','nMAE','a10','constant'})]; %#ok<AGROW>
end
writetable(benchmark,fullfile(resultsDir,'model_benchmark_summary.csv'));
writetable(perOutput,fullfile(resultsDir,'model_benchmark_per_output.csv'));

% Negative control: destroy the input-target pairing before FMRVR fitting.
rng(cfg.seed+99,'twister'); perm=randperm(numel(dev));
permutedModel=train_task3_fmrvr(apply_task3_standardizer(dataset.X(dev,:),saved.xScaler), ...
    Ydev(perm,modeled),saved.selection.selected_width,cfg);
permStd=zeros(numel(test),cfg.num_outputs);
permStd(:,modeled)=predict_task3_fmrvr(permutedModel,Xt);
permPrediction=reverse_task3_standardizer(permStd,saved.yScaler);
permMetrics=calculate_task3_metrics(observed,permPrediction,cfg.preprocessing.constant_tolerance);
permUse=~[permMetrics.constant];
negativeControl=table(mean([permMetrics(permUse).R2]),mean([permMetrics(permUse).nRMSE]), ...
    'VariableNames',{'mean_R2','mean_nRMSE'});
writetable(negativeControl,fullfile(resultsDir,'permutation_negative_control.csv'));

% Screening sensitivity around the final adopted 5x finite-reference rule.
raw=load(cfg.raw.task3_data_file,'Task3'); sensitivity=table;
[Ybase,auditBase]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
for multiplier=[10 20]
    [Yalt,auditAlt]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,multiplier);
    scale=max(abs(Ybase),1e-12); relative=abs(Yalt-Ybase)./scale;
    finiteRows=isfinite(auditAlt.screening_onset_s) & isfinite(auditBase.screening_onset_s);
    onsetDifference=abs(auditAlt.screening_onset_s(finiteRows)-auditBase.screening_onset_s(finiteRows));
    sensitivity=[sensitivity;table(multiplier,median(relative(:)), ...
        percentile(relative(:),95),max(relative(:)),median(onsetDifference),max(onsetDifference), ...
        'VariableNames',{'threshold_multiplier','median_relative_target_change', ...
        'p95_relative_target_change','maximum_relative_target_change', ...
        'median_onset_change_s','maximum_onset_change_s'})]; %#ok<AGROW>
end
writetable(sensitivity,fullfile(resultsDir,'screening_sensitivity.csv'));

runtime=table(replayError,ridgeInfo.selected_lambda,elmInfo.hidden_units,elmInfo.lambda, ...
    svrSeconds,forestSeconds,saved.model.iterations,saved.model.output_rank, ...
    'VariableNames',{'prediction_replay_max_abs_error','ridge_lambda','elm_hidden_units', ...
    'elm_lambda','svr_training_seconds','forest_training_seconds','fmrvr_iterations','output_rank'});
writetable(runtime,fullfile(resultsDir,'validation_runtime_and_settings.csv'));
make_validation_figures(benchmark,sensitivity,figuresDir);

report.benchmark=benchmark; report.negativeControl=negativeControl;
report.sensitivity=sensitivity; report.runtime=runtime;
fprintf('Task 3 validation complete. FMRVR mean R2 %.4f; best comparator %.4f; permuted %.4f.\n', ...
    benchmark.mean_R2(1),max(benchmark.mean_R2(2:end)),negativeControl.mean_R2);
end

function [prediction,info]=fit_ridge(X,Y,dev,test,cfg)
lambdas=[0 1e-4 1e-2 1 100]; scores=zeros(size(lambdas));
fold=make_folds(numel(dev),5,cfg.seed+31);
for a=1:numel(lambdas)
    foldScore=zeros(5,1);
    for f=1:5
        trainIds=dev(fold~=f); validIds=dev(fold==f);
        xs=fit_task3_standardizer(X(trainIds,:),cfg.preprocessing.constant_tolerance);
        ys=fit_task3_standardizer(Y(trainIds,:),cfg.preprocessing.constant_tolerance);
        A=[ones(numel(trainIds),1) apply_task3_standardizer(X(trainIds,:),xs)];
        B=apply_task3_standardizer(Y(trainIds,:),ys);
        penalty=eye(size(A,2)); penalty(1,1)=0;
        beta=(A'*A+lambdas(a)*penalty)\(A'*B);
        pv=[ones(numel(validIds),1) apply_task3_standardizer(X(validIds,:),xs)]*beta;
        pred=reverse_task3_standardizer(pv,ys);
        mt=calculate_task3_metrics(Y(validIds,:),pred,cfg.preprocessing.constant_tolerance);
        use=~[mt.constant]; foldScore(f)=mean([mt(use).nRMSE]);
    end
    scores(a)=mean(foldScore);
end
[~,best]=min(scores); info.selected_lambda=lambdas(best); info.cv_scores=scores;
xs=fit_task3_standardizer(X(dev,:),cfg.preprocessing.constant_tolerance);
ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
A=[ones(numel(dev),1) apply_task3_standardizer(X(dev,:),xs)];
penalty=eye(size(A,2)); penalty(1,1)=0;
beta=(A'*A+info.selected_lambda*penalty)\(A'*apply_task3_standardizer(Y(dev,:),ys));
prediction=reverse_task3_standardizer([ones(numel(test),1) apply_task3_standardizer(X(test,:),xs)]*beta,ys);
end

function [prediction,info]=fit_elm(X,Y,dev,test,cfg)
hidden=[10 25 50 100]; lambdas=[1e-4 1e-2 1]; scores=inf(numel(hidden),numel(lambdas));
fold=make_folds(numel(dev),5,cfg.seed+41);
for h=1:numel(hidden)
    for a=1:numel(lambdas)
        fs=zeros(5,1);
        for f=1:5
            trainIds=dev(fold~=f); validIds=dev(fold==f);
            xs=fit_task3_standardizer(X(trainIds,:),cfg.preprocessing.constant_tolerance);
            ys=fit_task3_standardizer(Y(trainIds,:),cfg.preprocessing.constant_tolerance);
            rng(cfg.seed+1000*h+f,'twister');
            W=randn(size(X,2),hidden(h)); b=randn(1,hidden(h));
            H=tanh(bsxfun(@plus,apply_task3_standardizer(X(trainIds,:),xs)*W,b)); A=[ones(size(H,1),1) H];
            penalty=eye(size(A,2)); penalty(1,1)=0;
            beta=(A'*A+lambdas(a)*penalty)\(A'*apply_task3_standardizer(Y(trainIds,:),ys));
            Hv=tanh(bsxfun(@plus,apply_task3_standardizer(X(validIds,:),xs)*W,b));
            pred=reverse_task3_standardizer([ones(size(Hv,1),1) Hv]*beta,ys);
            mt=calculate_task3_metrics(Y(validIds,:),pred,cfg.preprocessing.constant_tolerance);
            use=~[mt.constant]; fs(f)=mean([mt(use).nRMSE]);
        end
        scores(h,a)=mean(fs);
    end
end
[~,linear]=min(scores(:)); [hi,ai]=ind2sub(size(scores),linear);
info.hidden_units=hidden(hi); info.lambda=lambdas(ai); info.cv_scores=scores;
xs=fit_task3_standardizer(X(dev,:),cfg.preprocessing.constant_tolerance);
ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
rng(cfg.seed+1000*hi+99,'twister'); W=randn(size(X,2),hidden(hi)); b=randn(1,hidden(hi));
H=tanh(bsxfun(@plus,apply_task3_standardizer(X(dev,:),xs)*W,b)); A=[ones(size(H,1),1) H];
penalty=eye(size(A,2)); penalty(1,1)=0;
beta=(A'*A+info.lambda*penalty)\(A'*apply_task3_standardizer(Y(dev,:),ys));
Ht=tanh(bsxfun(@plus,apply_task3_standardizer(X(test,:),xs)*W,b));
prediction=reverse_task3_standardizer([ones(size(Ht,1),1) Ht]*beta,ys);
end

function fold=make_folds(n,k,seed)
rng(seed,'twister'); order=randperm(n); fold=zeros(n,1);
for i=1:n, fold(order(i))=mod(i-1,k)+1; end
end

function value=percentile(x,p)
x=sort(x(isfinite(x))); q=1+(numel(x)-1)*p/100; lo=floor(q); hi=ceil(q);
if lo==hi, value=x(lo); else, value=x(lo)+(q-lo)*(x(hi)-x(lo)); end
end

function make_validation_figures(benchmark,~,outDir)
f=figure('Visible','off','Color','w','Position',[100 100 900 480]);
bar(categorical(benchmark.method,benchmark.method),benchmark.mean_R2,'FaceColor',[0.10 0.35 0.62]);
yline(0,'k:'); ylabel('Mean held-out R^2'); title('Model comparison on the fixed test set'); grid on;
set(gca,'FontSize',10); xtickangle(20); save_figure(f,fullfile(outDir,'model_comparison')); close(f);
generate_task3_screening_sensitivity_figure(outDir);
end

function save_figure(fig,pathBase)
set(fig,'PaperPositionMode','auto');
exportgraphics(fig,[pathBase '.pdf'],'ContentType','vector');
exportgraphics(fig,[pathBase '.png'],'Resolution',300);
end
