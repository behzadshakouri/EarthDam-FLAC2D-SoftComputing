clc;
clear;
close all;

% ==========================================================
% ROOT DIRECTORY (where P1/P2/... folders exist)
% ==========================================================
outRoot = 'E:\University\My Thesis\Flac model\New\Maku_PT2_Data\ELMIGWO_FULL70_OUT\';

if ~exist(outRoot,'dir')
    error('Output root not found:\n%s', outRoot);
end

% ==========================================================
% OPTIONS
% ==========================================================
Points    = 1:10;   % P1..P10
Responses = 1:7;    % R1..R7

DownsampleTo = 2500;    % per tile (set [] to disable)
TimeWindow   = [0 20];  % [] for auto
YlimMode     = 'perResponse';  % 'perResponse' | 'perTile'

% Robust y-limits (avoid one spike flattening curves)
YLimitPctl = [0.5 99.5];  % use pHi to estimate ymax
PadFrac    = 0.05;        % 5% padding on ymax

figName = 'ALL 70 | SAFE Time history (Observed vs Predicted)';
pngOut  = fullfile(outRoot, 'ALL70_SAFE_timeseries_obs_vs_pred.png');

% Export controls (match scatter-grid “zoomed” quality)
ExportDPI    = 300;
MinFigPixels = [4200 2800];

% ==========================================================
% CALL THE GRID PLOT FUNCTION
% ==========================================================
fprintf('Creating 7x10 time-series grid plot from:\n%s\n', outRoot);

plot_grid_timeseries_obs_pred_7x10(outRoot, ...
    'Points', Points, ...
    'Responses', Responses, ...
    'DownsampleTo', DownsampleTo, ...
    'TimeWindow', TimeWindow, ...
    'YlimMode', YlimMode, ...
    'YLimitPctl', YLimitPctl, ...
    'PadFrac', PadFrac, ...
    'FigureName', figName, ...
    'SavePNG', pngOut, ...
    'ExportDPI', ExportDPI, ...
    'MinFigPixels', MinFigPixels);

fprintf('\nDONE.\nSaved figure:\n%s\n', pngOut);
