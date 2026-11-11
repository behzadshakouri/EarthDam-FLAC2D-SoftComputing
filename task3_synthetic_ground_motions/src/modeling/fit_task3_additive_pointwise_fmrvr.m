function model=fit_task3_additive_pointwise_fmrvr(X,Y,options)
%FIT_TASK3_ADDITIVE_POINTWISE_FMRVR Record/dynamic factorized FMRVR kernel.
if nargin<3,options=struct;end
defaults=struct('record_count',16,'record_rank',8,'dynamic_rank',8, ...
    'record_centers',60,'dynamic_centers',60,'width_factors',[.3 .7 1.5], ...
    'max_iterations',600,'tolerance',.03,'seed',20260830);
for name=string(fieldnames(defaults))',if ~isfield(options,name),options.(name)=defaults.(name);end,end
X=double(X);Y=double(Y);assert(all(isfinite(X),'all')&&all(isfinite(Y),'all')&&all(Y>=0,'all'));
model.xmean=mean(X,1);model.xstd=std(X,0,1);model.xstd(model.xstd<=1e-12)=1;
X=(X-model.xmean)./model.xstd;nr=options.record_count;
R=X(:,1:nr);D=X(:,nr+1:end);Ru=unique(R,'rows','stable');
[~,~,Vr]=svd(Ru,'econ');[~,~,Vd]=svd(D,'econ');
model.Vr=Vr(:,1:min(options.record_rank,size(Vr,2)));model.Vd=Vd(:,1:min(options.dynamic_rank,size(Vd,2)));
R=R*model.Vr;D=D*model.Vd;
rng(options.seed,'twister');[~,model.rcenters]=kmeans(Ru*model.Vr,min(options.record_centers,size(Ru,1)), ...
    'Replicates',3,'MaxIter',500,'Start','plus');
[~,model.dcenters]=kmeans(D,min(options.dynamic_centers,size(D,1)), ...
    'Replicates',3,'MaxIter',500,'Start','plus');
model.rwidths=kernel_widths(model.rcenters,options.width_factors);
model.dwidths=kernel_widths(model.dcenters,options.width_factors);
Phi=make_basis(R,D,model);

model.target_scale=median(Y,1);fallback=mean(Y,1);bad=model.target_scale<=1e-12;
model.target_scale(bad)=fallback(bad);model.target_scale(model.target_scale<=1e-12)=1;
T=asinh(Y./model.target_scale);model.ymean=mean(T,1);model.ystd=std(T,0,1);
model.ystd(model.ystd<=1e-12)=1;T=(T-model.ymean)./model.ystd;
[~,~,V]=svd(T,'econ');model.output_basis=V(:,1:min(7,size(V,2)));latent=T*model.output_basis;
model.latent_mean=mean(latent,1);latent=latent-model.latent_mean;
[model.used,model.alpha,model.Mu,model.invSigma,model.Omega,model.iterations]= ...
    fmrvr_task3_sufficient(Phi,latent,options.max_iterations,options.tolerance);
model.target_max=max(Y,[],1);model.options=options;model.candidate_basis_count=size(Phi,2);
end

function widths=kernel_widths(C,factors)
d=sqrt(max(pdist2(C,C,'squaredeuclidean'),0));d=d(triu(true(size(d)),1));
base=median(d(d>0&isfinite(d)));if isempty(base),base=sqrt(size(C,2));end;widths=base*factors;
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
