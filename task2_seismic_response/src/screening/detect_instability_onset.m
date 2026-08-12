function result = detect_instability_onset(y, time_s, response_index, detector)
%DETECT_INSTABILITY_ONSET Legacy v4.2 detector adapted to one time history.
% The trigger behavior intentionally matches detect_failure_per_sim_col17_v4_2.

y = y(:);
time_s = time_s(:);
assert(numel(y) == numel(time_s));
if numel(time_s) < 2
    error('Task2:HistoryTooShort', 'At least two time samples are required.');
end

p = response_index;
dt = median(diff(time_s));
ys = movmedian(abs(y), detector.smoothing_window, 'Endpoints', 'shrink');
peak_value = max(ys, [], 'omitnan');

result.failure_detected = false;
result.onset_step = inf;
result.onset_time_s = inf;
result.onset_value = nan;
result.method = "no_failure";
result.peak_value = peak_value;

% v4.2 low-signal guard.
if ~isfinite(peak_value) || peak_value < detector.minimum_signal
    result.method = "no_failure_low_signal";
    result.center = nan;
    result.derivative_mean = nan;
    result.derivative_std = nan;
    return;
end

n_steps = numel(ys);
n_base = max(5, round(detector.baseline_s(p) / dt));
n_base = min(n_base, n_steps);
base_level = median(ys(1:n_base), 'omitnan') + eps;

if detector.use_log
    transformed = log(ys + eps);
else
    transformed = ys;
end

dz = [0; diff(transformed)] / dt;
mu = mean(dz(1:n_base), 'omitnan');
sg = std(dz(1:n_base), 'omitnan');
sg = max(sg, detector.minimum_derivative_std);
zscore = (dz - mu) / sg;

level_ok = ys >= detector.level_factor(p) * base_level * ...
    detector.min_exceed_factor;
jump_ok = zscore >= detector.z_threshold(p);
if detector.absolute_jump_threshold(p) > 0
    jump_ok = jump_ok & abs(dz) >= detector.absolute_jump_threshold(p);
end

hold_n = max(1, detector.hold_steps(p));
sf = nan;

if detector.logic(p) == "and"
    % Legacy small-response path: jump and level at the candidate, followed
    % by a sustained level exceedance.
    candidate = find(level_ok & jump_ok, 1, 'first');
    if ~isempty(candidate)
        last_start = max(1, n_steps - hold_n + 1);
        for k = candidate:last_start
            if all(level_ok(k:k + hold_n - 1))
                sf = k;
                break;
            end
        end
    end
else
    % Legacy large-response path A: sustained level exceedance with a jump
    % in the preceding lookback window.
    candidate_level = find(level_ok, 1, 'first');
    if ~isempty(candidate_level)
        last_start = max(1, n_steps - hold_n + 1);
        lookback = max(1, detector.jump_lookback_steps(p));
        for k = candidate_level:last_start
            if all(level_ok(k:k + hold_n - 1))
                j0 = max(1, k - lookback);
                if any(jump_ok(j0:k))
                    sf = k;
                    break;
                end
            end
        end
    end

    % Legacy large-response path B: sustained jump-only onset.
    if ~isfinite(sf)
        jump_hold = max(1, detector.jump_only_hold(p));
        candidate_jump = find(jump_ok, 1, 'first');
        if ~isempty(candidate_jump)
            last_jump_start = max(1, n_steps - jump_hold + 1);
            for k = candidate_jump:last_jump_start
                if all(jump_ok(k:k + jump_hold - 1))
                    sf = k;
                    break;
                end
            end
        end
    end
end

if isfinite(sf)
    result.failure_detected = true;
    result.onset_step = sf;
    result.onset_time_s = time_s(sf);
    result.onset_value = y(sf);
    if detector.logic(p) == "and"
        result.method = "jump+level+hold";
    else
        result.method = "legacy_large_or";
    end
end

result.center = base_level;
result.derivative_mean = mu;
result.derivative_std = sg;
end
