function generate_original_task2_plots(resultsDir,points,responses,varargin)
%GENERATE_ORIGINAL_TASK2_PLOTS Run the latest nonduplicative original plots.
% Works for a P1-R1 smoke-test folder or completed FULL70 results.
% Figures are hidden and closed by default; PNG/CSV/XLSX outputs are saved.
root = setup_task2;
cfg = task2_config(root);
if nargin < 1 || isempty(resultsDir), resultsDir = newest_smoke_or_production(cfg); end
resultsDir = resolve_results_dir(resultsDir,cfg);
if nargin < 2 || isempty(points), points = discover_axis(resultsDir,'point'); end
if nargin < 3 || isempty(responses), responses = discover_axis(resultsDir,'response'); end
if isempty(points) || isempty(responses), error('Task2:NoSavedCases','No saved P#_R#.mat cases were found in %s.',resultsDir); end

p = inputParser;
p.addParameter('Silent',true,@(x)islogical(x)&&isscalar(x));
p.addParameter('CloseFigures',true,@(x)islogical(x)&&isscalar(x));
p.parse(varargin{:});
opt = p.Results;

% Do not disturb figures that existed before this function was called.
oldVisibility = get(groot,'DefaultFigureVisible');
oldFigures = get(groot,'Children');
cleanup = onCleanup(@() restore_graphics(oldVisibility,oldFigures,opt.CloseFigures)); %#ok<NASGU>
if opt.Silent
    set(groot,'DefaultFigureVisible','off');
end

roots = export_original_plot_inputs(resultsDir);
responseLabels = final_response_labels();
models = {'ELM','ELMABC','ELMACOR','ELMIGWO'};
for im = 1:numel(models)
    method = models{im}; outRoot = roots.(method);
    if ~isfolder(outRoot), continue; end
    plotDir = fullfile(resultsDir,'plots','original','latest',method);
    if ~isfolder(plotDir), mkdir(plotDir); end
    plot_grid_obs_vs_pred_7x10(outRoot,'Points',points,'Responses',responses,'MethodTag',method, ...
        'ResponseLabels',responseLabels, ...
        'SavePNG',fullfile(plotDir,[method '_obs_vs_pred.png']), ...
        'FigPosition',[20 20 max(1600,900*numel(points)) max(1200,900*numel(responses))]);
    plot_grid_timeseries_obs_pred_7x10(outRoot,'Points',points,'Responses',responses, ...
        'TimeWindow',[0 cfg.num_time_steps*cfg.time_step_s], ...
        'SavePNG',fullfile(plotDir,[method '_timeseries_obs_pred.png']), ...
        'MinFigPixels',[max(1600,900*numel(points)) max(1200,700*numel(responses))]);
    % Use only the latest "pretty" metric heatmaps. The older grid heatmap
    % routine remains available under scripts/original_plots for manual use.
    plot_all70_metric_heatmaps_pretty(outRoot,'Points',points,'Responses',responses,'SaveDir',plotDir);
    % For one P1-R1 case, the median series duplicates the ordinary series.
    if numel(points)*numel(responses) > 1
        plot_all70_median_timeseries(outRoot,'Points',points,'Responses',responses,'Series','both', ...
            'TimeWindow',[0 cfg.num_time_steps*cfg.time_step_s], ...
            'SavePNG',fullfile(plotDir,[method '_median_timeseries.png']));
    end
    plot_heatmap_all70_over_time(outRoot,'Points',points,'Responses',responses,'Series','pred', ...
        'TimeWindow',[0 cfg.num_time_steps*cfg.time_step_s], ...
        'SavePNG',fullfile(plotDir,[method '_prediction_heatmap_over_time.png']));
    t0 = cfg.time_step_s*round(cfg.num_time_steps/2);
    plot_grid_scatter_at_t_7x10(outRoot,t0,'Points',points,'Responses',responses, ...
        'SavePNG',fullfile(plotDir,sprintf('%s_scatter_t_%gs.png',method,t0)), ...
        'MinFigPixels',[max(1600,900*numel(points)) max(1200,700*numel(responses))]);
    if opt.CloseFigures, close_new_figures(oldFigures); end
end
available = models(cellfun(@(m) ~isempty(dir(fullfile(resultsDir,m,'P*_R*.mat'))),models));
if numel(available) >= 2
    % Explicit mapping is compatible with MATLAB R2020a; vectorized STRREP
    % requires equal-sized nonscalar cell arrays in that release.
    displayNames = available;
    for i=1:numel(displayNames)
        switch displayNames{i}
            case 'ELMIGWO', displayNames{i}='ELM-IGWO';
            case 'ELMACOR', displayNames{i}='ELM-ACOR';
            case 'ELMABC',  displayNames{i}='ELM-ABC';
        end
    end
    rootByModel = struct();
    for i=1:numel(available)
        rootByModel.(strrep(displayNames{i},'-','_')) = roots.(available{i});
    end
    compareDir = fullfile(resultsDir,'plots','original','latest','model_comparison');
    if ~isfolder(compareDir), mkdir(compareDir); end
    baseline = displayNames{1};
    if any(strcmp(displayNames,'ELM')), baseline='ELM'; end
    plot_compare_models_metrics('Models',displayNames, ...
        'Baseline',baseline,'RootByModel',rootByModel,'Points',points,'Responses',responses, ...
        'ResponseLabels',responseLabels, ...
        'OutRoot',fullfile(resultsDir,'original_plot_inputs'),'SaveDir',compareDir);
    if opt.CloseFigures, close_new_figures(oldFigures); end
else
    fprintf('Model-comparison plots skipped: only one completed model is available.\n');
end
fprintf('Latest original plots saved silently under:\n%s\n', ...
    fullfile(resultsDir,'plots','original','latest'));
end

function restore_graphics(oldVisibility,oldFigures,closeFigures)
set(groot,'DefaultFigureVisible',oldVisibility);
if closeFigures, close_new_figures(oldFigures); end
end

function close_new_figures(oldFigures)
currentFigures = get(groot,'Children');
for k = 1:numel(currentFigures)
    if ~any(currentFigures(k) == oldFigures)
        close(currentFigures(k));
    end
end
end

function resultsDir = resolve_results_dir(resultsDir,cfg)
% Resolve result folders against the configured package, not MATLAB's pwd.
% This also recovers calls made while MATLAB is in the Polyspace bin folder.
resultsDir = char(resultsDir);
if isfolder(resultsDir), return; end
[~,leaf] = fileparts(resultsDir);
candidate = fullfile(cfg.results_dir,leaf);
if isfolder(candidate)
    warning('Task2:ResultsPathRecovered', ...
        'Requested results folder was not found:\n%s\nUsing configured Task 2 results folder instead:\n%s', ...
        resultsDir,candidate);
    resultsDir = candidate;
    return;
end
error('Task2:ResultsFolderNotFound', ...
    ['Results folder does not exist:\n%s\nExpected it under the configured package, for example:\n%s'], ...
    resultsDir,candidate);
end

function resultsDir = newest_smoke_or_production(cfg)
d = dir(fullfile(cfg.root,'results','P1R1_smoke_test_*')); d = d([d.isdir]);
if isempty(d), resultsDir=cfg.results_dir; else, [~,i]=max([d.datenum]); resultsDir=fullfile(d(i).folder,d(i).name); end
end
function values = discover_axis(resultsDir,whichAxis)
values=[]; models={'ELM','ELMABC','ELMACOR','ELMIGWO'};
for i=1:numel(models)
 d=dir(fullfile(resultsDir,models{i},'P*_R*.mat'));
 for k=1:numel(d)
  tok=regexp(d(k).name,'^P(\d+)_R(\d+)\.mat$','tokens','once'); if isempty(tok),continue;end
  if strcmp(whichAxis,'point'),values(end+1)=str2double(tok{1});else,values(end+1)=str2double(tok{2});end %#ok<AGROW>
 end
end
values=unique(values);
end
