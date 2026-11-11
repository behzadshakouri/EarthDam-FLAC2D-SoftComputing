function [cleaned,info] = clean_task4_history(history,cfg)
%CLEAN_TASK4_HISTORY Truncate at the first NaN, Inf, or FLAC2D sentinel.
history = double(history(:));
invalid = ~isfinite(history) | abs(history)>=cfg.sentinel_abs_threshold;
firstInvalid = find(invalid,1,'first');
if isempty(firstInvalid), cleaned=history; else, cleaned=history(1:firstInvalid-1); end
info.original_length = numel(history);
info.clean_length = numel(cleaned);
info.first_invalid_index = firstInvalid;
info.was_truncated = ~isempty(firstInvalid);
info.is_usable = numel(cleaned)>=cfg.minimum_clean_samples;
if isempty(cleaned), info.maximum_absolute_clean_value=NaN;
else, info.maximum_absolute_clean_value=max(abs(cleaned)); end
end
