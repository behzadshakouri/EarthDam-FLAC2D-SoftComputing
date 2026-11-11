function Y=predict_task3_fmrvr_variant(model,X)
%PREDICT_TASK3_FMRVR_VARIANT Predict from fit_task3_fmrvr_variant output.
if ~isempty(model.input_scale), X=asinh(bsxfun(@rdivide,X,model.input_scale)); end
X=apply_task3_standardizer(X,model.xs); X=bsxfun(@times,X,sqrt(model.feature_weight));
part=model.part; K1=task3_rbf_design(X,part.centers,part.width,false);
K2=linear_kernel(X,part.centers); Phi=[ones(size(X,1),1) (1-part.linear_mix)*K1+part.linear_mix*K2];
value=bsxfun(@plus,Phi(:,part.used)*part.Mu,part.output_mean);
if ~isempty(model.output_basis), value=value*model.output_basis'; end
Z=zeros(size(X,1),numel(model.modeled)); Z(:,part.cols)=value;
Y=reverse_task3_standardizer(Z,model.ys);
end
function K=linear_kernel(A,B)
K=A*B'; denom=sqrt(sum(A.^2,2)*sum(B.^2,2)'); K=K./max(denom,eps);
end
