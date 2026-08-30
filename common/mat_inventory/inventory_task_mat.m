function reportFile = inventory_task_mat(preferredVariable, matFile, reportFile)
%INVENTORY_TASK_MAT Create a bounded recursive inventory of a task MAT-file.
% The report defaults to the same directory as the selected MAT-file.
if nargin < 1, preferredVariable = ''; end
if nargin < 2 || isempty(matFile)
    [name, folder] = uigetfile('*.mat','Select the task MAT-file');
    if isequal(name,0), error('No MAT-file was selected.'); end
    matFile = fullfile(folder,name);
end
assert(exist(matFile,'file') == 2,'MAT-file not found: %s',matFile);
top = whos('-file',matFile);
assert(~isempty(top),'No variables were found in %s.',matFile);
names = {top.name}; selected = find(strcmpi(names,preferredVariable),1);
if isempty(selected)
    if numel(names) == 1
        selected = 1;
    else
        fprintf('Top-level variables:\n');
        for k = 1:numel(names), fprintf('  %d: %s\n',k,names{k}); end
        selected = input('Enter the variable number to inspect: ');
        assert(isscalar(selected) && selected >= 1 && ...
            selected <= numel(names) && selected == floor(selected), ...
            'Invalid variable selection.');
    end
end
variableName = names{selected};
if nargin < 3 || isempty(reportFile)
    [matFolder,base] = fileparts(matFile);
    reportFile = fullfile(matFolder,[base '_structure.txt']);
end
fid = fopen(reportFile,'w');
assert(fid >= 0,'Could not create report: %s',reportFile);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fileInfo = dir(matFile);
writeBoth(fid,'%s MAT-FILE INVENTORY\n',upper(variableName));
writeBoth(fid,'%s\n\n',repmat('=',1,numel(variableName)+19));
writeBoth(fid,'File: %s\nFile size: %.3f GB\nModified: %s\n\n', ...
    matFile,fileInfo.bytes/1024^3,fileInfo.date);
writeBoth(fid,'TOP-LEVEL VARIABLES\n-------------------\n\n');
for k = 1:numel(top)
    w = top(k);
    writeBoth(fid,['Variable %d\nName: %s\nClass: %s\nDimensions: %s\n' ...
        'Elements: %g\nBytes: %.0f\nComplex: %d\nSparse: %d\n\n'], ...
        k,w.name,w.class,sizeText(w.size),prod(double(w.size)), ...
        double(w.bytes),w.complex,w.sparse);
end
writeBoth(fid,'SELECTED VARIABLE\n-----------------\n');
writeBoth(fid,'Loading only variable: %s\n\n',variableName);
loaded = load(matFile,variableName);
describeValue(fid,loaded.(variableName),variableName,0,5);
writeBoth(fid,'\nEND OF INVENTORY\n');
fprintf('\nInventory written beside the MAT-file:\n%s\n',reportFile);
end

function describeValue(fid,value,path,depth,maxDepth)
indent = repmat('  ',1,depth);
writeBoth(fid,'%sPath: %s\n%sClass: %s\n%sSize: %s\n%sElements: %g\n', ...
    indent,path,indent,class(value),indent,sizeText(size(value)),indent,numel(value));
if depth >= maxDepth
    writeBoth(fid,'%sMaximum reporting depth reached.\n\n',indent); return
end
if isstruct(value)
    fields = fieldnames(value);
    writeBoth(fid,'%sFields (%d):\n',indent,numel(fields));
    for f = 1:numel(fields), writeBoth(fid,'%s  - %s\n',indent,fields{f}); end
    indices = representativeIndices(numel(value));
    for n = 1:numel(indices)
        idx = indices(n); suffix = indexSuffix(size(value),idx);
        for f = 1:numel(fields)
            describeValue(fid,value(idx).(fields{f}), ...
                sprintf('%s%s.%s',path,suffix,fields{f}),depth+1,maxDepth);
        end
    end
elseif iscell(value)
    writeBoth(fid,'%sCell count: %d\n',indent,numel(value));
    indices = representativeIndices(numel(value));
    for n = 1:numel(indices)
        idx = indices(n);
        describeValue(fid,value{idx},sprintf('%s{%d}',path,idx),depth+1,maxDepth);
    end
elseif isnumeric(value) || islogical(value)
    writeBoth(fid,'%sReal: %d\n',indent,isreal(value));
    writeNumericSample(fid,value,indent);
elseif ischar(value)
    preview = value(1:min(numel(value),300)); suffix = '';
    if numel(value)>300, suffix='...'; end
    writeBoth(fid,'%sValue: %s%s\n',indent,preview,suffix);
elseif isstring(value) || iscategorical(value)
    preview = value(representativeIndices(numel(value)));
    writeBoth(fid,'%sPreview: %s\n',indent,strjoin(cellstr(string(preview)),', '));
elseif istable(value) || istimetable(value)
    writeBoth(fid,'%sVariables (%d): %s\n',indent,width(value), ...
        strjoin(value.Properties.VariableNames,', '));
else
    writeBoth(fid,'%sNo detailed preview implemented for this class.\n',indent);
end
writeBoth(fid,'\n');
end

function writeNumericSample(fid,value,indent)
if isempty(value), writeBoth(fid,'%sEmpty numeric/logical value.\n',indent); return; end
flat = value(:); finite = flat(isfinite(flat));
writeBoth(fid,'%sFinite values: %d of %d\n',indent,numel(finite),numel(flat));
if ~isempty(finite) && isreal(finite)
    writeBoth(fid,'%sMinimum: %.12g\n%sMaximum: %.12g\n', ...
        indent,min(finite),indent,max(finite));
end
indices = representativeIndices(numel(flat));
for k = 1:numel(indices)
    idx = indices(k);
    if isreal(flat(idx))
        writeBoth(fid,'%sValue(%d): %.12g\n',indent,idx,flat(idx));
    else
        writeBoth(fid,'%sValue(%d): %.12g %+.12gi\n',indent,idx, ...
            real(flat(idx)),imag(flat(idx)));
    end
end
end

function indices = representativeIndices(n)
if n <= 0, indices = [];
elseif n <= 3, indices = 1:n;
else, indices = unique([1 2 n]);
end
end
function suffix = indexSuffix(arraySize,linearIndex)
if prod(arraySize)==1, suffix=''; else, suffix=sprintf('(%d)',linearIndex); end
end
function text = sizeText(sz)
text = sprintf('%d x ',sz); text = text(1:end-3);
end
function writeBoth(fid,varargin)
fprintf(fid,varargin{:}); fprintf(varargin{:});
end
