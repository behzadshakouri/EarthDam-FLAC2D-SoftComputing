function T = compute_aggregated_metrics_normalized(modelRoot, varargin)
% Aggregates predictive performance over ALL monitoring points + time steps
% Reports: nRMSE, nMAE, R2, a10-index (%)

p = inputParser;
p.addRequired('modelRoot', @(s)ischar(s)||isstring(s));

p.addParameter('Points',    1:10);
p.addParameter('Responses', 1:7);
p.addParameter('FilePattern','*_obs_pred.csv');

p.addParameter('OutCSV',  fullfile(modelRoot,'AggregatedMetrics_NORMALIZED.csv'));
p.addParameter('OutXLSX', fullfile(modelRoot,'AggregatedMetrics_NORMALIZED.xlsx'));
p.addParameter('SheetName','Aggregated');

% Normalization percentiles
p.addParameter('NormPctl',[5 95]);

% a10 settings
p.addParameter('A10Band',0.10);
p.addParameter('ZeroObsTol',1e-12);
p.addParameter('ZeroAbsTol',1e-8);

defaultLabels = { ...
    'Horizontal Displacement (m)' ...
    'Vertical Displacement (m)' ...
    'Horizontal Stress \sigma_{xx} (Pa)' ...
    'Vertical Stress \sigma_{yy} (Pa)' ...
    'Pore Water Pressure (Pa)' ...
    'Shear Strain Increment (-)' ...
    'Volumetric Strain Increment (-)' ...
};
p.addParameter('ResponseLabels',defaultLabels);

p.parse(modelRoot,varargin{:});
opt = p.Results;

nR = numel(opt.Responses);
labels = opt.ResponseLabels;

OBS  = cell(nR,1);
PRED = cell(nR,1);

for ir = 1:nR
    OBS{ir}  = [];
    PRED{ir} = [];
end

% -------------------------------------------------------
% Collect data
% -------------------------------------------------------
for ip = opt.Points
    for ir = 1:nR

        R = opt.Responses(ir);
        folderPR = fullfile(modelRoot, sprintf('P%d',ip), sprintf('R%d',R));
        if ~exist(folderPR,'dir'), continue; end

        files = dir(fullfile(folderPR,opt.FilePattern));
        if isempty(files), continue; end

        [~,idx] = max([files.datenum]);
        fpath = fullfile(folderPR,files(idx).name);

        X = readmatrix(fpath);
        if size(X,2) < 2, continue; end

        obs  = X(:,end-1);
        pred = X(:,end);

        safe = isfinite(obs) & isfinite(pred);
        obs  = obs(safe);
        pred = pred(safe);

        OBS{ir}  = [OBS{ir}; obs];
        PRED{ir} = [PRED{ir}; pred];
    end
end

% -------------------------------------------------------
% Compute metrics
% -------------------------------------------------------
nrmse = nan(nR,1);
nmae  = nan(nR,1);
r2    = nan(nR,1);
a10   = nan(nR,1);
nSafe = zeros(nR,1);

for ir = 1:nR

    obs  = OBS{ir};
    pred = PRED{ir};
    nSafe(ir) = numel(obs);

    if isempty(obs), continue; end

    e = pred - obs;

    rmse = sqrt(mean(e.^2));
    mae  = mean(abs(e));

    % Robust normalization range
    pr = prctile(obs,opt.NormPctl);
    span = pr(2) - pr(1);

    if span > 0
        nrmse(ir) = rmse / span;
        nmae(ir)  = mae  / span;
    end

    % R2
    ss_res = sum((obs - pred).^2);
    ss_tot = sum((obs - mean(obs)).^2);
    if ss_tot > 0
        r2(ir) = 1 - ss_res/ss_tot;
    end

    % a10-index
    band = opt.A10Band;

    isZero = abs(obs) <= opt.ZeroObsTol;
    okZero = abs(pred(isZero)-obs(isZero)) <= opt.ZeroAbsTol;

    obsNZ  = obs(~isZero);
    predNZ = pred(~isZero);
    ratio  = predNZ ./ obsNZ;

    okNZ = ratio >= (1-band) & ratio <= (1+band);

    a10(ir) = 100*(sum(okNZ)+sum(okZero))/numel(obs);
end

% -------------------------------------------------------
% Output table
% -------------------------------------------------------
T = table(labels(:), nrmse, nmae, r2, a10, nSafe, ...
    'VariableNames',{'ResponseVariable','nRMSE','nMAE','R2','A10_percent','N_SAFE'});

writetable(T,opt.OutCSV);
writetable(T,opt.OutXLSX,'Sheet',opt.SheetName);

% -------------------------------------------------------
% Print LaTeX rows
% -------------------------------------------------------
fprintf('\nLaTeX rows (normalized metrics):\n');
for ir = 1:nR
    fprintf('%s & %.4f & %.4f & %.3f & %.1f \\\\\n', ...
        labels{ir}, nrmse(ir), nmae(ir), r2(ir), a10(ir));
end

fprintf('\nSaved:\n%s\n%s\n', opt.OutCSV, opt.OutXLSX);
end