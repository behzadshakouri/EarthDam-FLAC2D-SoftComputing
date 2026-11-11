function Y=predict_task3_fmrvr_advanced(model,X)
%PREDICT_TASK3_FMRVR_ADVANCED Predict advanced FMRVR peak demands.
X=asinh(bsxfun(@rdivide,X,model.input_scale));
X=apply_task3_standardizer(X,model.xs);
X=bsxfun(@times,X,sqrt(model.feature_weight));
K=zeros(size(X,1),size(model.centers,1));
for width=model.widths, K=K+task3_rbf_design(X,model.centers,width,false); end
K=K/numel(model.widths); K2=linear_kernel(X,model.centers);
Phi=[ones(size(X,1),1) (1-model.spec.linear_mix)*K+model.spec.linear_mix*K2];
value=bsxfun(@plus,Phi(:,model.used)*model.Mu,model.output_mean);
if ~isempty(model.output_basis), value=value*model.output_basis'; end
Z=zeros(size(X,1),numel(model.modeled)); Z(:,model.cols)=value;
Y=reverse_task3_standardizer(Z,model.ys);
if model.target_transform=="asinh"
    Y=bsxfun(@times,sinh(Y),model.target_scale); Y=max(Y,0);
elseif model.target_transform=="log1p"
    Y=bsxfun(@times,expm1(Y),model.target_scale); Y=max(Y,0);
end
end

function K=linear_kernel(A,B)
K=A*B'; denom=sqrt(sum(A.^2,2)*sum(B.^2,2)'); K=K./max(denom,eps);
end
