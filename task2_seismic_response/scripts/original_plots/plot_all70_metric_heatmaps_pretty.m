function plot_all70_metric_heatmaps_pretty(outRoot, varargin)
% plot_all70_metric_heatmaps_pretty(outRoot)
% Makes 4 "pretty" annotated heatmaps (R2, RMSE, MAE, a10) in the style you showed:
% - square cells
% - warm colormap (red->yellow)
% - values written inside cells
% - no axis frame/ticks (by default)
% - thin white gridlines between cells
% - robust PNG export (no "text-only" bug)
%
% Reads newest "*_obs_pred.csv" from outRoot/P#/R#/ folders.
%
% Options:
%   'Points'        1:10
%   'Responses'     1:7
%   'FilePattern'   '*_obs_pred.csv'
%   'MinSafe'       50
%   'A10_Tol'       0.10
%   'ClampNonneg'   true
%   'ShowLabels'    false   (if true, shows P and R labels like P1..P10, R1..R7)
%   'TextFormat'    '%.2f'  (R2/a10 recommended), RMSE/MAE will auto-use '%.2g' unless you override
%   'FigurePrefix'  'ALL 70 | SAFE metrics'
%   'SaveDir'       '' or folder (if set, saves 4 PNGs)
%   'ExportDPI'     300
%   'MinFigPixels'  [1400 900] (increase for higher-res look)
%   'RobustLimits'  true (for RMSE/MAE)
%   'CLimPctl'      [2 98] (for RMSE/MAE)
%   'ReverseCmap'   false (set true if you want high=red low=yellow)
%
% Example:
%   plot_all70_metric_heatmaps_pretty(outRoot, 'SaveDir', outRoot, 'ShowLabels', false);

p = inputParser;
p.addRequired('outRoot', @(s)ischar(s) || isstring(s));
p.addParameter('Points', 1:10, @(x)isnumeric(x)&&isvector(x));
p.addParameter('Responses', 1:7, @(x)isnumeric(x)&&isvector(x));
p.addParameter('FilePattern', '*_obs_pred.csv', @(s)ischar(s)||isstring(s));
p.addParameter('MinSafe', 50, @(x)isnumeric(x)&&isscalar(x)&&x>=2);
p.addParameter('A10_Tol', 0.10, @(x)isnumeric(x)&&isscalar(x)&&x>0&&x<1);
p.addParameter('ClampNonneg', true, @(x)islogical(x)&&isscalar(x));
p.addParameter('ShowLabels', false, @(x)islogical(x)&&isscalar(x));
p.addParameter('TextFormat', '', @(s)ischar(s)||isstring(s)); % '' => auto
p.addParameter('FigurePrefix', 'ALL 70 | SAFE metrics', @(s)ischar(s)||isstring(s));
p.addParameter('SaveDir', '', @(s)ischar(s)||isstring(s));
p.addParameter('ExportDPI', 300, @(x)isnumeric(x)&&isscalar(x)&&x>=72&&x<=1200);
p.addParameter('MinFigPixels', [1400 900], @(x)isnumeric(x)&&numel(x)==2&&all(x>0));
p.addParameter('RobustLimits', true, @(x)islogical(x)&&isscalar(x));
p.addParameter('CLimPctl', [2 98], @(x)isnumeric(x)&&numel(x)==2&&x(1)>=0&&x(1)<x(2)&&x(2)<=100);
p.addParameter('ReverseCmap', false, @(x)islogical(x)&&isscalar(x));
p.parse(outRoot, varargin{:});
opts = p.Results;

outRoot   = char(opts.outRoot);
Points    = opts.Points(:)';     nP = numel(Points);
Responses = opts.Responses(:)';  nR = numel(Responses);

% --- locate newest CSV per tile once ---
csvPath = strings(nR, nP);
for ir = 1:nR
    R = Responses(ir);
    for ip = 1:nP
        P = Points(ip);
        caseDir = fullfile(outRoot, sprintf('P%d',P), sprintf('R%d',R));
        if ~exist(caseDir,'dir'), continue; end
        ff = dir(fullfile(caseDir, opts.FilePattern));
        if isempty(ff), continue; end
        [~,ix] = max([ff.datenum]);
        csvPath(ir,ip) = string(fullfile(ff(ix).folder, ff(ix).name));
    end
end

% --- compute 4 metric matrices ---
M_R2   = nan(nR,nP);
M_RMSE = nan(nR,nP);
M_MAE  = nan(nR,nP);
M_A10  = nan(nR,nP);

for ir = 1:nR
    for ip = 1:nP
        if strlength(csvPath(ir,ip))==0, continue; end

        [yobs, ypred] = local_read_y(csvPath(ir,ip));
        if opts.ClampNonneg
            ypred = max(0, ypred);
        end

        safe = isfinite(yobs) & isfinite(ypred);
        if nnz(safe) < opts.MinSafe
            continue;
        end

        yo = yobs(safe);
        yp = ypred(safe);
        e  = yp - yo;

        M_R2(ir,ip)   = local_r2(yo, yp);
        M_RMSE(ir,ip) = sqrt(mean(e.^2, 'omitnan'));
        M_MAE(ir,ip)  = mean(abs(e), 'omitnan');

        denom = max(abs(yo), eps);
        rel = abs(e) ./ denom;
        M_A10(ir,ip) = mean(rel <= opts.A10_Tol);
    end
end

% --- draw in your requested style (4 separate figures) ---
draw_pretty(M_R2,   'R^2',       'R2',   true);
draw_pretty(M_RMSE, 'RMSE',      'RMSE', false);
draw_pretty(M_MAE,  'MAE',       'MAE',  false);
draw_pretty(M_A10,  'a10-index', 'a10',  true);

% ===================== nested plotter =====================
function draw_pretty(M, metricTitle, fileTag, unit01)
    figTitle = sprintf('%s | %s', char(opts.FigurePrefix), metricTitle);

    fig = figure('Color','w', 'Name', figTitle);
    set(fig,'Renderer','opengl','RendererMode','manual');

    ax = axes(fig);
    imagesc(ax, M);
    axis(ax,'image');   % square cells
    axis(ax,'tight');
    set(ax,'YDir','normal');

    % ---- warm heatmap like your sample (red->yellow) ----
    cmap = autumn(256);         % low=red, high=yellow
    if opts.ReverseCmap
        cmap = flipud(cmap);    % low=yellow, high=red
    end
    colormap(ax, cmap);
    colorbar(ax);

    % color limits
    if unit01
        caxis(ax,[0 1]);
    else
        if opts.RobustLimits
            vv = M(isfinite(M));
            if ~isempty(vv)
                lo = prctile(vv, opts.CLimPctl(1));
                hi = prctile(vv, opts.CLimPctl(2));
                if ~isfinite(lo), lo = min(vv); end
                if ~isfinite(hi), hi = max(vv); end
                if hi <= lo, hi = lo + 1e-12; end
                caxis(ax,[lo hi]);
            end
        end
    end

    % ---- remove axis look (your request) ----
    if ~opts.ShowLabels
        set(ax,'XTick',[],'YTick',[]);
        axis(ax,'off');
    else
        xticks(ax,1:nP); xticklabels(ax,compose('P%d',Points));
        yticks(ax,1:nR); yticklabels(ax,compose('R%d',Responses));
        set(ax,'TickLength',[0 0]);
        box(ax,'off');
    end

    % Title (keep it clean)
    title(ax, figTitle, 'FontWeight','bold');

    % ---- white grid lines between cells ----
    hold(ax,'on');
    for x = 0.5:1:(nP+0.5)
        plot(ax,[x x],[0.5 nR+0.5],'-','Color',[1 1 1],'LineWidth',1.0);
    end
    for y = 0.5:1:(nR+0.5)
        plot(ax,[0.5 nP+0.5],[y y],'-','Color',[1 1 1],'LineWidth',1.0);
    end

    % ---- value annotations inside each cell ----
    fmt = char(opts.TextFormat);
    if isempty(fmt)
        if unit01
            fmt = '%.2f';
        else
            fmt = '%.2g';
        end
    end

    for r = 1:nR
        for c = 1:nP
            v = M(r,c);
            if ~isfinite(v), continue; end
            text(ax, c, r, sprintf(fmt, v), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize', 10, ...
                'FontWeight','bold', ...
                'Color', 'k');
        end
    end
    hold(ax,'off');

    % ---- robust PNG save (no “text-only”) ----
    if ~isempty(opts.SaveDir)
        outDir = char(opts.SaveDir);
        if ~exist(outDir,'dir'), mkdir(outDir); end
        outPng = fullfile(outDir, sprintf('ALL70_%s_heatmap.png', fileTag));

        set(fig,'Units','pixels');
        pos = get(fig,'Position');
        pos(3) = max(pos(3), opts.MinFigPixels(1));
        pos(4) = max(pos(4), opts.MinFigPixels(2));
        set(fig,'Position',pos);

        drawnow; pause(0.1); drawnow;

        try
            img = print(fig, '-RGBImage', sprintf('-r%d', round(opts.ExportDPI)));
            imwrite(img, outPng);
            fprintf('Saved PNG:\n  %s\n', outPng);
        catch ME
            warning('RGBImage export failed (%s). Falling back to getframe...', ME.message);
            fr = getframe(fig);
            imwrite(fr.cdata, outPng);
            fprintf('Saved PNG (getframe):\n  %s\n', outPng);
        end
    end
end

end

% ===================== local helpers =====================
function [yobs, ypred] = local_read_y(csvfile)
try
    o = detectImportOptions(csvfile);
    want = intersect(o.VariableNames, {'y_obs','y_pred'});
    o.SelectedVariableNames = want;
    T = readtable(csvfile, o);
catch
    T = readtable(csvfile);
end

if ismember('y_obs', T.Properties.VariableNames)
    yobs = T.y_obs;
else
    yobs = nan(height(T),1);
end
if ismember('y_pred', T.Properties.VariableNames)
    ypred = T.y_pred;
else
    ypred = nan(height(T),1);
end
end

function r2 = local_r2(y, yhat)
y = y(:); yhat = yhat(:);
ok = isfinite(y) & isfinite(yhat);
y = y(ok); yhat = yhat(ok);
if numel(y) < 2, r2 = NaN; return; end
ss_res = sum((y - yhat).^2);
ss_tot = sum((y - mean(y)).^2);
if ss_tot <= 0, r2 = NaN; else, r2 = 1 - ss_res/ss_tot; end
end
