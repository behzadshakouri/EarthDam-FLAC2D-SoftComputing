function [Y,audit,summary] = build_task3_envelope_targets(Task3,cfg)
%BUILD_TASK3_ENVELOPE_TARGETS Task 2-style envelopes with native Task 3 time grids.
% Raw histories are not modified. The v4.2 response-specific detector is
% applied to each finite pre-sentinel envelope, and the final admissible
% envelope value becomes the scalar Task 3 demand target.

task2Root=fullfile(fileparts(cfg.root),'task2_seismic_response');
addpath(fullfile(task2Root,'src','screening'));
detector=task2_detector_settings();
dictionary=task3_response_dictionary();
n=cfg.num_realizations; m=cfg.num_outputs;
Y=nan(n,m);
rows=cell(n*m,1); q=0;

for i=1:n
    timeAll=double(Task3.Outputs.dytime{i}(:));
    assert(all(isfinite(timeAll)) && all(diff(timeAll)>0), ...
        'Invalid time vector for realization %d.',i);
    for k=1:m
        p=dictionary(k).point; r=dictionary(k).response;
        raw=double(Task3.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r)){i}(:));
        assert(numel(raw)==numel(timeAll), ...
            'Length mismatch for realization %d, P%dR%d.',i,p,r);
        bad=find(~isfinite(raw) | abs(raw)>=cfg.qc.sentinel_abs_threshold,1);
        hadSentinel=~isempty(bad);
        if hadSentinel, lastFinite=bad-1; sentinelTime=timeAll(bad);
        else, lastFinite=numel(raw); sentinelTime=inf; end
        assert(lastFinite>=cfg.qc.minimum_history_length, ...
            'Insufficient finite prefix for realization %d, P%dR%d.',i,p,r);
        time=timeAll(1:lastFinite); values=raw(1:lastFinite);

        if ismember(r,[3 4 5])
            envelope=cummax(abs(values-values(1)));
            definition="cumulative_absolute_increment";
        else
            envelope=cummax(abs(values));
            definition="cumulative_absolute_response";
        end

        detection=detect_instability_onset(envelope,time,r,detector);
        admissible=true(size(envelope));
        if detection.failure_detected
            admissible=time<detection.onset_time_s;
        end
        if nnz(admissible)<cfg.qc.minimum_history_length
            % A detector onset inside the baseline is not usable for a scalar
            % demand. Retain the finite prefix and flag this fallback.
            admissible=true(size(envelope));
            fallback=true;
        else
            fallback=false;
        end
        target=envelope(find(admissible,1,'last'));
        Y(i,k)=target;
        q=q+1;
        rows{q}=table(i,p,r,k,hadSentinel,sentinelTime, ...
            detection.failure_detected,detection.onset_time_s,string(detection.method), ...
            fallback,numel(envelope),nnz(admissible),target,definition, ...
            'VariableNames',{'realization_id','point','response','output_column', ...
            'had_sentinel','sentinel_time_s','instability_detected','onset_time_s', ...
            'detection_method','early_onset_fallback','finite_samples', ...
            'admissible_samples','target','target_definition'});
    end
    if mod(i,25)==0
        fprintf('Task 3 envelope screening: %d/%d realizations.\n',i,n);
    end
end

audit=vertcat(rows{:});
assert(all(isfinite(Y(:))) && all(Y(:)>=0));
simulationDetected=splitapply(@any,audit.instability_detected, ...
    findgroups(audit.realization_id));
simulationSentinel=splitapply(@any,audit.had_sentinel, ...
    findgroups(audit.realization_id));
summary=table(n,height(audit),sum(simulationSentinel),sum(simulationDetected), ...
    sum(audit.instability_detected),sum(audit.early_onset_fallback), ...
    'VariableNames',{'simulations','histories','sentinel_simulations', ...
    'detected_simulations','detected_histories','early_onset_fallbacks'});
end

function detector=task2_detector_settings()
% Frozen Task 2 v4.2 settings, copied explicitly for a reproducible experiment.
detector.version='legacy_v4_2_adapter';
detector.smoothing_window=11;
detector.baseline_s=[2 2 1 1 1 2 2];
detector.z_threshold=[6 6 5 5 5 6 6];
detector.level_factor=[50 50 2.5 2.5 2.5 50 50];
detector.hold_steps=[10 10 5 5 5 10 10];
detector.logic=["and" "and" "or" "or" "or" "and" "and"];
detector.use_log=false;
detector.min_exceed_factor=.5;
detector.jump_only_hold=[1 1 3 3 3 1 1];
detector.jump_lookback_steps=[1 1 25 25 25 1 1];
detector.minimum_signal=1e-12;
detector.minimum_derivative_std=1e-12;
detector.absolute_jump_threshold=zeros(1,7);
end
