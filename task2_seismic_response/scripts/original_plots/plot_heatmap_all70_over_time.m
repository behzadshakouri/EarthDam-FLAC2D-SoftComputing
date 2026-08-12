function plot_heatmap_all70_over_time(outRoot, varargin)
% plot_heatmap_all70_over_time(outRoot)
% One heatmap: rows=70 cases (P1R1..P10R7), cols=time, value=statistic across sims (SAFE only).
% Reads newest "*_obs_pred.csv" inside outRoot/P#/R#/ folders.
%
% Updates (aligned with latest plot revisions):
%   - Faster reads: read only needed columns via detectImportOptions when possible
%   - Robust raster PNG export using print('-RGBImage') + imwrite (fixes "text-only" export)
%   - Figure pixel sizing controls (mimics “zoomed / 200%” look)
%   - Safer float-time alignment: uses ismembertol first, then nearest fallback
%   - Optional trimming of y tick labels (70 labels can be unreadable)
%
% Options (name-value):
%   'Points'        : default 1:10
%   'Responses'     : default 1:7
%   'FilePattern'   : default '*_obs_pred.csv'
%   'Series'        : 'pred' | 'obs' | 'abs_err' | 'err'  (default 'pred')
%   'Stat'          : 'median' | 'mean' (default 'median')
%   'TimeWindow'    : [tmin tmax] or [] auto, default [0 20]
%   'MinCount'      : minimum available sims at a time step to keep value, default 10
%   'MissingValue'  : 'nan' | 'zero' (default 'nan')
%   'Normalize'     : 'none' | 'perRow' | 'perResponse' (default 'none')
%   'FigureName'    : default 'All 70 | heatmap over time'
%   'SavePNG'       : '' or filepath
%   'ExportDPI'     : default 300
%   'MinFigPixels'  : default [4200 2800]
%   'ShowYLabels'   : 'all' | 'sparse' | 'none'  (default 'sparse')
%   'YLabelStride'  : show every Nth case label when ShowYLabels='sparse' (default 2)
%
% Examples:
%   plot_heatmap_all70_over_time(outRoot, 'Series','pred', 'Stat','median', ...
%       'SavePNG', fullfile(outRoot,'ALL70_heatmap_pred_median.png'));
%
%   plot_heatmap_all70_over_time(outRoot, 'Series','abs_err', 'Stat','median', ...
%       'Normalize','perResponse');

p = inputParser;
p.addRequired('outRoot', @(s)ischar(s) || isstring(s));
p.addParameter('Points', 1:10, @(x)isnumeric(x)&&isvector(x));
p.addParameter('Responses', 1:7, @(x)isnumeric(x)&&isvector(x));
p.addParameter('FilePattern', '*_obs_pred.csv', @(s)ischar(s)||isstring(s));
p.addParameter('Series', 'pred', @(s)ischar(s)||isstring(s));
p.addParameter('Stat', 'median', @(s)ischar(s)||isstring(s));
p.addParameter('TimeWindow', [0 20], @(x)isempty(x)||(isnumeric(x)&&numel(x)==2));
p.addParameter('MinCount', 10, @(x)isnumeric(x)&&isscalar(x)&&x>=1);
p.addParameter('MissingValue', 'nan', @(s)ischar(s)||isstring(s));
p.addParameter('Normalize', 'none', @(s)ischar(s)||isstring(s));
p.addParameter('FigureName', 'All 70 | heatmap over time', @(s)ischar(s)||isstring(s));
p.addParameter('SavePNG', '', @(s)ischar(s)||isstring(s));
p.addParameter('ExportDPI', 300, @(x)isnumeric(x)&&isscalar(x)&&x>=72&&x<=1200);
p.addParameter('MinFigPixels', [4200 2800], @(x)isnumeric(x)&&numel(x)==2&&all(x>0));
p.addParameter('ShowYLabels', 'sparse', @(s)ischar(s)||isstring(s));
p.addParameter('YLabelStride', 2, @(x)isnumeric(x)&&isscalar(x)&&x>=1);
p.parse(outRoot, varargin{:});
opts = p.Results;

outRoot = char(opts.outRoot);
Points = opts.Points(:)';
Responses = opts.Responses(:)';

series = lower(string(opts.Series));
statName = lower(string(opts.Stat));
missingMode = lower(string(opts.MissingValue));
normMode = lower(string(opts.Normalize));
showY = lower(string(opts.ShowYLabels));
yStride = round(opts.YLabelStride);

% -------------------------------------------------------------------------
% 1) Find first available file to get common time vector
% -------------------------------------------------------------------------
t_ref = [];
dt_est = [];
refFile = "";

for P = Points
    for R = Responses
        caseDir = fullfile(outRoot, sprintf('P%d',P), sprintf('R%d',R));
        if ~exist(caseDir,'dir'), continue; end
        ff = dir(fullfile(caseDir, opts.FilePattern));
        if isempty(ff), continue; end
        [~,ix] = max([ff.datenum]);
        refFile = fullfile(ff(ix).folder, ff(ix).name);

        [t0ref, ~, ~] = local_read_min(refFile);

        if ~isfinite(t0ref(1))
            t0ref = t0ref(isfinite(t0ref));
        end
        if isempty(t0ref), continue; end

        if ~isempty(opts.TimeWindow)
            tw = opts.TimeWindow;
            keep = (t0ref >= tw(1)) & (t0ref <= tw(2));
            t0ref = t0ref(keep);
        end

        tu = unique(t0ref, 'stable');

        if numel(tu) >= 2
            d = diff(tu);
            d = d(d>0);
            if ~isempty(d), dt_est = median(d); end
        end

        t_ref = tu; % per-step times
        break;
    end
    if ~isempty(t_ref), break; end
end

if isempty(t_ref)
    error('No *_obs_pred.csv files found under outRoot. Check folder structure.');
end

if isempty(dt_est) || ~isfinite(dt_est) || dt_est<=0
    % safe fallback; only used for tolerance
    dt_est = 0.01;
end

% enforce time window on t_ref (again, safe)
if ~isempty(opts.TimeWindow)
    tw = opts.TimeWindow;
    t_ref = t_ref((t_ref >= tw(1)) & (t_ref <= tw(2)));
end

nT = numel(t_ref);

% -------------------------------------------------------------------------
% 2) Allocate matrix: rows=70, cols=nT
% -------------------------------------------------------------------------
caseLabels = strings(numel(Points)*numel(Responses), 1);
caseP = nan(numel(caseLabels),1);
caseR = nan(numel(caseLabels),1);

% Ordering: rows by Response then Point (7 blocks of 10)
row = 0;
for R = Responses
    for P = Points
        row = row + 1;
        caseLabels(row) = sprintf('P%dR%d', P, R);
        caseP(row) = P;
        caseR(row) = R;
    end
end

H = nan(numel(caseLabels), nT);

% -------------------------------------------------------------------------
% 3) Fill H(row,:) by reading each case CSV and computing per-time statistic
% -------------------------------------------------------------------------
tolT = max(1e-12, 0.51 * dt_est);  % slightly > half dt

for row = 1:numel(caseLabels)
    P = caseP(row);
    R = caseR(row);

    caseDir = fullfile(outRoot, sprintf('P%d',P), sprintf('R%d',R));
    ff = dir(fullfile(caseDir, opts.FilePattern));
    if isempty(ff), continue; end
    [~,ix] = max([ff.datenum]);
    csvfile = fullfile(ff(ix).folder, ff(ix).name);

    [t, yobs, ypred] = local_read_min(csvfile);

    okT = isfinite(t);
    t = t(okT); yobs = yobs(okT); ypred = ypred(okT);

    switch series
        case "pred"
            y = ypred;
        case "obs"
            y = yobs;
        case "err"
            y = ypred - yobs;
        case "abs_err"
            y = abs(ypred - yobs);
        otherwise
            error('Unknown Series: %s', series);
    end

    % Apply time window
    if ~isempty(opts.TimeWindow)
        tw = opts.TimeWindow;
        keep = (t >= tw(1)) & (t <= tw(2));
        t = t(keep);
        y = y(keep);
    end
    if isempty(t), continue; end

    [tu,~,g] = unique(t, 'stable');
    ystat = group_stat(y, g, statName, opts.MinCount);

    y_aligned = nan(nT,1);

    % Prefer direct tolerant match, then fallback to nearest
    [tfound, loc] = ismembertol(t_ref, tu, tolT, 'DataScale', 1);
    if any(tfound)
        j = loc(tfound);
        y_aligned(tfound) = ystat(j);
    end

    % for remaining times, nearest fallback (handles rounding weirdness)
    missing = ~tfound;
    if any(missing)
        for k = find(missing(:))'
            [~,j] = min(abs(tu - t_ref(k)));
            if ~isempty(j) && isfinite(ystat(j))
                y_aligned(k) = ystat(j);
            end
        end
    end

    H(row,:) = y_aligned;
end

% -------------------------------------------------------------------------
% 4) Missing fill
% -------------------------------------------------------------------------
switch missingMode
    case "zero"
        H_f = H; H_f(~isfinite(H_f)) = 0;
    case "nan"
        H_f = H;
    otherwise
        error('Unknown MissingValue: %s', missingMode);
end

% -------------------------------------------------------------------------
% 5) Optional normalization
% -------------------------------------------------------------------------
H_plot = H_f;

switch normMode
    case "none"
        % nothing
    case "perrow"
        for i = 1:size(H_plot,1)
            v = H_plot(i,:);
            vv = v(isfinite(v));
            if numel(vv) < 5, continue; end
            med = median(vv);
            iqrV = iqr(vv); if iqrV==0, iqrV = 1; end
            H_plot(i,:) = (v - med) ./ iqrV;
        end
    case "perresponse"
        for ir = 1:numel(Responses)
            R = Responses(ir);
            rowsR = find(caseR == R);
            vv = H_plot(rowsR,:);
            vv = vv(isfinite(vv));
            if numel(vv) < 20, continue; end
            med = median(vv);
            iqrV = iqr(vv); if iqrV==0, iqrV = 1; end
            H_plot(rowsR,:) = (H_plot(rowsR,:) - med) ./ iqrV;
        end
    otherwise
        error('Unknown Normalize: %s', normMode);
end

% -------------------------------------------------------------------------
% 6) Plot heatmap
% -------------------------------------------------------------------------
fig = figure('Color','w', 'Name', char(opts.FigureName));
set(fig,'Renderer','opengl','RendererMode','manual');

imagesc(t_ref, 1:size(H_plot,1), H_plot);
set(gca,'YDir','normal');
colormap(gca, parula);
colorbar;

xlabel('Time (s)');
ylabel('Case (P#R#)');

ttl = sprintf('Heatmap | %s | %s across sims | SAFE-only via NaNs', upper(char(series)), upper(char(statName)));
if ~isempty(opts.TimeWindow)
    ttl = sprintf('%s | window [%.2f, %.2f] s', ttl, opts.TimeWindow(1), opts.TimeWindow(2));
end
if normMode ~= "none"
    ttl = sprintf('%s | normalized=%s', ttl, normMode);
end
title(ttl);

% y tick labels
switch showY
    case "all"
        yticks(1:numel(caseLabels));
        yticklabels(caseLabels);
    case "sparse"
        idx = 1:yStride:numel(caseLabels);
        yticks(idx);
        yticklabels(caseLabels(idx));
    case "none"
        yticks([]);
        yticklabels([]);
    otherwise
        error('Unknown ShowYLabels: %s', showY);
end

set(gca,'FontSize',9);

% -------------------------------------------------------------------------
% 7) Save (robust raster export)
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

% =========================================================================
% Helper: per-time-group statistic ignoring NaNs, with min count
% =========================================================================
function ystat = group_stat(y, g, statName, minCount)
g = g(:);
y = y(:);
if isempty(g)
    ystat = nan(0,1);
    return;
end

K = max(g);
ystat = nan(K,1);
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
