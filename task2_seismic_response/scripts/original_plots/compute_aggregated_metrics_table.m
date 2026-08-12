function T = compute_aggregated_metrics_table(modelRoot, varargin)
% compute_aggregated_metrics_table(modelRoot, ...)
% Aggregates predictive performance over ALL monitoring points and time steps.
%
% Assumes files exist under:
%   modelRoot\P#\R#\*_obs_pred.csv
%
% Robust to CSV formats:
% - If header contains variables named like obs/pred => uses them
% - Otherwise uses the LAST TWO numeric columns as [obs, pred]
%
% Metrics (SAFE-only):
%   RMSE, MAE, R2, a10-index (%)
%
% Outputs:
%   - Writes CSV + XLSX
%   - Prints LaTeX rows for the table
%   - Returns table T

p = inputParser;
p.addRequired('modelRoot', @(s)ischar(s)||isstring(s));

p.addParameter('Points',    1:10);
p.addParameter('Responses', 1:7);

p.addParameter('FilePattern', '*_obs_pred.csv');
p.addParameter('OutCSV',  fullfile(modelRoot, 'AggregatedMetrics_ALL.csv'));
p.addParameter('OutXLSX', fullfile(modelRoot, 'AggregatedMetrics_ALL.xlsx'));
p.addParameter('SheetName', 'Aggregated');

% a10 definition handling near-zero obs
p.addParameter('ZeroObsTol', 1e-12);          % |obs| <= tol treated as "zero"
p.addParameter('ZeroAbsTol', 1e-8);           % for zero-obs points: |pred-obs| <= ZeroAbsTol counts as within 10%
p.addParameter('A10Band', 0.10);              % 10% band (0.10 => 0.9..1.1)

% Response labels (edit to your exact names)
defaultLabels = { ...
    'Horizontal Displacement (m)' ...
    'Vertical Displacement (m)' ...
    'Horizontal Stress \sigma_{xx} (Pa)' ...
    'Vertical Stress \sigma_{yy} (Pa)' ...
    'Pore Water Pressure (Pa)' ...
    'Shear Strain Increment (-)' ...
    'Volumetric Strain Increment (-)' ...
};
p.addParameter('ResponseLabels', defaultLabels);

% optional: also compute normalized metrics (not used in your LaTeX table)
p.addParameter('ComputeNormalized', false);

p.parse(modelRoot, varargin{:});
opt = p.Results;

modelRoot = char(modelRoot);

nR = numel(opt.Responses);
labels = opt.ResponseLabels;
if numel(labels) ~= nR
    error('ResponseLabels must have same length as Responses.');
end

% Accumulators per response
OBS = cell(nR,1);
PRED = cell(nR,1);
for ir = 1:nR
    OBS{ir}  = [];
    PRED{ir} = [];
end

% -----------------------------------------
% Crawl folders and collect obs/pred
% -----------------------------------------
for ip = opt.Points
    for ir = 1:nR
        R = opt.Responses(ir);

        folderPR = fullfile(modelRoot, sprintf('P%d', ip), sprintf('R%d', R));
        if ~exist(folderPR, 'dir')
            % silently skip missing cases (keeps pipeline resilient)
            continue;
        end

        files = dir(fullfile(folderPR, opt.FilePattern));
        if isempty(files)
            continue;
        end

        % Use newest file in that folder
        [~, idxNewest] = max([files.datenum]);
        fpath = fullfile(folderPR, files(idxNewest).name);

        [obs, pred] = read_obs_pred_any(fpath);

        % SAFE mask (finite pairs only)
        safe = isfinite(obs) & isfinite(pred);
        obs  = obs(safe);
        pred = pred(safe);

        if isempty(obs)
            continue;
        end

        OBS{ir}  = [OBS{ir};  obs(:)];  %#ok<AGROW>
        PRED{ir} = [PRED{ir}; pred(:)]; %#ok<AGROW>
    end
end

% -----------------------------------------
% Compute metrics per response
% -----------------------------------------
rmse = nan(nR,1);
mae  = nan(nR,1);
r2   = nan(nR,1);
a10  = nan(nR,1);

nSafe = zeros(nR,1);

% Optional normalized metrics
nrmse = nan(nR,1);
nmae  = nan(nR,1);

for ir = 1:nR
    obs  = OBS{ir};
    pred = PRED{ir};
    nSafe(ir) = numel(obs);

    if isempty(obs)
        continue;
    end

    e = pred - obs;

    rmse(ir) = sqrt(mean(e.^2));
    mae(ir)  = mean(abs(e));

    % R^2
    ss_res = sum((obs - pred).^2);
    ss_tot = sum((obs - mean(obs)).^2);
    if ss_tot > 0
        r2(ir) = 1 - ss_res/ss_tot;
    else
        r2(ir) = NaN; % degenerate (all obs identical)
    end

    % a10-index (%): within ±10% in ratio space for nonzero obs;
    % for near-zero obs use absolute tolerance.
    band = opt.A10Band;

    isZero = abs(obs) <= opt.ZeroObsTol;
    okZero = abs(pred(isZero) - obs(isZero)) <= opt.ZeroAbsTol;

    obsNZ  = obs(~isZero);
    predNZ = pred(~isZero);
    ratio  = predNZ ./ obsNZ;

    okNZ = (ratio >= (1-band)) & (ratio <= (1+band));

    a10(ir) = 100 * (sum(okNZ) + sum(okZero)) / numel(obs);

    % Optional normalized
    if opt.ComputeNormalized
        span = prctile(obs, 95) - prctile(obs, 5);
        if span > 0
            nrmse(ir) = rmse(ir) / span;
            nmae(ir)  = mae(ir)  / span;
        end
    end
end

% -----------------------------------------
% Build output table
% -----------------------------------------
T = table( ...
    labels(:), rmse, mae, r2, a10, nSafe, ...
    'VariableNames', {'ResponseVariable','RMSE','MAE','R2','A10_percent','N_SAFE'} );

if opt.ComputeNormalized
    T.NRMSE = nrmse;
    T.NMAE  = nmae;
end

% -----------------------------------------
% Save CSV / Excel
% -----------------------------------------
try
    writetable(T, opt.OutCSV);
catch me
    warning('Could not write CSV: %s', me.message);
end

try
    writetable(T, opt.OutXLSX, 'Sheet', opt.SheetName);
catch me
    warning('Could not write XLSX: %s', me.message);
end

% -----------------------------------------
% Print LaTeX table rows
% -----------------------------------------
fprintf('\nLaTeX rows (paste into tabular):\n');
for ir = 1:nR
    if isnan(rmse(ir)), continue; end
    fprintf('%s & %s & %s & %.3f & %.1f \\\\\n', ...
        latex_escape(labels{ir}), ...
        sci_fmt(rmse(ir)), sci_fmt(mae(ir)), r2(ir), a10(ir));
end
fprintf('\nSaved:\n  %s\n  %s\n', opt.OutCSV, opt.OutXLSX);

end

% ========================================================================
% Helper: read obs/pred from unknown csv structure
% ========================================================================
function [obs, pred] = read_obs_pred_any(fpath)
% Try readtable first (handles headers). Fall back to readmatrix.

try
    T = readtable(fpath, 'PreserveVariableNames', true);

    vars = lower(string(T.Properties.VariableNames));

    % Common names
    iObs  = find(contains(vars, "obs")  | contains(vars, "true") | contains(vars,"target"), 1, 'first');
    iPred = find(contains(vars, "pred") | contains(vars, "hat")  | contains(vars,"output"), 1, 'first');

    if ~isempty(iObs) && ~isempty(iPred)
        obs  = T{:, iObs};
        pred = T{:, iPred};
        obs  = obs(:);
        pred = pred(:);
        return;
    end

    % Otherwise: take last two numeric columns
    X = table2array(T);
    X = X(:, all(isfinite_or_nan(X),1)); %#ok<NASGU>
    X = table2array(T); % keep as-is; below logic handles NaNs

    [obs, pred] = last_two_numeric_cols(X);
    return;

catch
    % Fall back
end

X = readmatrix(fpath);
[obs, pred] = last_two_numeric_cols(X);
end

function tf = isfinite_or_nan(x)
tf = isfinite(x) | isnan(x);
end

function [obs, pred] = last_two_numeric_cols(X)
if isempty(X) || size(X,2) < 2
    obs = []; pred = [];
    return;
end

% Keep numeric columns only (readmatrix already numeric; readtable->array could be mixed)
if ~isnumeric(X)
    X = double(X);
end

obs  = X(:, end-1);
pred = X(:, end);
obs  = obs(:);
pred = pred(:);
end

function s = sci_fmt(x)
% LaTeX-friendly scientific formatting:
% 1234 => 1.23 \times 10^{3}
if ~isfinite(x)
    s = 'NaN';
    return;
end
if x == 0
    s = '0';
    return;
end

ax = abs(x);
e  = floor(log10(ax));
m  = x / 10^e;

% If exponent small, print fixed
if e >= -2 && e <= 2
    s = sprintf('%.3g', x);
else
    s = sprintf('%.2f \\times 10^{%d}', m, e);
end
end

function s = latex_escape(s)
% minimal escaping for LaTeX table cells
s = strrep(s, '_', '\_');
end