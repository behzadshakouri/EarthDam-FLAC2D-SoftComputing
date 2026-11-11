function model=fit_task3_fmrvr_variant(X,Y,spec,cfg)
%FIT_TASK3_FMRVR_VARIANT Fit a mixed-kernel/reduced-rank FMRVR variant.
if spec.input_asinh
    model.input_scale=median(abs(X),1); model.input_scale(model.input_scale<=eps)=1;
    X=asinh(bsxfun(@rdivide,X,model.input_scale));
else, model.input_scale=[]; end
model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs); model.feature_weight=ones(1,size(X,2));
if strcmp(spec.distance,'supervised')
    C=corr(X,Y,'Rows','pairwise'); score=sqrt(mean(C.^2,2,'omitnan'))';
    score=max(score,prctile(score,25)); model.feature_weight=score/mean(score);
end
X=bsxfun(@times,X,sqrt(model.feature_weight));
model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
Z=apply_task3_standardizer(Y,model.ys); model.modeled=~model.ys.constant;
cols=find(model.modeled); target=Z(:,cols); model.output_basis=[];
if isfinite(spec.output_rank) && spec.output_rank<size(target,2)
    [~,~,V]=svd(target,'econ'); r=min(spec.output_rank,size(V,2));
    model.output_basis=V(:,1:r); target=target*model.output_basis;
end
model.part=fit_part(X,target,spec,cfg); model.part.cols=cols;
model.used_total=numel(model.part.used); model.spec=spec;
end

function part=fit_part(X,T,spec,cfg)
width=task3_median_distance(X)*spec.width_factor;
K1=task3_rbf_design(X,X,width,false); K2=linear_kernel(X,X);
Phi=[ones(size(X,1),1) (1-spec.linear_mix)*K1+spec.linear_mix*K2];
outputMean=mean(T,1); centered=bsxfun(@minus,T,outputMean);
[U,S,V]=svd(centered,'econ'); singular=diag(S);
keep=singular>max(size(centered))*eps(max(singular));
transform=V(:,keep)*diag(singular(keep)/sqrt(size(T,1)-1));
latent=U(:,keep)*sqrt(size(T,1)-1);
[used,alpha,latentMu,invSigma,latentOmega,nIters]=fmrvr_task3(Phi,latent,cfg.fmrvr.max_iterations,cfg.fmrvr.tolerance);
part.centers=X; part.width=width; part.used=used; part.alpha=alpha;
part.Mu=latentMu*transform'; part.invSigma=invSigma;
part.Omega=transform*latentOmega*transform'; part.iterations=nIters;
part.output_mean=outputMean; part.linear_mix=spec.linear_mix;
end
function K=linear_kernel(A,B)
K=A*B'; denom=sqrt(sum(A.^2,2)*sum(B.^2,2)'); K=K./max(denom,eps);
end
