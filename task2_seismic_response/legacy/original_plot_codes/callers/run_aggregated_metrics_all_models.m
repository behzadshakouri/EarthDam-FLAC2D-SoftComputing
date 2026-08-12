clc; clear; close all;

% ============================================================
% ROOT DATA DIRECTORY
% ============================================================
dataRoot = 'E:\University\My Thesis\Flac model\New\Maku_PT2_Data\';

% ============================================================
% MODEL FOLDERS
% ============================================================
Models = { ...
    'ELM_FULL70_OUT'      , 'ELM'; ...
    'ELMABC_FULL70_OUT'   , 'ELM-ABC'; ...
    'ELMACOR_FULL70_OUT'  , 'ELM-ACOR'; ...
    'ELMIGWO_FULL70_OUT'  , 'ELM-IGWO'; ...
};

% ============================================================
% SETTINGS
% ============================================================
Points    = 1:10;
Responses = 1:7;

ResponseLabels = { ...
    'Horizontal Displacement (m)' ...
    'Vertical Displacement (m)' ...
    'Horizontal Stress \sigma_{xx} (Pa)' ...
    'Vertical Stress \sigma_{yy} (Pa)' ...
    'Pore Water Pressure (Pa)' ...
    'Shear Strain Increment (-)' ...
    'Volumetric Strain Increment (-)' ...
};

% ============================================================
% 1️⃣ MAIN TABLE — BEST MODEL (ELM-IGWO)
% ============================================================
fprintf('\n=====================================================\n');
fprintf('Aggregated metrics for BEST model: ELM-IGWO\n');
fprintf('=====================================================\n');

bestRoot = fullfile(dataRoot,'ELMIGWO_FULL70_OUT');

T_best = compute_aggregated_metrics_normalized(bestRoot, ...
    'Points', Points, ...
    'Responses', Responses, ...
    'ResponseLabels', ResponseLabels, ...
    'OutCSV',  fullfile(bestRoot,'Table_elm_metrics_bestmodel.csv'), ...
    'OutXLSX', fullfile(bestRoot,'Table_elm_metrics_bestmodel.xlsx'));

% ============================================================
% 2️⃣ OPTIONAL — ALL MODELS COMPARISON (Excel with sheets)
% ============================================================
fprintf('\n=====================================================\n');
fprintf('Computing metrics for ALL models\n');
fprintf('=====================================================\n');

AllTables = cell(size(Models,1),1);

for i = 1:size(Models,1)

    folderName = Models{i,1};
    modelTag   = Models{i,2};

    modelRoot = fullfile(dataRoot, folderName);

    fprintf('\nProcessing: %s\n', modelTag);

    T = compute_aggregated_metrics_normalized(modelRoot, ...
        'Points', Points, ...
        'Responses', Responses, ...
        'ResponseLabels', ResponseLabels, ...
        'OutCSV',  fullfile(modelRoot, ['AggregatedMetrics_' modelTag '.csv']), ...
        'OutXLSX', fullfile(modelRoot, ['AggregatedMetrics_' modelTag '.xlsx']));

    T.Model = repmat({modelTag},height(T),1);
    AllTables{i} = T;
end

% Combine all models into one big table
Tall = vertcat(AllTables{:});

% Save combined comparison file
comparisonFile = fullfile(dataRoot,'AggregatedMetrics_ALL_MODELS.xlsx');
writetable(Tall, comparisonFile, 'Sheet','AllModels');

fprintf('\n=====================================================\n');
fprintf('DONE.\n');
fprintf('Best-model table saved in:\n%s\n', bestRoot);
fprintf('All-model comparison saved in:\n%s\n', comparisonFile);
fprintf('=====================================================\n');