function plot_grid_median_failure_pga_7x10_updated(full_mat, FT_file, varargin)
% plot_grid_median_failure_pga_7x10_updated(full_mat, FT_file, ...)
% Heatmap (7x10): median PGA at first failure, using FULL.Point(p).X(:,16).
% Adds % failed sims per cell (optional).
%
% Requires:
%   FULL.Point(p).X is time-major stacked by sim (same as your training layout)
%   FT.* provides step_fail and failed_sim for response/point/global modes.
%
% House style:
% - NO titles anywhere
% - P labels only on TOP
% - Response names via ResponseLabels (tex)
% - Arial fonts + consistent sizing
% - Robust PNG saving via print('-RGBImage')
% - First response in Responses appears at the TOP

% ----------------------------
% Parse inputs
% ----------------------------
p = inputParser;
p.addRequired('full_mat', @(s)ischar(s)||isstring(s));
p.addRequired('FT_file',  @(s)ischar(s)||isstring(s));

p.addParameter('Points',        1:10, @(x)isnumeric(x)&&isvector(x));
p.addParameter('Responses',     1:7,  @(x)isnumeric(x)&&isvector(x));
p.addParameter('FailureMode',   'response', @(s)ischar(s)||isstring(s));

p.addParameter('ShowValues',    true, @(x)islogical(x)&&isscalar(x));
p.addParameter('ValueFormat',   '%.3g', @(s)ischar(s)||isstring(s));

p.addParameter('ShowFailedPct', true, @(x)islogical(x)&&isscalar(x));
p.addParameter('PctFormat',     '%.0f%%', @(s)ischar(s)||isstring(s));
p.addParameter('TextMode',      'both', @(s)ischar(s)||isstring(s)); % both|value|pct

p.addParameter('Colormap',      'hot', @(s)ischar(s)||isstring(s));
p.addParameter('RobustLimits',  true, @(x)islogical(x)&&isscalar(x));
p.addParameter('CLimPctl',      [5 95], @(x)isnumeric(x)&&numel(x)==2);

% real response names
p.addParameter('ResponseLabels', {}, @(c)iscell(c)||isstring(c));

p.addParameter('SaveDir',       '', @(s)ischar(s)||isstring(s));
p.addParameter('FileTag',       '', @(s)ischar(s)||isstring(s));
p.addParameter('ExportDPI',     300, @(x)isnumeric(x)&&isscalar(x)&&x>0);

% House style knobs
p.addParameter('FigPosition',   [60 60 4200 2800], @(x)isnumeric(x)&&numel(x)==4);
p.addParameter('FontName',      'Arial', @(s)ischar(s)||isstring(s));
p.addParameter('FontSize',      18, @(x)isnumeric(x)&&isscalar(x));     % base axis / cbar size
p.addParameter('CellFontSize',  14, @(x)isnumeric(x)&&isscalar(x));     % text in cells

% tighter layout / larger side-top labels
p.addParameter('TopLabelFontSize',  26, @(x)isnumeric(x)&&isscalar(x));
p.addParameter('SideLabelFontSize', 26, @(x)isnumeric(x)&&isscalar(x));
p.addParameter('AxesPosition', [0.060 0.055 0.82 0.89], @(x)isnumeric(x)&&numel(x)==4);

p.parse(full_mat, FT_file, varargin{:});
opt = p.Results;

Points    = opt.Points(:)';     nP = numel(Points);
Responses = opt.Responses(:)';  nR = numel(Responses);

% ----------------------------
% Response labels
% ----------------------------
respLabels = opt.ResponseLabels;
if isstring(respLabels), respLabels = cellstr(respLabels); end
if isempty(respLabels)
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

% ----------------------------
% Load FULL + FT
% ----------------------------
Sf = load(char(full_mat), 'FULL');
if ~isfield(Sf,'FULL'), error('FULL not found in %s', char(full_mat)); end
FULL = Sf.FULL;

S = load(char(FT_file));
if ~isfield(S,'FT'), error('FT not found in %s', char(FT_file)); end
FT = S.FT;

nsample = FT.meta.nsample;

Z  = nan(nR, nP); % median failure PGA
PF = nan(nR, nP); % % failed

% ----------------------------
% Helper: get failed_sim + step_fail for a cell
% ----------------------------
    function [failed_sim, step_fail] = get_fail_for_cell(pnt, r)
        failed_sim = false(nsample,1);
        step_fail  = nan(nsample,1);

        switch lower(string(opt.FailureMode))
            case "response"
                det = FT.resp(pnt, r).det;
                if isfield(det,'failed_sim') && ~isempty(det.failed_sim), failed_sim = det.failed_sim(:); end
                if isfield(det,'step_fail')  && ~isempty(det.step_fail),  step_fail  = det.step_fail(:);  end

            case "point"
                d = FT.point(pnt);
                if isfield(d,'failed_sim') && ~isempty(d.failed_sim), failed_sim = d.failed_sim(:); end
                if isfield(d,'step_fail')  && ~isempty(d.step_fail),  step_fail  = d.step_fail(:);  end

            case "global"
                d = FT.global;
                if isfield(d,'failed_sim') && ~isempty(d.failed_sim), failed_sim = d.failed_sim(:); end
                if isfield(d,'step_fail')  && ~isempty(d.step_fail),  step_fail  = d.step_fail(:);  end

            otherwise
                error('Unknown FailureMode: %s', opt.FailureMode);
        end

        % pad/trim to nsample (robust)
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

        step_fail(~failed_sim) = NaN;
    end

% ----------------------------
% Compute median failure PGA per cell
% ----------------------------
for ir = 1:nR
    r = Responses(ir);
    for ip = 1:nP
        pnt = Points(ip);

        [failed_sim, step_fail] = get_fail_for_cell(pnt, r);
        PF(ir,ip) = 100 * nnz(failed_sim) / nsample;

        if ~any(failed_sim) || all(~isfinite(step_fail))
            continue;
        end

        X = FULL.Point(pnt).X;
        if size(X,2) < 16
            error('FULL.Point(%d).X has only %d columns; expected >= 16', pnt, size(X,2));
        end

        sim_id = (1:nsample)';                 % 1..nsample
        row    = (step_fail(:) - 1) .* nsample + sim_id;

        good = failed_sim(:) & isfinite(row) & row >= 1 & row <= size(X,1);
        row = row(good);

        if isempty(row), continue; end

        pga_fail = X(row, 16);
        pga_fail = pga_fail(:);
        pga_fail = pga_fail(isfinite(pga_fail));

        if ~isempty(pga_fail)
            Z(ir,ip) = median(pga_fail);
        end
    end
end

% ----------------------------
% Color limits
% ----------------------------
Zvec = Z(isfinite(Z));
if isempty(Zvec)
    clim = [0 1];
elseif opt.RobustLimits
    clim = prctile(Zvec, opt.CLimPctl);
    if ~all(isfinite(clim)) || clim(1)==clim(2)
        clim = [min(Zvec) max(Zvec)];
    end
else
    clim = [min(Zvec) max(Zvec)];
end
if ~all(isfinite(clim)) || clim(1)==clim(2)
    clim = [0 1];
end

% ----------------------------
% Plot (NO title)
% ----------------------------
fig = figure('Color','w','Renderer','opengl');
set(fig,'Units','pixels','Position',opt.FigPosition);

ax = axes(fig); %#ok<LAXES>
set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize,'FontWeight','bold');

% tighter layout to remove extra white space
ax.Position = opt.AxesPosition;

imagesc(ax, Z);
set(ax,'YDir','reverse');
colormap(ax, char(opt.Colormap));
caxis(ax, clim);

hcb = colorbar(ax);
ylabel(hcb, 'Median failure PGA', 'Interpreter','none', ...
    'FontName',opt.FontName, 'FontSize',opt.FontSize, 'FontWeight','bold');

% tighten colorbar placement too
cbPos = hcb.Position;
cbPos(1) = 0.895;
cbPos(3) = 0.018;
cbPos(2) = ax.Position(2);
cbPos(4) = ax.Position(4);
hcb.Position = cbPos;

% P labels only on TOP
ax.XAxisLocation = 'top';

ax.XTick = 1:nP;
ax.XTickLabel = arrayfun(@(x)sprintf('\\bf P%d',x), Points, 'uni',0);

ax.YTick = 1:nR;
yl = cell(nR,1);
for ir = 1:nR
    yl{ir} = ['\bf ' respLabels{Responses(ir)}];
end
ax.YTickLabel = yl;
ax.TickLabelInterpreter = 'tex';

% make top and side labels bigger
ax.XAxis.FontSize = opt.TopLabelFontSize;
ax.YAxis.FontSize = opt.SideLabelFontSize;

% comment out Point / Response axis labels
% xlabel(ax,'\bf Point','Interpreter','tex', ...
%     'FontName',opt.FontName,'FontSize',opt.FontSize);
% ylabel(ax,'\bf Response','Interpreter','tex', ...
%     'FontName',opt.FontName,'FontSize',opt.FontSize);

box(ax,'on');
grid(ax,'off');
set(ax,'TickLength',[0 0]);

% ----------------------------
% Cell text (median PGA + %failed)
% ----------------------------
if opt.ShowValues || opt.ShowFailedPct
    for ir = 1:nR
        for ip = 1:nP
            tVal = "";
            tPct = "";

            if opt.ShowValues && isfinite(Z(ir,ip))
                tVal = string(sprintf(opt.ValueFormat, Z(ir,ip)));
            end
            if opt.ShowFailedPct && isfinite(PF(ir,ip))
                tPct = string(sprintf(opt.PctFormat, PF(ir,ip)));
            end

            mode = lower(string(opt.TextMode));
            switch mode
                case "both"
                    if strlength(tVal)>0 && strlength(tPct)>0
                        txt = tVal + newline + tPct;
                    elseif strlength(tVal)>0
                        txt = tVal;
                    else
                        txt = tPct;
                    end
                case "value"
                    txt = tVal;
                case "pct"
                    txt = tPct;
                otherwise
                    txt = tVal;
            end

            if strlength(txt)>0
                text(ax, ip, ir, txt, ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontSize',opt.CellFontSize, ...
                    'FontName',opt.FontName, ...
                    'FontWeight','normal', ...
                    'Interpreter','none', ...
                    'Color','k', ...
                    'BackgroundColor','w', ...
                    'Margin',1);
            end
        end
    end
end

% ----------------------------
% Save (robust)
% ----------------------------
if ~isempty(opt.SaveDir)
    sd = char(opt.SaveDir);
    if ~exist(sd,'dir'), mkdir(sd); end

    tag = char(opt.FileTag);
    if ~isempty(tag), tag = ['_' tag]; end

    outPng = fullfile(sd, sprintf('ALL70_median_failure_PGA_%s%s.png', ...
        char(opt.FailureMode), tag));

    save_png_rgbimage(fig, outPng, opt.ExportDPI);
    fprintf('Saved:\n  %s\n', outPng);
end

end % main


% =====================================================================
% Subfunctions
% =====================================================================
function save_png_rgbimage(fig, filename, dpi)
drawnow;
img = print(fig,'-RGBImage',sprintf('-r%d',dpi));
imwrite(img, filename);
end