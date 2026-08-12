function plot_pga_cdfs_all70(FT_file, FULL_file, varargin)
% plot_pga_cdfs_all70(FT_file, FULL_file, ...)
% Empirical CDFs of PGA-at-failure for all 70 cases (P1..P10 x R1..R7).
%
% Uses:
%   FT (FAILURE_TIMES_v6.mat): failed_sim, step_fail (and/or fail_time)
%   FULL (FULL_ALL_POINTS_ALL_RESPONSES_XY.mat): FULL.Point(p).X(:,16) = PGA
%
% For each sim s that failed:
%   row = (step_fail(s)-1)*nsample + s  (time-major)
%   pga_fail(s) = X16(row)
%
% Options:
%   'Points'        : 1:10
%   'Responses'     : 1:7
%   'FailureMode'   : 'response' | 'point' | 'global'   (default 'response')
%   'MinFailed'     : minimum failed sims to plot CDF (default 10)
%   'FigMode'       : 'by_response' | 'all_in_one' | 'grid70'
%   'ShowMedian'    : true/false (default true)
%   'XLabel'        : 'PGA at failure (X(:,16))'
%   'SaveDir'       : '' (no save) or folder
%   'ExportDPI'     : 300
%   'FigPosition'   : [60 60 4200 2800]
%   'Padding'       : 'compact'
%   'TileSpacing'   : 'compact'
%   'FontName'      : 'Arial'
%   'FontSize'      : 18
%   'LineWidth'     : 1.8
%   'ThinWidth'     : 0.8
%
% House style:
%   - NO titles anywhere
%   - Grid70: show empty framed boxes for missing/insufficient data
%   - Global labels via tiledlayout (grid70)
%   - Y ticks fixed: [0 0.5 1] with labels {'0','0.5','1'}
%   - Legend top-right where used
%   - Robust PNG saving via print('-RGBImage')

% -------------------------
% Parse
% -------------------------
p = inputParser;
p.addRequired('FT_file',   @(s)ischar(s)||isstring(s));
p.addRequired('FULL_file', @(s)ischar(s)||isstring(s));

p.addParameter('Points',      1:10, @(x)isnumeric(x)&&isvector(x));
p.addParameter('Responses',   1:7,  @(x)isnumeric(x)&&isvector(x));
p.addParameter('FailureMode', 'response', @(s)ischar(s)||isstring(s));

p.addParameter('MinFailed',   10, @(x)isnumeric(x)&&isscalar(x));
p.addParameter('FigMode',     'by_response', @(s)ischar(s)||isstring(s)); % by_response|all_in_one|grid70
p.addParameter('ShowMedian',  true, @(x)islogical(x)&&isscalar(x));

p.addParameter('XLabel',      'PGA at failure (X(:,16))', @(s)ischar(s)||isstring(s));
p.addParameter('SaveDir',     '', @(s)ischar(s)||isstring(s));
p.addParameter('ExportDPI',   300, @(x)isnumeric(x)&&isscalar(x));

% House style knobs
p.addParameter('FigPosition', [60 60 4200 2800], @(x)isnumeric(x)&&numel(x)==4);
p.addParameter('Padding',     'compact', @(s)ischar(s)||isstring(s));
p.addParameter('TileSpacing', 'compact', @(s)ischar(s)||isstring(s));
p.addParameter('FontName',    'Arial', @(s)ischar(s)||isstring(s));
p.addParameter('FontSize',    18, @(x)isnumeric(x)&&isscalar(x));

p.addParameter('LineWidth',   1.8, @(x)isnumeric(x)&&isscalar(x));
p.addParameter('ThinWidth',   0.8, @(x)isnumeric(x)&&isscalar(x));

p.parse(FT_file, FULL_file, varargin{:});
opt = p.Results;

Points    = opt.Points(:)';     nP = numel(Points);
Responses = opt.Responses(:)';  nR = numel(Responses);

% -------------------------
% Load FT + FULL
% -------------------------
Sf = load(char(opt.FT_file));
if ~isfield(Sf,'FT'), error('FT not found inside: %s', char(opt.FT_file)); end
FT = Sf.FT;

Sx = load(char(opt.FULL_file), 'FULL');
if ~isfield(Sx,'FULL'), error('FULL not found inside: %s', char(opt.FULL_file)); end
FULL = Sx.FULL;

% meta
nsample = getfield_fallback(FT, {'meta','nsample'}, getfield_fallback(FULL, {'info','nsample'}, 300));

% -------------------------
% Compute PGA-fail vectors for all cases
% -------------------------
PGAfail = cell(nR, nP);   % PGAfail{ir,ip} is vector of PGA for failed sims
Nfail   = nan(nR, nP);

for ir = 1:nR
    r = Responses(ir);
    for ip = 1:nP
        pnt = Points(ip);

        [failed_sim, step_fail] = get_fail_pair(FT, opt.FailureMode, pnt, r, nsample);

        failed_sim = logical(failed_sim(:));
        if numel(failed_sim) ~= nsample
            tmp = false(nsample,1);
            tmp(1:min(nsample,numel(failed_sim))) = failed_sim(1:min(nsample,numel(failed_sim)));
            failed_sim = tmp;
        end

        sf = step_fail(:);
        if numel(sf) ~= nsample
            tmp = nan(nsample,1);
            tmp(1:min(nsample,numel(sf))) = sf(1:min(nsample,numel(sf)));
            sf = tmp;
        end

        nfail = nnz(failed_sim);
        Nfail(ir,ip) = nfail;

        if nfail < opt.MinFailed
            PGAfail{ir,ip} = [];
            continue;
        end

        P = FULL.Point(pnt);
        X16 = double(P.X(:,16));
        Nrows = numel(X16);

        pf = nan(nsample,1);
        for s = 1:nsample
            if ~failed_sim(s), continue; end
            step = sf(s);
            if ~isfinite(step) || step < 1, continue; end
            step = round(step);
            row = (step-1)*nsample + s;
            if row>=1 && row<=Nrows
                pf(s) = X16(row);
            end
        end

        pf = pf(failed_sim);
        pf = pf(isfinite(pf));
        if numel(pf) < opt.MinFailed
            pf = [];
        end

        PGAfail{ir,ip} = pf;
    end
end

% -------------------------
% Plot modes
% -------------------------
figMode = lower(string(opt.FigMode));
saveDir = char(opt.SaveDir);
doSave = ~isempty(saveDir);
if doSave && ~exist(saveDir,'dir'), mkdir(saveDir); end

switch figMode
    case "by_response"
        for ir = 1:nR
            r = Responses(ir);

            fig = figure('Color','w','Renderer','opengl');
            set(fig,'Units','pixels','Position',opt.FigPosition);

            ax = axes(fig); %#ok<LAXES>
            set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize);
            box(ax,'on'); grid(ax,'on'); hold(ax,'on');

            for ip=1:nP
                pnt = Points(ip);
                pf = PGAfail{ir,ip};
                if isempty(pf), continue; end

                [F,x] = ecdf(pf);
                plot(ax, x, F, 'LineWidth', opt.LineWidth, ...
                    'DisplayName', sprintf('P%d (n=%d)', pnt, numel(pf)));

                if opt.ShowMedian
                    med = median(pf);
                    plot(ax, [med med], [0 1], '--', 'LineWidth', 1.0, 'HandleVisibility','off');
                end
            end

            xlabel(ax, opt.XLabel, 'Interpreter','none');
            ylabel(ax, 'CDF', 'Interpreter','none');

            % House style Y ticks
            ax.YTick = [0 0.5 1];
            ax.YTickLabel = {'0','0.5','1'};

            legend(ax, 'Location','northeast', 'Interpreter','none');
            hold(ax,'off');

            if doSave
                outPng = fullfile(saveDir, sprintf('CDF_PGAfail_R%d_mode_%s.png', r, char(opt.FailureMode)));
                save_png_rgbimage(fig, outPng, opt.ExportDPI);
                fprintf('Saved: %s\n', outPng);
            end
        end

    case "all_in_one"
        fig = figure('Color','w','Renderer','opengl');
        set(fig,'Units','pixels','Position',opt.FigPosition);

        ax = axes(fig); %#ok<LAXES>
        set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize);
        box(ax,'on'); grid(ax,'on'); hold(ax,'on');

        for ir = 1:nR
            for ip = 1:nP
                pf = PGAfail{ir,ip};
                if isempty(pf), continue; end
                [F,x] = ecdf(pf);
                plot(ax, x, F, 'LineWidth', opt.ThinWidth);
            end
        end

        xlabel(ax, opt.XLabel, 'Interpreter','none');
        ylabel(ax, 'CDF', 'Interpreter','none');
        ax.YTick = [0 0.5 1];
        ax.YTickLabel = {'0','0.5','1'};

        hold(ax,'off');

        if doSave
            outPng = fullfile(saveDir, sprintf('CDF_PGAfail_ALL70_mode_%s.png', char(opt.FailureMode)));
            save_png_rgbimage(fig, outPng, opt.ExportDPI);
            fprintf('Saved: %s\n', outPng);
        end

    case "grid70"
        fig = figure('Color','w','Renderer','opengl');
        set(fig,'Units','pixels','Position',opt.FigPosition);

        tl = tiledlayout(fig, nR, nP, 'Padding',char(opt.Padding), 'TileSpacing',char(opt.TileSpacing));

        for ir=1:nR
            r = Responses(ir);
            for ip=1:nP
                pnt = Points(ip);

                ax = nexttile(tl);
                set(ax,'FontName',opt.FontName,'FontSize',opt.FontSize);
                box(ax,'on'); grid(ax,'on'); hold(ax,'on');

                pf = PGAfail{ir,ip};
                if ~isempty(pf)
                    [F,x] = ecdf(pf);
                    plot(ax, x, F, 'LineWidth', 1.2);
                end

                % House style Y ticks
                ax.YTick = [0 0.5 1];
                ax.YTickLabel = {'0','0.5','1'};

                % No per-tile titles. Use top-row and left-col labels only.
                if ir == 1
                    ax.Title.String = sprintf('P%d', pnt);
                    ax.Title.FontWeight = 'normal';
                end
                if ip == 1
                    ylabel(ax, sprintf('R%d', r), 'Interpreter','none');
                end

                % No xlabel/ylabel inside except global ones (below)
                hold(ax,'off');
            end
        end

        % Global labels (like your grid plots)
        xlabel(tl, opt.XLabel, 'Interpreter','none');
        ylabel(tl, 'CDF', 'Interpreter','none');

        if doSave
            outPng = fullfile(saveDir, sprintf('CDF_PGAfail_GRID70_mode_%s.png', char(opt.FailureMode)));
            save_png_rgbimage(fig, outPng, opt.ExportDPI);
            fprintf('Saved: %s\n', outPng);
        end

    otherwise
        error('Unknown FigMode="%s". Use by_response | all_in_one | grid70.', figMode);
end

end

% =====================================================================
% helpers
% =====================================================================
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
        if ~isfield(t, pathCell{k}), return; end
        t = t.(pathCell{k});
    end
    v = t;
catch
    v = defaultVal;
end
end

function [failed_sim, step_fail] = get_fail_pair(FT, mode, pnt, r, nsample)
failed_sim = false(nsample,1);
step_fail  = nan(nsample,1);

mode = lower(string(mode));
switch mode
    case "response"
        d = FT.resp(pnt, r).det;
        if isfield(d,'failed_sim') && ~isempty(d.failed_sim), failed_sim = d.failed_sim(:); end
        if isfield(d,'step_fail')  && ~isempty(d.step_fail),  step_fail  = d.step_fail(:);  end

    case "point"
        d = FT.point(pnt);
        if isfield(d,'failed_sim') && ~isempty(d.failed_sim), failed_sim = d.failed_sim(:); end
        if isfield(d,'step_fail')  && ~isempty(d.step_fail),  step_fail  = d.step_fail(:);  end

    case "global"
        d = FT.global;
        if isfield(d,'failed_sim') && ~isempty(d.failed_sim), failed_sim = d.failed_sim(:); end
        if isfield(d,'step_fail')  && ~isempty(d.step_fail),  step_fail  = d.step_fail(:);  end

    otherwise
        error('Unknown FailureMode="%s".', mode);
end
end