function [cleaned, info] = clean_task3_history(history, cfg)
%CLEAN_TASK3_HISTORY Truncate a response at its first invalid/sentinel value.
history = double(history(:));
invalid = ~isfinite(history) | abs(history) >= cfg.qc.sentinel_abs_threshold;
firstInvalid = find(invalid, 1, 'first');
if isempty(firstInvalid)
    cleaned = history;
else
    cleaned = history(1:firstInvalid-1);
end
info.original_length = numel(history);
info.clean_length = numel(cleaned);
info.first_invalid_index = firstInvalid;
info.was_truncated = ~isempty(firstInvalid);
info.is_usable = numel(cleaned) >= cfg.qc.minimum_history_length;
end
