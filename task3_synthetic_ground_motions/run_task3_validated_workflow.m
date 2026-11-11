function report = run_task3_validated_workflow(mode)
%RUN_TASK3_VALIDATED_WORKFLOW Reproduce the accepted Task 3 paper workflow.
%   REPORT = RUN_TASK3_VALIDATED_WORKFLOW() starts from the private Task3
%   MAT-file, rebuilds the prepared data and screened response targets, runs
%   the scalar benchmark and final ridge-free point-wise validation, and
%   then regenerates the paper figures and tables.
%
%   RUN_TASK3_VALIDATED_WORKFLOW("artifacts") regenerates paper-facing
%   figures and tables from existing analysis CSV files without fitting.
%   RUN_TASK3_VALIDATED_WORKFLOW("verify") only checks the required outputs.
%
%   Generated MAT/CSV/PDF/PNG products are written to the machine-specific
%   external roots configured in task3_local_paths.m. Original raw data and
%   external paper files are never modified.

if nargin < 1 || isempty(mode), mode = "full"; end
mode = lower(string(mode));
assert(isscalar(mode) && any(mode == ["full" "artifacts" "verify"]), ...
    'Task3:WorkflowMode','Mode must be full, artifacts, or verify.');

root = setup_task3();
analysisDir = fullfile(root,'analysis');
addpath(analysisDir);
cleanup = onCleanup(@()rmpath(analysisDir));
report = struct;

if mode == "full"
    check_task3_dependencies;
    run_task3_smoke_test;

    % Rebuild the original prepared dataset, QC records, and fixed baseline.
    report.production = run_task3_production;
    report.fixed_baseline = run_task3_manuscript_analysis;

    % Audit the common simulation-level loss-of-validity rule. The common
    % onset defines the admissible interval; response-specific onset remains
    % a sensitivity analysis.
    report.envelope_audit = run_task3_envelope_target_audit;
    report.response_specific_audit = run_task3_response_specific_envelope_audit;
    report.envelope_equivalence = verify_task3_common_onset_envelope_equivalence;
    report.detector_sensitivity = run_task3_detector_model_sensitivity;
    report.screening_sensitivity = run_task3_screening_sensitivity_final;
    report.development_reference_sensitivity = run_task3_development_reference_sensitivity;

    % Scalar-demand benchmark retained from the precommit formulation.
    report.scalar_fmrvr = run_task3_fmrvr_experts_nested_validation;
    report.scalar_comparators = run_task3_final_matched_comparators;

    % Primary cumulative-envelope result reported in the manuscript.
    report.pointwise_fmrvr = run_task3_compact_pointwise_fmrvr_validation(10);
    report.reviewer_ablation = run_task3_reviewer_ablation(10);

    % Physical interpretation and a documented rejected refinement.
    report.modal = run_task3_modal_period_analysis;
    report.rejected_refinement = run_task3_fmrvr_severity_family_validation;
end

if mode ~= "verify"
    % Only the final point-wise figures belong to the accepted artifact path.
    % Scalar-demand and residual-era presentation scripts remain available as
    % development evidence but are not regenerated here.
    generate_task3_compact_fmrvr_figures;
    generate_task3_taylor_diagram;
    generate_task3_ground_motion_figures;
    generate_task3_screening_sensitivity_figure;
    generate_task3_monitoring_response_figure;
end
report.verification = verify_task3_validated_artifacts;
fprintf('Task 3 validated workflow complete in %s mode.\n',mode);
end
