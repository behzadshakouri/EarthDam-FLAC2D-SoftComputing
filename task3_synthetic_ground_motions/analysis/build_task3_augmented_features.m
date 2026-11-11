function [X,names,groups] = build_task3_augmented_features(Task3,cfg)
%BUILD_TASK3_AUGMENTED_FEATURES Add duration and 5%-damped spectral IMs.
periods=[0.1 0.2 0.5 1.0 2.0 3.0]; n=cfg.num_realizations;
baseNames=string(cfg.features.names); extraNames=["record_duration_s", ...
    compose('Sa_%.1fs_g',periods),"Housner_0p1_2p5_m","D5_75_s","D20_80_s","frequency_bandwidth_Hz"];
names=[baseNames extraNames]; X=nan(n,numel(names));
for i=1:n
    gm=Task3.Inputs.InputsMatrix(i); time=double(gm.time(:)); accel=double(gm.accel(:));
    X(i,1:numel(baseNames))=extract_ground_motion_features(time,accel,cfg);
    duration=time(end)-time(1);
    sa=zeros(size(periods)); for p=1:numel(periods), sa(p)=pseudo_sa(time,accel,periods(p),0.05,cfg); end
    hPeriods=(0.1:0.1:2.5); psv=zeros(size(hPeriods));
    for p=1:numel(hPeriods), [~,psv(p)]=pseudo_sa(time,accel,hPeriods(p),0.05,cfg); end
    housner=trapz(hPeriods,psv);
    accelMS2=accel*cfg.features.gravity_m_s2;
    arias=cumtrapz(time,accelMS2.^2)*pi/(2*cfg.features.gravity_m_s2);
    d575=duration_between(arias,time,0.05,0.75); d2080=duration_between(arias,time,0.20,0.80);
    dt=median(diff(time)); centered=accelMS2-mean(accelMS2); amp=abs(fft(centered));
    freq=(0:numel(centered)-1)'/(numel(centered)*dt); use=freq>0 & freq<=1/(2*dt);
    power=amp(use).^2; f=freq(use); centroid=sum(f.*power)/max(sum(power),eps);
    bandwidth=sqrt(sum(((f-centroid).^2).*power)/max(sum(power),eps));
    X(i,numel(baseNames)+1:end)=[duration sa housner d575 d2080 bandwidth];
end
assert(all(isfinite(X(:))));
groups.base=1:9; groups.duration=1:10; groups.spectral=1:16; groups.all=1:size(X,2);
end

function [saG,psv]=pseudo_sa(time,accelG,period,zeta,cfg)
dt=median(diff(time)); uniform=(time(1):dt:time(end))';
if numel(uniform)~=numel(time) || max(abs(uniform-time(1:numel(uniform))))>1e-6*max(1,time(end)-time(1))
    ag=interp1(time,accelG,uniform,'linear',0)*cfg.features.gravity_m_s2;
else
    ag=accelG*cfg.features.gravity_m_s2;
end
ag=ag-mean(ag); omega=2*pi/period; c=2*zeta*omega; k=omega^2;
beta=1/4; gamma=1/2; a0=1/(beta*dt^2); a1=gamma/(beta*dt);
a2=1/(beta*dt); a3=1/(2*beta)-1; a4=gamma/beta-1; a5=dt*(gamma/(2*beta)-1);
khat=k+a0+a1*c; u=0; v=0; ar=-ag(1); maxU=0;
for j=2:numel(ag)
    effective=-ag(j)+(a0*u+a2*v+a3*ar)+c*(a1*u+a4*v+a5*ar);
    unew=effective/khat; anew=a0*(unew-u)-a2*v-a3*ar;
    vnew=v+dt*((1-gamma)*ar+gamma*anew); u=unew; v=vnew; ar=anew;
    maxU=max(maxU,abs(u));
end
psv=omega*maxU; saG=omega^2*maxU/cfg.features.gravity_m_s2;
end

function value=duration_between(cumulative,time,p1,p2)
total=cumulative(end); if total<=0, value=0; return; end
value=crossing(cumulative,time,p2*total)-crossing(cumulative,time,p1*total);
end
function value=crossing(cumulative,time,target)
idx=find(cumulative>=target,1); if isempty(idx),value=time(end);elseif idx==1,value=time(1);
else
    x=cumulative(idx-1:idx); y=time(idx-1:idx);
    if x(2)==x(1),value=y(2);else,value=interp1(x,y,target);end
end
end
