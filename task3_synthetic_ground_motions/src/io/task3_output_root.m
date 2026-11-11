function path = task3_output_root(root)
%TASK3_OUTPUT_ROOT Resolve generated figures and presentation artifacts.
if nargin < 1 || isempty(root)
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
cfg = task3_config(root);
path = cfg.output_root;
end
