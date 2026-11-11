function report = run_task3_repeated_split_validation()
%RUN_TASK3_REPEATED_SPLIT_VALIDATION Test model rankings across 10 held-out splits.
% This is a manuscript-side robustness analysis. It reads the screened target
% matrix and never changes the raw Task 3 MAT files or production outputs.

analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset');
screened=load(fullfile(resultsDir,'task3_screened_targets.mat'),'Y','screeningAudit');
X=prepared.dataset.X; Y=screened.Y; audit=screened.screeningAudit;

methodNames=["FMRVR";"Linear ridge";"ELM";"Gaussian SVR";"Random forest"];
nRepeats=10; nMethods=numel(methodNames); splitRows=table; outputRows=table;
predictionRows=table; splitMembership=table;

screenedIds=find(logical(audit.had_sentinel)); stableIds=find(~logical(audit.had_sentinel));
assert(numel(screenedIds)==48 && numel(stableIds)==102);

for repeat=1:nRepeats
    rng(cfg.seed+500+repeat,'twister');
    % Preserve the screened/unscreened composition: 34+71 development cases.
    screenedOrder=screenedIds(randperm(numel(screenedIds)));
    stableOrder=stableIds(randperm(numel(stableIds)));
    dev=sort([screenedOrder(1:34);stableOrder(1:71)]);
    test=sort([screenedOrder(35:end);stableOrder(72:end)]);
    assert(numel(dev)==105 && numel(test)==45 && isempty(intersect(dev,test)));
    partition=repmat("test",cfg.num_realizations,1); partition(dev)="development";
    splitMembership=[splitMembership;table(repmat(repeat,cfg.num_realizations,1), ...
        (1:cfg.num_realizations)',partition,logical(audit.had_sentinel), ...
        'VariableNames',{'repeat','realization_id','partition','screened'})]; %#ok<AGROW>

    xs=fit_task3_standardizer(X(dev,:),cfg.preprocessing.constant_tolerance);
    ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
    Xdev=apply_task3_standardizer(X(dev,:),xs); Xtest=apply_task3_standardizer(X(test,:),xs);
    Ydev=apply_task3_standardizer(Y(dev,:),ys); modeled=~ys.constant;
    predictions=cell(nMethods,1); runtimes=zeros(nMethods,1);

    width=0.5*task3_median_distance(Xdev);
    tic; model=train_task3_fmrvr(Xdev,Ydev(:,modeled),width,cfg);
    z=zeros(numel(test),cfg.num_outputs); z(:,modeled)=predict_task3_fmrvr(model,Xtest);
    predictions{1}=reverse_task3_standardizer(z,ys); runtimes(1)=toc;

    tic; predictions{2}=fit_ridge_fixed(X,Y,dev,test,cfg,1); runtimes(2)=toc;
    tic; predictions{3}=fit_elm_fixed(X,Y,dev,test,cfg,10,1,cfg.seed+700+repeat); runtimes(3)=toc;

    tic; z=zeros(numel(test),cfg.num_outputs);
    for j=find(modeled)
        m=fitrsvm(Xdev,Ydev(:,j),'KernelFunction','gaussian','KernelScale','auto', ...
            'BoxConstraint',1,'Epsilon',0.1,'Standardize',false);
        z(:,j)=predict(m,Xtest);
    end
    predictions{4}=reverse_task3_standardizer(z,ys); runtimes(4)=toc;

    rng(cfg.seed+800+repeat,'twister'); tic; z=zeros(numel(test),cfg.num_outputs);
    for j=find(modeled)
        m=TreeBagger(100,Xdev,Ydev(:,j),'Method','regression','MinLeafSize',5,'OOBPrediction','off');
        z(:,j)=predict(m,Xtest);
    end
    predictions{5}=reverse_task3_standardizer(z,ys); runtimes(5)=toc;

    for k=1:nMethods
        metrics=calculate_task3_metrics(Y(test,:),predictions{k},cfg.preprocessing.constant_tolerance);
        use=~[metrics.constant];
        splitRows=[splitRows;table(repeat,methodNames(k),mean([metrics(use).R2]), ...
            median([metrics(use).R2]),mean([metrics(use).nRMSE]),mean([metrics(use).nMAE]), ...
            mean([metrics(use).a10]),runtimes(k), ...
            'VariableNames',{'repeat','method','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','training_seconds'})]; %#ok<AGROW>
        outputRows=[outputRows;table(repmat(repeat,cfg.num_outputs,1), ...
            repmat(methodNames(k),cfg.num_outputs,1),(1:cfg.num_outputs)', ...
            string({prepared.dataset.output_dictionary.label})',[metrics.R2]',[metrics.nRMSE]', ...
            [metrics.nMAE]',[metrics.a10]',[metrics.constant]', ...
            'VariableNames',{'repeat','method','output_column','label','R2','nRMSE','nMAE','a10','constant'})]; %#ok<AGROW>
        predictionRows=[predictionRows;table(repmat(repeat,numel(test),1), ...
            repmat(methodNames(k),numel(test),1),test(:), ...
            'VariableNames',{'repeat','method','realization_id'}) array2table(predictions{k}, ...
            'VariableNames',compose('Yhat_%02d',1:cfg.num_outputs))]; %#ok<AGROW>
    end
    fprintf('Repeated split %d/%d complete.\n',repeat,nRepeats);
end

summary=table;
for k=1:nMethods
    rows=splitRows.method==methodNames(k); r2=splitRows.mean_R2(rows); e=splitRows.mean_nRMSE(rows);
    summary=[summary;table(methodNames(k),mean(r2),std(r2),percentile(r2,2.5), ...
        percentile(r2,97.5),median(r2),mean(e),mean(splitRows.mean_nMAE(rows)), ...
        mean(splitRows.mean_a10(rows)),mean(splitRows.training_seconds(rows)), ...
        'VariableNames',{'method','mean_R2','sd_R2','p025_R2','p975_R2','median_R2', ...
        'mean_nRMSE','mean_nMAE','mean_a10','mean_training_seconds'})]; %#ok<AGROW>
end

fmrvr=splitRows.mean_R2(splitRows.method=="FMRVR"); paired=table;
for k=2:nMethods
    value=splitRows.mean_R2(splitRows.method==methodNames(k))-fmrvr;
    paired=[paired;table(methodNames(k),mean(value),median(value),min(value),max(value), ...
        sum(value>0),nRepeats,'VariableNames',{'comparator','mean_delta_R2','median_delta_R2', ...
        'minimum_delta_R2','maximum_delta_R2','wins_over_FMRVR','repeats'})]; %#ok<AGROW>
end

writetable(summary,fullfile(resultsDir,'repeated_split_model_summary.csv'));
writetable(splitRows,fullfile(resultsDir,'repeated_split_metrics.csv'));
writetable(outputRows,fullfile(resultsDir,'repeated_split_per_output.csv'));
writetable(paired,fullfile(resultsDir,'repeated_split_paired_comparison.csv'));
writetable(splitMembership,fullfile(resultsDir,'repeated_split_membership.csv'));
save(fullfile(resultsDir,'repeated_split_predictions.mat'),'predictionRows','-v7.3');
make_figure(splitRows,methodNames,figuresDir);
report.summary=summary; report.paired=paired; report.metrics=splitRows;
fprintf('Repeated validation complete: %d stratified 105/45 splits.\n',nRepeats);
end

function prediction=fit_ridge_fixed(X,Y,dev,test,cfg,lambda)
xs=fit_task3_standardizer(X(dev,:),cfg.preprocessing.constant_tolerance);
ys=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
A=[ones(numel(dev),1) apply_task3_standardizer(X(dev,:),xs)];
penalty=eye(size(A,2)); penalty(1,1)=0;
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

function value=percentile(x,p)
x=sort(x(isfinite(x))); q=1+(numel(x)-1)*p/100; lo=floor(q); hi=ceil(q);
if lo==hi, value=x(lo); else, value=x(lo)+(q-lo)*(x(hi)-x(lo)); end
end

function make_figure(rows,names,outDir)
values=nan(sum(rows.method==names(1)),numel(names));
for k=1:numel(names), values(:,k)=rows.mean_R2(rows.method==names(k)); end
f=figure('Visible','off','Color','w','Position',[100 100 900 500]);
boxplot(values,'Labels',cellstr(names)); hold on;
for k=1:numel(names), scatter(k+linspace(-0.08,0.08,size(values,1)),values(:,k),24,'filled','MarkerFaceAlpha',0.65); end
yline(0,'k:'); ylabel('Mean held-out R^2'); title('Model robustness across 10 stratified held-out splits');
grid on; xtickangle(18); set(gca,'FontSize',10); set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'repeated_split_model_comparison.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(outDir,'repeated_split_model_comparison.png'),'-dpng','-r220'); close(f);
end
