function report = explore_task3_improved_models()
%EXPLORE_TASK3_IMPROVED_MODELS Development-only search for stronger surrogates.
% Candidate selection uses OOF predictions from the fixed 105-case
% development partition. Only the single selected candidate is then fit on
% all development cases and evaluated on the untouched 45-case test set.

analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset');
screened=load(fullfile(resultsDir,'task3_screened_targets.mat'),'Y');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
X=prepared.dataset.X; Y=screened.Y; dev=saved.developmentIds; test=saved.testIds;

fold=make_folds(numel(dev),5,cfg.seed+901); candidates=make_candidates();
cvRows=table; allOof=cell(height(candidates),1);
for c=1:height(candidates)
    oof=nan(numel(dev),cfg.num_outputs);
    for f=1:5
        trLocal=find(fold~=f); vaLocal=find(fold==f);
        tr=dev(trLocal); va=dev(vaLocal);
        model=fit_candidate(X(tr,:),Y(tr,:),candidates(c,:),cfg);
        oof(vaLocal,:)=predict_candidate(model,X(va,:));
    end
    assert(all(isfinite(oof(:)))); allOof{c}=oof;
    mt=calculate_task3_metrics(Y(dev,:),oof,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    cvRows=[cvRows;table(c,string(candidates.family(c)),candidates.param1(c),candidates.param2(c), ...
        mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]), ...
        mean([mt(use).nMAE]),mean([mt(use).a10]), ...
        'VariableNames',{'candidate_id','family','param1','param2','oof_mean_R2', ...
        'oof_median_R2','oof_mean_nRMSE','oof_mean_nMAE','oof_mean_a10'})]; %#ok<AGROW>
    fprintf('Improved-model candidate %d/%d: %s, OOF mean R2 %.4f.\n', ...
        c,height(candidates),candidates.family(c),cvRows.oof_mean_R2(end));
end

% Select by the predeclared normalized error used by the original workflow.
[~,best]=min(cvRows.oof_mean_nRMSE); selected=candidates(best,:);
finalModel=fit_candidate(X(dev,:),Y(dev,:),selected,cfg);
prediction=predict_candidate(finalModel,X(test,:));
testMetrics=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance);
use=~[testMetrics.constant];
testSummary=table(best,string(selected.family),selected.param1,selected.param2, ...
    mean([testMetrics(use).R2]),median([testMetrics(use).R2]),mean([testMetrics(use).nRMSE]), ...
    mean([testMetrics(use).nMAE]),mean([testMetrics(use).a10]), ...
    'VariableNames',{'candidate_id','family','param1','param2','mean_R2','median_R2', ...
    'mean_nRMSE','mean_nMAE','mean_a10'});

perOutput=table((1:cfg.num_outputs)',string({prepared.dataset.output_dictionary.label})', ...
    [testMetrics.R2]',[testMetrics.nRMSE]',[testMetrics.nMAE]',[testMetrics.a10]', ...
    [testMetrics.constant]','VariableNames',{'output_column','label','R2','nRMSE','nMAE','a10','constant'});
predTable=table(test(:),'VariableNames',{'realization_id'});
for j=1:cfg.num_outputs
    predTable.(sprintf('observed_%02d',j))=Y(test,j);
    predTable.(sprintf('predicted_%02d',j))=prediction(:,j);
end

writetable(cvRows,fullfile(resultsDir,'improved_model_development_cv.csv'));
writetable(testSummary,fullfile(resultsDir,'improved_model_test_summary.csv'));
writetable(perOutput,fullfile(resultsDir,'improved_model_test_per_output.csv'));
writetable(predTable,fullfile(resultsDir,'improved_model_test_predictions.csv'));
developmentIds=dev; testIds=test;
save(fullfile(resultsDir,'improved_model_selected.mat'),'finalModel','selected','cvRows', ...
    'developmentIds','testIds','fold','-v7.3');
make_figures(cvRows,testMetrics,Y(test,:),prediction,prepared.dataset.output_dictionary,figuresDir);
report.cv=cvRows; report.selected=selected; report.test=testSummary;
fprintf('Selected %s (%.4g, %.4g): development OOF R2 %.4f, test R2 %.4f.\n', ...
    selected.family,selected.param1,selected.param2,cvRows.oof_mean_R2(best),testSummary.mean_R2);
end

function candidates=make_candidates()
family=strings(0,1); p1=zeros(0,1); p2=zeros(0,1);
for lambda=[1e-4 1e-2 1 100]
    family(end+1)="linear_ridge"; p1(end+1)=lambda; p2(end+1)=0; %#ok<AGROW>
    family(end+1)="quadratic_ridge"; p1(end+1)=lambda; p2(end+1)=0; %#ok<AGROW>
    family(end+1)="asinhX_ridge"; p1(end+1)=lambda; p2(end+1)=0; %#ok<AGROW>
    family(end+1)="asinhY_ridge"; p1(end+1)=lambda; p2(end+1)=0; %#ok<AGROW>
    family(end+1)="asinhXY_ridge"; p1(end+1)=lambda; p2(end+1)=0; %#ok<AGROW>
end
for width=[0.25 0.5 1 2 4]
    for lambda=[1e-4 1e-2 1 100]
        family(end+1)="kernel_ridge"; p1(end+1)=width; p2(end+1)=lambda; %#ok<AGROW>
        family(end+1)="asinhY_kernel_ridge"; p1(end+1)=width; p2(end+1)=lambda; %#ok<AGROW>
    end
end
for components=[1 2 3 5 7 9]
    family(end+1)="pls"; p1(end+1)=components; p2(end+1)=0; %#ok<AGROW>
    family(end+1)="asinhY_pls"; p1(end+1)=components; p2(end+1)=0; %#ok<AGROW>
end
candidates=table(family(:),p1(:),p2(:),'VariableNames',{'family','param1','param2'});
end

function model=fit_candidate(X,Y,spec,cfg)
model.family=string(spec.family); model.spec=spec;
model.xTransform=contains(model.family,"asinhX");
model.yTransform=contains(model.family,"asinhY") || model.family=="asinhXY_ridge";
if model.xTransform
    model.xScale=median(abs(X),1); model.xScale(model.xScale<=eps)=1;
    X=asinh(bsxfun(@rdivide,X,model.xScale));
end
if model.yTransform
    model.yScale=median(abs(Y),1); fallback=mean(abs(Y),1);
    bad=model.yScale<=eps; model.yScale(bad)=fallback(bad); model.yScale(model.yScale<=eps)=1;
    Y=asinh(bsxfun(@rdivide,Y,model.yScale));
end
if model.family=="quadratic_ridge", X=quadratic_features(X); end
model.xStandardizer=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
model.yStandardizer=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
Xs=apply_task3_standardizer(X,model.xStandardizer);
Ys=apply_task3_standardizer(Y,model.yStandardizer);

if contains(model.family,"ridge") && ~contains(model.family,"kernel")
    A=[ones(size(Xs,1),1) Xs]; penalty=eye(size(A,2)); penalty(1,1)=0;
    model.beta=(A'*A+spec.param1*penalty)\(A'*Ys);
elseif contains(model.family,"kernel_ridge")
    model.centers=Xs; model.width=spec.param1*task3_median_distance(Xs);
    K=rbf(Xs,Xs,model.width); model.alpha=(K+spec.param2*eye(size(K)))\Ys;
elseif contains(model.family,"pls")
    components=min([spec.param1,size(Xs,2),size(Xs,1)-1]);
    [~,~,~,~,model.beta]=plsregress(Xs,Ys,components);
else
    error('Unknown candidate family %s.',model.family);
end
end

function prediction=predict_candidate(model,X)
if model.xTransform, X=asinh(bsxfun(@rdivide,X,model.xScale)); end
if model.family=="quadratic_ridge", X=quadratic_features(X); end
Xs=apply_task3_standardizer(X,model.xStandardizer);
if contains(model.family,"ridge") && ~contains(model.family,"kernel")
    z=[ones(size(Xs,1),1) Xs]*model.beta;
elseif contains(model.family,"kernel_ridge")
    z=rbf(Xs,model.centers,model.width)*model.alpha;
elseif contains(model.family,"pls")
    z=[ones(size(Xs,1),1) Xs]*model.beta;
end
prediction=reverse_task3_standardizer(z,model.yStandardizer);
if model.yTransform
    prediction=bsxfun(@times,sinh(prediction),model.yScale);
    prediction=max(prediction,0);
end
end

function Z=quadratic_features(X)
d=size(X,2); Z=[X X.^2];
for a=1:d-1, for b=a+1:d, Z=[Z X(:,a).*X(:,b)]; end, end %#ok<AGROW>
end

function K=rbf(A,B,width)
aa=sum(A.^2,2); bb=sum(B.^2,2)'; d2=max(0,bsxfun(@plus,aa,bb)-2*(A*B'));
K=exp(-d2/(2*max(width,eps)^2));
end

function fold=make_folds(n,k,seed)
rng(seed,'twister'); order=randperm(n); fold=zeros(n,1);
for i=1:n, fold(order(i))=mod(i-1,k)+1; end
end

function make_figures(cvRows,testMetrics,observed,predicted,dictionary,outDir)
[~,order]=sort(cvRows.oof_mean_R2,'descend'); top=order(1:min(15,numel(order)));
labels=compose('%s (%.3g,%.3g)',cvRows.family(top),cvRows.param1(top),cvRows.param2(top));
f=figure('Visible','off','Color','w','Position',[100 100 1050 600]);
barh(categorical(labels,labels(end:-1:1)),cvRows.oof_mean_R2(top),'FaceColor',[0.10 0.35 0.62]);
xlabel('Development-only out-of-fold mean R^2'); title('Top candidate surrogate configurations'); grid on;
set(gca,'FontSize',9); set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'improved_model_development_cv.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(outDir,'improved_model_development_cv.png'),'-dpng','-r220'); close(f);

use=find(~[testMetrics.constant]); [~,rank]=sort([testMetrics(use).R2]); pick=use(rank(round(linspace(1,numel(rank),6))));
f=figure('Visible','off','Color','w','Position',[100 100 1000 650]);
for k=1:numel(pick)
    j=pick(k); subplot(2,3,k); scatter(observed(:,j),predicted(:,j),22,[0.10 0.35 0.62],'filled'); hold on;
    lo=min([observed(:,j);predicted(:,j)]); hi=max([observed(:,j);predicted(:,j)]); plot([lo hi],[lo hi],'k--');
    axis square; grid on; title(sprintf('%s, R^2=%.2f',dictionary(j).label,testMetrics(j).R2));
    xlabel('Observed'); ylabel('Predicted');
end
sgtitle('Selected improved model: held-out predictions'); set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'improved_model_test_scatter.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(outDir,'improved_model_test_scatter.png'),'-dpng','-r220'); close(f);
end
