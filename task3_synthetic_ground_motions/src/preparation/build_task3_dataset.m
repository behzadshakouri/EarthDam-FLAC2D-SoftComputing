function [dataset, qc] = build_task3_dataset(Task3, cfg)
%BUILD_TASK3_DATASET Build X (150-by-p) and Y (150-by-70) from Task3.
assert(isstruct(Task3) && isfield(Task3,'Inputs') && isfield(Task3,'Outputs'));
n = cfg.num_realizations; dictionary = task3_response_dictionary();
assert(numel(Task3.Inputs.InputsMatrix) == n, 'Unexpected input realization count.');
X = nan(n, numel(cfg.features.names)); sourcePGA = nan(n,1);
Y = nan(n, cfg.num_outputs);
truncated = false(n, cfg.num_outputs); cleanLength = zeros(n, cfg.num_outputs);
for i = 1:n
    gm = Task3.Inputs.InputsMatrix(i);
    X(i,:) = extract_ground_motion_features(gm.time, gm.accel, cfg);
    sourcePGA(i) = double(gm.PGA);
    for k = 1:cfg.num_outputs
        p = dictionary(k).point; r = dictionary(k).response;
        pointData = Task3.Outputs.(sprintf('P%d',p));
        histories = pointData.(sprintf('R%d',r));
        [cleaned, info] = clean_task3_history(histories{i}, cfg);
        truncated(i,k) = info.was_truncated; cleanLength(i,k) = info.clean_length;
        if info.is_usable
            Y(i,k) = reduce_task3_history(cleaned, cfg.output.reduction_modes{r});
        end
    end
end
dataset.X = X; dataset.Y = Y;
dataset.feature_names = cfg.features.names;
dataset.output_dictionary = dictionary;
dataset.realization_id = (1:n)';
dataset.output_reduction_modes = cfg.output.reduction_modes;
qc.truncated = truncated; qc.clean_length = cleanLength;
qc.source_PGA = sourcePGA;
qc.computed_minus_source_PGA = X(:,1)-sourcePGA;
qc.invalid_X = ~isfinite(X); qc.invalid_Y = ~isfinite(Y);
qc.constant_outputs = (max(Y,[],1)-min(Y,[],1)) <= cfg.qc.constant_tolerance;
validate_task3_dataset(dataset, cfg);
end
