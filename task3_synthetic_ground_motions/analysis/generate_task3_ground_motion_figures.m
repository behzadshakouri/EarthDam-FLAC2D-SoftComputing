function path = generate_task3_ground_motion_figures(outputDir)
%GENERATE_TASK3_GROUND_MOTION_FIGURES Characterize the 150 synthetic motions.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_task3;cfg=task3_config(root);
if nargin<1||isempty(outputDir),outputDir=fullfile(cfg.output_root,'compact_pointwise_fmrvr');end
if ~exist(outputDir,'dir'),mkdir(outputDir);end
raw=load(cfg.raw.task3_data_file,'Task3');prepared=load(fullfile(cfg.results_dir,'task3_prepared_dataset.mat'),'dataset');
dataset=prepared.dataset;X=double(dataset.X);names=string(dataset.feature_names);
pga=X(:,names=="PGA_g");duration=arrayfun(@(q) max(double(q.time))-min(double(q.time)),raw.Task3.Inputs.InputsMatrix)';
[~,order]=sort(pga);chosen=order(round(linspace(1,numel(order),6)));
f=figure('Visible','off','Color','w','Position',[60 60 1200 820]);t=tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(t);hold(ax,'on');
colors=[0.16 0.32 0.75; 0.10 0.55 0.72; 0.13 0.67 0.53; ...
        0.72 0.68 0.19; 0.91 0.49 0.16; 0.76 0.20 0.33];
offsets=1:6;
for j=1:6
    gm=raw.Task3.Inputs.InputsMatrix(chosen(j));
    time=double(gm.time(:)); accel=double(gm.accel(:));
    plot(ax,time,offsets(j)+0.38*accel/max(abs(accel)), ...
        'Color',colors(j,:),'LineWidth',.9);
end
xlabel(ax,'Time (s)'); ylabel(ax,'Representative record');
yticks(ax,offsets); yticklabels(ax,compose('R%d (%.2fg)',chosen,pga(chosen)));
ylim(ax,[0.45 6.55]); title(ax,'Six representative motions (individually normalized)');
grid(ax,'on'); ax.YGrid='off';
ax=nexttile(t); hold(ax,'on');
scatter(ax,duration,pga,30,X(:,names=="Arias_m_s"),'filled', ...
    'DisplayName','150 synthetic motions');
trendX=linspace(min(duration),max(duration),200)';
logFit=polyfit(log(duration),log(pga),1);
trendY=exp(polyval(logFit,log(trendX)));
plot(ax,trendX,trendY,'k--','LineWidth',1.8,'DisplayName','Log--log least-squares trend');
grid(ax,'on'); cb=colorbar(ax); cb.Label.String='Arias intensity (m/s)';
xlabel(ax,'Record duration (s)');ylabel(ax,'PGA (g)');title(ax,'Duration--intensity coverage');
legend(ax,'Location','northeast','FontSize',8,'Box','off');
periods=.10:.01:3.00;spectra=zeros(cfg.num_realizations,numel(periods));
for i=1:cfg.num_realizations
    gm=raw.Task3.Inputs.InputsMatrix(i);
    for j=1:numel(periods),spectra(i,j)=spectral_acceleration(double(gm.time),double(gm.accel),periods(j),cfg.features.gravity_m_s2);end
end
ax=nexttile(t);hold(ax,'on');for i=1:size(X,1),plot(ax,periods,spectra(i,:),'-','Color',[.82 .87 .92], ...
        'HandleVisibility','off');end
plot(ax,periods,median(spectra,1),'-','Color',[.05 .30 .62],'LineWidth',2.3, ...
    'DisplayName','Ensemble median');
set(ax,'XScale','log');grid(ax,'on');xlabel(ax,'Oscillator period (s)');ylabel(ax,'S_a (g)');
title(ax,'5%-damped spectra (0.01-s period spacing)');
legend(ax,'Location','northeast','FontSize',8,'Box','off');
ax=nexttile(t);histogram(ax,duration,12,'FaceColor',[.85 .33 .10]);grid(ax,'on');xlabel(ax,'Record duration (s)');ylabel(ax,'Count');title(ax,'Unequal native durations');
set(findall(f,'Type','axes'),'FontName','Arial','FontSize',10,'TickDir','out','Box','on');
path=fullfile(outputDir,'task3_ground_motion_characterization.png');exportgraphics(f,path,'Resolution',300);
exportgraphics(f,fullfile(outputDir,'task3_ground_motion_characterization.pdf'),'ContentType','vector');close(f);
end

function sa=spectral_acceleration(time,accelG,period,g)
time=double(time(:));accelG=double(accelG(:));dt=median(diff(time));omega=2*pi/period;zeta=.05;c=2*zeta*omega;k=omega^2;
beta=1/4;gamma=1/2;a0=1/(beta*dt^2);a1=gamma/(beta*dt);a2=1/(beta*dt);a3=1/(2*beta)-1;a4=gamma/beta-1;a5=dt*(gamma/(2*beta)-1);
khat=k+a0+a1*c;ag=(accelG-mean(accelG))*g;u=0;v=0;ar=-ag(1);maximum=0;
for q=2:numel(ag)
    effective=-ag(q)+(a0*u+a2*v+a3*ar)+c*(a1*u+a4*v+a5*ar);unew=effective/khat;
    anew=a0*(unew-u)-a2*v-a3*ar;vnew=v+dt*((1-gamma)*ar+gamma*anew);u=unew;v=vnew;ar=anew;maximum=max(maximum,abs(u));
end
sa=omega^2*maximum/g;
end
