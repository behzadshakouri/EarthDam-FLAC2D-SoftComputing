function raw = task1_user_paths(root)
%TASK1_USER_PATHS User-editable locations of historical Task 1 inputs.
raw.outputs_gp_file = ''; % outputs_gp.mat
raw.fos_data_file = '';   % PT1_FoS_SCT.xlsx
raw.reference_dir = '';   % optional published/reference outputs
raw.search_root = fileparts(root);
raw.search_parent_levels = 4;
end
