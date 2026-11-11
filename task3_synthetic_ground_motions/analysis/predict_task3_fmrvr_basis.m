function Y=predict_task3_fmrvr_basis(model,X)
%PREDICT_TASK3_FMRVR_BASIS Predict with the explicit-basis FMRVR model.
X=apply_task3_standardizer(X,model.xs);
Phi=trajectory_basis(X,model.basis_scale);
value=bsxfun(@plus,Phi(:,model.used)*model.Mu,model.output_mean);
if ~isempty(model.output_basis), value=value*model.output_basis'; end
Z=zeros(size(X,1),numel(model.modeled)); Z(:,model.cols)=value;
Y=reverse_task3_standardizer(Z,model.ys);
end

function Phi=trajectory_basis(X,scale)
durationFraction=X(:,18);
Phi=[ones(size(X,1),1) X X.^2 bsxfun(@times,X(:,1:16),durationFraction)];
Phi=bsxfun(@rdivide,Phi,scale);
end
