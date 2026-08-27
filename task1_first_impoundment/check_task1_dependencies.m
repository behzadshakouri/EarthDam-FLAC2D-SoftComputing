function report = check_task1_dependencies()
%CHECK_TASK1_DEPENDENCIES Verify the clean-clone MATLAB environment.
setup_task1;
names = {'mapminmax','ypea_problem','ypea_var','ypea_abc','ypea_acor', ...
    'IGWO','initialization','boundConstraint','pdist','pdist2','squareform'};
available = false(size(names)); resolved = strings(size(names));
for i=1:numel(names)
    available(i)=exist(names{i},'file')~=0;
    p=which(names{i}); if ~isempty(p), resolved(i)=string(p); end
end
report=table(string(names(:)),available(:),resolved(:), ...
    'VariableNames',{'dependency','available','resolved_path'});
disp(report);
if any(~available)
    error('Task1:MissingDependencies','Missing: %s',strjoin(names(~available),', '));
end
fprintf('All Task 1 dependencies are available.\n');
end
