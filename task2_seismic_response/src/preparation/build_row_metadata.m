function metadata = build_row_metadata(cfg)
% Rows are time-major: all realizations at step 1, then step 2, etc.
metadata.step = repelem((1:cfg.num_time_steps)', cfg.num_realizations);
metadata.sim_id = repmat((1:cfg.num_realizations)', cfg.num_time_steps, 1);
metadata.time_s = metadata.step * cfg.time_step_s;
metadata.row = (1:numel(metadata.step))';
expected_first_time = cfg.time_step_s;
expected_last_time = cfg.num_time_steps * cfg.time_step_s;
tol = 10 * eps(max(1, expected_last_time));
assert(abs(metadata.time_s(1) - expected_first_time) <= tol, ...
    'First row time does not match cfg.time_step_s.');
assert(abs(metadata.time_s(end) - expected_last_time) <= tol, ...
    'Last row time does not match cfg.num_time_steps * cfg.time_step_s.');
end
