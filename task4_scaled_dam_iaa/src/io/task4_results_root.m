function path = task4_results_root(root)
%TASK4_RESULTS_ROOT Resolve the machine-specific full-results directory.
if nargin < 1 || isempty(root)
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
cfg = task4_config(root);
path = cfg.results_dir;
end
