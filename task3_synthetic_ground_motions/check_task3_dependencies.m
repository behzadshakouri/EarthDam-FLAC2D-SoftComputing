function report = check_task3_dependencies()
%CHECK_TASK3_DEPENDENCIES Report required files and configured private data.
root = setup_task3(); cfg = task3_config(root);
required = {'fmrvr','task3_rbf_design','extract_ground_motion_features', ...
    'build_task3_dataset','select_task3_kernel_width'};
available = cellfun(@(name) exist(name,'file')==2,required);
report = table(required(:),available(:),'VariableNames',{'component','available'});
disp(report);
fprintf('Private data configured and found: %d\n',exist(cfg.raw.task3_data_file,'file')==2);
assert(all(available),'One or more Task 3 code dependencies are missing.');
end
