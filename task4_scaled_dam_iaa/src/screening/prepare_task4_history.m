function [envelope, admissible, info] = prepare_task4_history(time, history, response, cfg)
%PREPARE_TASK4_HISTORY Task 2 preparation and per-response onset masking.
% Raw sentinel QC remains separate from this modeling-domain assessment.
time=double(time(:)); history=double(history(:));
% Extend only an already-failed tail; never invent a valid response plateau.
info.padded_tail_samples=0;
lastFinite=find(isfinite(history),1,'last');
if ~isempty(lastFinite) && abs(history(lastFinite))>=cfg.sentinel_abs_threshold ...
        && numel(history)<=numel(time)
    tailEnd=numel(time);
    info.padded_tail_samples=tailEnd-lastFinite;
    history(lastFinite+1:tailEnd)=history(lastFinite);
end
assert(numel(time)==numel(history),'Task4:HistoryLengthMismatch', ...
    'Time and response lengths differ.');
% A failed run may also end before the canonical 20-second endpoint.
paired=isfinite(time) & isfinite(history);
if any(paired)
    pairedIds=find(paired); [lastTime,pos]=max(time(paired));
    lastValue=history(pairedIds(pos));
    if abs(lastValue)>=cfg.sentinel_abs_threshold && lastTime<cfg.time_s(end)
        extra=cfg.time_s(cfg.time_s>lastTime);
        time=[time;extra]; history=[history;repmat(lastValue,numel(extra),1)];
        info.padded_tail_samples=info.padded_tail_samples+numel(extra);
    end
end
info.removed_nonfinite_pairs=sum(~isfinite(time) | ~isfinite(history));
sentinel=isfinite(time) & isfinite(history) & abs(history)>=cfg.sentinel_abs_threshold;
info.sentinel_time_s=inf;
if any(sentinel), info.sentinel_time_s=min(time(sentinel)); end
% Bound sentinel magnitudes to keep interpolation and derivative statistics
% finite. Sentinel time is an independent hard exclusion, never a valid target.
history(sentinel)=sign(history(sentinel))*cfg.sentinel_abs_threshold;
y=interpolate_task4_response_history(time,history,cfg.time_s,'Task 4 history');
envelope=cummax(abs(y));
info.detector=detect_task4_instability_onset(envelope,cfg.time_s,response,cfg.detector);
info.onset_time_s=min(info.detector.onset_time_s,info.sentinel_time_s);
admissible=cfg.time_s < info.onset_time_s;
% Also exclude canonical samples whose interpolation touches a sentinel.
paired=isfinite(time) & isfinite(history);
unsafe=interpolate_task4_response_history(time(paired), ...
    double(sentinel(paired)),cfg.time_s,'Task 4 sentinel support');
firstUnsafe=find(unsafe>0,1);
if ~isempty(firstUnsafe)
    info.onset_time_s=min(info.onset_time_s,cfg.time_s(firstUnsafe));
    admissible=cfg.time_s < info.onset_time_s;
end
info.admissible_samples=sum(admissible);
info.is_usable=info.admissible_samples>=cfg.minimum_clean_samples;
end
