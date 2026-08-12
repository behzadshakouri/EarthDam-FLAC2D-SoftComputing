function plot_grid_obs_vs_pred_7x10(outRoot, varargin)
% 7x10 obs-vs-pred grid (packs tight like plot_pga_cdfs_grid70)
% - NO forced square plot-box (prevents x free-space)
% - Optional square DATA span (keeps 1:1 comparison fair)
% - True global axis labels via tiledlayout
% - Caller controls figure size via FigPosition

p = inputParser;
p.addRequired('outRoot', @(s)ischar(s)||isstring(s));

p.addParameter('Points',1:10);
p.addParameter('Responses',1:7);
p.addParameter('FilePattern','*_obs_pred.csv');
p.addParameter('MaxPerTile',4000);
p.addParameter('PctlLo',0.5);
p.addParameter('PctlHi',99.5);
p.addParameter('PadFrac',0.05);

p.addParameter('FigureName','ALL 70 | Observed vs Predicted (SAFE)', @(s)ischar(s)||isstring(s));

% layout / export
p.addParameter('Padding','compact');
p.addParameter('TileSpacing','compact');     % like CDF (tight, no weird x gaps)
p.addParameter('ExportDPI',300);
p.addParameter('SavePNG','');

% figure sizing (caller decides)
p.addParameter('FigPosition', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==4));

% labels / style
p.addParameter('MethodTag','ELM');
p.addParameter('ResponseLabels',[]);
p.addParameter('FontName','Arial');
p.addParameter('TileFontSize',7);
p.addParameter('HeaderFontSize',8);
p.addParameter('R2FontSize',7);
p.addParameter('MarkerSize',4);

% square behavior:
% SquareDataRange = true  -> make x/y span equal (good for 1:1 comparison)
% SquareTiles     = false -> DO NOT force square plot-box (avoids free space)
p.addParameter('SquareDataRange', true, @(x)islogical(x)&&isscalar(x));
p.addParameter('SquareTiles', false, @(x)islogical(x)&&isscalar(x));   % <<< default FALSE now

p.parse(outRoot,varargin{:});
opts = p.Results;

Points    = opts.Points(:)';     nP = numel(Points);
Responses = opts.Responses(:)';  nR = numel(Responses);

% default response labels (TOP->BOTTOM)
respLabels = opts.ResponseLabels;
if isempty(respLabels)
    respLabels = {
        '\Delta_x [m]'
        '\Delta_y [m]'
        '\sigma_{xx} [-]'
        '\sigma_{yy} [-]'
        'P_{pore} [-]'
        '\delta\gamma [-]'
        '\delta\nu_s [-]'
    };
end
if isstring(respLabels), respLabels = cellstr(respLabels); end

% locate newest CSV per tile
csvPath = strings(nR,nP);
for ir=1:nR
    for ip=1:nP
        d = fullfile(outRoot, sprintf('P%d',Points(ip)), sprintf('R%d',Responses(ir)));
        if ~exist(d,'dir'), continue; end
        ff = dir(fullfile(d, opts.FilePattern));
        if isempty(ff), continue; end
        [~,ix] = max([ff.datenum]);
        csvPath(ir,ip) = string(fullfile(ff(ix).folder, ff(ix).name));
    end
end

% FIGURE
fig = figure('Color','w','Renderer','opengl','Name',char(opts.FigureName));
set(fig,'Units','pixels');
if ~isempty(opts.FigPosition)
    set(fig,'Position', opts.FigPosition);
end

tl = tiledlayout(nR,nP, 'Padding',opts.Padding, 'TileSpacing',opts.TileSpacing);

for ir=1:nR
for ip=1:nP
    ax = nexttile(tl);
    set(ax,'FontName',opts.FontName,'FontSize',opts.TileFontSize);
    box(ax,'on'); hold(ax,'on');

    if csvPath(ir,ip)=="" || strlength(csvPath(ir,ip))==0
        axis(ax,'off'); continue;
    end

    T = readtable(csvPath(ir,ip));
    if ~all(ismember({'y_obs','y_pred'}, T.Properties.VariableNames))
        axis(ax,'off'); continue;
    end

    yobs  = T.y_obs;
    ypred = T.y_pred;
    ok = isfinite(yobs) & isfinite(ypred);
    if ~any(ok)
        axis(ax,[0 1 0 1]); continue;
    end

    % robust limits
    xlo = prctile(yobs(ok), opts.PctlLo);
    xhi = prctile(yobs(ok), opts.PctlHi);
    ylo = prctile(ypred(ok), opts.PctlLo);
    yhi = prctile(ypred(ok), opts.PctlHi);

    if xhi<=xlo, xhi=xlo+1; end
    if yhi<=ylo, yhi=ylo+1; end

    xpad = opts.PadFrac*(xhi-xlo);
    ypad = opts.PadFrac*(yhi-ylo);
    xmin = xlo-xpad; xmax=xhi+xpad;
    ymin = ylo-ypad; ymax=yhi+ypad;

    % square DATA span (optional)
    if opts.SquareDataRange
        cx = mean([xmin xmax]); cy = mean([ymin ymax]);
        span = max(xmax-xmin, ymax-ymin);
        xmin = cx-span/2; xmax=cx+span/2;
        ymin = cy-span/2; ymax=cy+span/2;
    end

    axis(ax,[xmin xmax ymin ymax]);

    % DO NOT force square plot-box unless explicitly requested
    if opts.SquareTiles
        set(ax,'PlotBoxAspectRatio',[1 1 1]);
    end

    % 1:1 line
    dmin = max(xmin,ymin); dmax = min(xmax,ymax);
    plot(ax,[dmin dmax],[dmin dmax],'k--','LineWidth',0.8);

    % scatter
    idx = find(ok);
    if numel(idx) > opts.MaxPerTile
        rng(1); idx = idx(randperm(numel(idx), opts.MaxPerTile));
    end
    plot(ax, yobs(idx), ypred(idx), '.', 'MarkerSize', opts.MarkerSize);

    % R^2
    denom = sum((yobs(ok)-mean(yobs(ok))).^2);
    r2 = NaN;
    if denom > 0
        r2 = 1 - sum((yobs(ok)-ypred(ok)).^2)/denom;
    end
    text(ax,0.02,0.98,sprintf('R^2=%.2f',r2), ...
        'Units','normalized','VerticalAlignment','top', ...
        'FontSize',opts.R2FontSize,'BackgroundColor','w','Margin',2);

    % headers/row labels
    if ir==1
        title(ax, sprintf('P%d',Points(ip)), 'FontSize',opts.HeaderFontSize,'FontWeight','bold');
    end
    if ip==1
        ylabel(ax, respLabels{ir}, 'FontSize',opts.HeaderFontSize, ...
            'FontWeight','bold','Interpreter','tex');
    end
end
end

xlabel(tl,'Observed (FLAC2D)', 'FontName',opts.FontName,'FontWeight','bold');
ylabel(tl,sprintf('Predicted (%s)', opts.MethodTag), 'FontName',opts.FontName,'FontWeight','bold');

if ~isempty(opts.SavePNG)
    drawnow;
    img = print(fig,'-RGBImage',sprintf('-r%d',opts.ExportDPI));
    imwrite(img, char(opts.SavePNG));
end
end
