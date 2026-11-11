function [Y,audit,summary] = build_task3_response_specific_envelope_targets(Task3,qc,cfg,multiplier)
%BUILD_TASK3_RESPONSE_SPECIFIC_ENVELOPE_TARGETS Positive peak demands.
% Uses Task 3-calibrated thresholds and response-specific onsets. Original
% signed histories remain unchanged; sentinel and onset samples are excluded.
if nargin<4 || isempty(multiplier), multiplier=5; end
dictionary=task3_response_dictionary(); n=cfg.num_realizations; m=cfg.num_outputs;

referenceMaximum=zeros(1,m);
for k=1:m
    p=dictionary(k).point; r=dictionary(k).response;
    histories=Task3.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r));
    stable=find(~qc.truncated(:,k)); maxima=zeros(numel(stable),1);
    for j=1:numel(stable)
        raw=double(histories{stable(j)}(:));
        envelope=make_envelope(raw,r); maxima(j)=envelope(end);
    end
    referenceMaximum(k)=max(maxima);
end
threshold=max(multiplier*referenceMaximum,1e-12);

Y=nan(n,m); rows=cell(n*m,1); q=0;
for i=1:n
    timeAll=double(Task3.Outputs.dytime{i}(:));
    assert(all(isfinite(timeAll)) && all(diff(timeAll)>0));
    for k=1:m
        p=dictionary(k).point; r=dictionary(k).response;
        raw=double(Task3.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r)){i}(:));
        assert(numel(raw)==numel(timeAll));
        bad=find(~isfinite(raw) | abs(raw)>=cfg.qc.sentinel_abs_threshold,1);
        hadSentinel=~isempty(bad);
        if hadSentinel, lastFinite=bad-1; sentinelTime=timeAll(bad);
        else, lastFinite=numel(raw); sentinelTime=inf; end
        assert(lastFinite>=cfg.qc.minimum_history_length);
        time=timeAll(1:lastFinite); envelope=make_envelope(raw(1:lastFinite),r);
        crossing=find(envelope>=threshold(k),1);
        detected=~isempty(crossing);
        if detected, onsetTime=time(crossing); admissible=(1:numel(envelope))'<crossing;
        else, onsetTime=sentinelTime; admissible=true(size(envelope)); end
        if nnz(admissible)<cfg.qc.minimum_history_length
            error('Task3:EnvelopeOnsetTooEarly', ...
                'Onset leaves too few samples for realization %d, P%dR%d.',i,p,r);
        end
        target=envelope(find(admissible,1,'last')); Y(i,k)=target;
        q=q+1;
        rows{q}=table(i,p,r,k,hadSentinel,sentinelTime,detected,onsetTime, ...
            threshold(k),referenceMaximum(k),numel(envelope),nnz(admissible),target, ...
            'VariableNames',{'realization_id','point','response','output_column', ...
            'had_sentinel','sentinel_time_s','instability_detected','onset_time_s', ...
            'runaway_threshold','stable_reference_maximum','finite_samples', ...
            'admissible_samples','target'});
    end
    if mod(i,25)==0
        fprintf('Task 3 response-specific envelope screening: %d/%d realizations.\n',i,n);
    end
end
audit=vertcat(rows{:}); assert(all(isfinite(Y(:))) && all(Y(:)>=0));
g=findgroups(audit.realization_id);
simulationDetected=splitapply(@any,audit.instability_detected,g);
simulationSentinel=splitapply(@any,audit.had_sentinel,g);
summary=table(multiplier,n,height(audit),sum(simulationSentinel),sum(simulationDetected), ...
    sum(audit.had_sentinel),sum(audit.instability_detected), ...
    sum(audit.instability_detected & ~audit.had_sentinel), ...
    'VariableNames',{'threshold_multiplier','simulations','histories', ...
    'sentinel_simulations','detected_simulations','sentinel_histories', ...
    'detected_histories','detections_without_sentinel'});
end

function envelope=make_envelope(raw,response)
raw=double(raw(:)); assert(all(isfinite(raw)) && ~isempty(raw));
if ismember(response,[3 4 5])
    envelope=cummax(abs(raw-raw(1)));
else
    envelope=cummax(abs(raw));
end
end
