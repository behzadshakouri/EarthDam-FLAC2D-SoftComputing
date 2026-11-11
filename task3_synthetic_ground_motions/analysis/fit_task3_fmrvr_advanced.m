function model=fit_task3_fmrvr_advanced(X,Y,spec,cfg)
%FIT_TASK3_FMRVR_ADVANCED Multiscale and target-transformed FMRVR.
model.spec=spec;
model.input_scale=median(abs(X),1); model.input_scale(model.input_scale<=eps)=1;
X=asinh(bsxfun(@rdivide,X,model.input_scale));
model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs);

C=corr(X,Y,'Rows','pairwise'); score=sqrt(mean(C.^2,2,'omitnan'))';
score=max(score,prctile(score,25)); model.feature_weight=score/mean(score);
X=bsxfun(@times,X,sqrt(model.feature_weight));

model.target_transform=string(spec.target_transform);
model.target_scale=[];
if ismember(model.target_transform,["asinh" "log1p"])
    model.target_scale=median(abs(Y),1); fallback=mean(abs(Y),1);
    bad=model.target_scale<=eps; model.target_scale(bad)=fallback(bad);
    model.target_scale(model.target_scale<=eps)=1;
    if model.target_transform=="asinh"
        Y=asinh(bsxfun(@rdivide,Y,model.target_scale));
    else
        Y=log1p(bsxfun(@rdivide,max(Y,0),model.target_scale));
    end
end
model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
Z=apply_task3_standardizer(Y,model.ys); model.modeled=~model.ys.constant;
cols=find(model.modeled); target=Z(:,cols); model.output_basis=[];
if isfinite(spec.output_rank) && spec.output_rank<size(target,2)
    [~,~,V]=svd(target,'econ'); rank=min(spec.output_rank,size(V,2));
    model.output_basis=V(:,1:rank); target=target*model.output_basis;
end

base=task3_median_distance(X); model.widths=base*spec.width_factors(:)';
K=zeros(size(X,1));
for width=model.widths, K=K+task3_rbf_design(X,X,width,false); end
K=K/numel(model.widths); K2=linear_kernel(X,X);
Phi=[ones(size(X,1),1) (1-spec.linear_mix)*K+spec.linear_mix*K2];

outputMean=mean(target,1); centered=bsxfun(@minus,target,outputMean);
[U,S,V]=svd(centered,'econ'); singular=diag(S);
keep=singular>max(size(centered))*eps(max(singular));
transform=V(:,keep)*diag(singular(keep)/sqrt(size(target,1)-1));
latent=U(:,keep)*sqrt(size(target,1)-1);
[used,alpha,latentMu,invSigma,latentOmega,nIters]=fmrvr_task3( ...
    Phi,latent,cfg.fmrvr.max_iterations,cfg.fmrvr.tolerance);
model.centers=X; model.used=used; model.alpha=alpha;
model.Mu=latentMu*transform'; model.invSigma=invSigma;
model.Omega=transform*latentOmega*transform'; model.iterations=nIters;
model.output_mean=outputMean; model.cols=cols;
end

function K=linear_kernel(A,B)
K=A*B'; denom=sqrt(sum(A.^2,2)*sum(B.^2,2)'); K=K./max(denom,eps);
end
