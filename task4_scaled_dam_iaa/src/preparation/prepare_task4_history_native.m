function [envelope, admissible, info] = prepare_task4_history_native(time, history, response, cfg)
%PREPARE_TASK4_HISTORY_NATIVE Prepare only the response interval FLAC2D stored.
% Ordinary early-ended histories are never extrapolated.  Sentinel-ended
% histories retain the established failed-tail handling so their failure
% support remains available to the detector and is then excluded.

time=double(time(:)); history=double(history(:)); target=double(cfg.time_s(:));
info.padded_tail_samples=0;

% Some exported response cells can be shorter than their shared time cell.
% Extend only an already-failed sentinel tail; otherwise retain paired data.
lastFinite=find(isfinite(history),1,'last');
if ~isempty(lastFinite) && abs(history(lastFinite))>=cfg.sentinel_abs_threshold ...
        && numel(history)<numel(time)
    history(lastFinite+1:numel(time))=history(lastFinite);
    info.padded_tail_samples=numel(time)-lastFinite;
end
n=min(numel(time),numel(history));
info.unpaired_samples=abs(numel(time)-numel(history));
time=time(1:n); history=history(1:n);
valid=isfinite(time) & isfinite(history);
info.removed_nonfinite_pairs=sum(~valid);
time=time(valid); history=history(valid);
[time,order]=sort(time); history=history(order);
[time,keep]=unique(time,'stable'); history=history(keep);
if numel(time)<2
    error('Task4:HistoryTooShort','Fewer than two finite paired samples remain.');
end

sentinel=abs(history)>=cfg.sentinel_abs_threshold;
info.sentinel_time_s=inf;
if any(sentinel), info.sentinel_time_s=min(time(sentinel)); end

% A failed run may end before 20 s.  Carry only its failure marker forward;
% it is a hard exclusion and is never used as a valid response target.
if sentinel(end) && time(end)<target(end)
    extra=target(target>time(end));
    time=[time;extra];
    history=[history;repmat(history(end),numel(extra),1)];
    sentinel=[sentinel;true(numel(extra),1)];
    info.padded_tail_samples=info.padded_tail_samples+numel(extra);
end
history(sentinel)=sign(history(sentinel))*cfg.sentinel_abs_threshold;

dt=median(diff(target)); tol=abs(dt)/2+max(1e-10,abs(dt)*1e-6);
coverage=target>=time(1)-tol & target<=time(end)+tol;
query=target(coverage);
if isempty(query)
    error('Task4:NoObservedCoverage','History does not overlap the canonical time grid.');
end
% Permit only half-step boundary snapping, consistent with the strict path.
ti=time; yi=history; si=double(sentinel);
if ti(1)>query(1) && ti(1)<=query(1)+tol
    ti=[query(1);ti]; yi=[yi(1);yi]; si=[si(1);si];
end
if ti(end)<query(end) && ti(end)>=query(end)-tol
    ti=[ti;query(end)]; yi=[yi;yi(end)]; si=[si;si(end)];
end
yq=interp1(ti,yi,query,'linear');
unsafe=interp1(ti,si,query,'linear');
if any(~isfinite(yq)) || any(~isfinite(unsafe))
    error('Task4:InterpolationNonfinite','Native-duration interpolation failed.');
end

envelope=nan(size(target)); envelope(coverage)=cummax(abs(yq));
admissible=coverage;
firstUnsafe=find(unsafe>0,1);
if isempty(firstUnsafe)
    safeCount=numel(query);
else
    safeCount=firstUnsafe-1;
    admissible(find(coverage,1,'first')+firstUnsafe-1:end)=false;
end

coveredIds=find(coverage);
if safeCount>=2
    detector=detect_task4_instability_onset(envelope(coveredIds(1:safeCount)), ...
        target(coveredIds(1:safeCount)),response,cfg.detector);
else
    detector=empty_detector_result();
end
info.detector=detector;
info.onset_time_s=min(detector.onset_time_s,info.sentinel_time_s);
admissible=admissible & target<info.onset_time_s;
info.observed_start_time_s=time(1);
info.observed_end_time_s=time(end);
info.admissible_samples=sum(admissible);
info.is_usable=info.admissible_samples>=cfg.minimum_clean_samples;
end

function result=empty_detector_result()
result=struct('failure_detected',false,'onset_step',inf,'onset_time_s',inf, ...
    'onset_value',nan,'method',"insufficient_safe_samples",'peak_value',nan, ...
    'center',nan,'derivative_mean',nan,'derivative_std',nan);
end
