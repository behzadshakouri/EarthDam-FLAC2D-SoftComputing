function Y=predict_task3_compact_pointwise_fmrvr(model,X)
%PREDICT_TASK3_COMPACT_POINTWISE_FMRVR Predict seven responses at one point.
X=asinh(double(X)./model.input_scale);X=(X-model.x_location)./model.x_scale;
switch string(model.options.basis)
    case "linear",Phi=[ones(size(X,1),1) X];
    case "quadratic",Phi=[ones(size(X,1),1) X X.^2];
    otherwise,error('Unknown compact basis: %s',string(model.options.basis));
end
Phi=Phi./model.basis_scale;latent=Phi(:,model.used)*model.Mu+model.latent_mean;
Ty=(latent*model.output_basis').*model.y_scale+model.y_location;
switch model.target_transform
    case "none",Y=Ty;
    case "log1p",Y=expm1(Ty).*model.target_scale;
    case "asinh",Y=sinh(Ty).*model.target_scale;
end
Y=min(max(Y,0),model.target_max);
end
