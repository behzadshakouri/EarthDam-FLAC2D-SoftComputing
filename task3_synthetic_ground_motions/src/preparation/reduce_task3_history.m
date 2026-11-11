function value = reduce_task3_history(history, mode)
%REDUCE_TASK3_HISTORY Convert a valid temporal history to one scalar target.
history = double(history(:));
assert(~isempty(history) && all(isfinite(history)), 'History must be finite and nonempty.');
switch lower(mode)
    case 'max_absolute'
        value = max(abs(history));
    case 'max_absolute_increment'
        value = max(abs(history - history(1)));
    case 'maximum'
        value = max(history);
    case 'minimum'
        value = min(history);
    case 'final'
        value = history(end);
    otherwise
        error('Unknown Task 3 reduction mode: %s', mode);
end
end
