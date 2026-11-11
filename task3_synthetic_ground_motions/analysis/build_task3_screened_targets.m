function [Y,audit,screening] = build_task3_screened_targets(Task3,dataset,qc,cfg,multiplier,referenceIds)
%BUILD_TASK3_SCREENED_TARGETS Reduce native-duration histories before runaway.
% Thresholds are anchored to fully finite histories, and applied only to
% histories that later contain an explicit FLAC invalid/sentinel value.
n=cfg.num_realizations; m=cfg.num_outputs; dictionary=dataset.output_dictionary;
if nargin<5 || isempty(multiplier), multiplier=10; end
if nargin<6 || isempty(referenceIds), referenceIds=(1:n)'; end
referenceIds=unique(double(referenceIds(:)));
assert(all(referenceIds>=1 & referenceIds<=n & referenceIds==round(referenceIds)), ...
    'Task3:ReferenceIds','Reference realization IDs are invalid.');
referenceMaximum=zeros(1,m);
for k=1:m
    p=dictionary(k).point; r=dictionary(k).response;
    histories=Task3.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r));
    finiteIds=referenceIds(~qc.truncated(referenceIds,k));
    assert(~isempty(finiteIds), ...
        'Task3:ReferenceCoverage','No complete reference history for output %d.',k);
    values=zeros(numel(finiteIds),1);
    for j=1:numel(finiteIds)
        h=double(histories{finiteIds(j)}(:)); values(j)=max(abs(h));
    end
    referenceMaximum(k)=max(values);
end
screening.multiplier=multiplier;
screening.reference_ids=referenceIds;
screening.reference_maximum=referenceMaximum;
screening.runaway_threshold=max(screening.multiplier*referenceMaximum,1e-12);

Y=nan(n,m); onset=inf(n,1); sentinelTime=inf(n,1);
runawayMarkers=zeros(n,1); filledTailSamples=zeros(n,1);
for i=1:n
    time=double(Task3.Outputs.dytime{i}(:));
    assert(all(isfinite(time)) && all(diff(time)>0));
    if any(qc.truncated(i,:))
        candidates=[];
        for k=find(qc.truncated(i,:))
            p=dictionary(k).point; r=dictionary(k).response;
            history=double(Task3.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r)){i}(:));
            bad=find(~isfinite(history) | abs(history)>=cfg.qc.sentinel_abs_threshold,1);
            assert(~isempty(bad)); sentinelTime(i)=min(sentinelTime(i),time(bad));

            % Carry the repeated failure magnitude through this record's own
            % stored endpoint. It is retained only as a failure marker.
            if isfinite(history(bad))
                fillValue=history(bad);
            else
                previous=find(isfinite(history(1:bad-1)),1,'last');
                assert(~isempty(previous)); fillValue=history(previous);
            end
            history(bad:end)=fillValue;
            filledTailSamples(i)=filledTailSamples(i)+numel(history)-bad+1;

            crossing=find(abs(history(1:bad))>=screening.runaway_threshold(k),1);
            if ~isempty(crossing)
                candidates(end+1)=time(crossing); %#ok<AGROW>
                runawayMarkers(i)=runawayMarkers(i)+1;
            end
        end
        if ~isempty(candidates), onset(i)=min(candidates); else, onset(i)=sentinelTime(i); end
    end

    for k=1:m
        p=dictionary(k).point; r=dictionary(k).response;
        history=double(Task3.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r)){i}(:));
        admissible=isfinite(history) & abs(history)<cfg.qc.sentinel_abs_threshold;
        if isfinite(onset(i)), admissible=admissible & time<onset(i); end
        values=history(admissible);
        assert(numel(values)>=cfg.qc.minimum_history_length, ...
            'No admissible response prefix for realization %d, output %d.',i,k);
        Y(i,k)=reduce_task3_history(values,cfg.output.reduction_modes{r});
    end
    if mod(i,25)==0, fprintf('Task 3 runaway screening: %d/%d realizations.\n',i,n); end
end
assert(all(isfinite(Y(:))));
audit=table((1:n)',any(qc.truncated,2),onset,sentinelTime,runawayMarkers,filledTailSamples, ...
    'VariableNames',{'realization_id','had_sentinel','screening_onset_s', ...
    'first_sentinel_s','runaway_markers','filled_tail_samples'});
end
