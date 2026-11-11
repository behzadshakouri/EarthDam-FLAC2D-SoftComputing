function files = generate_task4_iaa_spectral_figures(outputDir)
%GENERATE_TASK4_IAA_SPECTRAL_FIGURES Task 4 PSA and PSV heatmaps.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_task4;
cfg=task4_config(root);
if nargin<1||isempty(outputDir)
    outputDir=fullfile(cfg.output_root,'pointwise_fmrvr');
end
if ~exist(outputDir,'dir'),mkdir(outputDir);end
[time,acceleration]=load_ground_motion(cfg.raw.ground_motion_file,cfg.expected_end_time_s);
periods=linspace(.05,2,120)';
[psa,psv]=running_spectra(time,acceleration*9.80665,periods,.05,9.80665);
files=struct;
files.psa=write_heatmap(time,periods,psa,'PSA (g)', ...
    fullfile(outputDir,'task4_iaa_psa_heatmap'));
files.psv=write_heatmap(time,periods,psv,'PSV (m/s)', ...
    fullfile(outputDir,'task4_iaa_psv_heatmap'));
files.acceleration=write_acceleration(time,acceleration, ...
    fullfile(outputDir,'task4_iaa_acceleration_running_pga'));
files.combined=write_combined_heatmaps(time,periods,psa,psv, ...
    fullfile(outputDir,'task4_iaa_spectral_heatmaps'));
files.data=fullfile(outputDir,'task4_iaa_spectral_heatmap_data.mat');
damping_ratio=.05;source_file=cfg.raw.ground_motion_file;
save(files.data,'time','acceleration','periods','psa','psv', ...
    'damping_ratio','source_file','-v7.3');
end

function [time,acceleration]=load_ground_motion(path,endTime)
fid=fopen(path,'r');
assert(fid>=0,'Task4:GroundMotion','Cannot open configured ground motion: %s',path);
cleanup=onCleanup(@()fclose(fid));
fgetl(fid);metadata=sscanf(fgetl(fid),'%f');values=textscan(fid,'%f');
assert(numel(metadata)>=2&&metadata(2)>0,'Task4:GroundMotion','Invalid ground-motion header.');
acceleration=double(values{1});
assert(numel(acceleration)>10&&all(isfinite(acceleration)), ...
    'Task4:GroundMotion','Ground-motion samples must be finite.');
dt=metadata(2);sampleCount=min(numel(acceleration),round(endTime/dt)+1);
acceleration=acceleration(1:sampleCount);time=(0:sampleCount-1)'*dt;
end

function [psa,psv]=running_spectra(time,groundAcceleration,periods,zeta,g0)
n=numel(time);m=numel(periods);dt=median(diff(time));
psa=zeros(m,n);psv=zeros(m,n);beta=1/4;gamma=1/2;
for j=1:m
    omega=2*pi/periods(j);stiffness=omega^2;damping=2*zeta*omega;
    displacement=0;velocity=0;
    relativeAcceleration=-groundAcceleration(1)-damping*velocity-stiffness*displacement;
    maximumDisplacement=0;
    a0=1/(beta*dt^2);a1=gamma/(beta*dt);a2=1/(beta*dt);
    a3=1/(2*beta)-1;a4=gamma/beta-1;a5=dt*(gamma/(2*beta)-1);
    effectiveStiffness=stiffness+a0+a1*damping;
    for i=2:n
        effectiveForce=-groundAcceleration(i)+(a0*displacement+a2*velocity+ ...
            a3*relativeAcceleration)+damping*(a1*displacement+a4*velocity+ ...
            a5*relativeAcceleration);
        newDisplacement=effectiveForce/effectiveStiffness;
        newAcceleration=a0*(newDisplacement-displacement)-a2*velocity- ...
            a3*relativeAcceleration;
        newVelocity=velocity+dt*((1-gamma)*relativeAcceleration+gamma*newAcceleration);
        displacement=newDisplacement;velocity=newVelocity;
        relativeAcceleration=newAcceleration;
        maximumDisplacement=max(maximumDisplacement,abs(displacement));
        psa(j,i)=omega^2*maximumDisplacement/g0;
        psv(j,i)=omega*maximumDisplacement;
    end
end
end

function files=write_heatmap(time,periods,values,colorbarLabel,pathStem)
f=figure('Visible','off','Color','w','Position',[100 100 900 500]);
colormap(f,parula);
ax=axes(f);plot_heatmap(ax,time,periods,values,colorbarLabel,'');
pngPath=[pathStem '.png'];pdfPath=[pathStem '.pdf'];
drawnow;print(f,pngPath,'-dpng','-r300');
print(f,pdfPath,'-dpdf','-painters','-bestfit');close(f);
files=struct('png',pngPath,'pdf',pdfPath);
end

function files=write_acceleration(time,acceleration,pathStem)
% Retain the acceleration/PGA diagnostic as a reproducible supporting output;
% it is intentionally not included in the manuscript's combined Figure 2.
f=figure('Visible','off','Color','w','Position',[100 100 900 420]);
ax=axes(f);runningPGA=cummax(abs(acceleration));
plot(ax,time,acceleration,'Color',[.20 .20 .24],'LineWidth',.65, ...
    'DisplayName','Acceleration');hold(ax,'on');
plot(ax,time,runningPGA,'Color',[.85 .325 .098],'LineWidth',1.15, ...
    'DisplayName','Running PGA');
plot(ax,time,-runningPGA,'Color',[.85 .325 .098],'LineWidth',1.15, ...
    'HandleVisibility','off');
yline(ax,0,'-','Color',[.65 .65 .65],'LineWidth',.55,'HandleVisibility','off');
xlim(ax,[time(1) time(end)]);xticks(ax,0:5:20);
xlabel(ax,'Time (s)');ylabel(ax,'Acceleration (g)');
legend(ax,'Location','northwest','Orientation','horizontal','Box','off','FontSize',9);
set(ax,'FontName','Arial','FontSize',10.5,'LineWidth',.8,'TickDir','out', ...
    'Layer','top','XGrid','off','YGrid','on','GridAlpha',.12);
pngPath=[pathStem '.png'];pdfPath=[pathStem '.pdf'];
drawnow;exportgraphics(f,pngPath,'Resolution',300);
exportgraphics(f,pdfPath,'ContentType','vector');close(f);
files=struct('png',pngPath,'pdf',pdfPath);
end

function files=write_combined_heatmaps(time,periods,psa,psv,pathStem)
% Combine the two running spectral summaries in a Task 4-specific style.
f=figure('Visible','off','Color','w','Position',[100 100 1050 760]);
colormap(f,task4_spectral_map(256));
ax1=axes(f,'Position',[.09 .55 .78 .39]);
plot_heatmap(ax1,time,periods,psa,'PSA (g)','(a)');xlabel(ax1,'');
ax2=axes(f,'Position',[.09 .08 .78 .39]);
plot_heatmap(ax2,time,periods,psv,'PSV (m/s)','(b)');
pngPath=[pathStem '.png'];pdfPath=[pathStem '.pdf'];
drawnow;exportgraphics(f,pngPath,'Resolution',300);
exportgraphics(f,pdfPath,'ContentType','vector');close(f);
files=struct('png',pngPath,'pdf',pdfPath);
end

function plot_heatmap(ax,time,periods,values,colorbarLabel,panelLabel)
imagesc(ax,time,periods,values);set(ax,'YDir','normal');hold(ax,'on');
finiteValues=values(isfinite(values));
if ~isempty(finiteValues)&&max(finiteValues)>min(finiteValues)
    levels=linspace(min(finiteValues),max(finiteValues),9);
    contour(ax,time,periods,values,levels,'Color',[.92 .92 .92],'LineWidth',.45);
end

xlim(ax,[time(1) time(end)]);ylim(ax,[periods(1) periods(end)]);
xlabel(ax,'Time (s)');ylabel(ax,'Period (s)');
cb=colorbar(ax);cb.Label.String=colorbarLabel;cb.Label.FontName='Arial';cb.Label.FontSize=11;
box(ax,'on');grid(ax,'off');
set(ax,'FontName','Arial','FontSize',10.5,'LineWidth',.8,'TickDir','out', ...
    'Layer','top','XTick',0:5:20,'YTick',.25:.25:2);
if ~isempty(panelLabel)
    text(ax,.012,.94,panelLabel,'Units','normalized','FontName','Arial', ...
        'FontSize',11,'FontWeight','bold','Color','k','BackgroundColor','w', ...
        'Margin',2,'VerticalAlignment','top');
end
end

function cmap=task4_spectral_map(n)
% A perceptually ordered blue--cyan--yellow--red map defined locally so the
% figure remains reproducible with MATLAB releases that predate turbo().
if nargin<1
    n=256;
end
anchors=[0.08 0.12 0.42; ...
         0.05 0.48 0.72; ...
         0.12 0.72 0.66; ...
         0.95 0.82 0.24; ...
         0.78 0.18 0.12];
x=linspace(0,1,size(anchors,1));
cmap=interp1(x,anchors,linspace(0,1,n),'pchip');
cmap=max(0,min(1,cmap));
end
