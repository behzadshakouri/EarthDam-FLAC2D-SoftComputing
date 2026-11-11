function path = task3_results_root(root)
%TASK3_RESULTS_ROOT Resolve the machine-specific full-results directory.
if nargin < 1 || isempty(root)
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
cfg = task3_config(root);
path = cfg.results_root;
end
