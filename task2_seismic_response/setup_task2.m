function root = setup_task2()
%SETUP_TASK2 Add canonical Task 2 folders to the MATLAB path.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'config'));
addpath(genpath(fullfile(root, 'src')));
addpath(fullfile(root, 'scripts'));
addpath(fullfile(root, 'scripts', 'original_plots'));
addpath(fullfile(root, 'tests'));
% Version-pinned third-party implementations used by the original methods.
ypeaRoot = fullfile(root,'third_party','ypea','src');
igwoRoot = fullfile(root,'third_party','igwo');
if isfolder(ypeaRoot), addpath(genpath(ypeaRoot)); end
if isfolder(igwoRoot), addpath(igwoRoot); end
fprintf('Task 2 paths configured: %s\n', root);
end
