function plot_grid_obs_vs_pred_7x10(outRoot, varargin)

p = inputParser;
p.addRequired('outRoot', @(s)ischar(s)||isstring(s));

p.addParameter('Points',1:10);
p.addParameter('Responses',1:7);
p.addParameter('FilePattern','*_obs_pred.csv');
p.addParameter('MaxPerTile',4000);
p.addParameter('PctlLo',0.5);
p.addParameter('PctlHi',99.5);
p.addParameter('PadFrac',0.05);

p.addParameter('FigureName','FLAC2D reference versus surrogate prediction');
p.addParameter('ExportDPI',300);
p.addParameter('SavePNG','');

p.addParameter('FigPosition', []);

p.addParameter('MethodTag','ELM');
p.addParameter('ResponseLabels',[]);
p.addParameter('FontName','Arial');
p.addParameter('TileFontSize',8);
p.addParameter('HeaderFontSize',13);
p.addParameter('R2FontSize',8);
p.addParameter('LabelFontSize',18);
p.addParameter('MarkerSize',2.5);

p.addParameter('SquareDataRange', true);

p.addParameter('ShowGuideLines', true);
p.addParameter('GuideMode', 'all');
p.addParameter('ShowR2', true);

p.addParameter('TickMode', 'smart');
p.addParameter('MaxTicks', 3);
p.addParameter('TickLength', 0.035);

p.addParameter('UseCompactExponentLabels', true);
p.addParameter('ExponentThreshold', 2);
p.addParameter('ExponentYOffsetFrac', 0.035);
p.addParameter('ExponentXOffsetFrac', 0.020);

p.addParameter('LeftMargin',   0.055);
p.addParameter('RightMargin',  0.025);
p.addParameter('BottomMargin', 0.140);
p.addParameter('TopMargin',    0.035);
p.addParameter('HGap',         0.022);
p.addParameter('VGap',         0.048);

p.addParameter('PointTitleYOffset', 0.008);
p.addParameter('XAxisLabelYOffset', 0.055);
p.addParameter('YAxisLabelX',       0.018);

p.addParameter('PointTitleHeight', 0.028);
p.addParameter('XAxisLabelHeight', 0.030);
p.addParameter('YAxisLabelYOffset', 0.000);

p.addParameter('RowLabelX', -0.46);

p.addParameter('GuideFocusPrctLo',1);
p.addParameter('GuideFocusPrctHi',99);

p.addParameter('PlotFraction', 0.33);
p.addParameter('RandomSeed', 1);

p.addParameter('ShowGlobalPointLabel', false);
p.addParameter('ShowGlobalResponseLabel', false);
p.addParameter('BottomLabelY', 0.045);
p.addParameter('LeftGlobalLabelX', 0.013);

p.addParameter('ShowProgressiveTiles', true);

p.parse(outRoot,varargin{:});
opts = p.Results;

rng(opts.RandomSeed);

Points    = opts.Points(:)';
Responses = opts.Responses(:)';

nP = numel(Points);
nR = numel(Responses);

respLabels = opts.ResponseLabels;
if isempty(respLabels)
    respLabels = final_response_labels();
end

csvPath = strings(nR,nP);

for ir = 1:nR
    for ip = 1:nP
        d = fullfile(outRoot, sprintf('P%d',Points(ip)), sprintf('R%d',Responses(ir)));
        if ~exist(d,'dir')
            continue
        end

        ff = dir(fullfile(d, opts.FilePattern));
        if isempty(ff)
            continue
        end

        [~,ix] = max([ff.datenum]);
        csvPath(ir,ip) = string(fullfile(ff(ix).folder, ff(ix).name));
    end
end

fig = figure('Color','w','Renderer','opengl','Name',opts.FigureName);
set(fig,'Units','pixels');

if ~isempty(opts.FigPosition)
    set(fig,'Position', opts.FigPosition);
end

drawnow

figPos = get(fig,'Position');
figW = figPos(3);
figH = figPos(4);

Lm = opts.LeftMargin;
Rm = opts.RightMargin;
Bm = opts.BottomMargin;
Tm = opts.TopMargin;
Hg = opts.HGap;
Vg = opts.VGap;

availWn = 1 - Lm - Rm - (nP-1)*Hg;
availHn = 1 - Bm - Tm - (nR-1)*Vg;

tilePix = min((availWn*figW)/nP , (availHn*figH)/nR);
tileWn = tilePix/figW;
tileHn = tilePix/figH;

usedW = nP*tileWn + (nP-1)*Hg;
usedH = nR*tileHn + (nR-1)*Vg;

x0 = Lm;
y0 = Bm;

for ir = 1:nR
    for ip = 1:nP

        left   = x0 + (ip-1)*(tileWn + Hg);
        bottom = y0 + (nR-ir)*(tileHn + Vg);

        ax = axes(fig,'Position',[left bottom tileWn tileHn]);
        set(ax,'FontName',opts.FontName,'FontSize',opts.TileFontSize);
        set(ax,'TickLength',[opts.TickLength opts.TickLength]);
        hold(ax,'on')
        box(ax,'on')

        if opts.ShowProgressiveTiles
            drawnow limitrate
        end

        if csvPath(ir,ip) == ""
            xlim(ax,[0 1]);
            ylim(ax,[0 1]);
            axis(ax,'square');
            continue
        end

        T = readtable(csvPath(ir,ip));

        yobs  = T.y_obs;
        ypred = T.y_pred;

        ok = isfinite(yobs) & isfinite(ypred);
        yobs  = yobs(ok);
        ypred = ypred(ok);

        if isempty(yobs)
            xlim(ax,[0 1]);
            ylim(ax,[0 1]);
            axis(ax,'square');
            continue
        end

        [xmin,xmax,ymin,ymax] = localSafeLimits(yobs, ypred, opts);

        xlim(ax,[xmin xmax]);
        ylim(ax,[ymin ymax]);
        axis(ax,'square');

        switch lower(opts.TickMode)
            case 'smart'
                ax.XTick = smartTicks(xmin, xmax, opts.MaxTicks);
                ax.YTick = smartTicks(ymin, ymax, opts.MaxTicks);
            otherwise
                ax.XTickMode = 'auto';
                ax.YTickMode = 'auto';
                drawnow limitrate
                ax.XTick = ax.XTick(isfinite(ax.XTick));
                ax.YTick = ax.YTick(isfinite(ax.YTick));
        end

        ax.XTick = ax.XTick(ax.XTick >= 0 & ax.XTick >= xmin-eps & ax.XTick <= xmax+eps);
        ax.YTick = ax.YTick(ax.YTick >= 0 & ax.YTick >= ymin-eps & ax.YTick <= ymax+eps);

        ax.XTick = ensureMinTicks(ax.XTick, xmin, xmax, 3);
        ax.YTick = ensureMinTicks(ax.YTick, ymin, ymax, 3);

        ax.XAxis.Exponent = 0;
        ax.YAxis.Exponent = 0;

        if opts.UseCompactExponentLabels
            [xlabels, xexp, ~] = makeCompactTickLabels(ax.XTick, opts.ExponentThreshold);
            [ylabels, yexp, ~] = makeCompactTickLabels(ax.YTick, opts.ExponentThreshold);

            ax.XTickLabel = xlabels;
            ax.YTickLabel = ylabels;

            xr = ax.XLim(2) - ax.XLim(1);
            yr = ax.YLim(2) - ax.YLim(1);

            if ~isempty(xexp)
                text(ax, ax.XLim(2), ax.YLim(1) + opts.ExponentYOffsetFrac*yr, ...
                    sprintf('\\times10^{%d}', xexp), ...
                    'VerticalAlignment','bottom', ...
                    'HorizontalAlignment','right', ...
                    'FontSize', max(7, opts.TileFontSize-0.5), ...
                    'Interpreter','tex', ...
                    'Clipping','off');
            end

            if ~isempty(yexp)
                text(ax, ax.XLim(1) + opts.ExponentXOffsetFrac*xr, ax.YLim(2), ...
                    sprintf('\\times10^{%d}', yexp), ...
                    'VerticalAlignment','bottom', ...
                    'HorizontalAlignment','left', ...
                    'FontSize', max(7, opts.TileFontSize-0.5), ...
                    'Interpreter','tex', ...
                    'Clipping','off');
            end
            
        else
            ax.XTickLabel = compose('%.3g', ax.XTick);
            ax.YTickLabel = compose('%.3g', ax.YTick);
        end

        n = numel(yobs);
        frac = max(0,min(1,opts.PlotFraction));

        if frac < 1 && n > 1
            k = max(1, round(frac*n));
            idx = randperm(n, k);
            yobs_plot  = yobs(idx);
            ypred_plot = ypred(idx);
        else
            yobs_plot  = yobs;
            ypred_plot = ypred;
        end

        plot(ax, yobs_plot, ypred_plot, '.', ...
            'Color', [0.8500 0.3250 0.0980], ...
            'MarkerSize', opts.MarkerSize);

        xFocusMin = prctile(yobs, opts.GuideFocusPrctLo);
        xFocusMax = prctile(yobs, opts.GuideFocusPrctHi);

        if opts.ShowGuideLines
            x1 = max([xmin, ymin, xFocusMin]);
            x2 = min([xmax, ymax, xFocusMax]);

            if isfinite(x1) && isfinite(x2) && x2 > x1
                xx = linspace(x1, x2, 120);
                plot(ax, xx, xx, '--', ...
                    'Color', [0 0 0], ...
                    'LineWidth', 1.4);

                if strcmpi(opts.GuideMode,'all')
                    x1a = max([xmin, ymin/2, xFocusMin]);
                    x2a = min([xmax, ymax/2, xFocusMax]);

                    if isfinite(x1a) && isfinite(x2a) && x2a > x1a
                        xxa = linspace(x1a, x2a, 120);
                        plot(ax, xxa, 2*xxa, ':', ...
                            'Color', [0 0.4470 0.7410], ...
                            'LineWidth', 1.1);
                    end

                    x1b = max([xmin, 2*ymin, xFocusMin]);
                    x2b = min([xmax, 2*ymax, xFocusMax]);

                    if isfinite(x1b) && isfinite(x2b) && x2b > x1b
                        xxb = linspace(x1b, x2b, 120);
                        plot(ax, xxb, 0.5*xxb, ':', ...
                            'Color', [0 0.8500 0.1000], ...
                            'LineWidth', 1.1);
                    end
                end
            end
        end

        if opts.ShowR2
            den = sum((yobs - mean(yobs)).^2);

            if den <= 0 || ~isfinite(den)
                r2 = NaN;
            else
                r2 = 1 - sum((yobs - ypred).^2) / den;
            end

            if isfinite(r2)
                r2txt = sprintf('R^2=%.2f', r2);
            else
                r2txt = 'R^2=NA';
            end

            text(ax, 0.03, 0.97, r2txt, ...
                'Units','normalized', ...
                'VerticalAlignment','top', ...
                'HorizontalAlignment','left', ...
                'FontSize',opts.R2FontSize, ...
                'BackgroundColor','w', ...
                'Margin',0.5);
        end

        if ir == 1
            tt = title(ax, sprintf('P%d',Points(ip)), ...
                'FontSize', opts.HeaderFontSize, ...
                'FontWeight','bold');

            tt.Units = 'normalized';
            pos = tt.Position;
            pos(2) = pos(2) + opts.PointTitleYOffset;   % move title upward
            tt.Position = pos;
        end

        if ip == 1
            yl = ylabel(ax, respLabels{Responses(ir)}, ...
                'FontSize', opts.HeaderFontSize, ...
                'FontWeight', 'bold');

            yl.Units = 'normalized';
            yl.Position(1) = opts.RowLabelX;
            yl.Position(2) = 0.5;
        end

        if opts.ShowProgressiveTiles
            drawnow limitrate
        end
    end
end

annotation(fig,'textbox', ...
    [x0, opts.BottomLabelY, usedW, opts.XAxisLabelHeight], ...
    'String','FLAC2D reference', ...
    'EdgeColor','none', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle', ...
    'FontSize',opts.LabelFontSize, ...
    'FontName',opts.FontName);

axGlobal = axes('Parent',fig, ...
    'Position',[0 0 1 1], ...
    'Units','normalized', ...
    'Visible','off', ...
    'HitTest','off');
axGlobal.XLim = [0 1];
axGlobal.YLim = [0 1];

text(axGlobal, opts.LeftGlobalLabelX, y0 + usedH/2 + opts.YAxisLabelYOffset, ...
    [display_method_name(opts.MethodTag) ' prediction'], ...
    'Rotation', 90, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', opts.LabelFontSize, ...
    'FontName', opts.FontName);

drawnow

if ~isempty(opts.SavePNG)
    exportgraphics(fig, opts.SavePNG, 'Resolution', opts.ExportDPI);
end

end

% =========================================================================
function [xmin,xmax,ymin,ymax] = localSafeLimits(yobs, ypred, opts)

xlo = prctile(yobs,  opts.PctlLo);
xhi = prctile(yobs,  opts.PctlHi);
ylo = prctile(ypred, opts.PctlLo);
yhi = prctile(ypred, opts.PctlHi);

if ~isfinite(xlo), xlo = min(yobs);  end
if ~isfinite(xhi), xhi = max(yobs);  end
if ~isfinite(ylo), ylo = min(ypred); end
if ~isfinite(yhi), yhi = max(ypred); end

xspan = xhi - xlo;
yspan = yhi - ylo;

if ~isfinite(xspan) || xspan <= 0
    xref = max(abs([xlo xhi 1]));
    xpad = opts.PadFrac * xref;
else
    xpad = opts.PadFrac * xspan;
end

if ~isfinite(yspan) || yspan <= 0
    yref = max(abs([ylo yhi 1]));
    ypad = opts.PadFrac * yref;
else
    ypad = opts.PadFrac * yspan;
end

xmin = max(0, xlo - xpad);
xmax = xhi + xpad;
ymin = max(0, ylo - ypad);
ymax = yhi + ypad;

if ~isfinite(xmin), xmin = 0; end
if ~isfinite(ymin), ymin = 0; end
if ~isfinite(xmax), xmax = 1; end
if ~isfinite(ymax), ymax = 1; end

if xmax <= xmin
    xmax = xmin + max(1e-6, 0.05 * max([abs(xmin), abs(xmax), 1]));
end

if ymax <= ymin
    ymax = ymin + max(1e-6, 0.05 * max([abs(ymin), abs(ymax), 1]));
end

if opts.SquareDataRange
    span = max(xmax - xmin, ymax - ymin);

    if ~isfinite(span) || span <= 0
        span = max([abs(xmin), abs(xmax), abs(ymin), abs(ymax), 1]) * 0.1;
    end

    cx = 0.5 * (xmin + xmax);
    cy = 0.5 * (ymin + ymax);

    xmin = max(0, cx - span/2);
    xmax = cx + span/2;
    ymin = max(0, cy - span/2);
    ymax = cy + span/2;
end

xmin = max(0, xmin);
ymin = max(0, ymin);

if ~isfinite(xmin), xmin = 0; end
if ~isfinite(ymin), ymin = 0; end
if ~isfinite(xmax), xmax = 1; end
if ~isfinite(ymax), ymax = 1; end

if xmax <= xmin
    xmax = xmin + max(1e-6, 0.05 * max([abs(xmin), abs(xmax), 1]));
end

if ymax <= ymin
    ymax = ymin + max(1e-6, 0.05 * max([abs(ymin), abs(ymax), 1]));
end

end

% =========================================================================
function ticks = smartTicks(vmin, vmax, maxTicks)

if ~isfinite(vmin), vmin = 0; end
if ~isfinite(vmax), vmax = 1; end

vmin = max(0, vmin);

if vmax <= vmin
    vmax = vmin + max(1e-6, 0.1*max(1,abs(vmin)));
end

if nargin < 3 || isempty(maxTicks)
    maxTicks = 3;
end
maxTicks = max(2, round(maxTicks));

rawSpan = vmax - vmin;
rawStep = rawSpan / max(1, maxTicks-1);

pow10 = 10^floor(log10(rawStep));
niceBase = [1 2 2.5 5 10];
step = niceBase(find(niceBase*pow10 >= rawStep/(maxTicks-1), 1, 'first')) * pow10;

if isempty(step) || ~isfinite(step) || step <= 0
    step = rawSpan / max(1, maxTicks-1);
end

startTick = ceil(vmin/step)*step;
endTick   = floor(vmax/step)*step;

ticks = startTick:step:endTick;

if numel(ticks) < 2
    ticks = linspace(vmin, vmax, min(maxTicks,3));
end

ticks = unique([vmin, ticks, vmax]);

if numel(ticks) > maxTicks
    ticks = linspace(vmin, vmax, maxTicks);
end

ticks = unique(max(0, ticks));

scale = max(abs(ticks));
if scale == 0
    scale = 1;
end
ticks = round(ticks, max(0, 10 - floor(log10(scale))));
end

% =========================================================================
function ticks = ensureMinTicks(ticks, vmin, vmax, targetN)

if nargin < 4 || isempty(targetN)
    targetN = 3;
end

if ~isfinite(vmin), vmin = 0; end
if ~isfinite(vmax), vmax = 1; end

vmin = max(0, vmin);

if vmax <= vmin
    vmax = vmin + max(1e-6, 0.1*max(1,abs(vmin)));
end

ticks = ticks(isfinite(ticks));
ticks = unique(ticks(:).');

if numel(ticks) >= 2
    return
end

if targetN <= 2
    ticks = unique([vmin vmax]);
else
    ticks = linspace(vmin, vmax, targetN);
end

ticks = unique(max(0, ticks));

if numel(ticks) < 2
    ticks = [vmin vmax];
    ticks = unique(ticks);
end
end

% =========================================================================
function [labels,exp10,lastTick] = makeCompactTickLabels(ticks, exponentThreshold)

ticks = ticks(:).';
n = numel(ticks);

labels = cell(1,n);
exp10 = [];
lastTick = [];

if n == 0
    labels = {};
    return
end

amax = max(abs(ticks));

if ~isfinite(amax) || amax == 0
    labels = cellstr(compose('%.2g', ticks));
    return
end

exp10 = floor(log10(amax));

if abs(exp10) < exponentThreshold
    labels = cellstr(compose('%.2g', ticks));
    exp10 = [];
    return
end

scaled = ticks / 10^exp10;

for i = 1:n
    labels{i} = num2str(scaled(i),'%.2g');
end

lastTick = ticks(end);

end

function name = display_method_name(tag)
name = upper(char(tag));
name = strrep(name,'ELMIGWO','ELM-IGWO');
name = strrep(name,'ELMACOR','ELM-ACOR');
name = strrep(name,'ELMABC','ELM-ABC');
end
