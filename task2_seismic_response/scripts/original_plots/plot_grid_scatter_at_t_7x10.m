function plot_grid_scatter_at_t_7x10(outRoot, t0, varargin)
% plot_grid_scatter_at_t_7x10(outRoot, t0)
% 7x10 tiled figure: rows=R1..R7, cols=P1..P10.
% Each tile: scatter Observed vs Predicted at a fixed time t0 (SAFE only).
% Reads newest "*_obs_pred.csv" in outRoot/P#/R#/ folders.
%
% Updates (aligned with latest grid-plot revisions):
%   - Robust raster PNG export using print('-RGBImage') + imwrite (fixes "text-only" export)
%   - Figure pixel sizing controls (mimics “zoomed / 200%” look)
%   - Faster reads: read only needed columns using detectImportOptions when possible
%   - Robust per-response axis limits using percentiles (optional) so dots aren’t crushed
%   - Removes n= annotation (kept clean)
%   - R^2 shows 'N/A' when variance is zero
%
% Inputs:
%   outRoot : root output folder that contains P1/R1/... subfolders
%   t0      : target time in seconds (e.g., 2.0)
%
% Options (name-value):
%   'Points'        : default 1:10
%   'Responses'     : default 1:7
%   'FilePattern'   : default '*_obs_pred.csv'
%   'TimeTol'       : tolerance for selecting time rows, default [] (auto from dt)
%   'MaxPerTile'    : max SAFE points plotted per tile (downsample), default 300
%   'AxisMode'      : 'perResponse' (recommended) or 'perTile', default 'perResponse'
%   'AxisPctl'      : [lo hi] percentiles for axis limits, default [0.5 99.5]
%   'PadFrac'       : padding fraction for axis limits, default 0.02
%   'FigureName'    : default sprintf('ALL 70 | Obs vs Pred at t=%.2fs (SAFE)',t0)
%   'SavePNG'       : '' or filepath to save PNG, default ''
%   'ExportDPI'     : default 300
%   'MinFigPixels'  : default [4200 2800]
%
% Example:
%   plot_grid_scatter_at_t_7x10(outRoot, 2.0, ...
%       'MaxPerTile', 300, ...
%       'AxisMode','perResponse', ...
%       'SavePNG', fullfile(outRoot,'ALL70_scatter_t2s.png'));

p = inputParser;
p.addRequired('outRoot', @(s)ischar(s) || isstring(s));
p.addRequired('t0', @(x)isnumeric(x) && isscalar(x));
p.addParameter('Points', 1:10, @(x)isnumeric(x)&&isvector(x));
p.addParameter('Responses', 1:7, @(x)isnumeric(x)&&isvector(x));
p.addParameter('FilePattern', '*_obs_pred.csv', @(s)ischar(s)||isstring(s));
p.addParameter('TimeTol', [], @(x)isempty(x)||(isnumeric(x)&&isscalar(x)&&x>0));
p.addParameter('MaxPerTile', 300, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('AxisMode', 'perResponse', @(s)ischar(s)||isstring(s));
p.addParameter('AxisPctl', [0.5 99.5], @(x)isnumeric(x)&&numel(x)==2&&x(1)>=0&&x(1)<x(2)&&x(2)<=100);
p.addParameter('PadFrac', 0.02, @(x)isnumeric(x)&&isscalar(x)&&x>=0&&x<=0.5);
p.addParameter('FigureName', sprintf('ALL 70 | Obs vs Pred at t=%.2fs (SAFE)', t0), @(s)ischar(s)||isstring(s));
p.addParameter('SavePNG', '', @(s)ischar(s)||isstring(s));
p.addParameter('ExportDPI', 300, @(x)isnumeric(x)&&isscalar(x)&&x>=72&&x<=1200);
p.addParameter('MinFigPixels', [4200 2800], @(x)isnumeric(x)&&numel(x)==2&&all(x>0));
p.parse(outRoot, t0, varargin{:});
opts = p.Results;

outRoot  = char(opts.outRoot);
Points   = opts.Points(:)';     nP = numel(Points);
Responses = opts.Responses(:)'; nR = numel(Responses);

pLo = opts.AxisPctl(1);
pHi = opts.AxisPctl(2);

% -------------------------------------------------------------------------
% 1) Locate newest CSV per case
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
        [~,ix] = max([ff.datenum]);
        csvPath(ir,ip) = string(fullfile(ff(ix).folder, ff(ix).name));
    end
end

% -------------------------------------------------------------------------
% 2) Determine dt (and thus default TimeTol) from first available file
% -------------------------------------------------------------------------
dt_est = [];
for ir = 1:nR
    for ip = 1:nP
        if strlength(csvPath(ir,ip))==0, continue; end
        [tt, ~, ~] = local_read_min(csvPath(ir,ip));
        if numel(tt) >= 2
            d = diff(unique(tt));
            d = d(d>0);
            if ~isempty(d)
                dt_est = median(d);
                break;
            end
        end
    end
    if ~isempty(dt_est), break; end
end
if isempty(dt_est)
    dt_est = 0.01; % fallback
end
if isempty(opts.TimeTol)
    timeTol = dt_est/2;
else
    timeTol = opts.TimeTol;
end

% -------------------------------------------------------------------------
% 3) Axis limits
% -------------------------------------------------------------------------
rowLo = nan(nR,1);
rowHi = nan(nR,1);

if strcmpi(opts.AxisMode,'perResponse')
    for ir = 1:nR
        allVals = [];

        for ip = 1:nP
            if strlength(csvPath(ir,ip))==0, continue; end

            [t, yobs, ypred] = local_read_min(csvPath(ir,ip));

            safe = isfinite(yobs) & isfinite(ypred);
            at_t = abs(t - t0) <= timeTol;
            idx  = safe & at_t;

            if any(idx)
                allVals = [allVals; yobs(idx); ypred(idx)]; %#ok<AGROW>
            end
        end

        if isempty(allVals)
            rowLo(ir) = 0; rowHi(ir) = 1;
        else
            lo = prctile(allVals, pLo);
            hi = prctile(allVals, pHi);

            if ~isfinite(lo), lo = min(allVals); end
            if ~isfinite(hi), hi = max(allVals); end
            if hi <= lo
                lo = min(allVals); hi = max(allVals);
                if hi <= lo, hi = lo + 1; end
            end

            pad = opts.PadFrac * (hi - lo + eps);
            rowLo(ir) = max(0, lo - pad); % keep nonnegative
            rowHi(ir) = hi + pad;
            if rowHi(ir) <= rowLo(ir), rowHi(ir) = rowLo(ir) + 1; end
        end
    end
end

% -------------------------------------------------------------------------
% 4) Plot grid
% -------------------------------------------------------------------------
fig = figure('Color','w', 'Name', char(opts.FigureName));
set(fig,'Renderer','opengl','RendererMode','manual');
tiledlayout(nR, nP, 'Padding','compact', 'TileSpacing','compact');

for ir = 1:nR
    R = Responses(ir);
    for ip = 1:nP
        P = Points(ip);
        nexttile;

        if strlength(csvPath(ir,ip))==0
            axis off;
            text(0.5,0.5, sprintf('P%dR%d\n(missing)',P,R), ...
                'HorizontalAlignment','center', 'FontSize',8);
            continue;
        end

        [t, yobs, ypred] = local_read_min(csvPath(ir,ip));

        safe = isfinite(yobs) & isfinite(ypred);
        at_t = abs(t - t0) <= timeTol;
        idx  = safe & at_t;

        if ~any(idx)
            axis off;
            text(0.5,0.5, sprintf('P%dR%d\nno SAFE @ t=%.2f',P,R,t0), ...
                'HorizontalAlignment','center', 'FontSize',7);
            continue;
        end

        xo = yobs(idx);
        xp = ypred(idx);

        % Downsample for display (not for stats)
        nSafe = numel(xo);
        if nSafe > opts.MaxPerTile
            rng(1,'twister');
            pick = randperm(nSafe, opts.MaxPerTile);
            xo_plot = xo(pick);
            xp_plot = xp(pick);
        else
            xo_plot = xo;
            xp_plot = xp;
        end

        r2   = local_r2(xo, xp);
        rmse = sqrt(mean((xo - xp).^2, 'omitnan'));

        plot(xo_plot, xp_plot, '.', 'MarkerSize', 7); hold on; grid on; box on;

        % Axis limits
        if strcmpi(opts.AxisMode,'perResponse')
            lo = rowLo(ir);
            hi = rowHi(ir);
        else
            allVals = [xo; xp];
            lo = prctile(allVals, pLo);
            hi = prctile(allVals, pHi);
            if ~isfinite(lo), lo = min(allVals); end
            if ~isfinite(hi), hi = max(allVals); end
            if hi <= lo
                lo = min(allVals); hi = max(allVals);
                if hi <= lo, hi = lo + 1; end
            end
            pad = opts.PadFrac * (hi - lo + eps);
            lo = max(0, lo - pad);
            hi = hi + pad;
        end

        plot([lo hi],[lo hi],'k--','LineWidth',0.8);
        axis([lo hi lo hi]);

        % titles/labels
        if ir==1
            title(sprintf('P%d',P), 'FontSize',8, 'FontWeight','bold');
        else
            title(sprintf('P%d',P), 'FontSize',8);
        end
        if ip==1
            ylabel(sprintf('R%d',R), 'FontSize',9, 'FontWeight','bold');
        end

        if isnan(r2)
            r2txt = 'R^2=N/A';
        else
            r2txt = sprintf('R^2=%.2f', r2);
        end
        txt = sprintf('%s\nRMSE=%.2g', r2txt, rmse);
        text(lo + 0.03*(hi-lo), lo + 0.80*(hi-lo), txt, ...
            'FontSize',7, 'BackgroundColor','w', 'Margin',1);

        set(gca,'FontSize',7);

        if ir==1 && ip==1
            legend({'SAFE @ t0','1:1'}, 'Location','best', 'FontSize',7);
        end
    end
end

sgtitle(sprintf('Observed vs Predicted at t = %.2f s (SAFE only), tol=%.4g s', t0, timeTol), ...
    'FontWeight','bold');

% -------------------------------------------------------------------------
% 5) Save (robust raster export)
% -------------------------------------------------------------------------
if ~isempty(opts.SavePNG)
    outPng = char(opts.SavePNG);

    set(fig,'Units','pixels');
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
        fprintf('Saved PNG (RGBImage):\n  %s\n', outPng);
    catch ME
        warning('RGBImage export failed (%s). Falling back to getframe...', ME.message);
        drawnow;
        fr = getframe(fig);
        imwrite(fr.cdata, outPng);
        fprintf('Saved PNG (getframe):\n  %s\n', outPng);
    end
end

end

% =========================================================================
% Local helper: fast read of only needed columns
% =========================================================================
function [t, yobs, ypred] = local_read_min(csvfile)
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
