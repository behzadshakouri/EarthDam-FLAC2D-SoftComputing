function model=fit_task3_pointwise_fmrvr(X,Y,options)
%FIT_TASK3_POINTWISE_FMRVR Joint sparse prediction of 70 screened peak demands.
if nargin<3, options=struct; end
defaults=struct('output_rank',20,'center_count',80,'width_factors',[.5 1 2], ...
    'max_iterations',400,'tolerance',.05,'seed',20260830,'target_transform',"log1p");
names=fieldnames(defaults);
for k=1:numel(names)
    if ~isfield(options,names{k}), options.(names{k})=defaults.(names{k}); end
end
X=double(X); Y=double(Y);
assert(all(isfinite(X),'all')&&all(isfinite(Y),'all'));
model.target_transform=string(options.target_transform);
if model.target_transform=="log1p", assert(all(Y>=0,'all')); end
model.target_max=max(Y,[],1);

model.x_location=mean(X,1); model.x_scale=std(X,0,1);
model.x_scale(model.x_scale<=1e-12)=1;
Zx=(X-model.x_location)./model.x_scale;

if model.target_transform=="log1p"
    model.target_scale=median(Y,1); fallback=mean(Y,1);
    bad=model.target_scale<=1e-12; model.target_scale(bad)=fallback(bad);
    model.target_scale(model.target_scale<=1e-12)=1;
    Ty=log1p(Y./model.target_scale);
else
    model.target_scale=ones(1,size(Y,2)); Ty=Y;
end
model.y_location=mean(Ty,1); model.y_scale=std(Ty,0,1);
model.y_scale(model.y_scale<=1e-12)=1;
Ty=(Ty-model.y_location)./model.y_scale;

[~,~,V]=svd(Ty,'econ'); rank=min([options.output_rank,size(V,2),size(Ty,1)-1]);
model.output_basis=V(:,1:rank); latent=Ty*model.output_basis;

rng(options.seed,'twister'); count=min(options.center_count,size(Zx,1));
[~,centers]=kmeans(Zx,count,'MaxIter',500,'Replicates',3, ...
    'Start','plus','Options',statset('UseParallel',false));
model.centers=centers;
d=sqrt(max(pdist2(centers,centers,'squaredeuclidean'),0));
d=d(triu(true(size(d)),1)); base=median(d(d>0 & isfinite(d)));
if isempty(base)||~isfinite(base), base=sqrt(size(Zx,2)); end
model.widths=base*options.width_factors;
Phi=task4_peak_basis(Zx,model);

model.latent_mean=mean(latent,1); latent=latent-model.latent_mean;
[used,alpha,Mu,invSigma,Omega,nIters]=fmrvr_task3_sufficient( ...
    Phi,latent,options.max_iterations,options.tolerance);
model.used=used; model.alpha=alpha; model.Mu=Mu;
model.invSigma=invSigma; model.Omega=Omega; model.iterations=nIters;
model.options=options; model.candidate_basis_count=size(Phi,2);
end

function Phi=task4_peak_basis(X,model)
d2=pdist2(X,model.centers,'squaredeuclidean');
R=zeros(size(X,1),numel(model.widths)*size(model.centers,1));
offset=0;
for width=model.widths
    n=size(model.centers,1);
    R(:,offset+(1:n))=exp(-d2/(2*max(width,eps)^2)); offset=offset+n;
end
Phi=[ones(size(X,1),1) X X.^2 R];
end
