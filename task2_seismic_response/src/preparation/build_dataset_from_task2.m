function [X, Y, audit] = build_dataset_from_task2(Task2, paths, cfg)
%BUILD_DATASET_FROM_TASK2 Convert historical Task2Data into canonical arrays.
validate_task2_source(Task2, cfg);
inputs = load_inputs(Task2, paths, cfg);
pga_envelope = load_pga_envelope(paths.pga_file, cfg);

n_rows = cfg.num_realizations * cfg.num_time_steps;
X = zeros(n_rows, cfg.input_count, 'single');
Y = zeros(n_rows, cfg.num_points, cfg.num_responses, 'single');

for step = 1:cfg.num_time_steps
    rows = (step-1)*cfg.num_realizations + (1:cfg.num_realizations);
    X(rows,1:15) = single(inputs);
    X(rows,16) = single(pga_envelope(step));
end

fprintf('Building 70 response envelopes at 0.01-20.00 s...\n');
for p = 1:cfg.num_points
    point_name = sprintf('P%d', p);
    for r = 1:cfg.num_responses
        response_name = sprintf('R%d', r);
        histories = Task2.Outputs.(point_name).(response_name);
        envelope = zeros(cfg.num_realizations, cfg.num_time_steps, 'single');
        for sim = 1:cfg.num_realizations
            values = get_history(histories, sim, point_name, response_name);
            times = get_history(Task2.Outputs.dytime, sim, 'dytime', '');
            context = sprintf('%s%s, realization %d', point_name, response_name, sim);
            interpolated = interpolate_response_history(times, values, cfg.time_s, context);
            envelope(sim,:) = single(build_response_envelope(interpolated(:))');
        end
        Y(:,p,r) = envelope(:);
        fprintf('  P%dR%d complete (%d/70)\n', p, r, (p-1)*cfg.num_responses+r);
    end
end

Y = reshape(Y, n_rows, cfg.num_points, cfg.num_responses);
audit = struct('source_task2_data', paths.task2_data_file, ...
    'source_inputs', paths.inputs_file, 'source_pga', paths.pga_file, ...
    'time_definition', 'time_s = step * 0.01; step = 1..2000', ...
    'row_order', 'time-major; realization varies fastest');
end

function validate_task2_source(Task2, cfg)
assert(isfield(Task2, 'Inputs') && isfield(Task2, 'Outputs'), ...
    'Task2 must contain Inputs and Outputs.');
assert(isfield(Task2.Outputs, 'dytime'), 'Task2.Outputs.dytime is missing.');
for p = 1:cfg.num_points
    pn = sprintf('P%d', p);
    assert(isfield(Task2.Outputs, pn), 'Task2.Outputs.%s is missing.', pn);
    for r = 1:cfg.num_responses
        rn = sprintf('R%d', r);
        assert(isfield(Task2.Outputs.(pn), rn), 'Task2.Outputs.%s.%s is missing.', pn, rn);
    end
end
end

function inputs = load_inputs(Task2, paths, cfg)
if isfield(Task2.Inputs, 'InputsMatrix') && ~isempty(Task2.Inputs.InputsMatrix)
    inputs = Task2.Inputs.InputsMatrix;
elseif ~isempty(paths.inputs_file)
    inputs = readmatrix(paths.inputs_file);
else
    error('Task2:InputsMissing', ['No Task2.Inputs.InputsMatrix is available and RVs+WL.xlsx ' ...
        'was not found. Set raw.inputs_file in task2_user_paths.m.']);
end
inputs = inputs(:,1:min(15,size(inputs,2)));
assert(isequal(size(inputs), [cfg.num_realizations 15]), ...
    'The physical input matrix must be 300 x 15; found %d x %d.', size(inputs,1), size(inputs,2));
assert(all(isfinite(inputs(:))), 'The physical input matrix contains nonfinite values.');
end

function values = get_history(container, sim, label1, label2)
if iscell(container)
    values = container{sim};
elseif size(container,1) >= sim
    values = container(sim,:);
else
    error('Task2:HistoryMissing', 'Missing history for simulation %d (%s %s).', sim, label1, label2);
end
values = double(values(:));
if size(values,2) > 1, values = values(:,end); end
end

function pga = load_pga_envelope(filename, cfg)
[~,~,ext] = fileparts(filename);
if strcmpi(ext, '.mat')
    s = load(filename);
    names = fieldnames(s);
    raw = s.(names{1});
else
    raw = readmatrix(filename);
end
raw = raw(isfinite(raw));
raw = raw(:);
assert(numel(raw) >= cfg.num_time_steps, 'PGA input needs at least 2000 finite values.');
raw = raw(1:cfg.num_time_steps);
% Both historical accepted files are envelopes or raw acceleration. cummax(abs()) is idempotent.
pga = cummax(abs(double(raw)));
end
