function validate_consolidated_dataset(dataset, cfg)
required = {'X','Y','sim_id','step','time_s'};
for k = 1:numel(required)
    assert(isfield(dataset, required{k}), 'Missing dataset field: %s', required{k});
end
n = cfg.num_realizations * cfg.num_time_steps;
assert(isequal(size(dataset.X), [n cfg.input_count]), ...
    'X must be %d-by-%d for the current configuration.', n, cfg.input_count);
assert(isequal(size(dataset.Y), [n cfg.num_points cfg.num_responses]), ...
    'Y must be %d-by-%d-by-%d for the current configuration.', ...
    n, cfg.num_points, cfg.num_responses);
assert(numel(dataset.sim_id) == n && numel(dataset.step) == n && numel(dataset.time_s) == n);
assert(max(abs(dataset.time_s(:) - dataset.step(:)*cfg.time_step_s)) < 1e-12, 'Time metadata is shifted.');
expected_first_time = cfg.time_step_s;
expected_last_time = cfg.num_time_steps * cfg.time_step_s;
tol = 10 * eps(max(1, expected_last_time));
assert(abs(dataset.time_s(1) - expected_first_time) <= tol, ...
    'Dataset first time does not match cfg.time_step_s.');
assert(abs(dataset.time_s(end) - expected_last_time) <= tol, ...
    'Dataset last time does not match cfg.num_time_steps * cfg.time_step_s.');
assert(all(isfinite(dataset.X), 'all'), 'X contains nonfinite values.');
end
