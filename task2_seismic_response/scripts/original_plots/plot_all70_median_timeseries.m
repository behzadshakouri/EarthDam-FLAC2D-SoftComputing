function plot_all70_median_timeseries(outRoot, varargin)
% plot_all70_median_timeseries(outRoot)
% One figure with 70 curves over a time window.
% Each curve is the per-time-step statistic across simulations (SAFE only).
% Reads newest "*_obs_pred.csv" inside outRoot/P#/R#/ folders.
%
% Updates (aligned with latest grid-plot revisions):
%   - Robust raster PNG export using print('-RGBImage') + imwrite (fixes "text-only" export)
%   - Faster reads: read only needed columns via detectImportOptions when possible
%   - Optional figure pixel sizing (mimics “zoomed / 200%” look)
%   - Safer: drops rows where time is NaN / missing
%
% Options (name-value):
%   'Points'       : default 1:10
%   'Responses'    : default 1:7
%   'FilePattern'  : default '*_obs_pred.csv'
%   'Series'       : 'obs' | 'pred' | 'both'  (default 'pred')
%   'Stat'         : 'median' (default) | 'mean'
%   'TimeWindow'   : [tmin tmax] or [] (auto), default [0 20]
%   'MinCount'     : minimum sims available at a time step to keep point, default 10
%   'Legend'       : true/false, default false (70-entry legend is huge)
%   'FigureName'   : default 'All 70 | per-time-step statistic across sims (SAFE)'
%   'SavePNG'      : '' or filepath, default ''
%   'ExportDPI'    : default 300
%   'MinFigPixels' : default [2600 1600] (bump if you want heavier raster)
%
% Example:
%   plot_all70_median_timeseries(outRoot, 'Series','pred', 'Legend',false, ...
%       'SavePNG', fullfile(outRoot,'ALL70_pred_median.png'));

p = inputParser;
p.addRequired('outRoot', @(s)ischar(s) || isstring(s));
p.addParameter('Points', 1:10, @(x)isnumeric(x)&&isvector(x));
p.addParameter('Responses', 1:7, @(x)isnumeric(x)&&isvector(x));
p.addParameter('FilePattern', '*_obs_pred.csv', @(s)ischar(s)||isstring(s));
p.addParameter('Series', 'pred', @(s)ischar(s)||isstring(s));
p.addParameter('Stat', 'median', @(s)ischar(s)||isstring(s));
p.addParameter('TimeWindow', [0 20], @(x)isempty(x)||(isnumeric(x)&&numel(x)==2));
p.addParameter('MinCount', 10, @(x)isnumeric(x)&&isscalar(x)&&x>=1);
p.addParameter('Legend', false, @(x)islogical(x)&&isscalar(x));
p.addParameter('FigureName', 'All 70 | per-time-step statistic across sims (SAFE)', @(s)ischar(s)||isstring(s));
p.addParameter('SavePNG', '', @(s)ischar(s)||isstring(s));
p.addParameter('ExportDPI', 300, @(x)isnumeric(x)&&isscalar(x)&&x>=72&&x<=1200);
p.addParameter('MinFigPixels', [2600 1600], @(x)isnumeric(x)&&numel(x)==2&&all(x>0));
p.parse(outRoot, varargin{:});
opts = p.Results;

outRoot  = char(opts.outRoot);
Points   = opts.Points(:)';
Responses = opts.Responses(:)';
series   = lower(string(opts.Series));
statName = lower(string(opts.Stat));

fig = figure('Color','w', 'Name', char(opts.FigureName));
set(fig,'Renderer','opengl','RendererMode','manual');
ax = axes(fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on');

labels = {};

for P = Points
    for R = Responses
        caseDir = fullfile(outRoot, sprintf('P%d',P), sprintf('R%d',R));
        if ~exist(caseDir,'dir'), continue; end

        ff = dir(fullfile(caseDir, opts.FilePattern));
        if isempty(ff), continue; end
        [~,ix] = max([ff.datenum]);
        csvfile = fullfile(ff(ix).folder, ff(ix).name);

        % --- fast minimal read ---
        [t, yobs, ypred] = local_read_min(csvfile);

        % drop bad time rows
        okT = isfinite(t);
        t = t(okT); yobs = yobs(okT); ypred = ypred(okT);

        % time window
        if ~isempty(opts.TimeWindow)
            tw = opts.TimeWindow;
            keep = (t >= tw(1)) & (t <= tw(2));
            t = t(keep);
            yobs = yobs(keep);
            ypred = ypred(keep);
        end

        if isempty(t)
            continue;
        end

        % group by time step (rely on time_s)
        [tu,~,g] = unique(t, 'stable');

        switch series
            case "obs"
                ystat = group_stat(yobs, g, statName, opts.MinCount);
                plot(ax, tu, ystat, 'LineWidth', 0.8);
                labels{end+1} = sprintf('P%dR%d obs', P, R); %#ok<AGROW>

            case "pred"
                ystat = group_stat(ypred, g, statName, opts.MinCount);
                plot(ax, tu, ystat, 'LineWidth', 0.8);
                labels{end+1} = sprintf('P%dR%d pred', P, R); %#ok<AGROW>

            case "both"
                ystat_obs  = group_stat(yobs,  g, statName, opts.MinCount);
                ystat_pred = group_stat(ypred, g, statName, opts.MinCount);
                plot(ax, tu, ystat_obs,  '-',  'LineWidth', 0.7);
                plot(ax, tu, ystat_pred, '--', 'LineWidth', 0.7);
                labels{end+1} = sprintf('P%dR%d obs', P, R); %#ok<AGROW>
                labels{end+1} = sprintf('P%dR%d pred', P, R); %#ok<AGROW>

            otherwise
                error('Unknown Series: %s', series);
        end
    end
end

xlabel(ax, 'Time (s)');
ylabel(ax, sprintf('%s across sims (SAFE)', char(statName)));
title(ax, sprintf('All 70 cases | %s | %s across simulations', upper(char(series)), upper(char(statName))));

if opts.Legend
    legend(ax, labels, 'Location','eastoutside');
end

if ~isempty(opts.TimeWindow)
    xlim(ax, opts.TimeWindow);
end

% -------------------------------------------------------------------------
% Save (robust raster export)
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
% Local helper: minimal column read for speed
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

% ===== helper: per-time-group statistic ignoring NaNs, with min count =====
function ystat = group_stat(y, g, statName, minCount)
g = g(:);
y = y(:);

if isempty(g)
    ystat = nan(0,1);
    return;
end

K = max(g);
ystat = nan(K,1);

% count finite values per group
cnt = accumarray(g, isfinite(y), [K 1], @sum, 0);

switch statName
    case "median"
        for k = 1:K
            if cnt(k) < minCount, continue; end
            idx = (g==k) & isfinite(y);
            ystat(k) = median(y(idx));
        end

    case "mean"
        for k = 1:K
            if cnt(k) < minCount, continue; end
            idx = (g==k) & isfinite(y);
            ystat(k) = mean(y(idx));
        end

    otherwise
        error('Unknown Stat: %s', statName);
end
end
