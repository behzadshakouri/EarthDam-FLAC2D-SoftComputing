function timing = benchmark_final_surrogate_inference
%BENCHMARK_FINAL_SURROGATE_INFERENCE Time prediction using saved final models.
% No model is trained. Model loading, file I/O, and figure generation are
% excluded. Each timed execution predicts all 70 response-location histories
% for one held-out realization, including normalization, model evaluation,
% constant-case assignment, and inverse transformation.

root = setup_task2;
cfg = task2_config(root);

selected = struct( ...
    'method', {'ELM','ELMABC','ELMACOR','ELMIGWO'}, ...
    'neurons', {30,15,15,5}, ...
    'folder', {'ELM_N030','ELMABC_N015','ELMACOR_N015','ELMIGWO_N005'});

D = load(cfg.consolidated_file,'dataset');
dataset = D.dataset;
S = load(cfg.split_file,'split');
split = S.split;

% Use one complete held-out realization with the standard 2,000 input rows.
simulation_id = double(split.test_ids(1));
rows = dataset.sim_id == simulation_id;
Xnew = double(dataset.X(rows,:));
assert(size(Xnew,1) == cfg.num_time_steps, ...
    'Expected %d rows for one realization, but found %d.', ...
    cfg.num_time_steps,size(Xnew,1));

n_warmup = 5;
n_repeats = 100;
Tflac_s = 4*3600;
timing = table();

for im = 1:numel(selected)
    method = selected(im).method;
    expected_neurons = selected(im).neurons;
    experiment = selected(im).folder;
    cases = cell(cfg.num_points,cfg.num_responses);

    % Load checkpoints before timing.
    for p = 1:cfg.num_points
        for r = 1:cfg.num_responses
            checkpoint = fullfile(root,'results','method_neuron_sweep', ...
                experiment,method,sprintf('P%d_R%d.mat',p,r));
            if exist(checkpoint,'file') ~= 2
                checkpoint = locate_matching_checkpoint( ...
                    root,method,expected_neurons,p,r);
            end
            assert(~isempty(checkpoint), ...
                'No matching %s P%d-R%d checkpoint was found.',method,p,r);
            L = load(checkpoint,'case_result');
            cr = L.case_result;
            assert(strcmpi(char(cr.method),method), ...
                'Method mismatch in %s.',checkpoint);
            assert(double(cr.hidden_neurons) == expected_neurons, ...
                'Neuron-count mismatch in %s.',checkpoint);

            item = struct();
            item.model = cr.model;
            item.x_scaler = cr.x_scaler;
            item.y_scaler = cr.y_scaler;
            item.constant = isempty(cr.model);
            item.constant_value = 0;
            if item.constant && isfield(cr,'y_pred') && ~isempty(cr.y_pred)
                item.constant_value = double(cr.y_pred(1));
            end
            cases{p,r} = item;
        end
    end

    % Warm-up executions are excluded.
    for k = 1:n_warmup
        predict_all_70(cases,Xnew);
    end

    elapsed = zeros(n_repeats,1);
    for k = 1:n_repeats
        clock = tic;
        predict_all_70(cases,Xnew);
        elapsed(k) = toc(clock);
    end

    Tpred_s = median(elapsed);
    Tpred300_s = 300*Tpred_s;
    speedup = Tflac_s/Tpred_s;

    row = table(string(display_name(method)),expected_neurons,simulation_id, ...
        size(Xnew,1),n_repeats,Tpred_s,Tpred300_s,Tpred300_s/60, ...
        Tpred300_s/3600,speedup, ...
        'VariableNames',{'model','hidden_neurons','simulation_id', ...
        'time_steps_per_history','repetitions','prediction_s_per_realization', ...
        'prediction_s_for_300','prediction_min_for_300', ...
        'prediction_h_for_300','speedup_vs_4h_FLAC2D'});
    timing = [timing; row]; %#ok<AGROW>

    fprintf('%-10s | one realization: %.6f s | 300: %.3f s | speed-up: %.1fx\n', ...
        display_name(method),Tpred_s,Tpred300_s,speedup);
end

out_dir = fullfile(root,'results','final_inference_timing');
if ~exist(out_dir,'dir'), mkdir(out_dir); end
writetable(timing,fullfile(out_dir,'final_inference_timing.csv'));
save(fullfile(out_dir,'final_inference_timing.mat'), ...
    'timing','selected','simulation_id','n_warmup','n_repeats','-v7.3');

fprintf('\nTiming results written to:\n%s\n',out_dir);
disp(timing);
end

function predictions = predict_all_70(cases,Xnew)
predictions = cell(size(cases));
for p = 1:size(cases,1)
    for r = 1:size(cases,2)
        item = cases{p,r};
        if item.constant
            predictions{p,r} = repmat(item.constant_value,size(Xnew,1),1);
        else
            Xz = apply_mapminmax_scaler(Xnew,item.x_scaler);
            yz = predict_elm(item.model,Xz);
            predictions{p,r} = reverse_mapminmax_scaler(yz,item.y_scaler);
        end
    end
end
end

function checkpoint = locate_matching_checkpoint(root,method,neurons,p,r)
name = sprintf('P%d_R%d.mat',p,r);
d = dir(fullfile(root,'results','**',name));
checkpoint = '';
for i = 1:numel(d)
    candidate = fullfile(d(i).folder,d(i).name);
    try
        L = load(candidate,'case_result');
        cr = L.case_result;
        if isfield(cr,'method') && isfield(cr,'hidden_neurons') && ...
                strcmpi(char(cr.method),method) && ...
                double(cr.hidden_neurons) == neurons
            checkpoint = candidate;
            return;
        end
    catch
    end
end
end

function name = display_name(method)
switch upper(method)
    case 'ELM', name = 'ELM';
    case 'ELMABC', name = 'ELM--ABC';
    case 'ELMACOR', name = 'ELM--ACOR';
    case 'ELMIGWO', name = 'ELM--IGWO';
    otherwise, name = method;
end
end
