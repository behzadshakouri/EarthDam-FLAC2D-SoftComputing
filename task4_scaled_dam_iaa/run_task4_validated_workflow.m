function report = run_task4_validated_workflow(mode)
%RUN_TASK4_VALIDATED_WORKFLOW Reproduce the accepted Task 4 FMRVR workflow.
%   REPORT = RUN_TASK4_VALIDATED_WORKFLOW("full") audits the private Task 4
%   histories, rebuilds the combined 750-record data set, runs ten repeated
%   scale-stratified outer tests, and regenerates final figures.
%
%   "artifacts" regenerates figures from saved results. "verify" performs
%   read-only consistency checks. Source histories are never modified.

if nargin < 1 || isempty(mode), mode = "full"; end
mode = lower(string(mode));
assert(isscalar(mode) && any(mode == ["full" "artifacts" "verify"]), ...
    'Task4:WorkflowMode','Mode must be full, artifacts, or verify.');

setup_task4();
report = struct;
if mode == "full"
    report.dependencies = check_task4_dependencies;
    run_synthetic_self_test;
    report.synthetic_test_passed = true;
    report.audit = run_task4_data_audit;
    report.dataset = build_task4_scale_aware_dataset(100);
    report.pointwise_fmrvr = run_task4_pointwise_fmrvr_validation(10);
end
if mode ~= "verify"
    generate_task4_pointwise_fmrvr_figures;
    generate_task4_taylor_diagram;
    generate_task4_iaa_spectral_figures;
    generate_task4_geometry_scale_figure;
end
report.verification = verify_task4_validated_artifacts;
fprintf('Task 4 validated workflow complete in %s mode.\n',mode);
end
