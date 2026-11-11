function report = explore_task3_fmrvr_improvements()
%EXPLORE_TASK3_FMRVR_IMPROVEMENTS Development-selected FMRVR variants.
% Keeps the Ha--Zhang sparse Bayesian solver and tests physically informed
% inputs, supervised anisotropic distances, reduced output rank, response-
% family fits, and a linear/RBF mixed basis. Raw data are never modified.

analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3'); [Xall,names,groups]=build_task3_augmented_features(raw.Task3,cfg);
Y=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
dev=saved.developmentIds(:); test=saved.testIds(:); nFolds=3; fold=make_folds(numel(dev),nFolds,cfg.seed+1201);
cfg.fmrvr.max_iterations=400; cfg.fmrvr.tolerance=.2;

% A compact, hypothesis-led candidate set avoids tuning on the fixed test.
candidates=table;
candidates=add(candidates,"baseline",groups.base,false,"isotropic","all",Inf,"rbf",0);
for factor=[.25 .5 1 2]
    candidates=add(candidates,"spectral",groups.spectral,true,"isotropic","all",Inf,"rbf",factor);
end
for factor=[.25 .5 1]
    candidates=add(candidates,"spectral_ard",groups.spectral,true,"supervised","all",Inf,"rbf",factor);
end
for rank=[5 10 20]
    candidates=add(candidates,"reduced_rank",groups.spectral,true,"supervised","all",rank,"rbf",.5);
end
candidates=add(candidates,"family",groups.spectral,true,"supervised","family",Inf,"rbf",.5);
candidates=add(candidates,"mixed_kernel",groups.spectral,true,"supervised","all",Inf,"mixed",.5);
for mix=[.25 .75 .9 .99]
    candidates=add(candidates,"mixed_kernel",groups.spectral,true,"supervised","all",Inf,"mixed",mix);
end
for rank=[5 10 20 40]
    candidates=add(candidates,"mixed_reduced_rank",groups.spectral,true,"supervised","all",rank,"mixed",.9);
end
candidates=add(candidates,"mixed_family",groups.spectral,true,"supervised","family",Inf,"mixed",.9);

oof=cell(height(candidates),1); cvRows=table;
for c=1:height(candidates)
    pred=nan(numel(dev),size(Y,2));
    for f=1:nFolds
        tr=dev(fold~=f); va=dev(fold==f);
        model=fit_variant(Xall(tr,candidates.feature_ids{c}),Y(tr,:),candidates(c,:),cfg);
        pred(fold==f,:)=predict_variant(model,Xall(va,candidates.feature_ids{c}));
    end
    oof{c}=pred; mt=calculate_task3_metrics(Y(dev,:),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    cvRows=[cvRows; table(c,candidates.name(c),mean([mt(use).R2]),median([mt(use).R2]), ...
        mean([mt(use).nRMSE]),mean([mt(use).nMAE]),numel(model.used_total), ...
        'VariableNames',{'candidate_id','candidate','mean_R2','median_R2','mean_nRMSE','mean_nMAE','last_fold_bases'})]; %#ok<AGROW>
    fprintf('FMRVR candidate %d/%d: %s, OOF R2 %.4f.\n',c,height(candidates),candidates.name(c),cvRows.mean_R2(end));
end
[~,best]=min(cvRows.mean_nRMSE); chosen=candidates(best,:);
finalModel=fit_variant(Xall(dev,chosen.feature_ids{1}),Y(dev,:),chosen,cfg);
prediction=predict_variant(finalModel,Xall(test,chosen.feature_ids{1}));
mt=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
summary=table(best,chosen.name,mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]), ...
    mean([mt(use).nMAE]),mean([mt(use).a10]),sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8), ...
    finalModel.used_total,'VariableNames',{'candidate_id','candidate','mean_R2','median_R2','mean_nRMSE', ...
    'mean_nMAE','mean_a10','outputs_R2_ge_07','outputs_R2_ge_08','relevance_basis_count'});

candidateExport=candidates; candidateExport.feature_ids=[];
writetable([candidateExport cvRows(:,3:end)],fullfile(resultsDir,'fmrvr_improvement_development_cv.csv'));
writetable(summary,fullfile(resultsDir,'fmrvr_improvement_fixed_test_summary.csv'));
writetable(table((1:size(Y,2))',string({prepared.dataset.output_dictionary.label})',[mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.a10]',[mt.constant]', ...
    'VariableNames',{'output_column','label','R2','nRMSE','nMAE','a10','constant'}),fullfile(resultsDir,'fmrvr_improvement_fixed_test_per_output.csv'));
save(fullfile(resultsDir,'fmrvr_improvement_model.mat'),'finalModel','chosen','fold','names','dev','test','-v7.3');
make_figure(cvRows,best,figuresDir);
report.summary=summary; report.development=cvRows; report.chosen=chosen;
fprintf('Selected FMRVR %s: fixed-test mean R2 %.4f with %d bases.\n',chosen.name,summary.mean_R2,summary.relevance_basis_count);
end

function t=add(t,name,ids,inputAsinh,distance,fitMode,rank,kernel,param)
row=table(string(name),{ids},inputAsinh,string(distance),string(fitMode),rank,string(kernel),param, ...
    'VariableNames',{'name','feature_ids','input_asinh','distance','fit_mode','output_rank','kernel','parameter'});
t=[t;row];
end

function model=fit_variant(X,Y,spec,cfg)
if spec.input_asinh
    model.input_scale=median(abs(X),1); model.input_scale(model.input_scale<=eps)=1;
    X=asinh(bsxfun(@rdivide,X,model.input_scale));
else, model.input_scale=[]; end
model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs);
model.feature_weight=ones(1,size(X,2));
if spec.distance=="supervised"
    C=corr(X,Y,'Rows','pairwise'); score=sqrt(mean(C.^2,2,'omitnan'))';
    score=max(score,prctile(score,25)); model.feature_weight=score/mean(score);
end
X=bsxfun(@times,X,sqrt(model.feature_weight));
model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
Z=apply_task3_standardizer(Y,model.ys); model.modeled=~model.ys.constant;
model.fit_mode=spec.fit_mode; model.kernel=spec.kernel; model.parts={}; model.used_total=0;
if spec.fit_mode=="family"
    for r=1:7
        cols=find(mod((1:size(Y,2))-1,7)+1==r & model.modeled);
        part=fit_part(X,Z(:,cols),spec,cfg); part.cols=cols; model.parts{end+1}=part; %#ok<AGROW>
        model.used_total=model.used_total+numel(part.used);
    end
else
    cols=find(model.modeled); target=Z(:,cols); model.output_basis=[];
    if isfinite(spec.output_rank) && spec.output_rank<size(target,2)
        [~,~,V]=svd(target,'econ'); r=min(spec.output_rank,size(V,2)); model.output_basis=V(:,1:r); target=target*model.output_basis;
    end
    part=fit_part(X,target,spec,cfg); part.cols=cols; model.parts={part}; model.used_total=numel(part.used);
end
end

function part=fit_part(X,T,spec,cfg)
base=task3_median_distance(X);
if spec.kernel=="rbf"
    factor=spec.parameter; if factor==0, factor=.5; end
    width=base*factor; Phi=task3_rbf_design(X,X,width,true);
else
    width=base*.5; K1=task3_rbf_design(X,X,width,false); K2=linear_kernel(X,X);
    mix=spec.parameter; Phi=[ones(size(X,1),1) (1-mix)*K1+mix*K2];
end
% Use the same numerically independent output representation as the
% production wrapper. The source solver explicitly inverts cov(T).
outputMean=mean(T,1); centered=bsxfun(@minus,T,outputMean);
[U,S,V]=svd(centered,'econ'); singular=diag(S);
keep=singular>max(size(centered))*eps(max(singular));
transform=V(:,keep)*diag(singular(keep)/sqrt(size(T,1)-1));
latent=U(:,keep)*sqrt(size(T,1)-1);
[used,alpha,latentMu,invSigma,latentOmega,nIters]=fmrvr_task3(Phi,latent,cfg.fmrvr.max_iterations,cfg.fmrvr.tolerance);
Mu=latentMu*transform'; Omega=transform*latentOmega*transform';
part.centers=X; part.width=width; part.used=used; part.alpha=alpha; part.Mu=Mu; part.invSigma=invSigma;
part.Omega=Omega; part.iterations=nIters; part.kernel=spec.kernel; part.mix=spec.parameter;
part.output_mean=outputMean;
end

function Y=predict_variant(model,X)
if ~isempty(model.input_scale), X=asinh(bsxfun(@rdivide,X,model.input_scale)); end
X=apply_task3_standardizer(X,model.xs); X=bsxfun(@times,X,sqrt(model.feature_weight));
Z=zeros(size(X,1),numel(model.modeled));
for p=1:numel(model.parts)
    part=model.parts{p};
    if part.kernel=="rbf", Phi=task3_rbf_design(X,part.centers,part.width,true);
    else, Phi=[ones(size(X,1),1) (1-part.mix)*task3_rbf_design(X,part.centers,part.width,false)+part.mix*linear_kernel(X,part.centers)]; end
    value=bsxfun(@plus,Phi(:,part.used)*part.Mu,part.output_mean);
    if model.fit_mode~="family" && ~isempty(model.output_basis), value=value*model.output_basis'; end
    Z(:,part.cols)=value;
end
Y=reverse_task3_standardizer(Z,model.ys);
end

function K=linear_kernel(A,B)
K=A*B'; denom=sqrt(sum(A.^2,2)*sum(B.^2,2)'); K=K./max(denom,eps);
end
function fold=make_folds(n,k,seed), rng(seed,'twister'); order=randperm(n); fold=zeros(n,1); for i=1:n,fold(order(i))=mod(i-1,k)+1; end, end
function make_figure(rows,best,outDir)
f=figure('Visible','off','Color','w','Position',[100 100 1000 520]);
bar(rows.mean_R2,'FaceColor',[.15 .42 .67]); hold on; bar(best,rows.mean_R2(best),'FaceColor',[.85 .33 .10]);
yline(0,'k:'); grid on; xlabel('Development candidate'); ylabel('Three-fold OOF mean R^2');
title('FMRVR improvement search using development data only'); set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'fmrvr_improvement_development_cv.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(outDir,'fmrvr_improvement_development_cv.png'),'-dpng','-r220'); close(f);
end
