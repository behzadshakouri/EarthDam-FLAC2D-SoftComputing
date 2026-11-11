function report = verify_task3_validated_artifacts()
%VERIFY_TASK3_VALIDATED_ARTIFACTS Check the final ridge-free paper evidence.
root = setup_task3();
analysisDir = task3_analysis_results_root(root);
resultsDir = fullfile(task3_results_root(root),'compact_pointwise_fmrvr');
figuresDir = fullfile(task3_output_root(root),'compact_pointwise_fmrvr');
referenceDir = fullfile(root,'reference_results');

required = {
    fullfile(analysisDir,'detector_screening_summary.csv')
    fullfile(analysisDir,'common_onset_envelope_equivalence.csv')
    fullfile(referenceDir,'screening_sensitivity.csv')
    fullfile(referenceDir,'development_reference_screening_summary.csv')
    fullfile(referenceDir,'reviewer_predictor_ablation_summary.csv')
    fullfile(referenceDir,'reviewer_multi_vs_single_summary.csv')
    fullfile(referenceDir,'reviewer_projection_ablation_summary.csv')
    fullfile(referenceDir,'reviewer_terminal_metrics_by_family_summary.csv')
    fullfile(referenceDir,'reviewer_ranking_critical_point_by_family_summary.csv')
    fullfile(analysisDir,'fmrvr_experts_nested_summary.csv')
    fullfile(resultsDir,'summary.csv')
    fullfile(resultsDir,'outer_metrics.csv')
    fullfile(resultsDir,'inner_selections.csv')
    fullfile(resultsDir,'per_output.csv')
    fullfile(resultsDir,'point_summary.csv')
    fullfile(resultsDir,'response_summary.csv')
    fullfile(resultsDir,'timing.csv')
    fullfile(resultsDir,'split_assignments.csv')
    fullfile(resultsDir,'split1.mat')
    fullfile(figuresDir,'time_resolved_nested_validation.png')
    fullfile(figuresDir,'time_resolved_family_performance.png')
    fullfile(figuresDir,'time_resolved_output_map.png')
    fullfile(figuresDir,'time_resolved_all70_observed_predicted.png')
    fullfile(figuresDir,'time_resolved_representative_histories.png')
    fullfile(figuresDir,'task3_taylor_diagram.png')
    fullfile(figuresDir,'task3_ground_motion_characterization.png')
    fullfile(figuresDir,'task3_monitoring_response_composite.png')
    fullfile(task3_output_root(root),'figures','screening_sensitivity.png')
    };
exists = cellfun(@isfile,required);
assert(all(exists),'Task3:MissingArtifact','Missing required artifact: %s',required{find(~exists,1)});

summary = readtable(fullfile(resultsDir,'summary.csv'));
outer = readtable(fullfile(resultsDir,'outer_metrics.csv'));
outputs = readtable(fullfile(resultsDir,'per_output.csv'));
selections = readtable(fullfile(resultsDir,'inner_selections.csv'));
timing = readtable(fullfile(resultsDir,'timing.csv'));
splits = readtable(fullfile(resultsDir,'split_assignments.csv'));
saved = load(fullfile(resultsDir,'split1.mat'),'splitOne');
detector = readtable(fullfile(analysisDir,'detector_screening_summary.csv'));
equivalence = readtable(fullfile(analysisDir,'common_onset_envelope_equivalence.csv'));
predictorAblation = readtable(fullfile(referenceDir,'reviewer_predictor_ablation_summary.csv'));
methodAblation = readtable(fullfile(referenceDir,'reviewer_multi_vs_single_summary.csv'));
detector5 = detector(detector.threshold_multiplier==5,:);

assert(height(outer)==10 && numel(unique(outer.repeat))==10,'Task3:OuterSplits','Expected ten outer splits.');
assert(abs(summary.mean_R2-mean(outer.mean_R2))<1e-12);
assert(abs(summary.sd_R2-std(outer.mean_R2))<1e-12);
assert(abs(summary.mean_nRMSE-mean(outer.mean_nRMSE))<1e-12);
assert(abs(summary.mean_nMAE-mean(outer.mean_nMAE))<1e-12);
assert(abs(summary.mean_a10-mean(outer.mean_a10))<1e-12);
assert(sum(~outputs.constant)==670,'Task3:OutputCount','Expected 67 nonconstant outputs in each split.');
assert(height(selections)==100,'Task3:Selections','Expected ten point selections for each outer split.');
assert(height(splits)==1500,'Task3:SplitAssignments','Expected 150 assignment rows for each split.');
for repeat=1:10
    rows=splits.repeat==repeat;
    assert(sum(splits.partition(rows)=="development")==105 && sum(splits.partition(rows)=="test")==45, ...
        'Task3:SplitSize','Each split must contain 105 development and 45 test records.');
end
assert(all(timing.warmup_runs==5 & timing.measured_runs==100),'Task3:TimingProtocol','Unexpected timing protocol.');
assert(height(detector5)==1 && detector5.sentinel_records==48 && detector5.screened_records==48, ...
    'Task3:SentinelCount','Expected 48 sentinel-bearing and screened simulations at 5x.');
assert(equivalence.nonzero_differences==0,'Task3:TargetMismatch','Common-onset envelope targets differ.');
assert(height(predictorAblation)==4,'Task3:PredictorAblation','Expected four predictor-set checks.');
assert(height(methodAblation)==2,'Task3:MethodAblation','Expected matched multi- and single-output checks.');
assert(size(saved.splitOne.observed,1)==4500 && size(saved.splitOne.observed,2)==70, ...
    'Task3:SavedPredictionSize','Expected 45 records x 100 samples and 70 outputs.');
assert(numel(saved.splitOne.feature_names)==33,'Task3:FeatureCount','Expected 33 predictors.');
assert(all(saved.splitOne.prediction(:)>=0),'Task3:NegativePrediction','Predictions must be nonnegative.');
ids=unique(saved.splitOne.record_id,'stable');
for id=ids'
    rows=saved.splitOne.record_id==id;
    assert(all(all(diff(saved.splitOne.prediction(rows,:),1,1)>=-1e-12)), ...
        'Task3:NonmonotonicPrediction','Prediction is not nondecreasing.');
end

report = table(numel(required),height(outer),sum(~outputs.constant)/10,detector5.sentinel_records, ...
    summary.mean_R2,summary.mean_nRMSE,summary.mean_a10, ...
    'VariableNames',{'required_artifacts','outer_splits','nonconstant_outputs', ...
    'sentinel_simulations','mean_R2','mean_nRMSE','mean_a10'});
writetable(report,fullfile(resultsDir,'validated_workflow_verification.csv'));
fprintf('Verified final Task 3 evidence: %d splits, %d outputs, mean R2 %.4f.\n', ...
    report.outer_splits,report.nonconstant_outputs,report.mean_R2);
end
