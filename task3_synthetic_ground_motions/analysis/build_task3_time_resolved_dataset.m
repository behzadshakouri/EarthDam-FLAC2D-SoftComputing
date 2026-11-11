function data=build_task3_time_resolved_dataset(Task3,dataset,audit,cfg,samplesPerRecord)
%BUILD_TASK3_TIME_RESOLVED_DATASET Task 2-style native-duration envelopes.
% Each realization contributes an equal number of time samples. Response
% envelopes and cumulative excitation features stop before common runaway.
if nargin<5 || isempty(samplesPerRecord), samplesPerRecord=40; end
[recordFeatures,recordNames,groups]=build_task3_augmented_features(Task3,cfg);
recordFeatures=recordFeatures(:,groups.spectral); recordNames=recordNames(groups.spectral);
dynamicNames=["elapsed_time_s" "duration_fraction" "abs_accel_g" "running_PGA_g" ...
    "running_PGV_m_s" "running_PGD_m" "running_Arias_m_s" "Arias_fraction" ...
    "running_CAV_m_s" "CAV_fraction" "running_RMS_g" ...
    "running_Sa_0p1s_g" "running_Sa_0p2s_g" "running_Sa_0p5s_g" ...
    "running_Sa_1p0s_g" "running_Sa_2p0s_g" "running_Sa_3p0s_g"];
nRows=cfg.num_realizations*samplesPerRecord; X=nan(nRows,numel(recordNames)+numel(dynamicNames));
Y=nan(nRows,cfg.num_outputs); realization=zeros(nRows,1); time=zeros(nRows,1); q=0;
dictionary=dataset.output_dictionary; g=cfg.features.gravity_m_s2;
for i=1:cfg.num_realizations
    inputTime=double(Task3.Inputs.InputsMatrix(i).time(:)); a=double(Task3.Inputs.InputsMatrix(i).accel(:));
    t=double(Task3.Outputs.dytime{i}(:));
    duration=inputTime(end)-inputTime(1); centered=a-mean(a);
    velocity=cumtrapz(inputTime,centered*g); displacement=cumtrapz(inputTime,velocity);
    runningPGA=cummax(abs(a)); runningPGV=cummax(abs(velocity)); runningPGD=cummax(abs(displacement));
    arias=cumtrapz(inputTime,(a*g).^2)*pi/(2*g); cav=cumtrapz(inputTime,abs(a*g));
    rms=sqrt(cumtrapz(inputTime,a.^2)./max(inputTime-inputTime(1),median(diff(inputTime))));
    periods=[.1 .2 .5 1 2 3]; runningSa=zeros(numel(a),numel(periods));
    for periodIndex=1:numel(periods)
        runningSa(:,periodIndex)=running_spectral_acceleration(inputTime,a,periods(periodIndex),g);
    end
    dynamicInput=[inputTime-inputTime(1),(inputTime-inputTime(1))/max(duration,eps),abs(a),runningPGA,runningPGV,runningPGD, ...
        arias,arias/max(arias(end),eps),cav,cav/max(cav(end),eps),rms,runningSa];
    dynamic=interp1(inputTime,dynamicInput,t,'linear','extrap');
    validInput=true(size(t)); if isfinite(audit.screening_onset_s(i)), validInput=t<audit.screening_onset_s(i); end
    last=find(validInput,1,'last'); assert(last>=cfg.qc.minimum_history_length);
    selected=unique(max(1,min(last,round(linspace(1,last,samplesPerRecord)))),'stable');
    if numel(selected)<samplesPerRecord
        selected=[selected repmat(selected(end),1,samplesPerRecord-numel(selected))];
    end
    response=zeros(numel(t),cfg.num_outputs);
    for k=1:cfg.num_outputs
        p=dictionary(k).point; r=dictionary(k).response;
        raw=double(Task3.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r)){i}(:));
        assert(numel(raw)==numel(t));
        if ismember(r,[3 4 5]), envelope=cummax(abs(raw-raw(1))); else, envelope=cummax(abs(raw)); end
        response(:,k)=envelope;
    end
    rows=q+(1:samplesPerRecord); q=q+samplesPerRecord;
    X(rows,:)=[repmat(recordFeatures(i,:),samplesPerRecord,1) dynamic(selected,:)];
    Y(rows,:)=response(selected,:); realization(rows)=i; time(rows)=t(selected);
end
assert(all(isfinite(X(:))) && all(isfinite(Y(:))) && all(Y(:)>=0));
data=struct('X',X,'Y',Y,'realization_id',realization,'time_s',time, ...
    'feature_names',[recordNames dynamicNames],'samples_per_record',samplesPerRecord);
end

function runningSa=running_spectral_acceleration(time,accelG,period,g)
dt=median(diff(time)); omega=2*pi/period; zeta=.05; c=2*zeta*omega; k=omega^2;
beta=1/4; gamma=1/2; a0=1/(beta*dt^2); a1=gamma/(beta*dt);
a2=1/(beta*dt); a3=1/(2*beta)-1; a4=gamma/beta-1; a5=dt*(gamma/(2*beta)-1);
khat=k+a0+a1*c; ag=(accelG-mean(accelG))*g; u=0; v=0; ar=-ag(1);
runningSa=zeros(numel(ag),1); maximum=0;
for j=2:numel(ag)
    effective=-ag(j)+(a0*u+a2*v+a3*ar)+c*(a1*u+a4*v+a5*ar);
    unew=effective/khat; anew=a0*(unew-u)-a2*v-a3*ar;
    vnew=v+dt*((1-gamma)*ar+gamma*anew); u=unew; v=vnew; ar=anew;
    maximum=max(maximum,abs(u)); runningSa(j)=omega^2*maximum/g;
end
end
