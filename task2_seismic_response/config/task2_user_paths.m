function raw = task2_user_paths(root)
%TASK2_USER_PATHS User-editable locations of the historical Task 2 inputs.
% Leave a value empty to let run_data_preparation search near this package.

raw.task2_data_file = '';  % Task2Data.mat containing variable Task2
raw.inputs_file = '';      % Optional RVs+WL.xlsx; Task2.Inputs.InputsMatrix is preferred
raw.pga_file = '';         % IAAPGA20sec.xlsx or IAA-20sec.xlsx

% Auto-discovery searches the package folder and four parent folders.
raw.search_root = fileparts(root);
raw.search_parent_levels = 4;
end
