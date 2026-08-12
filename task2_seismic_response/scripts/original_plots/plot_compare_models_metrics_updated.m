function plot_compare_models_metrics_updated(varargin)
% plot_compare_models_metrics_updated(...)
% Comparative plots over 70 cases (P1..P10 x R1..R7).
% Reads newest "*_obs_pred.csv" inside <ModelRoot>\P#\R#\
% or re-plots directly from a previously saved metrics CSV/XLSX file.
%
% Current style:
% - No timestamps in file names
% - Response separation by color + marker shape
% - Same response symbols in dashboard and delta-vs-baseline
% - Panel tags (a) (b) (c) (d) only
% - No subplot titles / no sgtitle
% - Winner plot y-axis fixed to total number of cases
% - Winner plot y-axis label shown only on panel (a)
% - Dashboard and delta legends sit in the top-center gap between top panels
% - Can load from saved COMPARE_models_metrics.csv / .xlsx

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
p.addParameter('ResponseLabels', {}, @(c)iscell(c) || isstring(c));
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

% Robust floors / clipping
p.addParameter('LogFloor',   1e-12, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('RatioFloor', 1e-12, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('DeltaClip',  inf,   @(x)isnumeric(x)&&isscalar(x)&&x>0);

% Marker controls
p.addParameter('ResponseMarkers', {'o','s','^','d','p','h','*'}, @(c)iscell(c)&&~isempty(c));
p.addParameter('MarkerSize', 42, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('MarkerEdgeColor', 'k', @(x)ischar(x)||isstring(x)||(isnumeric(x)&&numel(x)==3));
p.addParameter('MarkerLineWidth', 0.6, @(x)isnumeric(x)&&isscalar(x)&&x>=0);

% Legends
p.addParameter('ShowLegend', true, @(x)islogical(x)&&isscalar(x));
p.addParameter('DashboardLegendGap', true, @(x)islogical(x)&&isscalar(x));
p.addParameter('DeltaLegendGap',     true, @(x)islogical(x)&&isscalar(x));
p.addParameter('DashboardLegendPosition', [0.395 0.905 0.21 0.055], @(x)isnumeric(x)&&numel(x)==4);
p.addParameter('DeltaLegendPosition',     [0.395 0.905 0.21 0.055], @(x)isnumeric(x)&&numel(x)==4);
p.addParameter('DashboardLegendLocation', 'eastoutside', @(s)ischar(s)||isstring(s));
p.addParameter('DeltaLegendLocation',     'eastoutside', @(s)ischar(s)||isstring(s));
p.addParameter('WinsLegendLocation',      'south', @(s)ischar(s)||isstring(s));

% Load/save metrics table
p.addParameter('MetricsFile', '', @(s)ischar(s)||isstring(s));
p.addParameter('WriteExcel', true, @(x)islogical(x)&&isscalar(x));

% Model roots mapping (display-name -> root folder)
p.addParameter('RootByModel', struct(), @(s)isstruct(s));

p.parse(varargin{:});
opt = p.Results;

OutRoot = char(opt.OutRoot);
if isempty(OutRoot), error('Please provide OutRoot.'); end

SaveDir = char(opt.SaveDir);
if isempty(SaveDir), SaveDir = OutRoot; end
if ~exist(SaveDir,'dir'), mkdir(SaveDir); end

metricsFile = char(opt.MetricsFile);

Models   = cellfun(@char, opt.Models,  'uni',0);
Metrics  = cellfun(@char, opt.Metrics, 'uni',0);
Baseline = char(opt.Baseline);

Points    = opt.Points(:)';
Responses = opt.Responses(:)';
nR = numel(Responses);

dotBy         = lower(string(opt.DotBy));
errScale      = lower(string(opt.ErrorScale));
normScope     = lower(string(opt.NormScope));
normMethod    = lower(string(opt.NormMethod));
normRefModel  = char(opt.NormRefModel);
if isempty(normRefModel), normRefModel = Baseline; end

logFloor   = double(opt.LogFloor);
ratioFloor = double(opt.RatioFloor);
deltaClip  = double(opt.DeltaClip);

responseMarkers = opt.ResponseMarkers(:)';
markerSize      = opt.MarkerSize;
markerEdgeColor = opt.MarkerEdgeColor;
markerLineWidth = opt.MarkerLineWidth;

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

if strcmpi(char(dotBy), 'response') && numel(responseMarkers) < nR
    error('ResponseMarkers must have at least one marker per response.');
end

if ~any(strcmpi(Models, Baseline))
    error('Baseline "%s" must be included in Models.', Baseline);
end

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
if isempty(metricsFile)
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
end

% =========================
% Per-response normalization scales
% =========================
respScale = [];
if isempty(metricsFile) && errScale == "normalized" && normScope == "per_response"
    refRoot = modelRoots.(matlab.lang.makeValidName(normRefModel));
    respScale = compute_response_scales(refRoot, Points, Responses, ...
        opt.FilePattern, opt.MinSafe, normMethod, opt.NormEps);
end

% =========================
% Collect metrics table OR load from saved file
% =========================
if ~isempty(metricsFile)
    if ~exist(metricsFile,'file')
        error('MetricsFile not found:\n%s', metricsFile);
    end

    [~,~,ext] = fileparts(metricsFile);
    switch lower(ext)
        case '.csv'
            T = readtable(metricsFile);
        case {'.xlsx','.xls'}
            T = readtable(metricsFile);
        otherwise
            error('Unsupported MetricsFile extension: %s', ext);
    end

    requiredVars = {'Model','Point','Response','CaseID','R2','RMSE','MAE','a10','NRMSE','NMAE'};
    for iReq = 1:numel(requiredVars)
        if ~ismember(requiredVars{iReq}, T.Properties.VariableNames)
            error('MetricsFile is missing required column: %s', requiredVars{iReq});
        end
    end

    if ~ismember('nSAFE', T.Properties.VariableNames)
        T.nSAFE = NaN(height(T),1);
    end
    if ~ismember('NormScaleUsed', T.Properties.VariableNames)
        T.NormScaleUsed = NaN(height(T),1);
    end
    if ~ismember('File', T.Properties.VariableNames)
        T.File = strings(height(T),1);
    end

    if ~isstring(T.Model),  T.Model  = string(T.Model);  end
    if ~isstring(T.CaseID), T.CaseID = string(T.CaseID); end
    if ~isstring(T.File),   T.File   = string(T.File);   end

    T = restrict_metrics_table(T, Models, Points, Responses);

else
    rows = [];
    for i=1:numel(Models)
        m = Models{i};
        mroot = modelRoots.(matlab.lang.makeValidName(m));

        for ip=1:numel(Points)
            pnt = Points(ip);
            for ir=1:numel(Responses)
                rsp = Responses(ir);

                csvFile = newest_obs_pred_csv(mroot, pnt, rsp, opt.FilePattern);

                if strlength(csvFile)==0
                    r = make_row(m, pnt, rsp, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, "");
                    rows = [rows; r]; %#ok<AGROW>
                    continue;
                end

                [R2, RMSE, MAE, a10, nSafe, scaleCase] = ...
                    compute_metrics_from_obs_pred(csvFile, opt.MinSafe, normMethod, opt.NormEps);

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

                r = make_row(m, pnt, rsp, R2, RMSE, MAE, a10, ...
                    NRMSE, NMAE, scaleUse, nSafe, string(csvFile));
                rows = [rows; r]; %#ok<AGROW>
            end
        end
    end

    T = struct2table(rows);
end

plotMetricNames = Metrics;
if errScale == "normalized"
    plotMetricNames = replace(plotMetricNames, "RMSE", "NRMSE");
    plotMetricNames = replace(plotMetricNames, "MAE",  "NMAE");
end

outCSV = fullfile(SaveDir, 'COMPARE_models_metrics.csv');
writetable(T, outCSV);

if opt.WriteExcel
    outXLSX = fullfile(SaveDir, 'COMPARE_models_metrics.xlsx');
    writetable(T, outXLSX, 'FileType', 'spreadsheet');
end

[dotLabels, dotColorIdx, dotLegendTitle] = make_dot_grouping(T, Points, Responses, dotBy, respLabels);
if dotBy ~= "none"
    dotCmap = lines(max(numel(dotLabels), 10));
else
    dotCmap = [];
end

panelTags = {'(a)','(b)','(c)','(d)'};
modelPos = 1:numel(Models);

% =========================
% Figure 1: Dashboard
% =========================
fig1 = figure('Color','w','Renderer','opengl','Name','COMPARE Dashboard');
set(fig1,'Units','pixels','Position',opt.FigPosition);
tl1 = tiledlayout(fig1, 2, 2, 'Padding',char(opt.Padding), 'TileSpacing',char(opt.TileSpacing));

dashboardLegend = [];
dashboardLegendAnchorAx = [];

for k=1:min(4, numel(plotMetricNames))
    metric = char(plotMetricNames{k});
    ax = nexttile(tl1);
    set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize);
    box(ax,'on'); grid(ax,'on'); hold(ax,'on');

    y = T.(metric);
    grp = nan(height(T),1);
    modelCell = cellstr(T.Model);
    for ii = 1:numel(Models)
        grp(strcmpi(modelCell, Models{ii})) = ii;
    end

    yPlot = y;
    if errScale == "log" && any(strcmp(metric, {'RMSE','MAE','NRMSE','NMAE'}))
        yPlot = sanitize_for_log(yPlot, logFloor);
    end

    maskBox = isfinite(yPlot) & isfinite(grp);
    if any(maskBox)
        boxplot(ax, yPlot(maskBox), grp(maskBox), ...
            'Positions', modelPos, ...
            'Whisker', 1.5, 'Symbol','');
    end

    xnum = grp;
    jitter = (rand(size(xnum))-0.5) * 2 * opt.JitterFrac;

    if dotBy == "none"
        maskSc = isfinite(yPlot) & isfinite(xnum);
        scatter(ax, xnum(maskSc) + jitter(maskSc), yPlot(maskSc), markerSize, ...
            'Marker', 'o', ...
            'MarkerFaceColor', [0.35 0.35 0.35], ...
            'MarkerEdgeColor', markerEdgeColor, ...
            'LineWidth', markerLineWidth, ...
            'MarkerFaceAlpha', 0.60, ...
            'MarkerEdgeAlpha', 0.35);

    elseif dotBy == "response"
        legendHandles = gobjects(numel(dotLabels),1);
        for g=1:numel(dotLabels)
            mask = (dotColorIdx == g) & isfinite(yPlot) & isfinite(xnum);
            if ~any(mask), continue; end

            legendHandles(g) = scatter(ax, ...
                xnum(mask) + jitter(mask), yPlot(mask), markerSize, ...
                'Marker', responseMarkers{g}, ...
                'MarkerFaceColor', dotCmap(g,:), ...
                'MarkerEdgeColor', markerEdgeColor, ...
                'LineWidth', markerLineWidth, ...
                'MarkerFaceAlpha', 0.78, ...
                'MarkerEdgeAlpha', 0.85);
        end

        if k == 1 && opt.ShowLegend
            validH = isgraphics(legendHandles);
            dashboardLegend = legend(ax, legendHandles(validH), dotLabels(validH), ...
                'Location', char(opt.DashboardLegendLocation), ...
                'Interpreter','tex', ...
                'FontSize', max(10,opt.FontSize-3), ...
                'Box','on');
            title(dashboardLegend, dotLegendTitle, 'Interpreter','none');
            dashboardLegendAnchorAx = ax;
        end
    else
        legendHandles = gobjects(numel(dotLabels),1);
        for g=1:numel(dotLabels)
            mask = (dotColorIdx == g) & isfinite(yPlot) & isfinite(xnum);
            if ~any(mask), continue; end

            legendHandles(g) = scatter(ax, ...
                xnum(mask) + jitter(mask), yPlot(mask), markerSize, ...
                'Marker', 'o', ...
                'MarkerFaceColor', dotCmap(g,:), ...
                'MarkerEdgeColor', markerEdgeColor, ...
                'LineWidth', markerLineWidth, ...
                'MarkerFaceAlpha', 0.75, ...
                'MarkerEdgeAlpha', 0.80);
        end

        if k == 1 && opt.ShowLegend
            validH = isgraphics(legendHandles);
            dashboardLegend = legend(ax, legendHandles(validH), dotLabels(validH), ...
                'Location', char(opt.DashboardLegendLocation), ...
                'Interpreter','none', ...
                'FontSize', max(10,opt.FontSize-3), ...
                'Box','on');
            title(dashboardLegend, dotLegendTitle, 'Interpreter','none');
            dashboardLegendAnchorAx = ax;
        end
    end

    set(ax,'XTick',modelPos,'XTickLabel',Models);
    xlim(ax, [0.5, numel(Models)+0.5]);

    if errScale == "log" && any(strcmp(metric, {'RMSE','MAE','NRMSE','NMAE'}))
        set(ax,'YScale','log');
        positiveVals = yPlot(isfinite(yPlot) & yPlot > 0);
        if isempty(positiveVals)
            ylim(ax,[logFloor, 10*logFloor]);
        else
            ymin = max(min(positiveVals), logFloor);
            ymax = max(positiveVals);
            if ymax <= ymin
                ymax = 10*ymin;
            end
            ylim(ax, [ymin, ymax*1.08]);
        end
    end

    [ylab, yinterp] = metric_ylabel(metric, errScale);
    ylabel(ax, ylab, 'Interpreter', yinterp);

    annotate_panel(ax, panelTags{k}, opt.FontName, opt.FontSize);
    hold(ax,'off');
end

if opt.ShowLegend && opt.DashboardLegendGap && isgraphics(dashboardLegend)
    set(dashboardLegend, 'Units','normalized');
    set(dashboardLegend, 'Position', opt.DashboardLegendPosition);
end

outPng1 = fullfile(SaveDir, 'COMPARE_dashboard.png');
save_png_rgbimage(fig1, outPng1, opt.ExportDPI);

% =========================
% Figure 2: Win / Top-2 counts
% =========================
fig2 = figure('Color','w','Renderer','opengl','Name','COMPARE Wins/Top2');
pos2 = opt.FigPosition;
pos2(4) = round(pos2(4)*0.80);
set(fig2,'Units','pixels','Position',pos2);
tl2 = tiledlayout(fig2, 2, 2, 'Padding',char(opt.Padding), 'TileSpacing',char(opt.TileSpacing));

caseKeys = unique(T.CaseID);
nCases = numel(caseKeys);
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
    ax = nexttile(tl2);
    set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize);
    box(ax,'on'); grid(ax,'on'); hold(ax,'on');

    W  = winCounts(k,:);
    T2 = top2Counts(k,:);

    bh = bar(ax, modelPos, [W(:), (T2(:)-W(:))], 'stacked', 'BarWidth', 0.80);
    set(ax,'XTick',modelPos,'XTickLabel',Models);
    xlim(ax, [0.5, numel(Models)+0.5]);

    if k == 1
        ylabel(ax, sprintf('Count (out of %d)', nCases), 'Interpreter','none');
        if opt.ShowLegend
            lg2 = legend(ax, bh, {'Winner','Top-2'}, ...
                'Location', char(opt.WinsLegendLocation), ...
                'Interpreter','none', ...
                'Box','on');
            lg2.FontSize = max(10,opt.FontSize-3);
        end
    else
        ylabel(ax, '');
    end

    ylim(ax, [0 nCases]);
    annotate_panel(ax, panelTags{k}, opt.FontName, opt.FontSize);
    hold(ax,'off');
end

outPng2 = fullfile(SaveDir, 'COMPARE_wins_top2.png');
save_png_rgbimage(fig2, outPng2, opt.ExportDPI);

% =========================
% Figure 3: Delta vs baseline
% =========================
fig3 = figure('Color','w','Renderer','opengl','Name','COMPARE Delta vs Baseline');
set(fig3,'Units','pixels','Position',opt.FigPosition);
tl3 = tiledlayout(fig3, 2, 2, 'Padding',char(opt.Padding), 'TileSpacing',char(opt.TileSpacing));

baseIdx = find(strcmpi(Models, Baseline), 1);
hybModels = Models;
hybModels(baseIdx) = [];
hybPos = 1:numel(hybModels);

deltaLegend = [];

for k=1:min(4,numel(plotMetricNames))
    metric = char(plotMetricNames{k});
    ax = nexttile(tl3);
    set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize);
    box(ax,'on'); grid(ax,'on'); hold(ax,'on');

    allD   = [];
    allX   = [];
    allRsp = [];

    for ii=1:numel(hybModels)
        hm = hybModels{ii};

        D  = nan(numel(caseKeys),1);
        RR = nan(numel(caseKeys),1);

        for c=1:numel(caseKeys)
            ck = caseKeys(c);

            vb = get_case_metric(T, ck, Baseline, metric);
            vh = get_case_metric(T, ck, hm,      metric);

            if ~isfinite(vb) || ~isfinite(vh)
                D(c)  = NaN;
                RR(c) = NaN;
                continue;
            end

            if any(strcmp(metric, {'RMSE','MAE','NRMSE','NMAE'}))
                nume = max(vh, ratioFloor);
                deno = max(vb, ratioFloor);
                D(c) = log10(nume / deno);
            else
                D(c) = vh - vb;
            end

            if isfinite(deltaClip)
                D(c) = max(min(D(c), deltaClip), -deltaClip);
            end

            RR(c) = parse_response_from_caseid(ck);
        end

        allD   = [allD; D]; %#ok<AGROW>
        allRsp = [allRsp; RR]; %#ok<AGROW>
        allX   = [allX; repmat(ii, numel(D), 1)]; %#ok<AGROW>
    end

    maskBox = isfinite(allD) & isfinite(allX);
    if any(maskBox)
        boxplot(ax, allD(maskBox), allX(maskBox), ...
            'Positions', hybPos, ...
            'Whisker', 1.5, 'Symbol','');
    end

    yline(ax, 0, '-', 'LineWidth', 1.2);

    jitter = (rand(size(allX))-0.5) * 2 * opt.JitterFrac;

    legendHandles = gobjects(numel(Responses),1);
    for g=1:numel(Responses)
        rr = Responses(g);
        mask = isfinite(allD) & isfinite(allX) & (allRsp == rr);
        if ~any(mask), continue; end

        legendHandles(g) = scatter(ax, ...
            allX(mask) + jitter(mask), allD(mask), markerSize, ...
            'Marker', responseMarkers{g}, ...
            'MarkerFaceColor', dotCmap(g,:), ...
            'MarkerEdgeColor', markerEdgeColor, ...
            'LineWidth', markerLineWidth, ...
            'MarkerFaceAlpha', 0.78, ...
            'MarkerEdgeAlpha', 0.85);
    end

    set(ax,'XTick',hybPos,'XTickLabel',hybModels);
    xlim(ax, [0.5, numel(hybModels)+0.5]);

    if k == 1 && opt.ShowLegend
        validH = isgraphics(legendHandles);
        deltaLegend = legend(ax, legendHandles(validH), dotLabels(validH), ...
            'Location', char(opt.DeltaLegendLocation), ...
            'Interpreter','tex', ...
            'FontSize', max(10,opt.FontSize-3), ...
            'Box','on');
        title(deltaLegend, dotLegendTitle, 'Interpreter','none');
    end

    if any(strcmp(metric, {'RMSE','MAE','NRMSE','NMAE'}))
        ylabel(ax, sprintf('log_{10}(%s / %s)', metric_display(metric), Baseline), 'Interpreter','tex');
    else
        ylabel(ax, sprintf('\\Delta%s vs %s', metric_display(metric), Baseline), 'Interpreter','tex');
    end

    annotate_panel(ax, panelTags{k}, opt.FontName, opt.FontSize);
    hold(ax,'off');
end

if opt.ShowLegend && opt.DeltaLegendGap && isgraphics(deltaLegend)
    set(deltaLegend, 'Units','normalized');
    set(deltaLegend, 'Position', opt.DeltaLegendPosition);
end

outPng3 = fullfile(SaveDir, ['COMPARE_delta_vs_' Baseline '.png']);
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

function y = sanitize_for_log(y, floorVal)
y = double(y);
bad = ~isfinite(y) | y <= 0;
y(bad) = NaN;
good = isfinite(y) & y > 0;
y(good) = max(y(good), floorVal);
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
ref = abs(yobs);
ref(ref < eps) = eps;
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

function T = restrict_metrics_table(T, Models, Points, Responses)
keep = ismember(cellstr(T.Model), Models) & ismember(T.Point, Points) & ismember(T.Response, Responses);
T = T(keep,:);
end

function v = get_case_metric(T, caseID, model, metric)
ii = find(strcmp(T.CaseID, caseID) & strcmpi(cellstr(T.Model), model), 1);
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
            labels{i} = respLabels{rr};
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
interp = 'tex';
switch metric
    case 'R2'
        ylab = 'R^{2}';
    case 'a10'
        ylab = 'a10-index';
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
        if errScale == "log"
            ylab = 'nRMSE (log scale)';
        else
            ylab = 'nRMSE';
        end
    case 'NMAE'
        if errScale == "log"
            ylab = 'nMAE (log scale)';
        else
            ylab = 'nMAE';
        end
    otherwise
        ylab = metric;
        interp = 'none';
end
end

function s = metric_display(metric)
switch metric
    case 'R2',    s = 'R^{2}';
    case 'a10',   s = 'a10';
    case 'NRMSE', s = 'nRMSE';
    case 'NMAE',  s = 'nMAE';
    otherwise,    s = metric;
end
end

function annotate_panel(ax, tagText, fontName, fontSize)
text(ax, 0.02, 0.98, tagText, ...
    'Units','normalized', ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','top', ...
    'FontName',fontName, ...
    'FontSize',fontSize, ...
    'FontWeight','bold', ...
    'Interpreter','none', ...
    'BackgroundColor','w', ...
    'Margin',1);
end

function rr = parse_response_from_caseid(caseID)
tok = regexp(char(caseID), 'R(\d+)$', 'tokens', 'once');
if isempty(tok)
    rr = NaN;
else
    rr = str2double(tok{1});
end
end