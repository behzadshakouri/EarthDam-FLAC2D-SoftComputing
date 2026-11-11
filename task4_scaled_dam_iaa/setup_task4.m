function root = setup_task4()
%SETUP_TASK4 Add the preliminary Task 4 workflow to the MATLAB path.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'config'));
addpath(fullfile(root,'analysis'));
addpath(genpath(fullfile(root,'src')));
addpath(fullfile(root,'tests'));
fprintf('Task 4 paths configured: %s\n',root);
end
