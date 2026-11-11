function model = train_task3_fmrvr(X, Y, width, cfg)
%TRAIN_TASK3_FMRVR Train the original Ha FMRVR on standardized matrices.
assert(size(X,1) == size(Y,1));
assert(strcmp(cfg.fmrvr.kernel_type,'+gauss'), ...
    'The validated Task 3 implementation currently supports +gauss only.');
Phi = task3_rbf_design(X, X, width, true);
% Fit in the numerically independent output subspace. The source solver
% inverts cov(Y), which is singular for linearly dependent response columns.
% Whitening is learned exclusively from this fit's training targets.
outputMean=mean(Y,1); centered=bsxfun(@minus,Y,outputMean);
[U,S,V]=svd(centered,'econ'); singular=diag(S);
rankTolerance=max(size(centered))*eps(max(singular));
retained=singular>rankTolerance;
assert(any(retained),'Task3:ConstantTraining','No variable training outputs.');
transform=V(:,retained)*diag(singular(retained)/sqrt(size(Y,1)-1));
latent=U(:,retained)*sqrt(size(Y,1)-1);
[used, alpha, latentMu, invSigma, latentOmega, nIters] = fmrvr_task3(Phi, latent, ...
    cfg.fmrvr.max_iterations, cfg.fmrvr.tolerance);
Mu=latentMu*transform'; Omega=transform*latentOmega*transform';
assert(all(isfinite(Mu(:))),'Task3:NonfiniteModel','Nonfinite FMRVR coefficients.');
model.centers = X; model.width = width; model.kernel_type = cfg.fmrvr.kernel_type;
model.used = used; model.alpha = alpha; model.Mu = Mu;
model.invSigma = invSigma; model.Omega = Omega; model.iterations = nIters;
model.output_mean=outputMean; model.output_rank=sum(retained);
model.output_transform=transform; model.output_rank_tolerance=rankTolerance;
end
