function plot_grid_timeseries_obs_pred_7x10(outRoot, varargin)
% plot_grid_timeseries_obs_pred_7x10(outRoot)
% 7x10 tiled figure: rows=R1..R7, cols=P1..P10.
% Each tile shows time-history of SAFE observed vs predicted from newest "*_obs_pred.csv"
% found in outRoot/P#/R#/ folders.
%
% Updates (aligned with latest scatter-grid revisions):
%   - Robust raster PNG export using print('-RGBImage') + imwrite (fixes "text-only" export)
%   - Figure pixel sizing controls (mimics "zoom 200%" quality)
%   - Faster CSV reads: read only needed columns via detectImportOptions when possible
%   - Percentile-based y-limits (optional) to avoid one spike crushing the plot
%   - R^2 label uses 'N/A' when variance is zero (instead of NaN)
%
% Options (name-value):
%   'Points'        : default 1:10
%   'Responses'     : default 1:7
%   'FilePattern'   : default '*_obs_pred.csv'
%   'FigureName'    : default 'ALL 70 | Time history (SAFE) obs vs pred'
%   'DownsampleTo'  : default 2500 (per tile). Set [] to disable.
%   'TimeWindow'    : [tmin tmax] or [] (auto), default []
%   'YlimMode'      : 'perResponse' (same ylim for each response row) or 'perTile', default 'perResponse'
%   'YLimitPctl'    : [lo hi] percentiles for ymax estimate, default [0.5 99.5]
%                    (uses max( pctl(obs), pctl(pred) ) for ymax; ymin is always 0)
%   'PadFrac'       : padding fraction for ymax, default 0.05
%   'SavePNG'       : '' or filepath, default ''
%   'ExportDPI'     : default 300
%   'MinFigPixels'  : default [4200 2800]
%
% Example:
%   plot_grid_timeseries_obs_pred_7x10(outRoot, ...
%       'DownsampleTo', 2000, ...
%       'TimeWindow', [0 20], ...
%       'SavePNG', fullfile(outRoot,'ALL70_timeseries_grid.png'));

p = inputParser;
p.addRequired('outRoot', @(s)ischar(s) || isstring(s));
p.addParameter('Points', 1:10, @(x)isnumeric(x)&&isvector(x));
p.addParameter('Responses', 1:7, @(x)isnumeric(x)&&isvector(x));
p.addParameter('FilePattern', '*_obs_pred.csv', @(s)ischar(s)||isstring(s));
p.addParameter('FigureName', 'ALL 70 | Time history (SAFE) obs vs pred', @(s)ischar(s)||isstring(s));
p.addParameter('DownsampleTo', 2500, @(x)isempty(x)||(isnumeric(x)&&isscalar(x)&&x>10));
p.addParameter('TimeWindow', [], @(x)isempty(x)||(isnumeric(x)&&numel(x)==2));
p.addParameter('YlimMode', 'perResponse', @(s)ischar(s)||isstring(s));
p.addParameter('YLimitPctl', [0.5 99.5], @(x)isnumeric(x)&&numel(x)==2&&x(1)>=0&&x(1)<x(2)&&x(2)<=100);
p.addParameter('PadFrac', 0.05, @(x)isnumeric(x)&&isscalar(x)&&x>=0&&x<=0.5);
p.addParameter('SavePNG', '', @(s)ischar(s)||isstring(s));
p.addParameter('ExportDPI', 300, @(x)isnumeric(x)&&isscalar(x)&&x>=72&&x<=1200);
p.addParameter('MinFigPixels', [4200 2800], @(x)isnumeric(x)&&numel(x)==2&&all(x>0));
p.parse(outRoot, varargin{:});
opts = p.Results;

outRoot = char(opts.outRoot);
Points = opts.Points(:)';     nP = numel(Points);
Responses = opts.Responses(:)'; nR = numel(Responses);

pLo = opts.YLimitPctl(1);
pHi = opts.YLimitPctl(2);

% -------------------------------------------------------------------------
% 1) Find newest CSV in each case folder
% -------------------------------------------------------------------------
csvPath = strings(nR, nP);
for ir = 1:nR
    R = Responses(ir);
    for ip = 1:nP
        P = Points(ip);

        caseDir = fullfile(outRoot, sprintf('P%d',P), sprintf('R%d',R));
        if ~exist(caseDir,'dir'), continue; end

        ff = dir(fullfile(caseDir, opts.FilePattern));
        if isempty(ff), continue; end

        [~,ix] = max([ff.datenum]); % newest
        csvPath(ir,ip) = string(fullfile(ff(ix).folder, ff(ix).name));
    end
end

% -------------------------------------------------------------------------
% 2) Compute y-limits per response row (robust)
% -------------------------------------------------------------------------
rowYmax = nan(nR,1);
if strcmpi(opts.YlimMode, 'perResponse')
    for ir = 1:nR
        ymax_list = [];

        for ip = 1:nP
            if strlength(csvPath(ir,ip))==0, continue; end

            [t, yobs, ypred] = local_read_timeseries_min(csvPath(ir,ip));

            safe = isfinite(yobs) & isfinite(ypred);

            if ~isempty(opts.TimeWindow)
                tw = opts.TimeWindow;
                safe = safe & (t >= tw(1)) & (t <= tw(2));
            end

            if any(safe)
                yo = yobs(safe);
                yp = ypred(safe);

                % robust ymax from percentiles to avoid one spike crushing the plot
                ymax = max(prctile(yo, pHi), prctile(yp, pHi));
                if ~isfinite(ymax) || ymax<=0
                    ymax = max([max(yo), max(yp)]);
                end
                if isfinite(ymax) && ymax>0
                    ymax_list(end+1,1) = ymax; %#ok<AGROW>
                end
            end
        end

        if isempty(ymax_list)
            rowYmax(ir) = 1;
        else
            % be slightly conservative: take max across points for this response row
            rowYmax(ir) = max(ymax_list);
            rowYmax(ir) = rowYmax(ir) * (1 + opts.PadFrac);
            if ~isfinite(rowYmax(ir)) || rowYmax(ir)<=0, rowYmax(ir)=1; end
        end
    end
end

% -------------------------------------------------------------------------
% 3) Plot grid
% -------------------------------------------------------------------------
fig = figure('Color','w', 'Name', char(opts.FigureName));
set(fig,'Renderer','opengl','RendererMode','manual');  % keep OpenGL stable
tiledlayout(nR, nP, 'Padding','compact', 'TileSpacing','compact');

for ir = 1:nR
    R = Responses(ir);

    for ip = 1:nP
        P = Points(ip);
        nexttile;

        if strlength(csvPath(ir,ip)) == 0
            axis off;
            text(0.5,0.5, sprintf('P%dR%d\n(missing)',P,R), ...
                'HorizontalAlignment','center', 'FontSize',8);
            continue;
        end

        [t, yobs, ypred] = local_read_timeseries_min(csvPath(ir,ip));

        safe = isfinite(yobs) & isfinite(ypred);

        % Apply time window
        if ~isempty(opts.TimeWindow)
            tw = opts.TimeWindow;
            keep = (t >= tw(1)) & (t <= tw(2));
            t = t(keep); yobs = yobs(keep); ypred = ypred(keep); safe = safe(keep);
        end

        grid on; box on; hold on;

        if ~any(safe)
            axis([0 1 0 1]); % keep axes sane
            title(sprintf('P%d',P), 'FontSize',8);
            if ip==1, ylabel(sprintf('R%d',R), 'FontWeight','bold'); end
            text(0.5,0.5,'no SAFE','Units','normalized','HorizontalAlignment','center','FontSize',7,...
                'BackgroundColor','w','Margin',1);
            set(gca,'FontSize',7);
            continue;
        end

        ts = t(safe);
        yo = yobs(safe);
        yp = ypred(safe);

        % Optional downsample (uniform in index)
        if ~isempty(opts.DownsampleTo) && numel(ts) > opts.DownsampleTo
            idx = round(linspace(1, numel(ts), opts.DownsampleTo));
            ts = ts(idx); yo = yo(idx); yp = yp(idx);
        end

        plot(ts, yo, '-', 'LineWidth', 0.7);
        plot(ts, yp, '-', 'LineWidth', 0.7);

        % labels/titles
        if ir==1
            title(sprintf('P%d',P), 'FontSize',8, 'FontWeight','bold');
        else
            title(sprintf('P%d',P), 'FontSize',8);
        end
        if ip==1
            ylabel(sprintf('R%d',R), 'FontSize',9, 'FontWeight','bold');
        end

        % y-limits
        if strcmpi(opts.YlimMode, 'perResponse')
            ylim([0 rowYmax(ir)]);
        else
            % per-tile robust ymax
            ymax = max(prctile(yo, pHi), prctile(yp, pHi));
            if ~isfinite(ymax) || ymax<=0
                ymax = max([max(yo), max(yp)]);
            end
            if ~isfinite(ymax) || ymax<=0, ymax = 1; end
            ymax = ymax*(1+opts.PadFrac);
            ylim([0 ymax]);
        end

        % x-limits
        if ~isempty(opts.TimeWindow)
            xlim(opts.TimeWindow);
        end

        % R^2 annotation (full SAFE in-window, not downsampled)
        r2 = local_r2(yobs(safe), ypred(safe));
        if isnan(r2)
            txt = 'R^2=N/A';
        else
            txt = sprintf('R^2=%.2f', r2);
        end
        xl = xlim; yl = ylim;
        text(xl(1) + 0.03*(xl(2)-xl(1)), yl(1) + 0.82*(yl(2)-yl(1)), txt, ...
            'FontSize',7, 'BackgroundColor','w', 'Margin',1);

        set(gca,'FontSize',7);

        % Legend only once (top-left tile)
        if ir==1 && ip==1
            legend({'Observed (SAFE)','Predicted (SAFE)'}, 'Location','best', 'FontSize',7);
        end
    end
end

sgtitle(char(opts.FigureName), 'FontWeight','bold');

% -------------------------------------------------------------------------
% 4) Save (robust raster export like scatter-grid script)
% -------------------------------------------------------------------------
if ~isempty(opts.SavePNG)
    outPng = char(opts.SavePNG);

    % Make the figure large in pixels (mimics “zoomed in” rendering quality)
    set(fig, 'Units','pixels');
    pos = get(fig,'Position');
    pos(3) = max(pos(3), opts.MinFigPixels(1));
    pos(4) = max(pos(4), opts.MinFigPixels(2));
    set(fig,'Position',pos);

    set(fig,'Renderer','opengl','RendererMode','manual');
    set(fig,'Color','w');
    drawnow; pause(0.1); drawnow;

    try
        img = print(fig, '-RGBImage', sprintf('-r%d', round(opts.ExportDPI)));
        imwrite(img, outPng);
        fprintf('Saved grid PNG (RGBImage):\n  %s\n', outPng);
    catch ME
        warning('RGBImage export failed (%s). Falling back to getframe...', ME.message);
        drawnow;
        fr = getframe(fig);
        imwrite(fr.cdata, outPng);
        fprintf('Saved grid PNG (getframe):\n  %s\n', outPng);
    end
end

end

% =========================================================================
% Local helper: minimal column read for speed
% =========================================================================
function [t, yobs, ypred] = local_read_timeseries_min(csvfile)
try
    o = detectImportOptions(csvfile);
    want = intersect(o.VariableNames, {'time_s','y_obs','y_pred'});
    o.SelectedVariableNames = want;
    T = readtable(csvfile, o);
catch
    T = readtable(csvfile);
end

if ismember('time_s', T.Properties.VariableNames)
    t = T.time_s;
else
    % fallback: if time_s missing, use row index
    t = (1:height(T))';
end

if ismember('y_obs', T.Properties.VariableNames)
    yobs = T.y_obs;
else
    yobs = nan(size(t));
end

if ismember('y_pred', T.Properties.VariableNames)
    ypred = T.y_pred;
else
    ypred = nan(size(t));
end
end

% =========================================================================
% Local helper: R^2 (returns NaN if variance is zero)
% =========================================================================
function r2 = local_r2(y, yhat)
y = y(:); yhat = yhat(:);
ok = isfinite(y) & isfinite(yhat);
y = y(ok); yhat = yhat(ok);
if numel(y) < 2, r2 = NaN; return; end
ss_res = sum((y - yhat).^2);
ss_tot = sum((y - mean(y)).^2);
if ss_tot <= 0, r2 = NaN; else, r2 = 1 - ss_res/ss_tot; end
end
