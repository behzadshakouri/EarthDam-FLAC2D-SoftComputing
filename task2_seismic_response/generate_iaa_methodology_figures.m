function files = generate_iaa_methodology_figures(inputFile,outDir,varargin)
%GENERATE_IAA_METHODOLOGY_FIGURES Recreate the IAA figures used in Figure 3.
% MATLAB R2020a compatible.
%
% files = generate_iaa_methodology_figures
% files = generate_iaa_methodology_figures(inputFile,outDir)
% files = generate_iaa_methodology_figures(...,'InputUnits','g')
%
% The input must contain the signed acceleration history, not its monotonic
% cumulative PGA envelope. A two-column file is interpreted as time and
% acceleration; a one-column file uses Dt (default 0.01 s).

if nargin < 1, inputFile = ''; end
if nargin < 2, outDir = ''; end

p = inputParser;
p.addParameter('DampingRatio',0.05,@(x)isnumeric(x)&&isscalar(x)&&x>=0&&x<1);
p.addParameter('Periods',linspace(0.05,2.0,120),@(x)isnumeric(x)&&isvector(x)&&all(x>0));
p.addParameter('Dt',0.01,@(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('InputUnits','auto',@(x)ischar(x)||isstring(x));
p.addParameter('TimeColumn',[],@(x)isempty(x)||(isnumeric(x)&&isscalar(x)&&x>=1));
p.addParameter('AccelerationColumn',[],@(x)isempty(x)||(isnumeric(x)&&isscalar(x)&&x>=1));
p.addParameter('ExportDPI',300,@(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('MakeIAAPlot',true,@(x)islogical(x)&&isscalar(x));
p.addParameter('EnvelopeSteps',10,@(x)isnumeric(x)&&isscalar(x)&&x>=1&&fix(x)==x);
p.addParameter('ContourLevels',10,@(x)isnumeric(x)&&isscalar(x)&&x>=2&&fix(x)==x);
p.parse(varargin{:});
opt = p.Results;

root = fileparts(mfilename('fullpath'));
if isempty(inputFile), inputFile = find_iaa_input(root); end
if isempty(outDir), outDir = fullfile(root,'results','final_manuscript_figures'); end
if ~exist(outDir,'dir'), mkdir(outDir); end

[t,ag,sourceUnits] = load_signed_acceleration(inputFile,opt);
g0 = 9.80665;
if strcmpi(sourceUnits,'g'), agSI = ag*g0; else, agSI = ag; end

periods = opt.Periods(:);
[psaG,psv] = running_spectra(t,agSI,periods,opt.DampingRatio,g0);

files = struct;
files.psa = fullfile(outDir,'a_PSA_heatmap.png');
files.psv = fullfile(outDir,'b_PSV_heatmap.png');
files.iaa = '';
files.data = fullfile(outDir,'IAA_spectral_heatmap_data.mat');

write_heatmap(t,periods,psaG,'PSA (g)',files.psa,opt.ExportDPI,opt.ContourLevels);
write_heatmap(t,periods,psv,'PSV (m/s)',files.psv,opt.ExportDPI,opt.ContourLevels);

if opt.MakeIAAPlot
    files.iaa = fullfile(outDir,'IAA.png');
    write_iaa_plot(t,agSI/g0,files.iaa,opt.ExportDPI,opt.EnvelopeSteps);
end

dampingRatio = opt.DampingRatio; %#ok<NASGU>
sourceFile = inputFile; %#ok<NASGU>
save(files.data,'t','ag','agSI','periods','psaG','psv','dampingRatio', ...
    'sourceFile','sourceUnits','-v7.3');
fprintf('IAA methodology figures written to %s\n',outDir);
end

function inputFile = find_iaa_input(root)
candidates = {};
userPathsFile = fullfile(root,'config','task2_user_paths.m');
if exist(userPathsFile,'file')
    try
        configDir = fileparts(userPathsFile);
        wasOnPath = contains([path pathsep],[configDir pathsep]);
        if ~wasOnPath, addpath(configDir); end
        userPaths = task2_user_paths();
        if ~wasOnPath, rmpath(configDir); end
        if isfield(userPaths,'raw') && isfield(userPaths.raw,'pga_file') && ...
                ~isempty(userPaths.raw.pga_file)
            candidates{end+1} = userPaths.raw.pga_file; %#ok<AGROW>
        end
    catch err
        if exist('configDir','var') && exist('wasOnPath','var') && ~wasOnPath
            rmpath(configDir);
        end
        warning('Task2:UserPaths','Could not read task2_user_paths.m: %s',err.message);
    end
end
names = {'IAAPGA20sec.xlsx','IAA-20sec.xlsx','IAAPGA20sec.mat'};
folders = {root,fullfile(root,'data'),fileparts(root)};
for i = 1:numel(folders)
    for j = 1:numel(names)
        candidates{end+1} = fullfile(folders{i},names{j}); %#ok<AGROW>
    end
end
for i = 1:numel(candidates)
    if exist(candidates{i},'file'), inputFile = candidates{i}; return; end
end
error('Task2:MissingIAAInput',[ ...
    'No IAA input was found. Pass its path explicitly or set raw.pga_file ' ...
    'in config/task2_user_paths.m.']);
end

function [t,a,units] = load_signed_acceleration(file,opt)
if ~exist(file,'file'), error('Task2:MissingIAAInput','File not found: %s',file); end
[~,~,ext] = fileparts(file);
if strcmpi(ext,'.mat')
    s = load(file); names = fieldnames(s); raw = [];
    for i = 1:numel(names)
        value = s.(names{i});
        if isnumeric(value) && ismatrix(value) && numel(value)>10
            raw = value; break;
        end
    end
    if isempty(raw), error('Task2:InvalidIAAInput','No usable numeric array in %s.',file); end
else
    raw = readmatrix(file);
end
raw = raw(~all(~isfinite(raw),2),:);
raw = raw(:,~all(~isfinite(raw),1));
if isempty(raw), error('Task2:InvalidIAAInput','No finite numeric data in %s.',file); end

if size(raw,2)==1
    a = raw(:,1); t = (1:numel(a))'*opt.Dt;
else
    tc = opt.TimeColumn; ac = opt.AccelerationColumn;
    if isempty(tc)
        tc = find(arrayfun(@(j)is_time_candidate(raw(:,j)),1:size(raw,2)),1);
        if isempty(tc), tc = 1; end
    end
    if isempty(ac)
        choices = setdiff(1:size(raw,2),tc);
        spreads = arrayfun(@(j)std(raw(isfinite(raw(:,j)),j)),choices);
        [~,k] = max(spreads); ac = choices(k);
    end
    t = raw(:,tc); a = raw(:,ac);
end
keep = isfinite(t)&isfinite(a); t=t(keep); a=a(keep);
[t,order] = sort(t); a=a(order);
[t,uniqueRows] = unique(t,'stable'); a=a(uniqueRows);
if numel(t)<10 || any(diff(t)<=0)
    error('Task2:InvalidIAAInput','The time and acceleration series is invalid or too short.');
end
tol = max(1e-10,1e-7*max(abs(a)));
if all(a>=-tol) && all(diff(a)>=-tol)
    error('Task2:PGAEnvelopeNotMotion',[ ...
        'The selected series is a monotonic cumulative PGA envelope. ' ...
        'PSA/PSV spectra require the signed IAA acceleration history.']);
end
dt = median(diff(t));
if max(abs(diff(t)-dt)) > max(1e-9,1e-4*dt)
    tu = (t(1):dt:t(end))'; a = interp1(t,a,tu,'linear'); t = tu;
end
units = lower(char(opt.InputUnits));
if strcmp(units,'auto')
    if max(abs(a))<=3, units='g'; else, units='m/s2'; end
end
if ~ismember(units,{'g','m/s2'})
    error('Task2:InvalidUnits','InputUnits must be auto, g, or m/s2.');
end
fprintf('Loaded %d samples from %s; interpreted acceleration as %s.\n',numel(a),file,units);
end

function tf = is_time_candidate(x)
x=x(isfinite(x)); tf=numel(x)>10 && all(diff(x)>0);
end

function [psaG,psv] = running_spectra(t,ag,periods,zeta,g0)
n=numel(t); m=numel(periods); dt=median(diff(t));
psaG=zeros(m,n); psv=zeros(m,n); beta=1/4; gamma=1/2;
for j=1:m
    w=2*pi/periods(j); k=w^2; c=2*zeta*w;
    u=0; v=0; acc=-ag(1)-c*v-k*u; umax=0;
    a0=1/(beta*dt^2); a1=gamma/(beta*dt); a2=1/(beta*dt);
    a3=1/(2*beta)-1; a4=gamma/beta-1; a5=dt*(gamma/(2*beta)-1);
    keff=k+a0+a1*c;
    for i=2:n
        peff=-ag(i)+(a0*u+a2*v+a3*acc)+c*(a1*u+a4*v+a5*acc);
        un=peff/keff;
        an=a0*(un-u)-a2*v-a3*acc;
        vn=v+dt*((1-gamma)*acc+gamma*an);
        u=un; v=vn; acc=an; umax=max(umax,abs(u));
        psaG(j,i)=w^2*umax/g0; psv(j,i)=w*umax;
    end
end
end

function write_iaa_plot(t,ag,file,dpi,nSteps)
envRun=cummax(abs(ag)); fitCoefficients=polyfit(t,envRun,1);
envLinear=max(polyval(fitCoefficients,t),0);
edges=linspace(t(1),t(end),nSteps+1); envStep=zeros(size(t));
for k=1:nSteps
    if k<nSteps, idx=t>=edges(k)&t<edges(k+1); else, idx=t>=edges(k)&t<=edges(k+1); end
    if any(idx), envStep(idx)=max(envRun(idx)); end
end
f=figure('Color','w','Visible','off','Position',[100 100 1200 450]);
plot(t,ag,'k','LineWidth',1.3); hold on;
plot(t,envRun,'r--','LineWidth',1.5); plot(t,-envRun,'r--','LineWidth',1.5);
plot(t,envLinear,'b:','LineWidth',2.0); plot(t,-envLinear,'b:','LineWidth',2.0);
plot(t,envStep,'m-.','LineWidth',1.7); plot(t,-envStep,'m-.','LineWidth',1.7);
grid on; xlabel('Time (s)','FontSize',20); ylabel('Acceleration (g)','FontSize',20);
set(gca,'FontName','Arial','FontSize',18);
lgd=legend({'IAA acceleration','PGA envelope (running max |a|)', ...
    'PGA envelope (linearized)',sprintf('PGA envelope (stepped, %d levels)',nSteps)}, ...
    'Location','northwest'); lgd.Box='off'; lgd.FontSize=16;
print(f,file,'-dpng',sprintf('-r%d',dpi)); close(f);
end

function write_heatmap(t,periods,z,labelText,file,dpi,nContourLevels)
f=figure('Color','w','Visible','off','Position',[100 100 900 520]);
imagesc(t,periods,z); set(gca,'YDir','reverse'); colormap(parula); box on; hold on;
finiteValues=z(isfinite(z));
if ~isempty(finiteValues) && max(finiteValues)>min(finiteValues)
    levels=linspace(min(finiteValues),max(finiteValues),nContourLevels);
    contour(t,periods,z,levels,'k','LineWidth',0.8);
end
xlabel('Time (s)','FontSize',20); ylabel('Period (s)','FontSize',20);
cb=colorbar; ylabel(cb,labelText); cb.Label.FontSize=18;
set(gca,'FontName','Arial','FontSize',18);
print(f,file,'-dpng',sprintf('-r%d',dpi)); close(f);
end
