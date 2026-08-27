function D = load_task1_dataset(cfg)
%LOAD_TASK1_DATASET Load and validate the two private Task 1 inputs.
if isempty(cfg.raw.outputs_gp_file) || ~isfile(cfg.raw.outputs_gp_file)
    error('Task1:MissingOutputs','Configure cfg.raw.outputs_gp_file.');
end
S=load(cfg.raw.outputs_gp_file,'RVs','outputs_gp');
assert(isfield(S,'RVs') && isequal(size(S.RVs),[500 18]), ...
    'Task1:BadRVs','RVs must be 500 x 18.');
assert(isfield(S,'outputs_gp') && isequal(size(S.outputs_gp),[28392 6 500]), ...
    'Task1:BadOutputs','outputs_gp must be 28392 x 6 x 500.');
assert(all(isfinite(S.RVs(:))) && all(isfinite(S.outputs_gp(:))), ...
    'Task1:NonfiniteData','Inputs must contain only finite values.');
D.RVs=S.RVs; D.outputs_gp=S.outputs_gp;
if ~isempty(cfg.raw.fos_data_file) && isfile(cfg.raw.fos_data_file)
    A=readmatrix(cfg.raw.fos_data_file);
    A=A(1:500,1:19);
    assert(isequal(size(A),[500 19]) && all(isfinite(A(:))), ...
        'Task1:BadFoS','FoS workbook must contain finite data in A1:S500.');
    D.fos_X=A(:,1:18); D.fos_y=A(:,19);
else
    D.fos_X=[]; D.fos_y=[];
end
end
