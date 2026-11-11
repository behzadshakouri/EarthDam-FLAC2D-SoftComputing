function model=fit_task3_fmrvr_basis(X,Y,outputRank,cfg)
%FIT_TASK3_FMRVR_BASIS Standalone FMRVR with an explicit trajectory basis.
model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs);
model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
Z=apply_task3_standardizer(Y,model.ys);
model.modeled=~model.ys.constant; model.cols=find(model.modeled);
target=Z(:,model.cols); model.output_basis=[];
if isfinite(outputRank) && outputRank<size(target,2)
    [~,~,V]=svd(target,'econ'); rank=min(outputRank,size(V,2));
    model.output_basis=V(:,1:rank); target=target*model.output_basis;
end
[Phi,model.basis_scale]=trajectory_basis(X,[]);
outputMean=mean(target,1); centered=bsxfun(@minus,target,outputMean);
[U,S,V]=svd(centered,'econ'); singular=diag(S);
keep=singular>max(size(centered))*eps(max(singular));
transform=V(:,keep)*diag(singular(keep)/sqrt(size(target,1)-1));
latent=U(:,keep)*sqrt(size(target,1)-1);
[model.used,model.alpha,latentMu,model.invSigma,latentOmega,model.iterations]= ...
    fmrvr_task3_general(Phi,latent,cfg.fmrvr.max_iterations,cfg.fmrvr.tolerance);
model.Mu=latentMu*transform'; model.Omega=transform*latentOmega*transform';
model.output_mean=outputMean;
end

function [Phi,scale]=trajectory_basis(X,scale)
% Linear, quadratic, and record-by-time candidates are pruned jointly by ARD.
durationFraction=X(:,18);
Phi=[ones(size(X,1),1) X X.^2 bsxfun(@times,X(:,1:16),durationFraction)];
if isempty(scale), scale=sqrt(sum(Phi.^2,1)); scale(scale<=eps)=1; end
Phi=bsxfun(@rdivide,Phi,scale);
end
