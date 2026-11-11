function [X,names,periods]=build_task3_dense_spectral_features(Task3,cfg)
%BUILD_TASK3_DENSE_SPECTRAL_FEATURES Dense 5%-damped response-spectrum inputs.
periods=logspace(log10(.05),log10(5),25); n=cfg.num_realizations;
names=[string(cfg.features.names) "record_duration_s" compose('Sa_%.4gs_g',periods)];
X=nan(n,numel(names));
for i=1:n
    gm=Task3.Inputs.InputsMatrix(i); time=double(gm.time(:)); accel=double(gm.accel(:));
    X(i,1:9)=extract_ground_motion_features(time,accel,cfg);
    X(i,10)=time(end)-time(1);
    for p=1:numel(periods), X(i,10+p)=pseudo_sa(time,accel,periods(p),cfg); end
end
assert(all(isfinite(X(:))));
end
function saG=pseudo_sa(time,accelG,period,cfg)
dt=median(diff(time)); uniform=(time(1):dt:time(end))';
if numel(uniform)~=numel(time) || max(abs(uniform-time(1:numel(uniform))))>1e-6*max(1,time(end)-time(1))
    ag=interp1(time,accelG,uniform,'linear',0)*cfg.features.gravity_m_s2;
else, ag=accelG*cfg.features.gravity_m_s2; end
ag=ag-mean(ag); omega=2*pi/period; zeta=.05; c=2*zeta*omega; k=omega^2;
beta=1/4; gamma=1/2; a0=1/(beta*dt^2); a1=gamma/(beta*dt);
a2=1/(beta*dt); a3=1/(2*beta)-1; a4=gamma/beta-1; a5=dt*(gamma/(2*beta)-1);
khat=k+a0+a1*c; u=0; v=0; ar=-ag(1); maxU=0;
for j=2:numel(ag)
    effective=-ag(j)+(a0*u+a2*v+a3*ar)+c*(a1*u+a4*v+a5*ar);
    unew=effective/khat; anew=a0*(unew-u)-a2*v-a3*ar;
    vnew=v+dt*((1-gamma)*ar+gamma*anew); u=unew; v=vnew; ar=anew; maxU=max(maxU,abs(u));
end
saG=omega^2*maxU/cfg.features.gravity_m_s2;
end
