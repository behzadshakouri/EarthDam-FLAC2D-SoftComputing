function path = task3_analysis_results_root(root)
%TASK3_ANALYSIS_RESULTS_ROOT Resolve exploratory and intermediate outputs.
if nargin < 1 || isempty(root)
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
cfg = task3_config(root);
path = cfg.analysis_results_dir;
end
