function mask = build_admissible_mask(step, sim_id, onset_step_by_sim)
% The onset step itself and every later step are inadmissible.
mask = true(size(step));
for s = 1:numel(onset_step_by_sim)
    rows = sim_id == s;
    mask(rows) = step(rows) < onset_step_by_sim(s);
end
end
