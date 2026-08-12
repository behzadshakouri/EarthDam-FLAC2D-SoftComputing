function report = check_task2_dependencies()
%CHECK_TASK2_DEPENDENCIES Verify the clean-clone MATLAB environment.
root=setup_task2; %#ok<NASGU>
names={'ypea_problem','ypea_var','ypea_abc','ypea_acor', ...
       'IGWO','initialization','boundConstraint','pdist','pdist2','squareform'};
available=false(size(names)); resolved=strings(size(names));
for i=1:numel(names)
    available(i)=exist(names{i},'file')~=0;
    p=which(names{i}); if ~isempty(p),resolved(i)=string(p);end
end
report=table(string(names(:)),available(:),resolved(:), ...
    'VariableNames',{'dependency','available','resolved_path'});
disp(report);
if any(~available)
    error('Task2:MissingDependencies','Missing: %s', ...
        strjoin(names(~available),', '));
end
fprintf('All Task 2 dependencies are available.\n');
end
