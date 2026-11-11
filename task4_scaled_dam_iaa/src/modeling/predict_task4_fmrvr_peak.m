function Y=predict_task4_fmrvr_peak(model,X)
%PREDICT_TASK4_FMRVR_PEAK Predict one point's seven cumulative envelopes jointly.
Zx=(double(X)-model.x_location)./model.x_scale;
Phi=local_basis(Zx,model);
latent=Phi(:,model.used)*model.Mu+model.latent_mean;
Ty=latent*model.output_basis';
Ty=Ty.*model.y_scale+model.y_location;
switch model.target_transform
    case "log1p",normalizedY=expm1(Ty).*model.target_scale;
    case "asinh",normalizedY=sinh(Ty).*model.target_scale;
    case "none",normalizedY=Ty;
end
normalizedY=max(normalizedY,0);
if model.scale_normalize
    scaleValue=double(X(:,model.scale_column));
    scaleTrend=exp(model.scale_intercept).*scaleValue.^model.scale_power;
    Y=normalizedY.*scaleTrend;
else
    Y=normalizedY;
end
Y=min(Y,model.target_max);
end

function Phi=local_basis(X,model)
d2=pdist2(X,model.centers,'squaredeuclidean');
R=zeros(size(X,1),numel(model.widths)*size(model.centers,1)); offset=0;
for width=model.widths
    n=size(model.centers,1);
    R(:,offset+(1:n))=exp(-d2/(2*max(width,eps)^2)); offset=offset+n;
end
Phi=[ones(size(X,1),1) X X.^2 R];
end
