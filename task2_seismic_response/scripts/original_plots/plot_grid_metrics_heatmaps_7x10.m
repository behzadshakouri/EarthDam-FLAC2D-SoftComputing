function plot_grid_metrics_heatmaps_7x10(outRoot, varargin)
% plot_grid_metrics_heatmaps_7x10(outRoot)
% Creates 4 heatmap figures (R2, RMSE, MAE, a10) in a 7x10 grid:
%   rows = R1..R7, cols = P1..P10
% Each cell computes metrics on SAFE rows only (finite y_obs and y_pred)
% from the newest "*_obs_pred.csv" in outRoot/P#/R#/ .
%
% Similar spirit to plot_grid_obs_vs_pred_7x10.m, but as heatmaps.
%
% Options (name-value):
%   'Points'        : default 1:10
%   'Responses'     : default 1:7
%   'FilePattern'   : default '*_obs_pred.csv'
%   'MinSafe'       : minimum SAFE points to compute metrics, default 50
%   'A10_Tol'       : a10 tolerance fraction, default 0.10  (|pred-obs|<=0.1*|obs|)
%   'ClampNonneg'   : clamp y_pred to >=0 before metrics, default true
%   'FigurePrefix'  : default 'ALL 70 | SAFE metrics'
%   'SaveDir'       : '' or folder path; if set, saves 4 PNGs there
%   'ExportDPI'     : default 300
%   'MinFigPixels'  : default [4200 2800] (bigger = “zoomed” look)
%   'ShowValues'    : overlay numeric values in cells, default true
%   'ValueFormat'   : sprintf format for overlay, default '%.2g'
%   'Colormap'      : colormap name, default 'parula'
%   'RobustLimits'  : true => clim by percentiles (avoid one outlier flattening), default true
%   'CLimPctl'      : [lo hi] percentiles for robust clim, default [2 98]
%
% Notes:
% - Missing / insufficient SAFE => NaN cell.
% - R2 is computed as 1 - SSE/SST (NaN if variance zero).
% - a10 uses relative error w.r.t |obs| with eps safeguard.
%
% Example:
%   plot_grid_metrics_heatmaps_7x10(outRoot, ...
%       'SaveDir', outRoot, 'ShowValues', true);

p = inputParser;
p.addRequired('outRoot', @(s)ischar(s) || isstring(s));
p.addParameter('Points', 1:10, @(x)isnumeric(x)&&isvector(x));
p.addParameter('Responses', 1:7, @(x)isnumeric(x)&&isvector(x));
p.addParameter('FilePattern', '*_obs_pred.csv', @(s)ischar(s)||isstring(s));
p.addParameter('MinSafe', 50, @(x)isnumeric(x)&&isscalar(x)&&x>=2);
p.addParameter('A10_Tol', 0.10, @(x)isnumeric(x)&&isscalar(x)&&x>0&&x<1);
p.addParameter('ClampNonneg', true, @(x)islogical(x)&&isscalar(x));
p.addParameter('FigurePrefix', 'ALL 70 | SAFE metrics', @(s)ischar(s)||isstring(s));
p.addParameter('SaveDir', '', @(s)ischar(s)||isstring(s));
p.addParameter('ExportDPI', 300, @(x)isnumeric(x)&&isscalar(x)&&x>=72&&x<=1200);
p.addParameter('MinFigPixels', [4200 2800], @(x)isnumeric(x)&&numel(x)==2&&all(x>0));
p.addParameter('ShowValues', true, @(x)islogical(x)&&isscalar(x));
p.addParameter('ValueFormat', '%.2g', @(s)ischar(s)||isstring(s));
p.addParameter('Colormap', 'parula', @(s)ischar(s)||isstring(s));
p.addParameter('RobustLimits', true, @(x)islogical(x)&&isscalar(x));
p.addParameter('CLimPctl', [2 98], @(x)isnumeric(x)&&numel(x)==2&&x(1)>=0&&x(1)<x(2)&&x(2)<=100);
p.parse(outRoot, varargin{:});
opts = p.Results;

outRoot   = char(opts.outRoot);
Points    = opts.Points(:)';     nP = numel(Points);
Responses = opts.Responses(:)';  nR = numel(Responses);

% Pre-locate newest CSV per tile (speed)
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

% Metric matrices
M_R2   = nan(nR,nP);
M_RMSE = nan(nR,nP);
M_MAE  = nan(nR,nP);
M_A10  = nan(nR,nP);

% Compute metrics per tile
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

        % RMSE / MAE
        e = yp - yo;
        M_RMSE(ir,ip) = sqrt(mean(e.^2, 'omitnan'));
        M_MAE(ir,ip)  = mean(abs(e), 'omitnan');

        % R2
        M_R2(ir,ip) = local_r2(yo, yp);

        % a10-index: relative error <= tol
        denom = max(abs(yo), eps);
        rel = abs(e) ./ denom;
        M_A10(ir,ip) = mean(rel <= opts.A10_Tol);
    end
end

% Draw 4 heatmaps
plot_one_metric(M_R2,   'R^2',        'R2',   true);
plot_one_metric(M_RMSE, 'RMSE',       'RMSE', false);
plot_one_metric(M_MAE,  'MAE',        'MAE',  false);
plot_one_metric(M_A10,  'a10-index',  'a10',  true);

% ===================== nested: plot helper =====================
function plot_one_metric(M, titleMetric, fileTag, isUnitInterval)
    figTitle = sprintf('%s | %s', char(opts.FigurePrefix), titleMetric);

    fig = figure('Color','w', 'Name', figTitle);
    set(fig,'Renderer','opengl','RendererMode','manual');

    imagesc(M);
    axis tight;
    set(gca,'YDir','normal');
    colormap(gca, feval(char(opts.Colormap)));
    cb = colorbar; %#ok<NASGU>

    % axis labels
    xticks(1:nP); xticklabels(compose('P%d', Points));
    yticks(1:nR); yticklabels(compose('R%d', Responses));
    xlabel('Point');
    ylabel('Response');
    title(figTitle, 'FontWeight','bold');

    % color limits
    if isUnitInterval
        % for R2 and a10, keep within [0,1] if possible
        clim = [0 1];
        if ~all(isfinite(M(:))) && opts.RobustLimits
            % still okay; keep [0,1]
        end
        caxis(clim);
    else
        if opts.RobustLimits
            vv = M(isfinite(M));
            if ~isempty(vv)
                lo = prctile(vv, opts.CLimPctl(1));
                hi = prctile(vv, opts.CLimPctl(2));
                if ~isfinite(lo), lo = min(vv); end
                if ~isfinite(hi), hi = max(vv); end
                if hi <= lo
                    lo = min(vv); hi = max(vv);
                    if hi <= lo, hi = lo + 1; end
                end
                caxis([lo hi]);
            end
        end
    end

    % overlay values
    if opts.ShowValues
        for r = 1:nR
            for c = 1:nP
                v = M(r,c);
                if ~isfinite(v), continue; end
                txt = sprintf(char(opts.ValueFormat), v);
                text(c, r, txt, ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontSize', 9, ...
                    'Color', 'k', ...
                    'BackgroundColor','w', ...
                    'Margin', 0.5);
            end
        end
    end

    set(gca,'FontSize',10);
    set(gca,'TickLength',[0 0]); % cleaner heatmap look

    % save (robust raster export like your other scripts)
    if ~isempty(opts.SaveDir)
        outDir = char(opts.SaveDir);
        if ~exist(outDir,'dir'), mkdir(outDir); end
        outPng = fullfile(outDir, sprintf('ALL70_metrics_%s_heatmap.png', fileTag));

        set(fig,'Units','pixels');
        pos = get(fig,'Position');
        pos(3) = max(pos(3), opts.MinFigPixels(1));
        pos(4) = max(pos(4), opts.MinFigPixels(2));
        set(fig,'Position',pos);

        drawnow; pause(0.1); drawnow;

        try
            img = print(fig, '-RGBImage', sprintf('-r%d', round(opts.ExportDPI)));
            imwrite(img, outPng);
            fprintf('Saved heatmap PNG (RGBImage):\n  %s\n', outPng);
        catch ME
            warning('RGBImage export failed (%s). Falling back to getframe...', ME.message);
            fr = getframe(fig);
            imwrite(fr.cdata, outPng);
            fprintf('Saved heatmap PNG (getframe):\n  %s\n', outPng);
        end
    end
end

end

% ===================== local helpers =====================
function [yobs, ypred] = local_read_y(csvfile)
% fast minimal read (y_obs,y_pred only)
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
if ss_tot <= 0
    r2 = NaN;
else
    r2 = 1 - ss_res/ss_tot;
end
end