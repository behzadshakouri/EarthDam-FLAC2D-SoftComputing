function Y=predict_task3_pointwise_fmrvr(model,X)
%PREDICT_TASK3_POINTWISE_FMRVR Predict 70 screened peak demands jointly.
Zx=(double(X)-model.x_location)./model.x_scale;
Phi=local_basis(Zx,model);
latent=Phi(:,model.used)*model.Mu+model.latent_mean;
Ty=latent*model.output_basis';
Ty=Ty.*model.y_scale+model.y_location;
if model.target_transform=="log1p"
    Y=min(max(expm1(Ty).*model.target_scale,0),model.target_max);
else
    Y=Ty;
end
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
