function Y=predict_task3_additive_pointwise_fmrvr(model,X)
%PREDICT_TASK3_ADDITIVE_POINTWISE_FMRVR Predict seven responses at a point.
X=(double(X)-model.xmean)./model.xstd;nr=model.options.record_count;
R=X(:,1:nr)*model.Vr;D=X(:,nr+1:end)*model.Vd;Phi=make_basis(R,D,model);
latent=Phi(:,model.used)*model.Mu+model.latent_mean;T=latent*model.output_basis';
T=T.*model.ystd+model.ymean;Y=min(max(sinh(T).*model.target_scale,0),model.target_max);
end
function Phi=make_basis(R,D,model)
Kr=rbf_bank(R,model.rcenters,model.rwidths);Kd=rbf_bank(D,model.dcenters,model.dwidths);
interaction=zeros(size(R,1),size(R,2)*size(D,2));q=0;
for i=1:size(R,2),for j=1:size(D,2),q=q+1;interaction(:,q)=R(:,i).*D(:,j);end,end
Phi=[ones(size(R,1),1) R D R.^2 D.^2 interaction Kr Kd];
end
function K=rbf_bank(X,C,widths)
d2=pdist2(X,C,'squaredeuclidean');K=zeros(size(X,1),size(C,1)*numel(widths));q=0;
for width=widths,n=size(C,1);K(:,q+(1:n))=exp(-d2/(2*max(width,eps)^2));q=q+n;end
end
