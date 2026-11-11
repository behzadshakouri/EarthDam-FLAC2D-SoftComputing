function report = verify_task4_validated_artifacts()
%VERIFY_TASK4_VALIDATED_ARTIFACTS Check the final Task 4 paper evidence.
root = setup_task4(); cfg = task4_config(root);
resultsDir = fullfile(cfg.results_dir,'scale_aware','production');
figuresDir = fullfile(cfg.output_root,'pointwise_fmrvr');

required = {
    fullfile(cfg.results_dir,'task4_simulation_metadata.csv')
    fullfile(cfg.results_dir,'task4_history_qc.csv')
    fullfile(cfg.results_dir,'scale_aware','task4_scale_aware_dataset.mat')
    fullfile(resultsDir,'pointwise_fmrvr_summary.csv')
    fullfile(resultsDir,'pointwise_fmrvr_outer_metrics.csv')
    fullfile(resultsDir,'pointwise_fmrvr_per_output.csv')
    fullfile(resultsDir,'pointwise_fmrvr_per_scale.csv')
    fullfile(resultsDir,'pointwise_fmrvr_per_scale_output.csv')
    fullfile(resultsDir,'pointwise_fmrvr_point_summary.csv')
    fullfile(resultsDir,'pointwise_fmrvr_response_summary.csv')
    fullfile(resultsDir,'pointwise_fmrvr_scale_summary.csv')
    fullfile(resultsDir,'pointwise_fmrvr_timing.csv')
    fullfile(resultsDir,'pointwise_fmrvr_split_assignments.csv')
    fullfile(resultsDir,'pointwise_fmrvr_split1.mat')
    fullfile(figuresDir,'task4_repeated_validation.png')
    fullfile(figuresDir,'task4_point_response_performance.png')
    fullfile(figuresDir,'task4_output_map.png')
    fullfile(figuresDir,'task4_scale_performance.png')
    fullfile(figuresDir,'task4_all70_observed_predicted.png')
    fullfile(figuresDir,'task4_taylor_diagram.png')
    fullfile(figuresDir,'task4_iaa_psa_heatmap.png')
    fullfile(figuresDir,'task4_iaa_psv_heatmap.png')
    fullfile(figuresDir,'task4_iaa_spectral_heatmaps.png')
    fullfile(figuresDir,'task4_geometry_scale_composite.png')
    };
exists = cellfun(@isfile,required);
assert(all(exists),'Task4:MissingArtifact','Missing required artifact: %s',required{find(~exists,1)});

summary = readtable(fullfile(resultsDir,'pointwise_fmrvr_summary.csv'));
outer = readtable(fullfile(resultsDir,'pointwise_fmrvr_outer_metrics.csv'));
outputs = readtable(fullfile(resultsDir,'pointwise_fmrvr_per_output.csv'));
timing = readtable(fullfile(resultsDir,'pointwise_fmrvr_timing.csv'));
splits = readtable(fullfile(resultsDir,'pointwise_fmrvr_split_assignments.csv'));
saved = load(fullfile(resultsDir,'pointwise_fmrvr_split1.mat'),'splitOne');

assert(height(outer)==10 && numel(unique(outer.repeat))==10,'Task4:OuterSplits','Expected ten outer splits.');
assert(abs(summary.mean_R2-mean(outer.mean_R2))<1e-12);
assert(abs(summary.sd_R2-std(outer.mean_R2))<1e-12);
assert(abs(summary.mean_nRMSE-mean(outer.mean_nRMSE))<1e-12);
assert(abs(summary.mean_nMAE-mean(outer.mean_nMAE))<1e-12);
assert(abs(summary.mean_a10-mean(outer.mean_a10))<1e-12);
assert(sum(~outputs.constant)==670,'Task4:OutputCount','Expected 67 nonconstant outputs in each split.');
assert(height(splits)==7500,'Task4:SplitAssignments','Expected 750 assignment rows for each split.');
part = string(splits.partition);
for repeat=1:10
    rows=splits.repeat==repeat;
    assert(sum(part(rows)=="development")==600 && sum(part(rows)=="test")==150, ...
        'Task4:SplitSize','Each split must contain 600 development and 150 test records.');
    for scale=[.25 .5 1 1.5]
        atScale=rows & splits.scale_factor==scale;
        expectedTest=30;if scale==1,expectedTest=60;end
        assert(sum(part(atScale)=="test")==expectedTest,'Task4:ScaleStratification','Unexpected scale allocation.');
    end
end
assert(all(timing.warmup_runs==5 & timing.measured_runs==100),'Task4:TimingProtocol','Unexpected timing protocol.');
assert(numel(saved.splitOne.models)==10 && numel(saved.splitOne.feature_names)==17, ...
    'Task4:ModelStructure','Expected ten point models and 17 predictors.');
for point=1:10
    prediction=double(saved.splitOne.predictions{point});
    ids=double(saved.splitOne.record_ids{point});
    assert(all(prediction(:)>=0),'Task4:NegativePrediction','Predictions must be nonnegative.');
    for id=unique(ids(:))'
        rows=ids==id;
        assert(all(all(diff(prediction(rows,:),1,1)>=-1e-12)), ...
            'Task4:NonmonotonicPrediction','Prediction is not nondecreasing.');
    end
end

report = table(numel(required),height(outer),sum(~outputs.constant)/10,17, ...
    summary.mean_R2,summary.mean_nRMSE,summary.mean_a10, ...
    'VariableNames',{'required_artifacts','outer_splits','nonconstant_outputs', ...
    'predictors','mean_R2','mean_nRMSE','mean_a10'});
writetable(report,fullfile(resultsDir,'validated_workflow_verification.csv'));
fprintf('Verified final Task 4 evidence: %d splits, %d outputs, mean R2 %.4f.\n', ...
    report.outer_splits,report.nonconstant_outputs,report.mean_R2);
end
