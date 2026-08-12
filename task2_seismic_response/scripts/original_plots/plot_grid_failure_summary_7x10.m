function plot_grid_failure_summary_7x10(FT_file, FULL_file, varargin)
% plot_grid_failure_summary_7x10(FT_file, FULL_file, ...)
% One "all-in-one" heatmap for 70 cases (R rows x P cols).
% Uses FT for failure timing (failed_sim/step_fail/fail_time), FULL for PGA at failure X(:,16).
%
% ColorBy:
%   't_median'   (default) median failure time [s]
%   'pga_median'          median failure PGA at failure
%   'fail_pct'            percent failed sims
%   'fail_count'          count failed sims
%
% FailureMode: 'response' | 'point' | 'global'
%
% House style:
% - NO titles anywhere
% - P labels on TOP
% - Response names via ResponseLabels (tex)
% - Robust PNG saving via print('-RGBImage')
% - Luminance-based text color using current colormap

% =========================
% Parse inputs
% =========================
p = inputParser;
p.addRequired('FT_file',   @(s)ischar(s)||isstring(s));
p.addRequired('FULL_file', @(s)ischar(s)||isstring(s));

p.addParameter('Points',        1:10, @(x)isnumeric(x)&&isvector(x));
p.addParameter('Responses',     1:7,  @(x)isnumeric(x)&&isvector(x));
p.addParameter('FailureMode',   'response', @(s)ischar(s)||isstring(s));

p.addParameter('ColorBy',       't_median', @(s)ischar(s)||isstring(s)); % t_median|pga_median|fail_pct|fail_count
p.addParameter('FailCountMode', 'count',    @(s)ischar(s)||isstring(s)); % percent|count (affects annotation label only)

p.addParameter('ShowValues',    true, @(x)islogical(x)&&isscalar(x));
p.addParameter('ValueFormatT',  '%.2f', @(s)ischar(s)||isstring(s));   % seconds
p.addParameter('ValueFormatPGA','%.3g', @(s)ischar(s)||isstring(s));   % PGA
p.addParameter('ValueFormatF',  '%.0f', @(s)ischar(s)||isstring(s));   % fail % or count

p.addParameter('Colormap',      'hot', @(s)ischar(s)||isstring(s));
p.addParameter('RobustLimits',  true, @(x)islogical(x)&&isscalar(x));
p.addParameter('CLimPctl',      [5 95], @(x)isnumeric(x)&&numel(x)==2);

% Response names
p.addParameter('ResponseLabels', {}, @(c)iscell(c)||isstring(c));

p.addParameter('SaveDir',       '', @(s)ischar(s)||isstring(s));
p.addParameter('ExportDPI',     300, @(x)isnumeric(x)&&isscalar(x));

% House style knobs (replace MinFigPixels)
p.addParameter('FigPosition',   [60 60 4200 2800], @(x)isnumeric(x)&&numel(x)==4);
p.addParameter('FontName',      'Arial', @(s)ischar(s)||isstring(s));
p.addParameter('AxisFontSize',  18, @(x)isnumeric(x)&&isscalar(x));
p.addParameter('CellFontSize',  11, @(x)isnumeric(x)&&isscalar(x));
p.addParameter('FontWeight',    'bold', @(s)ischar(s)||isstring(s));

% Text contrast
p.addParameter('TextLuminanceThresh', 0.60, @(x)isnumeric(x)&&isscalar(x)); % >thresh => black text else white
p.addParameter('TextNaNColor', [0.25 0.25 0.25], @(x)isnumeric(x)&&numel(x)==3);

p.parse(FT_file, FULL_file, varargin{:});
opt = p.Results;

FT_file   = char(opt.FT_file);
FULL_file = char(opt.FULL_file);

Points    = opt.Points(:)';     nP = numel(Points);
Responses = opt.Responses(:)';  nR = numel(Responses);

% =========================
% Response labels
% =========================
respLabels = opt.ResponseLabels;
if isstring(respLabels), respLabels = cellstr(respLabels); end
if isempty(respLabels)
    respLabels = cell(max(Responses),1);
    for rr=1:max(Responses)
        respLabels{rr} = sprintf('R%d', rr);
    end
else
    if numel(respLabels) < max(Responses)
        error('ResponseLabels must cover at least max(Responses).');
    end
    respLabels = respLabels(:);
end

% =========================
% Load FT + FULL
% =========================
Sf = load(FT_file);
if ~isfield(Sf,'FT'), error('FT not found inside: %s', FT_file); end
FT = Sf.FT;

Sx = load(FULL_file, 'FULL');
if ~isfield(Sx,'FULL'), error('FULL not found inside: %s', FULL_file); end
FULL = Sx.FULL;

% Prefer meta from FT if present; fallback to FULL.info
nsample = getfield_fallback(FT,   {'meta','nsample'},    getfield_fallback(FULL, {'info','nsample'}, 300));
sec_num = getfield_fallback(FT,   {'meta','sec_num'},    getfield_fallback(FULL, {'info','sec_num'}, 100));
start_t = getfield_fallback(FT,   {'meta','start_time'}, getfield_fallback(FULL, {'info','start_time'}, 0));

% =========================
% Compute matrices
% =========================
Tmed   = nan(nR,nP);     % median failure time [s]
PGAmed = nan(nR,nP);     % median failure PGA at failure
Fcnt   = nan(nR,nP);     % failed count
Fpct   = nan(nR,nP);     % failed percent

for ir = 1:nR
    r = Responses(ir);
    for ip = 1:nP
        pnt = Points(ip);

        [failed_sim, step_fail, fail_time] = get_failure_triplet(FT, opt.FailureMode, pnt, r, nsample);

        failed_sim = logical(failed_sim(:));
        if numel(failed_sim) ~= nsample
            tmp = false(nsample,1);
            m = min(numel(failed_sim), nsample);
            tmp(1:m) = failed_sim(1:m);
            failed_sim = tmp;
        end

        % normalize vectors to nsample
        sf = step_fail(:);
        if numel(sf) ~= nsample
            tmp = nan(nsample,1);
            m = min(numel(sf), nsample);
            tmp(1:m) = sf(1:m);
            sf = tmp;
        end

        ft = fail_time(:);
        if numel(ft) ~= nsample
            tmp = nan(nsample,1);
            m = min(numel(ft), nsample);
            tmp(1:m) = ft(1:m);
            ft = tmp;
        end

        % If fail_time missing, compute from step_fail
        if isempty(ft) || all(~isfinite(ft))
            if any(isfinite(sf))
                ft = (sf - 1)./sec_num + start_t;
            else
                ft = nan(nsample,1);
            end
        end

        % ---- fail stats ----
        nfail = nnz(failed_sim);
        Fcnt(ir,ip) = nfail;
        Fpct(ir,ip) = 100 * nfail / nsample;

        % ---- median time over failed sims ----
        tvals = ft(failed_sim);
        tvals = tvals(isfinite(tvals) & tvals >= 0);
        if ~isempty(tvals), Tmed(ir,ip) = median(tvals); end

        % ---- median PGA at failure (needs step_fail) ----
        P = FULL.Point(pnt);
        if ~isfield(P,'X') || size(P.X,2) < 16
            PGAmed(ir,ip) = nan;
            continue;
        end

        X16 = double(P.X(:,16));
        Nrows = numel(X16);

        pga_fail = nan(nsample,1);
        for s = 1:nsample
            if ~failed_sim(s), continue; end
            step = sf(s);
            if ~isfinite(step) || step < 1, continue; end
            step = round(step);
            row = (step-1)*nsample + s;
            if row >= 1 && row <= Nrows
                pga_fail(s) = X16(row);
            end
        end

        pf = pga_fail(failed_sim);
        pf = pf(isfinite(pf));
        if ~isempty(pf), PGAmed(ir,ip) = median(pf); end
    end
end

% =========================
% Choose color matrix
% =========================
colorBy = lower(string(opt.ColorBy));
switch colorBy
    case "t_median"
        Z = Tmed;
        cbarLabel = 'Median failure time (s)';
    case "pga_median"
        Z = PGAmed;
        cbarLabel = 'Median failure PGA (X(:,16))';
    case "fail_pct"
        Z = Fpct;
        cbarLabel = 'Failed sims (%)';
    case "fail_count"
        Z = Fcnt;
        cbarLabel = 'Failed sims (count)';
    otherwise
        error('Unknown ColorBy="%s".', opt.ColorBy);
end

% =========================
% Color limits
% =========================
Zvec = Z(isfinite(Z));
if isempty(Zvec)
    clim = [0 1];
elseif opt.RobustLimits
    clim = prctile(Zvec, opt.CLimPctl);
    if ~all(isfinite(clim)) || clim(1) == clim(2)
        clim = [min(Zvec) max(Zvec)];
    end
else
    clim = [min(Zvec) max(Zvec)];
end
if ~all(isfinite(clim)) || clim(1)==clim(2)
    clim = [0 1];
end

% =========================
% Plot (NO title)
% =========================
fig = figure('Color','w','Renderer','opengl');
set(fig,'Units','pixels','Position',opt.FigPosition);

ax = axes(fig); %#ok<LAXES>
set(ax,'FontName',opt.FontName,'FontSize',opt.AxisFontSize);

imagesc(ax, Z);
set(ax,'YDir','normal');
colormap(ax, char(opt.Colormap));
caxis(ax, clim);

hcb = colorbar(ax);
ylabel(hcb, cbarLabel, 'Interpreter','none', 'FontName',opt.FontName, 'FontSize',opt.AxisFontSize);

% P labels on TOP only
ax.XAxisLocation = 'top';

ax.XTick = 1:nP;
ax.XTickLabel = arrayfun(@(x)sprintf('P%d',x), Points, 'uni',0);

ax.YTick = 1:nR;
yl = cell(nR,1);
for ir=1:nR
    yl{ir} = respLabels{Responses(ir)};
end
ax.YTickLabel = yl;
ax.TickLabelInterpreter = 'tex';

% minimal axis labels (keep or remove as you like)
xlabel(ax, 'Point',    'Interpreter','none');
ylabel(ax, 'Response', 'Interpreter','none');

set(ax,'TickLength',[0 0]);
box(ax,'on');

% Cache colormap for luminance decisions
cmap = colormap(ax);

% =========================
% Cell annotations (t + PGA + fail)
% =========================
if opt.ShowValues
    for ir = 1:nR
        for ip = 1:nP
            t50  = Tmed(ir,ip);
            p50  = PGAmed(ir,ip);
            fcnt = Fcnt(ir,ip);
            fpct = Fpct(ir,ip);

            if isfinite(t50), sT = sprintf(opt.ValueFormatT, t50); else, sT = 'NaN'; end
            if isfinite(p50), sP = sprintf(opt.ValueFormatPGA, p50); else, sP = 'NaN'; end

            switch lower(string(opt.FailCountMode))
                case "percent"
                    if isfinite(fpct), sF = sprintf(opt.ValueFormatF, fpct); else, sF='NaN'; end
                    sF = [sF '%'];
                case "count"
                    if isfinite(fcnt), sF = sprintf(opt.ValueFormatF, fcnt); else, sF='NaN'; end
                otherwise
                    error('FailCountMode must be "percent" or "count".');
            end

            txt = sprintf('t=%s\nPGA=%s\nfail=%s', sT, sP, sF);

            % luminance-based text color (based on Z)
            z = Z(ir,ip);
            if isfinite(z)
                tc = pick_text_color_from_colormap(z, clim, cmap, opt.TextLuminanceThresh);
            else
                tc = opt.TextNaNColor;
            end

            text(ax, ip, ir, txt, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontName',opt.FontName, ...
                'FontSize',opt.CellFontSize, ...
                'FontWeight',char(opt.FontWeight), ...
                'Interpreter','none', ...
                'Color', tc);
        end
    end
end

% =========================
% Save (robust)
% =========================
if ~isempty(opt.SaveDir)
    sd = char(opt.SaveDir);
    if ~exist(sd,'dir'), mkdir(sd); end
    outPng = fullfile(sd, sprintf('ALL70_failure_summary_mode_%s_color_%s.png', ...
        char(opt.FailureMode), char(colorBy)));
    save_png_rgbimage(fig, outPng, opt.ExportDPI);
    fprintf('Saved:\n  %s\n', outPng);
end

end % main


% =========================
% Subfunctions
% =========================
function save_png_rgbimage(fig, filename, dpi)
drawnow;
img = print(fig,'-RGBImage',sprintf('-r%d',dpi));
imwrite(img, filename);
end

function v = getfield_fallback(S, pathCell, defaultVal)
v = defaultVal;
try
    t = S;
    for k=1:numel(pathCell)
        if ~isstruct(t) || ~isfield(t, pathCell{k})
            v = defaultVal;
            return;
        end
        t = t.(pathCell{k});
    end
    v = t;
catch
    v = defaultVal;
end
end

function tc = pick_text_color_from_colormap(z, clim, cmap, lumThresh)
nC = size(cmap,1);
den = max(clim(2)-clim(1), eps);
idx = 1 + (nC-1) * (z - clim(1)) / den;
idx = round(idx);
idx = min(max(idx,1), nC);

rgb = cmap(idx,:);
lum = 0.2126*rgb(1) + 0.7152*rgb(2) + 0.0722*rgb(3);

if lum > lumThresh
    tc = 'k';
else
    tc = 'w';
end
end

function [failed_sim, step_fail, fail_time] = get_failure_triplet(FT, mode, pnt, r, nsample)
failed_sim = false(nsample,1);
step_fail  = nan(nsample,1);
fail_time  = nan(nsample,1);

mode = lower(string(mode));
switch mode
    case "response"
        d = FT.resp(pnt, r).det;
    case "point"
        d = FT.point(pnt);
    case "global"
        d = FT.global;
    otherwise
        error('Unknown FailureMode="%s".', mode);
end

if isfield(d,'failed_sim') && ~isempty(d.failed_sim), failed_sim = d.failed_sim(:); end
if isfield(d,'step_fail')  && ~isempty(d.step_fail),  step_fail  = d.step_fail(:);  end
if isfield(d,'fail_time')  && ~isempty(d.fail_time),  fail_time  = d.fail_time(:);  end

% pad/trim to nsample
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
if numel(fail_time) < nsample
    fail_time(end+1:nsample) = NaN;
else
    fail_time = fail_time(1:nsample);
end
end