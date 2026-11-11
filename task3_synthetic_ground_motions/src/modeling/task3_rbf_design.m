function Phi = task3_rbf_design(X, centers, width, includeBias)
%TASK3_RBF_DESIGN Project-native Gaussian RBF design matrix.
assert(width > 0 && isfinite(width), 'Kernel width must be positive and finite.');
distanceSquared = bsxfun(@plus,sum(X.^2,2),sum(centers.^2,2)') - 2*(X*centers');
distanceSquared = max(distanceSquared,0);
Phi = exp(-distanceSquared/(2*width^2));
if includeBias, Phi = [ones(size(Phi,1),1) Phi]; end
end
