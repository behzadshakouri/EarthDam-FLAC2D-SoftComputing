clc;
clear;
close all;

% ==========================================================
% ROOT DIRECTORY (P1/R1/... structure)
% ==========================================================
outRoot = 'E:\University\My Thesis\Flac model\New\Maku_PT2_Data\ELMIGWO_FULL70_OUT\';

if ~exist(outRoot,'dir')
    error('Output root not found:\n%s', outRoot);
end

% ==========================================================
% COMMON SETTINGS
% ==========================================================
Points    = 1:10;
Responses = 1:7;

Series     = 'pred';        % 'pred' | 'obs' | 'err' | 'abs_err'
Stat       = 'median';      % 'median' | 'mean'
TimeWindow = [0 20];
MinCount   = 10;

Normalize     = 'none';     % 'none' | 'perRow' | 'perResponse'
MissingValue  = 'nan';      % 'nan' | 'zero'

ShowYLabels   = 'sparse';   % 'all' | 'sparse' | 'none'
YLabelStride = 2;           % show every 2nd label when sparse

ExportDPI    = 300;
MinFigPixels = [4200 2800];

figName = sprintf('ALL 70 | %s %s heatmap over time (SAFE)', ...
                  upper(Series), upper(Stat));

pngOut = fullfile(outRoot, ...
    sprintf('ALL70_heatmap_%s_%s.png', Series, Stat));

% ==========================================================
% CALL
% ==========================================================
fprintf('Creating ALL-70 heatmap (%s / %s)...\n', Series, Stat);

plot_heatmap_all70_over_time(outRoot, ...
    'Points', Points, ...
    'Responses', Responses, ...
    'Series', Series, ...
    'Stat', Stat, ...
    'TimeWindow', TimeWindow, ...
    'MinCount', MinCount, ...
    'Normalize', Normalize, ...
    'MissingValue', MissingValue, ...
    'ShowYLabels', ShowYLabels, ...
    'YLabelStride', YLabelStride, ...
    'FigureName', figName, ...
    'SavePNG', pngOut, ...
    'ExportDPI', ExportDPI, ...
    'MinFigPixels', MinFigPixels);

fprintf('\nDONE.\nSaved heatmap:\n%s\n', pngOut);
