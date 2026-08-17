function plot_compare_models_metrics(varargin)
% plot_compare_models_metrics(...)
% Comparative plots over 70 cases (P1..P10 x R1..R7).
% Reads newest "*_obs_pred.csv" inside <ModelRoot>\P#\R#\
%
% Requested style updates:
% - Show R-squared and a_{10}-index labels
% - Legend (winner/top2) in top-right corner
% - Dashboard: nRMSE / nMAE (no scale text), no SAFE-only in axis labels
% - Remove titles everywhere (no subplot titles, no sgtitle)
% - Dot legend uses real response names (ResponseLabels), not R1..R7
% - Model display names keep dashes (ELM-ABC, ...) while folders can differ via RootByModel

% =========================
% Parse inputs
% =========================
p = inputParser;

p.addParameter('OutRoot', '', @(s)ischar(s)||isstring(s));
p.addParameter('SaveDir', '', @(s)ischar(s)||isstring(s));

p.addParameter('Models',  {'ELM','ELM-IGWO','ELM-ACOR','ELM-ABC'}, @(c)iscell(c)&&~isempty(c));
p.addParameter('Metrics', {'R2','RMSE','MAE','a10'}, @(c)iscell(c)&&~isempty(c));
p.addParameter('Baseline','ELM', @(s)ischar(s)||isstring(s));

p.addParameter('Points',     1:10, @(x)isnumeric(x)&&isvector(x));
p.addParameter('Responses',  1:7,  @(x)isnumeric(x)&&isvector(x));
p.addParameter('ResponseLabels', {}, @(c)iscell(c) || isstring(c)); % <<< NEW
p.addParameter('FilePattern','*_obs_pred.csv', @(s)ischar(s)||isstring(s));
p.addParameter('MinSafe',     50, @(x)isnumeric(x)&&isscalar(x));

% Style / layout
p.addParameter('FigPosition',[60 60 4200 2800], @(x)isnumeric(x)&&numel(x)==4);
p.addParameter('ExportDPI',  300, @(x)isnumeric(x)&&isscalar(x));
p.addParameter('Padding',    'compact', @(s)ischar(s)||isstring(s));
p.addParameter('TileSpacing','compact', @(s)ischar(s)||isstring(s));
p.addParameter('FontName',   'Arial', @(s)ischar(s)||isstring(s));
p.addParameter('FontSize',   18, @(x)isnumeric(x)&&isscalar(x));
p.addParameter('JitterFrac', 0.18, @(x)isnumeric(x)&&isscalar(x));

% Dot & error scaling controls
p.addParameter('DotBy','response', @(s)ischar(s)||isstring(s));         % response|point|none
p.addParameter('ErrorScale','raw', @(s)ischar(s)||isstring(s));         % raw|log|normalized
p.addParameter('NormScope','per_response', @(s)ischar(s)||isstring(s)); % per_response|per_case
p.addParameter('NormMethod','p95p5', @(s)ischar(s)||isstring(s));       % p95p5|iqr|std|medianabs
p.addParameter('NormRefModel','', @(s)ischar(s)||isstring(s));          % default Baseline
p.addParameter('NormEps', 1e-12, @(x)isnumeric(x)&&isscalar(x));

% Fig3 log-ratio denominator floor
p.addParameter('RatioFloor', 1e-12, @(x)isnumeric(x)&&isscalar(x));

% Model roots mapping (display-name -> root folder)
p.addParameter('RootByModel', struct(), @(s)isstruct(s));

p.parse(varargin{:});
opt = p.Results;

OutRoot = char(opt.OutRoot);
if isempty(OutRoot), error('Please provide OutRoot.'); end

SaveDir = char(opt.SaveDir);
if isempty(SaveDir), SaveDir = OutRoot; end
if ~exist(SaveDir,'dir'), mkdir(SaveDir); end

Models   = cellfun(@char, opt.Models,  'uni',0);
Metrics  = cellfun(@char, opt.Metrics, 'uni',0);
Baseline = char(opt.Baseline);

Points    = opt.Points(:)';     nP = numel(Points);
Responses = opt.Responses(:)';  nR = numel(Responses);

dotBy      = lower(string(opt.DotBy));
errScale   = lower(string(opt.ErrorScale));
normScope  = lower(string(opt.NormScope));
normMethod = lower(string(opt.NormMethod));
normRefModel = char(opt.NormRefModel);
if isempty(normRefModel), normRefModel = Baseline; end

ratioFloor = double(opt.RatioFloor);

% Response labels (for DotBy=response legend)
respLabels = opt.ResponseLabels;
if isstring(respLabels), respLabels = cellstr(respLabels); end
if isempty(respLabels)
    respLabels = arrayfun(@(r)sprintf('R%d',r), Responses, 'uni',0);
else
    if numel(respLabels) < max(Responses)
        error('ResponseLabels must cover at least max(Response) entries.');
    end
    respLabels = respLabels(:);
end

% Validate baseline
if ~any(strcmpi(Models, Baseline))
    error('Baseline "%s" must be included in Models.', Baseline);
end

% Metric directions (+1 higher better; -1 lower better)
metricDir = containers.Map();
metricDir('R2')    = +1;
metricDir('a10')   = +1;
metricDir('RMSE')  = -1;
metricDir('MAE')   = -1;
metricDir('NRMSE') = -1;
metricDir('NMAE')  = -1;

% =========================
% Resolve model roots
% =========================
modelRoots = struct();
for i=1:numel(Models)
    m  = Models{i};
    fn = matlab.lang.makeValidName(m);

    mr = '';
    if isfield(opt.RootByModel, fn)
        mr = opt.RootByModel.(fn);
    elseif isfield(opt.RootByModel, m)
        mr = opt.RootByModel.(m);
    end

    if ~isempty(mr)
        mr = char(mr);
        if ~exist(mr,'dir')
            error('RootByModel for "%s" does not exist:\n%s', m, mr);
        end
        modelRoots.(fn) = mr;
    else
        modelRoots.(fn) = find_model_root(OutRoot, m);
    end
end

% =========================
% Per-response normalization scales (optional)
% =========================
respScale = [];
if errScale == "normalized" && normScope == "per_response"
    refRoot = modelRoots.(matlab.lang.makeValidName(normRefModel));
    respScale = compute_response_scales(refRoot, Points, Responses, opt.FilePattern, opt.MinSafe, normMethod, opt.NormEps);
end

% =========================
% Collect metrics table
% =========================
rows = [];
for i=1:numel(Models)
    m = Models{i};
    mroot = modelRoots.(matlab.lang.makeValidName(m));

    for ip=1:nP
        pnt = Points(ip);
        for ir=1:nR
            rsp = Responses(ir);

            csvFile = newest_obs_pred_csv(mroot, pnt, rsp, opt.FilePattern);

            if strlength(csvFile)==0
                r = make_row(m, pnt, rsp, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, "");
                rows = [rows; r]; %#ok<AGROW>
                continue;
            end

            [R2, RMSE, MAE, a10, nSafe, scaleCase] = compute_metrics_from_obs_pred(csvFile, opt.MinSafe, normMethod, opt.NormEps);

            if errScale == "normalized"
                if normScope == "per_response" && ~isempty(respScale)
                    scaleUse = respScale(rsp);
                else
                    scaleUse = scaleCase;
                end

                if isfinite(scaleUse) && scaleUse > 0
                    NRMSE = RMSE / scaleUse;
                    NMAE  = MAE  / scaleUse;
                else
                    NRMSE = NaN;
                    NMAE  = NaN;
                end
            else
                NRMSE = NaN;
                NMAE  = NaN;
                scaleUse = NaN;
            end

            r = make_row(m, pnt, rsp, R2, RMSE, MAE, a10, NRMSE, NMAE, scaleUse, nSafe, string(csvFile));
            rows = [rows; r]; %#ok<AGROW>
        end
    end
end

T = struct2table(rows);

% Decide plotting metric names (variable names)
plotMetricNames = Metrics;
if errScale == "normalized"
    plotMetricNames = replace(plotMetricNames, "RMSE", "NRMSE");
    plotMetricNames = replace(plotMetricNames, "MAE",  "NMAE");
end

% Save combined metrics CSV
stamp = datestr(now,'yyyymmdd_HHMMSS');
outCSV = fullfile(SaveDir, sprintf('COMPARE_models_metrics_%s.csv', stamp));
writetable(T, outCSV);

% Dot grouping
[dotLabels, dotColorIdx, dotLegendTitle] = make_dot_grouping(T, Points, Responses, dotBy, respLabels);
if dotBy ~= "none"
    dotCmap = lines(max(numel(dotLabels), 10));
else
    dotCmap = [];
end

% =========================
% Figure 1: Dashboard (NO titles)
% =========================
fig1 = figure('Color','w','Renderer','opengl','Name','COMPARE Dashboard');
set(fig1,'Units','pixels','Position',opt.FigPosition);
tl = tiledlayout(fig1, 2, 2, 'Padding',char(opt.Padding), 'TileSpacing',char(opt.TileSpacing));

for k=1:min(4, numel(plotMetricNames))
    metric = char(plotMetricNames{k});
    ax = nexttile(tl);
    set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize);
    box(ax,'on'); grid(ax,'on'); hold(ax,'on');

    cats = categorical(T.Model, Models, 'Ordinal', true);
    y = T.(metric);

    boxplot(ax, y, cats, 'Whisker', 1.5, 'Symbol','');

    xnum = double(cats);
    jitter = (rand(size(xnum))-0.5) * 2 * opt.JitterFrac;

    if dotBy == "none"
        scatter(ax, xnum + jitter, y, 18, 'filled', 'MarkerFaceAlpha', 0.55, 'MarkerEdgeAlpha', 0.2);
    else
        for g=1:numel(dotLabels)
            mask = (dotColorIdx == g) & isfinite(y) & isfinite(xnum);
            if ~any(mask), continue; end
            scatter(ax, xnum(mask) + jitter(mask), y(mask), 18, 'filled', ...
                'MarkerFaceColor', dotCmap(g,:), ...
                'MarkerFaceAlpha', 0.60, ...
                'MarkerEdgeAlpha', 0.15);
        end
    end

    if errScale == "log" && any(strcmp(metric, {'RMSE','MAE'}))
        yl = ylim(ax);
        if ~all(isfinite(yl)) || yl(2) <= 0
            ylim(ax,[1e-16, 1]);
        end
        set(ax,'YScale','log');
    end

    [ylab, yinterp] = metric_ylabel(metric, errScale);
    ylabel(ax, ylab, 'Interpreter', yinterp);

    % NO subplot titles
    % title(ax, ... ) removed

    if k == 1 && dotBy ~= "none"
        % Use explicit scatter handles so legend colors correspond to the
        % response groups rather than to boxplot line objects.
        hh=gobjects(numel(dotLabels),1);
        for g=1:numel(dotLabels)
            hh(g)=scatter(ax,nan,nan,24,dotCmap(g,:),'filled');
        end
        lg = legend(ax,hh,dotLabels, 'Location','eastoutside', 'Interpreter','tex');
        title(lg, dotLegendTitle, 'Interpreter','none');
        lg.Box='on'; lg.Color='w'; lg.FontName=opt.FontName;
    end

    add_panel_label(ax,k,opt.FontName,opt.FontSize);
    hold(ax,'off');
end

outPng1 = fullfile(SaveDir, sprintf('COMPARE_dashboard_%s.png', stamp));
save_png_rgbimage(fig1, outPng1, opt.ExportDPI);

% =========================
% Figure 2: Win / Top-2 counts (NO titles, legend top-right)
% =========================
fig2 = figure('Color','w','Renderer','opengl','Name','COMPARE Wins/Top2');
pos2 = opt.FigPosition; pos2(4) = round(pos2(4)*0.80);
set(fig2,'Units','pixels','Position',pos2);
tiledlayout(fig2, 2, 2, 'Padding',char(opt.Padding), 'TileSpacing',char(opt.TileSpacing));

caseKeys = unique(T.CaseID);
nM = numel(Models);
winCounts  = zeros(numel(plotMetricNames), nM);
top2Counts = zeros(numel(plotMetricNames), nM);

for k=1:numel(plotMetricNames)
    metric = char(plotMetricNames{k});
    dirSign = metricDir(metric);

    for c=1:numel(caseKeys)
        ck = caseKeys(c);

        vals = nan(1,nM);
        for ii=1:nM
            vals(ii) = get_case_metric(T, ck, Models{ii}, metric);
        end

        finiteMask = isfinite(vals);
        if nnz(finiteMask) < 2, continue; end

        if dirSign < 0
            [~, ord] = sort(vals, 'ascend');
        else
            [~, ord] = sort(vals, 'descend');
        end

        ord = ord(isfinite(vals(ord)));
        if isempty(ord), continue; end

        winCounts(k, ord(1)) = winCounts(k, ord(1)) + 1;
        top2 = ord(1:min(2,numel(ord)));
        top2Counts(k, top2) = top2Counts(k, top2) + 1;
    end
end

for k=1:min(4,numel(plotMetricNames))
    metric = char(plotMetricNames{k});
    ax = nexttile;
    set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize);
    box(ax,'on'); grid(ax,'on'); hold(ax,'on');

    W  = winCounts(k,:);
    T2 = top2Counts(k,:);

    bar(ax, categorical(Models, Models, 'Ordinal', true), [W(:), (T2(:)-W(:))], 'stacked');

    ylabel(ax, sprintf('Count (out of %d)', numel(caseKeys)), 'Interpreter','none');

    % One horizontal legend outside the first panel avoids obscuring bars.
    if k==1
        lg=legend(ax, {'Winner','Top-2 (excluding wins)'}, ...
            'Location','northoutside','Orientation','horizontal', ...
            'Interpreter','none');
        lg.Box='on'; lg.Color='w'; lg.FontName=opt.FontName;
    end

    % NO subplot titles
    add_panel_label(ax,k,opt.FontName,opt.FontSize);
    hold(ax,'off');
end

outPng2 = fullfile(SaveDir, sprintf('COMPARE_wins_top2_%s.png', stamp));
save_png_rgbimage(fig2, outPng2, opt.ExportDPI);

% =========================
% Figure 3: Delta vs baseline (NO titles)
% =========================
fig3 = figure('Color','w','Renderer','opengl','Name','COMPARE Delta vs Baseline');
set(fig3,'Units','pixels','Position',opt.FigPosition);
tl3 = tiledlayout(fig3, 2, 2, 'Padding',char(opt.Padding), 'TileSpacing',char(opt.TileSpacing));

baseIdx = find(strcmpi(Models, Baseline), 1);
hybModels = Models;
hybModels(baseIdx) = [];

for k=1:min(4,numel(plotMetricNames))
    metric = char(plotMetricNames{k});
    ax = nexttile(tl3);
    set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize);
    box(ax,'on'); grid(ax,'on'); hold(ax,'on');

    allD = [];
    allC = categorical({}, hybModels, 'Ordinal', true);

    for ii=1:numel(hybModels)
        hm = hybModels{ii};

        D = nan(numel(caseKeys),1);
        for c=1:numel(caseKeys)
            ck = caseKeys(c);

            vb = get_case_metric(T, ck, Baseline, metric);
            vh = get_case_metric(T, ck, hm,      metric);

            if ~isfinite(vb) || ~isfinite(vh)
                D(c) = NaN;
                continue;
            end

            if any(strcmp(metric, {'RMSE','MAE','NRMSE','NMAE'}))
                denom = max(vb, ratioFloor);
                D(c) = log10(vh / denom);
            else
                D(c) = vh - vb;
            end
        end

        allD = [allD; D]; %#ok<AGROW>
        allC = [allC; repmat(categorical({hm}, hybModels, 'Ordinal', true), numel(D), 1)]; %#ok<AGROW>
    end

    boxplot(ax, allD, allC, 'Whisker', 1.5, 'Symbol','');
    yline(ax, 0, '-', 'LineWidth', 1.5);

    xnum = double(allC);
    jitter = (rand(size(xnum))-0.5) * 2 * opt.JitterFrac;
    scatter(ax, xnum + jitter, allD, 14, 'filled', 'MarkerFaceAlpha', 0.45, 'MarkerEdgeAlpha', 0.15);

    if any(strcmp(metric, {'RMSE','MAE','NRMSE','NMAE'}))
        ylabel(ax, sprintf('log_{10}(%s / %s)', metric_display(metric), Baseline), 'Interpreter','tex');
    else
        ylabel(ax, sprintf('\\Delta%s vs %s', metric_display(metric), Baseline), 'Interpreter','tex');
    end

    % NO subplot titles
    add_panel_label(ax,k,opt.FontName,opt.FontSize);
    hold(ax,'off');
end

outPng3 = fullfile(SaveDir, sprintf('COMPARE_delta_vs_%s_%s.png', Baseline, stamp));
save_png_rgbimage(fig3, outPng3, opt.ExportDPI);

end % main


% =====================================================================
% Helpers
% =====================================================================

function save_png_rgbimage(fig, filename, dpi)
drawnow;
img = print(fig,'-RGBImage',sprintf('-r%d',dpi));
imwrite(img, filename);
end

function add_panel_label(ax,k,fontName,fontSize)
letters='abcd';
text(ax,0.015,0.975,sprintf('(%c)',letters(k)), ...
    'Units','normalized','HorizontalAlignment','left', ...
    'VerticalAlignment','top','FontName',fontName, ...
    'FontSize',fontSize,'FontWeight','bold','Color','k');
end

function r = make_row(model, pnt, rsp, R2, RMSE, MAE, a10, NRMSE, NMAE, normScaleUsed, nSafe, file)
r = struct();
r.Model = string(model);
r.Point = pnt;
r.Response = rsp;
r.CaseID = string(sprintf('P%dR%d', pnt, rsp));
r.R2 = R2;
r.RMSE = RMSE;
r.MAE = MAE;
r.a10 = a10;
r.NRMSE = NRMSE;
r.NMAE  = NMAE;
r.NormScaleUsed = normScaleUsed;
r.nSAFE = nSafe;
r.File  = string(file);
end

function root = find_model_root(outRoot, modelName)
d = dir(outRoot);
d = d([d.isdir]);
names = setdiff({d.name},{'.','..'});

cand = fullfile(outRoot, modelName);
if exist(cand,'dir'), root = cand; return; end

idx = find(strcmpi(names, modelName), 1);
if ~isempty(idx), root = fullfile(outRoot, names{idx}); return; end

tok = lower(regexprep(modelName,'[^a-zA-Z0-9]',''));
toks = cellfun(@(s)lower(regexprep(s,'[^a-zA-Z0-9]','')), names, 'uni',0);
idx = find(strcmp(toks, tok), 1);
if ~isempty(idx), root = fullfile(outRoot, names{idx}); return; end

idx = find(contains(lower(names), lower(modelName)), 1);
if ~isempty(idx), root = fullfile(outRoot, names{idx}); return; end

if ~isempty(tok)
    idx = find(contains(cellfun(@lower, names, 'uni',0), tok), 1);
    if ~isempty(idx), root = fullfile(outRoot, names{idx}); return; end
end

error('Could not auto-find model root for "%s" under OutRoot:\n  %s\nProvide RootByModel.', modelName, outRoot);
end

function f = newest_obs_pred_csv(modelRoot, pnt, rsp, pattern)
caseDir = fullfile(modelRoot, sprintf('P%d', pnt), sprintf('R%d', rsp));
if ~exist(caseDir,'dir'), f = ""; return; end
dd = dir(fullfile(caseDir, char(pattern)));
if isempty(dd), f = ""; return; end
[~, ix] = max([dd.datenum]);
f = string(fullfile(dd(ix).folder, dd(ix).name));
end

function [R2, RMSE, MAE, a10, nSafe, scaleCase] = compute_metrics_from_obs_pred(csvFile, minSafe, normMethod, normEps)
R2 = NaN; RMSE = NaN; MAE = NaN; a10 = NaN; nSafe = 0; scaleCase = NaN;

try
    Tb = readtable(csvFile);
catch
    return;
end

vnames = lower(string(Tb.Properties.VariableNames));
obsIdx = find(contains(vnames,'obs'), 1);
predIdx= find(contains(vnames,'pred'),1);

if isempty(obsIdx) || isempty(predIdx)
    obsIdx = find(ismember(vnames, ["y_obs","obs","ytrue","true"]), 1);
    predIdx= find(ismember(vnames, ["y_pred","pred","ypred"]), 1);
end
if isempty(obsIdx) || isempty(predIdx), return; end

yobs = double(Tb{:,obsIdx});
ypred= double(Tb{:,predIdx});

safe = isfinite(yobs) & isfinite(ypred);
yobs = yobs(safe);
ypred= ypred(safe);
nSafe = numel(yobs);
if nSafe < minSafe, return; end

err = ypred - yobs;

RMSE = sqrt(mean(err.^2));
MAE  = mean(abs(err));

RMSE = max(RMSE, eps);
MAE  = max(MAE,  eps);

den = sum((yobs - mean(yobs)).^2);
if den > 0
    R2 = 1 - sum((yobs - ypred).^2) / den;
end

tol = 0.10;
ref = abs(yobs); ref(ref < eps) = eps;
a10 = mean(abs(err) <= tol * ref);

scaleCase = robust_scale_from_obs(yobs, normMethod, normEps);
end

function s = robust_scale_from_obs(yobs, normMethod, normEps)
switch lower(string(normMethod))
    case "p95p5"
        s = prctile(yobs,95) - prctile(yobs,5);
    case "iqr"
        s = iqr(yobs);
    case "std"
        s = std(yobs);
    case "medianabs"
        s = median(abs(yobs));
    otherwise
        s = prctile(yobs,95) - prctile(yobs,5);
end
s = max(s, normEps);
end

function respScale = compute_response_scales(refRoot, Points, Responses, filePattern, minSafe, normMethod, normEps)
respScale = nan(max(Responses), 1);

for ir=1:numel(Responses)
    r = Responses(ir);
    sp = nan(numel(Points),1);

    for ip=1:numel(Points)
        pnt = Points(ip);
        f = newest_obs_pred_csv(refRoot, pnt, r, filePattern);
        if strlength(f)==0, continue; end

        try
            Tb = readtable(f);
        catch
            continue;
        end

        vnames = lower(string(Tb.Properties.VariableNames));
        obsIdx = find(contains(vnames,'obs'), 1);
        predIdx= find(contains(vnames,'pred'),1);

        if isempty(obsIdx)
            obsIdx = find(ismember(vnames, ["y_obs","obs","ytrue","true"]), 1);
        end
        if isempty(obsIdx), continue; end

        yobs = double(Tb{:,obsIdx});
        if ~isempty(predIdx)
            ypred = double(Tb{:,predIdx});
            safe = isfinite(yobs) & isfinite(ypred);
        else
            safe = isfinite(yobs);
        end

        yobs = yobs(safe);
        if numel(yobs) < minSafe, continue; end

        sp(ip) = robust_scale_from_obs(yobs, normMethod, normEps);
    end

    sp = sp(isfinite(sp));
    if isempty(sp)
        respScale(r) = normEps;
    else
        respScale(r) = max(median(sp), normEps);
    end
end
end

function v = get_case_metric(T, caseID, model, metric)
ii = find(strcmp(T.CaseID, caseID) & strcmpi(T.Model, model), 1);
if isempty(ii)
    v = NaN;
else
    v = T.(metric)(ii);
end
end

function [labels, colorIdx, legendTitle] = make_dot_grouping(T, Points, Responses, dotBy, respLabels)
switch dotBy
    case "response"
        labels = cell(numel(Responses),1);
        for i=1:numel(Responses)
            rr = Responses(i);
            labels{i} = respLabels{rr}; % real response names
        end
        legendTitle = "Response";
        colorIdx = nan(height(T),1);
        for i=1:numel(Responses)
            colorIdx(T.Response == Responses(i)) = i;
        end
    case "point"
        labels = arrayfun(@(p)sprintf('P%d', p), Points, 'uni',0);
        legendTitle = "Point";
        colorIdx = nan(height(T),1);
        for i=1:numel(Points)
            colorIdx(T.Point == Points(i)) = i;
        end
    otherwise
        labels = {};
        legendTitle = "";
        colorIdx = nan(height(T),1);
end
end

function [ylab, interp] = metric_ylabel(metric, errScale)
% Dashboard y-axis label (no SAFE-only, no scale details)
interp = 'tex';
switch metric
    case 'R2'
        ylab = 'R^{2}';
    case 'a10'
        ylab = 'a_{10}-index';
    case 'RMSE'
        if errScale == "log"
            ylab = 'RMSE (log scale)';
        else
            ylab = 'RMSE';
        end
    case 'MAE'
        if errScale == "log"
            ylab = 'MAE (log scale)';
        else
            ylab = 'MAE';
        end
    case 'NRMSE'
        ylab = 'nRMSE';
    case 'NMAE'
        ylab = 'nMAE';
    otherwise
        ylab = metric;
        interp = 'none';
end
end

function s = metric_display(metric)
% For Fig3 text only (uses your preferred names)
switch metric
    case 'R2',    s = 'R^{2}';
    case 'a10',   s = 'a_{10}';
    case 'NRMSE', s = 'nRMSE';
    case 'NMAE',  s = 'nMAE';
    otherwise,    s = metric;
end
end
