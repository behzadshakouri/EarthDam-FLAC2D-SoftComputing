function plot_pga_cdfs_grid70_updated(FT_file, FULL_file, varargin)
% 7x10 grid of empirical CDFs of PGA-at-failure (X(:,16))
% rows = Responses, cols = Points
% Empty cells are shown as empty framed boxes (no skip text)
%
% Layout note:
% - A dedicated top annotation band is added so P1...P10 sit above the
%   first row of boxes rather than on the box line itself.

% =========================
% Parse
% =========================
p = inputParser;
p.addRequired('FT_file',   @(s)ischar(s)||isstring(s));
p.addRequired('FULL_file', @(s)ischar(s)||isstring(s));

p.addParameter('Points',        1:10);
p.addParameter('Responses',     1:7);
p.addParameter('FailureMode',   'response');
p.addParameter('MinFailed',     10);

p.addParameter('ShowMedian',    true);
p.addParameter('ShowN',         true);

p.addParameter('UseGlobalXLim', true);
p.addParameter('XLimPctl',      [1 99]);
p.addParameter('XLabel',        'PGA at failure');

p.addParameter('ResponseLabels', {}, @(c)iscell(c)||isstring(c));

p.addParameter('SaveDir',       '');
p.addParameter('ExportDPI',     300);

p.addParameter('FigPosition',   [60 60 4200 2800]);
p.addParameter('Padding',       'compact');
p.addParameter('TileSpacing',   'compact');
p.addParameter('FontName',      'Arial');
p.addParameter('FontSize',      12);
p.addParameter('LabelFontSize', 18);
p.addParameter('LineWidth',     1.6);
p.addParameter('NFontSize',     11);

p.parse(FT_file, FULL_file, varargin{:});
opt = p.Results;

Points    = opt.Points(:)';
Responses = opt.Responses(:)';
nP = numel(Points);
nR = numel(Responses);

% =========================
% Response labels
% =========================
respLabels = opt.ResponseLabels;
if isstring(respLabels), respLabels = cellstr(respLabels); end

if isempty(respLabels)
    % default: use "R#" for the provided Responses list
    respLabels = cell(max(Responses),1);
    for rr = 1:max(Responses)
        respLabels{rr} = sprintf('R%d', rr);
    end
else
    if numel(respLabels) < max(Responses)
        error('ResponseLabels must cover at least max(Responses).');
    end
    respLabels = respLabels(:);
end

% =========================
% Load
% =========================
Sf = load(char(opt.FT_file));
if ~isfield(Sf,'FT'), error('FT not found inside: %s', char(opt.FT_file)); end
FT = Sf.FT;

Sx = load(char(opt.FULL_file),'FULL');
if ~isfield(Sx,'FULL'), error('FULL not found inside: %s', char(opt.FULL_file)); end
FULL = Sx.FULL;

nsample = getfield_fallback(FT,   {'meta','nsample'}, ...
          getfield_fallback(FULL, {'info','nsample'}, 300));

% =========================
% Compute PGA at failure
% =========================
PGAfail = cell(nR,nP);
allPF = [];

for ir = 1:nR
    r = Responses(ir);
    for ip = 1:nP
        pnt = Points(ip);

        [failed_sim, step_fail] = get_fail_pair(FT, opt.FailureMode, pnt, r, nsample);

        failed_sim = logical(failed_sim(:));
        step_fail  = step_fail(:);

        % pad/trim to nsample
        if numel(failed_sim) < nsample
            failed_sim(end+1:nsample) = false;
        else
            failed_sim = failed_sim(1:nsample);
        end
        if numel(step_fail) < nsample
            step_fail(end+1:nsample) = NaN;
        else
            step_fail = step_fail(1:nsample);
        end

        if nnz(failed_sim) < opt.MinFailed
            PGAfail{ir,ip} = [];
            continue;
        end

        X16 = double(FULL.Point(pnt).X(:,16));
        nrows = numel(X16);

        pf = nan(nsample,1);
        for s = 1:nsample
            if ~failed_sim(s), continue; end
            st = round(step_fail(s));
            if ~isfinite(st) || st < 1, continue; end
            row = (st-1)*nsample + s;
            if row >= 1 && row <= nrows
                pf(s) = X16(row);
            end
        end

        pf = pf(isfinite(pf));
        if numel(pf) < opt.MinFailed
            pf = [];
        end

        PGAfail{ir,ip} = pf;
        allPF = [allPF; pf(:)]; %#ok<AGROW>
    end
end

% =========================
% Global X limits
% =========================
xlimUse = [];
xticksUse = [];

if opt.UseGlobalXLim && ~isempty(allPF)
    xl = prctile(allPF, opt.XLimPctl);
    xl = [floor(xl(1)*2)/2 , ceil(xl(2)*2)/2];
    if isfinite(xl(1)) && isfinite(xl(2)) && xl(2) > xl(1)
        xlimUse   = xl;
        xticksUse = xl(1):0.5:xl(2);
    end
end

% =========================
% Plot grid
% =========================
fig = figure('Color','w','Renderer','opengl');
set(fig,'Units','pixels','Position',opt.FigPosition);

% Use normal padding for compatibility across MATLAB versions
tl = tiledlayout(fig,nR,nP,...
    'Padding','normal',...
    'TileSpacing',char(opt.TileSpacing));

axGrid = gobjects(nR,nP);

for ir = 1:nR
    r = Responses(ir);
    for ip = 1:nP
        pnt = Points(ip);

        ax = nexttile(tl,(ir-1)*nP+ip);
        axGrid(ir,ip) = ax;
        set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize);

        box(ax,'on'); grid(ax,'on'); hold(ax,'on');
        ylim(ax,[0 1]);
        ax.YTick = [0 0.5 1];
        ax.YTickLabel = {'0','0.5','1'};
        ax.TickLength = [0 0];

        if ~isempty(xlimUse)
            xlim(ax,xlimUse);
            ax.XTick = xticksUse;
        end

        pf = PGAfail{ir,ip};
        if ~isempty(pf)
            [F,x] = ecdf(pf);
            plot(ax,x,F,'LineWidth',opt.LineWidth);

            if opt.ShowMedian
                med = median(pf);
                plot(ax,[med med],[0 1],'--','LineWidth',1.1,'HandleVisibility','off');
            end

            if opt.ShowN
                text(ax,0.02,0.98,sprintf('n=%d',numel(pf)),...
                    'Units','normalized',...
                    'VerticalAlignment','top',...
                    'FontSize',opt.NFontSize,...
                    'FontWeight','normal');
            end
        end
        hold(ax,'off');

        % left labels only
        if ip==1
            ylabel(ax,respLabels{r},...
                'FontWeight','bold',...
                'FontSize',opt.LabelFontSize,...
                'Interpreter','tex');
        else
            ax.YTickLabel = [];
        end

        % hide x tick labels except bottom row
        if ir~=nR
            ax.XTickLabel = [];
        end
    end
end

xlabel(tl,opt.XLabel,'Interpreter','none',...
    'FontName',opt.FontName,'FontSize',opt.LabelFontSize);
ylabel(tl,'CDF','Interpreter','none',...
    'FontName',opt.FontName,'FontSize',opt.LabelFontSize);

% title(tl, sprintf('PGA-at-failure CDFs (%s mode)', char(opt.FailureMode)), ...
%     'FontName', opt.FontName, 'FontSize', opt.LabelFontSize);

% =========================
% Column headers P1...P10
% Dedicated top band above first row
% =========================
drawnow;

for ip = 1:nP
    axTop = axGrid(1,ip);
    pos = axTop.Position;   % normalized figure coordinates

    annotation(fig,'textbox', ...
        [pos(1), pos(2)+pos(4)+0.010, pos(3), 0.028], ...
        'String', sprintf('P%d', Points(ip)), ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'LineStyle', 'none', ...
        'Interpreter', 'none', ...
        'FontName', opt.FontName, ...
        'FontSize', opt.LabelFontSize, ...
        'FontWeight', 'bold', ...
        'FitBoxToText', 'off');
end

% =========================
% Save
% =========================
if ~isempty(opt.SaveDir)
    sd = char(opt.SaveDir);
    if ~exist(sd,'dir'), mkdir(sd); end
    outPng = fullfile(sd, sprintf('CDF_PGAfail_GRID70_mode_%s.png', char(opt.FailureMode)));
    save_png_rgbimage(fig,outPng,opt.ExportDPI);
    fprintf('Saved:\n  %s\n', outPng);
end

end % main

% =====================================================================
% Subfunctions (MUST be in same file)
% =====================================================================
function save_png_rgbimage(fig, filename, dpi)
drawnow;
img = print(fig,'-RGBImage',sprintf('-r%d',dpi));
imwrite(img, filename);
end

function v = getfield_fallback(S, pathCell, defaultVal)
v = defaultVal;
try
    t = S;
    for k=1:numel(pathCell)
        if ~isstruct(t) || ~isfield(t, pathCell{k})
            v = defaultVal;
            return;
        end
        t = t.(pathCell{k});
    end
    v = t;
catch
    v = defaultVal;
end
end

function [failed_sim, step_fail] = get_fail_pair(FT, mode, pnt, r, nsample)
failed_sim = false(nsample,1);
step_fail  = nan(nsample,1);

mode = lower(string(mode));
switch mode
    case "response"
        d = FT.resp(pnt,r).det;
    case "point"
        d = FT.point(pnt);
    case "global"
        d = FT.global;
    otherwise
        error('Unknown FailureMode="%s".', mode);
end

if isfield(d,'failed_sim') && ~isempty(d.failed_sim), failed_sim = d.failed_sim(:); end
if isfield(d,'step_fail')  && ~isempty(d.step_fail),  step_fail  = d.step_fail(:);  end
end