function path = task4_output_root(root)
%TASK4_OUTPUT_ROOT Resolve generated figures and presentation artifacts.
if nargin < 1 || isempty(root)
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
cfg = task4_config(root);
path = cfg.output_root;
end
