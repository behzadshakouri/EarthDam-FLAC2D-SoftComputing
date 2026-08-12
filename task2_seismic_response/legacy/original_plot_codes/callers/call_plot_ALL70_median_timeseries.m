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
% COMMON OPTIONS
% ==========================================================
Points    = 1:10;   % P1..P10
Responses = 1:7;    % R1..R7

Series = 'pred';    % 'obs' | 'pred' | 'both'
Stat   = 'median';  % 'median' | 'mean'

TimeWindow = [0 20];
MinCount   = 10;    % minimum SAFE sims per time step
ShowLegend = false; % 70 curves → usually false

ExportDPI    = 300;
MinFigPixels = [4200 2600];

figName = sprintf('ALL 70 | %s %s across simulations (SAFE)', ...
                  upper(Series), upper(Stat));

pngOut = fullfile(outRoot, ...
    sprintf('ALL70_%s_%s_timeseries.png', Series, Stat));

% ==========================================================
% CALL
% ==========================================================
fprintf('Creating ALL-70 %s %s time-series plot...\n', Series, Stat);

plot_all70_median_timeseries(outRoot, ...
    'Points', Points, ...
    'Responses', Responses, ...
    'Series', Series, ...
    'Stat', Stat, ...
    'TimeWindow', TimeWindow, ...
    'MinCount', MinCount, ...
    'Legend', ShowLegend, ...
    'FigureName', figName, ...
    'SavePNG', pngOut, ...
    'ExportDPI', ExportDPI, ...
    'MinFigPixels', MinFigPixels);

fprintf('\nDONE.\nSaved figure:\n%s\n', pngOut);
