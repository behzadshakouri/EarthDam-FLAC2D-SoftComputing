function validate_task4_structure(Task4,cfg)
%VALIDATE_TASK4_STRUCTURE Enforce the confirmed raw-data organization.
assert(isstruct(Task4) && isscalar(Task4));
assert(isfield(Task4,'Inputs') && isfield(Task4,'Outputs'));
assert(Task4.Inputs.Simulations == cfg.num_simulations);
assert(Task4.Outputs.Simulations == cfg.num_simulations);
assert(iscell(Task4.Outputs.dytime) && numel(Task4.Outputs.dytime)==450);
for p = 1:cfg.num_points
    pointName = sprintf('P%d',p);
    assert(isfield(Task4.Outputs,pointName),'Missing output point %s.',pointName);
    for r = 1:cfg.num_responses
        responseName = sprintf('R%d',r);
        histories = Task4.Outputs.(pointName).(responseName);
        assert(iscell(histories) && numel(histories)==450, ...
            'Unexpected organization at %s-%s.',pointName,responseName);
    end
end
end
