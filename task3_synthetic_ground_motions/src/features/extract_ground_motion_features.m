function [features, names] = extract_ground_motion_features(time, accel, cfg)
%EXTRACT_GROUND_MOTION_FEATURES Compute reproducible intensity descriptors.
time = double(time(:)); accel = double(accel(:));
valid = isfinite(time) & isfinite(accel);
time = time(valid); accel = accel(valid);
assert(numel(time) >= 3, 'Ground-motion history must contain at least 3 samples.');
assert(all(diff(time) > 0), 'Ground-motion time must be strictly increasing.');

switch lower(cfg.features.acceleration_units)
    case 'g'
        accelMS2 = accel * cfg.features.gravity_m_s2;
        accelG = accel;
    case {'m/s2','m/s^2'}
        accelMS2 = accel;
        accelG = accel / cfg.features.gravity_m_s2;
    otherwise
        error('Unsupported acceleration unit: %s', cfg.features.acceleration_units);
end
velocity = cumtrapz(time, accelMS2);
velocity = velocity - linspace(velocity(1), velocity(end), numel(velocity))';
displacement = cumtrapz(time, velocity);
displacement = displacement - linspace(displacement(1), displacement(end), numel(displacement))';
ariasCumulative = cumtrapz(time, accelMS2.^2) * pi / (2*cfg.features.gravity_m_s2);
arias = ariasCumulative(end);
if arias > 0
    t5 = interp_first_monotone(ariasCumulative, time, 0.05*arias);
    t95 = interp_first_monotone(ariasCumulative, time, 0.95*arias);
    duration = t95 - t5;
else
    duration = 0;
end

dt = median(diff(time)); n = numel(accelMS2);
centered = accelMS2 - mean(accelMS2);
amplitude = abs(fft(centered));
frequency = (0:n-1)'/(n*dt);
positive = frequency > 0 & frequency <= 1/(2*dt);
ampPositive = amplitude(positive); freqPositive = frequency(positive);
if any(ampPositive > 0)
    meanFrequency = sum(freqPositive.*ampPositive)/sum(ampPositive);
    [~, imax] = max(ampPositive);
    predominantPeriod = 1/freqPositive(imax);
else
    meanFrequency = 0; predominantPeriod = 0;
end

features = [max(abs(accelG)), max(abs(velocity)), max(abs(displacement)), ...
    arias, trapz(time, abs(accelMS2)), duration, sqrt(mean(accelG.^2)), ...
    meanFrequency, predominantPeriod];
names = cfg.features.names;
assert(numel(features) == numel(names));
end

function value = interp_first_monotone(cumulative, time, target)
idx = find(cumulative >= target, 1, 'first');
if isempty(idx), value = time(end); return; end
if idx == 1, value = time(1); return; end
x = cumulative(idx-1:idx); y = time(idx-1:idx);
if x(2) == x(1), value = y(2); else, value = interp1(x, y, target); end
end
