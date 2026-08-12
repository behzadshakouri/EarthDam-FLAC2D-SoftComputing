clc;
clear;
close all;

% ==========================================================
% ROOT DIRECTORY
% ==========================================================
outRoot = 'E:\University\My Thesis\Flac model\New\Maku_PT2_Data\ELMIGWO_FULL70_OUT\';

% ==========================================================
% TIMES TO PLOT (seconds)
% ==========================================================
t_list = [2 4 6 8 10 12];

% ==========================================================
% COMMON OPTIONS
% ==========================================================
Points    = 1:10;
Responses = 1:7;

MaxPerTile = 300;
AxisMode   = 'perResponse';
AxisPctl   = [0.5 99.5];
PadFrac    = 0.02;

ExportDPI    = 300;
MinFigPixels = [4200 2800];

% ==========================================================
% LOOP OVER TIMES
% ==========================================================
for it = 1:numel(t_list)
    t0 = t_list(it);

    figName = sprintf('ALL 70 | SAFE Obs vs Pred at t = %.0f s', t0);
    pngOut  = fullfile(outRoot, sprintf('ALL70_SAFE_scatter_t%02ds.png', t0));

    fprintf('\n--- Plotting scatter grid at t = %.1f s ---\n', t0);

    plot_grid_scatter_at_t_7x10(outRoot, t0, ...
        'Points', Points, ...
        'Responses', Responses, ...
        'MaxPerTile', MaxPerTile, ...
        'AxisMode', AxisMode, ...
        'AxisPctl', AxisPctl, ...
        'PadFrac', PadFrac, ...
        'FigureName', figName, ...
        'SavePNG', pngOut, ...
        'ExportDPI', ExportDPI, ...
        'MinFigPixels', MinFigPixels);
end

fprintf('\nALL t0 PLOTS DONE.\n');
