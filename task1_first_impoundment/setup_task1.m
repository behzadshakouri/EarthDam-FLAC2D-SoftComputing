function root = setup_task1()
%SETUP_TASK1 Add canonical Task 1 folders to the MATLAB path.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'config'));
addpath(genpath(fullfile(root,'src')));
addpath(fullfile(root,'tests'));
ypeaRoot = fullfile(root,'third_party','ypea','src');
igwoRoot = fullfile(root,'third_party','igwo');
if isfolder(ypeaRoot), addpath(genpath(ypeaRoot)); end
if isfolder(igwoRoot), addpath(igwoRoot); end
fprintf('Task 1 paths configured: %s\n',root);
end
