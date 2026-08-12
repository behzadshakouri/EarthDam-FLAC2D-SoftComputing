function paths = resolve_task2_input_paths(cfg)
%RESOLVE_TASK2_INPUT_PATHS Resolve explicit paths or unique nearby matches.
paths = cfg.raw;
paths.task2_data_file = resolve_one(paths.task2_data_file, 'Task2Data.mat', cfg);
paths.pga_file = resolve_pga(paths.pga_file, cfg);

if ~isempty(paths.inputs_file)
    paths.inputs_file = require_file(paths.inputs_file, 'inputs_file');
else
    paths.inputs_file = find_optional('RVs+WL.xlsx', cfg);
end
end

function path_out = resolve_pga(explicit_path, cfg)
if ~isempty(explicit_path)
    path_out = require_file(explicit_path, 'pga_file');
    return
end
names = {'IAAPGA20sec.xlsx', 'IAA-20sec.xlsx', 'IAAPGA20sec.mat'};
hits = strings(0,1);
for i = 1:numel(names)
    candidate = find_all(names{i}, cfg);
    hits = [hits; string(candidate(:))]; %#ok<AGROW>
end
hits = unique(hits, 'stable');
if isempty(hits)
    error('Task2:PgaNotFound', ['PGA input was not found. Set raw.pga_file in ' ...
        'config/task2_user_paths.m to IAAPGA20sec.xlsx or IAA-20sec.xlsx.']);
end
if numel(hits) > 1
    error('Task2:AmbiguousPga', 'Multiple PGA files found. Set raw.pga_file explicitly:\n%s', ...
        strjoin(cellstr(hits), newline));
end
path_out = char(hits);
end

function path_out = resolve_one(explicit_path, filename, cfg)
if ~isempty(explicit_path)
    path_out = require_file(explicit_path, filename);
    return
end
hits = find_all(filename, cfg);
if isempty(hits)
    error('Task2:InputNotFound', ['%s was not found. Set raw.task2_data_file in ' ...
        'config/task2_user_paths.m.'], filename);
end
if numel(hits) > 1
    error('Task2:AmbiguousInput', 'Multiple %s files found. Set the path explicitly:\n%s', ...
        filename, strjoin(hits, newline));
end
path_out = hits{1};
end

function path_out = find_optional(filename, cfg)
hits = find_all(filename, cfg);
if numel(hits) == 1, path_out = hits{1}; else, path_out = ''; end
end

function hits = find_all(filename, cfg)
root = cfg.raw.search_root;
hits = {};
for level = 0:cfg.raw.search_parent_levels
    if ~isfolder(root), break; end
    direct = fullfile(root, filename);
    if isfile(direct), hits{end+1,1} = direct; end %#ok<AGROW>
    listing = dir(fullfile(root, '**', filename));
    for k = 1:numel(listing)
        hits{end+1,1} = fullfile(listing(k).folder, listing(k).name); %#ok<AGROW>
    end
    parent = fileparts(root);
    if strcmp(parent, root), break; end
    root = parent;
end
hits = unique(hits, 'stable');
end

function path_out = require_file(path_in, label)
path_out = char(path_in);
if ~isfile(path_out)
    error('Task2:MissingFile', '%s does not exist: %s', label, path_out);
end
end
