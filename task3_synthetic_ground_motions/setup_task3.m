function root = setup_task3()
%SETUP_TASK3 Add the Task 3 implementation to the MATLAB path.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'config'));
addpath(fullfile(root, 'analysis'));
addpath(genpath(fullfile(root, 'src')));
addpath(fullfile(root, 'tests'));
addpath(fullfile(root, 'third_party', 'fmrvr_ha'));
fprintf('Task 3 paths configured: %s\n', root);
end
