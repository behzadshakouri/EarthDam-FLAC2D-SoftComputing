function yq = interpolate_response_history(time_raw, y_raw, time_target, context)
%INTERPOLATE_RESPONSE_HISTORY Interpolate one realization to canonical times.
if nargin < 4 || isempty(context), context = 'unknown history'; end
time_raw = time_raw(:); y_raw = y_raw(:); time_target = time_target(:);
if numel(time_raw) ~= numel(y_raw)
    error('Task2:HistoryLengthMismatch', ...
        '%s has %d time values but %d response values.', ...
        context, numel(time_raw), numel(y_raw));
end
valid = isfinite(time_raw) & isfinite(y_raw);
time_raw = time_raw(valid); y_raw = y_raw(valid);
[time_raw, order] = sort(time_raw); y_raw = y_raw(order);
[time_raw, keep] = unique(time_raw, 'stable'); y_raw = y_raw(keep);

% FLAC histories are commonly written at adaptive/irregular times, so their
% last stored sample can fall slightly before the nominal 20.00 s endpoint.
% Accept at most half one canonical output step at either boundary and snap
% that sample to the target boundary.  This is a zero-order endpoint hold,
% not unconstrained extrapolation; genuinely truncated runs still stop.
if numel(time_target) > 1
    target_dt = median(diff(time_target));
else
    target_dt = 0.01;
end
roundoff_tol = max(1e-10, abs(target_dt) * 1e-6);
boundary_tol = abs(target_dt) / 2 + roundoff_tol;
target_start = time_target(1);
target_end = time_target(end);

if numel(time_raw) < 2 || time_raw(1) > target_start + boundary_tol || ...
        time_raw(end) < target_end - boundary_tol
    if isempty(time_raw)
        actual_range = 'no finite paired samples';
    else
        actual_range = sprintf('%.15g to %.15g s (%d samples)', ...
            time_raw(1), time_raw(end), numel(time_raw));
    end
    error('Task2:InsufficientTimeCoverage', ...
        ['%s covers %s; required %.2f through %.2f s. ' ...
         'This may indicate an early-terminated FLAC2D realization.'], ...
        context, actual_range, target_start, target_end);
end

if time_raw(1) > target_start && time_raw(1) <= target_start + boundary_tol
    time_raw = [target_start; time_raw];
    y_raw = [y_raw(1); y_raw];
elseif abs(time_raw(1) - target_start) <= roundoff_tol
    time_raw(1) = target_start;
end
if time_raw(end) < target_end && time_raw(end) >= target_end - boundary_tol
    time_raw = [time_raw; target_end];
    y_raw = [y_raw; y_raw(end)];
elseif abs(time_raw(end) - target_end) <= roundoff_tol
    time_raw(end) = target_end;
end
yq = interp1(time_raw, y_raw, time_target, 'linear');
if any(~isfinite(yq))
    error('Task2:InterpolationNonfinite', ...
        '%s produced nonfinite values after interpolation.', context);
end
end
