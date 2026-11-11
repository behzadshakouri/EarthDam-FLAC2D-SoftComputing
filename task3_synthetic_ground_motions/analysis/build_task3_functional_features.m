function [X,names]=build_task3_functional_features(Task3,cfg)
%BUILD_TASK3_FUNCTIONAL_FEATURES Time-frequency and energy-path descriptors.
[Xdense,denseNames]=build_task3_dense_spectral_features(Task3,cfg);
q=(.05:.05:.95); nBands=20; nWindows=16; n=cfg.num_realizations;
names=[denseNames compose('Arias_t%02d_norm',round(100*q)) ...
    compose('FFT_band_%02d_logpower',1:nBands) compose('window_%02d_rms_g',1:nWindows) ...
    compose('window_%02d_peak_g',1:nWindows)];
X=nan(n,numel(names)); X(:,1:size(Xdense,2))=Xdense; start=size(Xdense,2);
for i=1:n
    gm=Task3.Inputs.InputsMatrix(i); t=double(gm.time(:)); a=double(gm.accel(:)); duration=t(end)-t(1);
    energy=cumtrapz(t,(a*cfg.features.gravity_m_s2).^2); total=energy(end);
    tq=zeros(size(q));
    if total>0
        for j=1:numel(q), tq(j)=crossing(energy,t,q(j)*total); end
        tq=(tq-t(1))/max(duration,eps);
    end
    dt=median(diff(t)); centered=a-mean(a); amp=abs(fft(centered));
    freq=(0:numel(a)-1)'/(numel(a)*dt); use=freq>0 & freq<=min(20,1/(2*dt)); f=freq(use); power=amp(use).^2;
    edges=logspace(log10(.1),log10(max(.11,max(f))),nBands+1); band=zeros(1,nBands);
    for j=1:nBands, band(j)=log10(sum(power(f>=edges(j)&f<edges(j+1)))+eps); end
    rmsv=zeros(1,nWindows); peak=zeros(1,nWindows); u=(t-t(1))/max(duration,eps);
    for j=1:nWindows
        take=u>=(j-1)/nWindows & (u<j/nWindows | (j==nWindows & u<=1));
        if any(take), rmsv(j)=sqrt(mean(a(take).^2));peak(j)=max(abs(a(take)));end
    end
    X(i,start+(1:numel(q)+nBands+2*nWindows))=[tq band rmsv peak];
end
assert(all(isfinite(X(:))));
end
function value=crossing(cumulative,time,target)
idx=find(cumulative>=target,1);if isempty(idx),value=time(end);elseif idx==1,value=time(1);else
    x=cumulative(idx-1:idx);y=time(idx-1:idx);if x(2)==x(1),value=y(2);else,value=interp1(x,y,target);end
end
end
