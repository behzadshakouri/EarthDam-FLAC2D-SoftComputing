function model=fit_task3_compact_pointwise_fmrvr(X,Y,options)
%FIT_TASK3_COMPACT_POINTWISE_FMRVR Robust point-wise FMRVR.
% The compact basis avoids record-specific RBF centers when ground motions
% differ between training and testing records.
if nargin<3,options=struct;end
defaults=struct('basis',"linear",'target_transform',"none",'output_rank',7, ...
    'max_iterations',500,'tolerance',.05);
names=fieldnames(defaults);
for k=1:numel(names),if ~isfield(options,names{k}),options.(names{k})=defaults.(names{k});end,end
X=double(X);Y=double(Y);assert(all(isfinite(X),'all')&&all(isfinite(Y),'all')&&all(Y>=0,'all'));

model.options=options;model.input_scale=median(abs(X),1);
model.input_scale(model.input_scale<=eps)=1;
X=asinh(X./model.input_scale);model.x_location=mean(X,1);model.x_scale=std(X,0,1);
model.x_scale(model.x_scale<=1e-12)=1;X=(X-model.x_location)./model.x_scale;

model.target_transform=string(options.target_transform);model.target_scale=median(Y,1);
fallback=mean(Y,1);bad=model.target_scale<=eps;model.target_scale(bad)=fallback(bad);
model.target_scale(model.target_scale<=eps)=1;
switch model.target_transform
    case "none",Ty=Y;
    case "log1p",Ty=log1p(Y./model.target_scale);
    case "asinh",Ty=asinh(Y./model.target_scale);
    otherwise,error('Unknown target transform: %s',model.target_transform);
end
model.y_location=mean(Ty,1);model.y_scale=std(Ty,0,1);
model.y_scale(model.y_scale<=1e-12)=1;Ty=(Ty-model.y_location)./model.y_scale;
[~,~,V]=svd(Ty,'econ');rank=min([options.output_rank,size(V,2),size(Ty,1)-1]);
model.output_basis=V(:,1:rank);latent=Ty*model.output_basis;
Phi=compact_basis(X,string(options.basis));model.basis_scale=sqrt(sum(Phi.^2,1));
model.basis_scale(model.basis_scale<=eps)=1;Phi=Phi./model.basis_scale;
model.latent_mean=mean(latent,1);latent=latent-model.latent_mean;
[model.used,model.alpha,model.Mu,model.invSigma,model.Omega,model.iterations]= ...
    fmrvr_task3_sufficient(Phi,latent,options.max_iterations,options.tolerance);
model.candidate_basis_count=size(Phi,2);model.target_max=max(Y,[],1);
end

function Phi=compact_basis(X,basis)
switch basis
    case "linear",Phi=[ones(size(X,1),1) X];
    case "quadratic",Phi=[ones(size(X,1),1) X X.^2];
    otherwise,error('Unknown compact basis: %s',basis);
end
end
